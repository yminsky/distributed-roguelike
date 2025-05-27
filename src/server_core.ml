open! Core
open! Import
open Async_kernel
open Async_log_kernel.Ppx_log_syntax
module Rpc = Async_rpc_kernel.Rpc

module Connection_state = struct
  type t =
    { mutable player_id : Player_id.t option
    ; mutable connection : Rpc.Connection.t option
    }

  let create () = { player_id = None; connection = None }
  let player_id t = t.player_id
end

module Server_state = struct
  type t =
    { mutable game_state : Game_state.t
    ; mutable next_player_id : int
        (* Counter for generating unique player IDs (e.g., player_1, player_2, etc.) *)
    ; update_writers : Protocol.Update.t Pipe.Writer.t list ref
    ; log : Async_log_kernel.Log.t
    }

  let create log =
    let maze_config =
      Game_state.Maze_config.Generated_dungeon
        (Dungeon_generation.Config.default, Random.int 1000000)
    in
    { game_state = Game_state.create ~maze_config ()
    ; next_player_id = 1
    ; update_writers = ref []
    ; log
    }
  ;;

  let add_update_writer t writer = t.update_writers := writer :: !(t.update_writers)

  let remove_update_writer t writer =
    t.update_writers
    := List.filter !(t.update_writers) ~f:(fun w -> not (phys_equal w writer))
  ;;

  let broadcast_update t update =
    List.iter !(t.update_writers) ~f:(fun writer ->
      if not (Pipe.is_closed writer) then Pipe.write_without_pushback writer update)
  ;;

  let add_player t ~player_name =
    let player_id = Player_id.of_int t.next_player_id in
    t.next_player_id <- t.next_player_id + 1;
    match Game_state.add_player t.game_state ~player_id ~player_name with
    | Ok (new_game_state, player) ->
      t.game_state <- new_game_state;
      broadcast_update t (Player_joined player);
      Ok player
    | Error msg -> Error msg
  ;;

  let move_player t ~player_id ~direction =
    match Game_state.move_player t.game_state ~player_id ~direction with
    | Ok (new_game_state, update) ->
      t.game_state <- new_game_state;
      broadcast_update t update;
      Ok ()
    | Error msg -> Error msg
  ;;

  let remove_player t ~player_id =
    let had_player = Game_state.get_player t.game_state ~player_id |> Option.is_some in
    if had_player
    then (
      t.game_state <- Game_state.remove_player t.game_state ~player_id;
      broadcast_update t (Player_left player_id));
    had_player
  ;;
end

let handle_request server_state connection_state request =
  match request with
  | Protocol.Request.Join { player_name } ->
    (match Server_state.add_player server_state ~player_name with
     | Ok player ->
       connection_state.Connection_state.player_id <- Some player.id;
       [%log.info
         server_state.log
           "Player joined"
           ~player_name:player.name
           ~player_id:(Player_id.to_string player.id)];
       return (Ok ())
     | Error msg ->
       [%log.error server_state.log "Join failed" ~reason:msg];
       return (Error msg))
  | Move { direction } ->
    (match connection_state.Connection_state.player_id with
     | None -> return (Error "Not joined")
     | Some player_id ->
       (match Server_state.move_player server_state ~player_id ~direction with
        | Ok () ->
          [%log.info
            server_state.log
              "Player moved"
              ~player_id:(Player_id.to_string player_id)
              ~direction:(Direction.to_string direction)];
          return (Ok ())
        | Error msg ->
          [%log.error server_state.log "Move failed" ~reason:msg];
          return (Error msg)))
  | Leave ->
    (match connection_state.Connection_state.player_id with
     | None -> return (Ok ())
     | Some player_id ->
       let _ = Server_state.remove_player server_state ~player_id in
       connection_state.Connection_state.player_id <- None;
       [%log.info
         server_state.log "Player left" ~player_id:(Player_id.to_string player_id)];
       return (Ok ()))
;;

let handle_state_rpc server_state connection_state connection =
  let your_id =
    match connection_state.Connection_state.player_id with
    | Some id -> id
    | None ->
      (* TODO: This is broken - we shouldn't create a fake player ID here.
         The protocol should be changed so that your_id is optional in Initial_state. *)
      Player_id.of_int 0
  in
  let initial_state =
    Protocol.Initial_state.
      { your_id
      ; all_players = Game_state.get_players server_state.Server_state.game_state
      ; walls = Game_state.get_walls server_state.Server_state.game_state
      ; npcs = Game_state.get_npcs server_state.Server_state.game_state
      }
  in
  let reader, writer = Pipe.create () in
  Server_state.add_update_writer server_state writer;
  upon (Rpc.Connection.close_finished connection) (fun () ->
    Server_state.remove_update_writer server_state writer;
    Pipe.close writer);
  return (Ok (initial_state, reader))
;;

let create_implementations server_state =
  let request_impl =
    Rpc.Rpc.implement Protocol.Rpc_calls.send_request (fun connection_state request ->
      handle_request server_state connection_state request)
  in
  let state_impl =
    Rpc.State_rpc.implement
      (Protocol.Rpc_calls.get_game_state ())
      (fun connection_state () ->
         match connection_state.Connection_state.connection with
         | None -> return (Error (Error.of_string "Connection not set"))
         | Some connection -> handle_state_rpc server_state connection_state connection)
  in
  [ request_impl; state_impl ]
;;

let serve_with_transport server_state (transport : Rpc.Transport.t) =
  let connection_state = Connection_state.create () in
  let%bind conn_result =
    Rpc.Connection.create
      transport
      ~implementations:
        (Rpc.Implementations.create_exn
           ~implementations:(create_implementations server_state)
           ~on_unknown_rpc:`Close_connection
           ~on_exception:Rpc.On_exception.Close_connection)
      ~connection_state:(fun rpc_conn ->
        connection_state.connection <- Some rpc_conn;
        [%log.info server_state.log "RPC connection established"];
        connection_state)
  in
  match conn_result with
  | Error exn ->
    [%log.error server_state.log "RPC connection failed" ~error:(Exn.to_string exn)];
    return ()
  | Ok rpc_conn ->
    (* Wait for connection to close *)
    let%bind () = Rpc.Connection.close_finished rpc_conn in
    (match connection_state.player_id with
     | None -> ()
     | Some player_id ->
       ignore (Server_state.remove_player server_state ~player_id : bool);
       [%log.info
         server_state.log "Player disconnected" ~player_id:(Player_id.to_string player_id)]);
    return ()
;;

open! Core
open Async_kernel
module Rpc = Async_rpc_kernel.Rpc

(** Core server implementation that works with any RPC transport. This module only depends
    on Async_kernel, not full Async. *)

module Connection_state = struct
  type t =
    { mutable player_id : Protocol.Player_id.t option
    ; mutable connection : Rpc.Connection.t option
    }

  let create () = { player_id = None; connection = None }
end

module Server_state = struct
  type t =
    { mutable game_state : Game_state.t
    ; mutable next_player_id : int
        (* TODO: leave a comment explaining what the next player id is for *)
    ; state_writers : Protocol.Update.t Pipe.Writer.t list ref
    (* TODO: Should these be called state_writers, or update writers?
       Doesn't the latter make more sense? *)
    }

  let create () =
    { game_state = Game_state.create (); next_player_id = 1; state_writers = ref [] }
  ;;

  let add_state_writer t writer = t.state_writers := writer :: !(t.state_writers)

  let remove_state_writer t writer =
    t.state_writers
    := List.filter !(t.state_writers) ~f:(fun w -> not (phys_equal w writer))
  ;;

  let broadcast_update t update =
    List.iter !(t.state_writers) ~f:(fun writer ->
      if not (Pipe.is_closed writer) then Pipe.write_without_pushback writer update)
  ;;

  let add_player t ~player_name =
    let player_id =
      Protocol.Player_id.create (Printf.sprintf "player_%d" t.next_player_id)
    in
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
    | Ok new_game_state ->
      t.game_state <- new_game_state;
      let player = Game_state.get_player t.game_state ~player_id in
      (match player with
       | Some p ->
         broadcast_update t (Player_moved { player_id; new_position = p.position });
         Ok ()
       | None -> Error "Player disappeared after move")
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
       printf
         "Player %s (%s) joined\n%!"
         player.name
         (Protocol.Player_id.to_string player.id);
       return Protocol.Response.Ok
     | Error msg ->
       printf "Join failed: %s\n%!" msg;
       return (Protocol.Response.Error msg))
  | Move { direction } ->
    (match connection_state.Connection_state.player_id with
     | None -> return (Protocol.Response.Error "Not joined")
     | Some player_id ->
       (match Server_state.move_player server_state ~player_id ~direction with
        | Ok () ->
          printf
            "Player %s moved %s\n%!"
            (Protocol.Player_id.to_string player_id)
            (Protocol.Direction.to_string direction);
          return Protocol.Response.Ok
        | Error msg ->
          printf "Move failed: %s\n%!" msg;
          return (Protocol.Response.Error msg)))
  | Leave ->
    (match connection_state.Connection_state.player_id with
     | None -> return Protocol.Response.Ok
     | Some player_id ->
       let _ = Server_state.remove_player server_state ~player_id in
       connection_state.Connection_state.player_id <- None;
       printf "Player %s left\n%!" (Protocol.Player_id.to_string player_id);
       return Protocol.Response.Ok)
;;

let handle_state_rpc server_state connection_state connection =
  let your_id =
    match connection_state.Connection_state.player_id with
    | Some id -> id
    | None -> Protocol.Player_id.create "" (* Not joined yet *)
  in
  let initial_state =
    Protocol.Initial_state.
      { your_id
      ; all_players = Game_state.get_players server_state.Server_state.game_state
      }
  in
  let reader, writer = Pipe.create () in
  Server_state.add_state_writer server_state writer;
  upon (Rpc.Connection.close_finished connection) (fun () ->
    Server_state.remove_state_writer server_state writer;
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
        printf "RPC connection established\n%!";
        connection_state)
  in
  match conn_result with
  | Error exn ->
    printf "RPC connection failed: %s\n%!" (Exn.to_string exn);
    return ()
  | Ok rpc_conn ->
    (* Wait for connection to close *)
    let%bind () = Rpc.Connection.close_finished rpc_conn in
    (match connection_state.player_id with
     | None -> ()
     | Some player_id ->
       ignore (Server_state.remove_player server_state ~player_id : bool);
       printf "Player %s disconnected\n%!" (Protocol.Player_id.to_string player_id));
    return ()
;;

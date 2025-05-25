open! Core
open Async

let default_host = "127.0.0.1"
let default_port = 8080

type game_client =
  { connection : Rpc.Connection.t
  ; mutable your_id : Protocol.Player_id.t
  ; mutable all_players : Protocol.Player.t list
  ; term : Notty_async.Term.t
  }

let send_request client request =
  Rpc.Rpc.dispatch Protocol.Rpc_calls.send_request client.connection request
;;

let handle_input client =
  let handle_movement_key direction =
    let%bind result = send_request client (Move { direction }) in
    match result with
    | Ok Ok -> return `Continue
    | Ok (Error msg) ->
      Stdio.eprintf "Movement failed: %s\n" msg;
      return `Continue
    | Error err ->
      Stdio.eprintf "RPC error: %s\n" (Error.to_string_hum err);
      return `Continue
  in
  let handle_quit_key = function
    | `ASCII ('q' | 'Q') ->
      let%bind _result = send_request client Leave in
      return `Quit
    | _ -> return `Continue
  in
  let handle_key key =
    match Protocol.Key_input.of_notty_key key with
    | Some key_input ->
      (match Game_state.key_to_action key_input with
       | Some direction -> handle_movement_key direction
       | None -> handle_quit_key key)
    | None -> return `Continue (* ignore unmappable keys *)
  in
  let rec loop () =
    let%bind result = Notty_async.Term.events client.term |> Pipe.read in
    match result with
    | `Eof -> return `Quit
    | `Ok event ->
      (match event with
       | `Key (key, []) ->
         let%bind action = handle_key key in
         (match action with
          | `Continue -> loop ()
          | `Quit -> return `Quit)
       | _ -> loop ())
  in
  loop ()
;;

let handle_state_updates client =
  let%bind result =
    Rpc.State_rpc.dispatch (Protocol.Rpc_calls.get_game_state ()) client.connection ()
  in
  let pipe, initial_state, _metadata =
    match result with
    | Ok (Ok (initial_state, pipe, metadata)) -> pipe, initial_state, metadata
    | Ok (Error err) -> failwith ("State RPC failed: " ^ Error.to_string_hum err)
    | Error err -> failwith ("State RPC dispatch failed: " ^ Error.to_string_hum err)
  in
  (* Initialize client state with the initial game state from server *)
  client.your_id <- initial_state.your_id;
  client.all_players <- initial_state.all_players;
  let rec loop () =
    let%bind result = Pipe.read pipe in
    match result with
    | `Eof -> return ()
    | `Ok update ->
      (match update with
       | Player_joined player ->
         client.all_players <- player :: client.all_players;
         loop ()
       | Player_moved { player_id; new_position } ->
         client.all_players
         <- List.map client.all_players ~f:(fun player ->
              if Protocol.Player_id.equal player.id player_id
              then { player with position = new_position }
              else player);
         loop ()
       | Player_left player_id ->
         client.all_players
         <- List.filter client.all_players ~f:(fun player ->
              not (Protocol.Player_id.equal player.id player_id));
         loop ())
  in
  loop ()
;;

let render_loop client =
  let rec loop () =
    let your_player =
      List.find client.all_players ~f:(fun player ->
        Protocol.Player_id.equal player.id client.your_id)
    in
    let center_pos =
      match your_player with
      | Some player -> player.position
      | None -> Protocol.Position.{ x = 0; y = 0 }
    in
    let world_view =
      Display.World_view.
        { players = client.all_players; center_pos; view_width = 60; view_height = 20 }
    in
    let ui = Display.render_ui world_view in
    let%bind () = Notty_async.Term.image client.term ui in
    let%bind () = after (Time_float.Span.of_ms 50.0) in
    loop ()
  in
  loop ()
;;

let connect_to_server ~host ~port ~player_name =
  let%bind socket_result =
    Monitor.try_with (fun () ->
      Tcp.connect (Tcp.Where_to_connect.of_host_and_port { host; port }))
  in
  let _socket, reader, writer =
    match socket_result with
    | Ok result -> result
    | Error exn ->
      printf "Failed to connect to server at %s:%d\n" host port;
      printf "Make sure the server is running: dune exec bin/game_server.exe\n";
      raise exn
  in
  let%bind connection_result =
    Rpc.Connection.create reader writer ~connection_state:(fun _ -> ())
  in
  let connection =
    match connection_result with
    | Ok connection -> connection
    | Error exn -> failwith ("Failed to create RPC connection: " ^ Exn.to_string exn)
  in
  let%bind result =
    Rpc.Rpc.dispatch Protocol.Rpc_calls.send_request connection (Join { player_name })
  in
  match result with
  | Error err -> failwith ("Join request failed: " ^ Error.to_string_hum err)
  | Ok (Error msg) -> failwith ("Join rejected: " ^ msg)
  | Ok Ok ->
    let%bind state_result =
      Rpc.State_rpc.dispatch (Protocol.Rpc_calls.get_game_state ()) connection ()
    in
    let pipe, initial_state =
      match state_result with
      | Ok (Ok (initial_state, pipe, _metadata)) -> pipe, initial_state
      | Ok (Error err) -> failwith ("State RPC failed: " ^ Error.to_string_hum err)
      | Error err -> failwith ("State RPC dispatch failed: " ^ Error.to_string_hum err)
    in
    let%bind term = Notty_async.Term.create () in
    let client =
      { connection
      ; your_id = initial_state.your_id
      ; all_players = initial_state.all_players
      ; term
      }
    in
    return (client, pipe)
;;

let main_loop ~host ~port ~player_name =
  let%bind client, _update_pipe = connect_to_server ~host ~port ~player_name in
  let%bind () = Notty_async.Term.cursor client.term (Some (0, 0)) in
  don't_wait_for (render_loop client);
  don't_wait_for (handle_state_updates client);
  let%bind result = handle_input client in
  match result with
  | `Quit -> return ()
  | `Continue -> return ()
;;

let command =
  let open Command.Let_syntax in
  Command.async
    ~summary:"Game client"
    [%map_open
      let host =
        flag
          "-host"
          (optional_with_default default_host string)
          ~doc:(Printf.sprintf "HOST Server host (default: %s)" default_host)
      and port =
        flag
          "-port"
          (optional_with_default default_port int)
          ~doc:(Printf.sprintf "PORT Server port (default: %d)" default_port)
      and player_name =
        flag
          "-name"
          (optional_with_default "Player" string)
          ~doc:"NAME Player name (default: Player)"
      in
      fun () -> main_loop ~host ~port ~player_name]
;;

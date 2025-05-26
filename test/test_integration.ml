open! Core
open Async
open Lan_rogue

(** Integration tests using pipe transport for deterministic client-server testing. *)

(* Create a test log with stable output for testing *)
let test_log = Log.For_testing.create `Info ~map_output:(fun s -> s)

let test_client_server_with_pipe_transport () =
  (* Create a pair of transports connected by pipes *)
  let client_transport, server_transport =
    Async_rpc_kernel.Pipe_transport.create_pair
      Async_rpc_kernel.Pipe_transport.Kind.bigstring
  in
  (* Set up server *)
  let server_state = Server_core.Server_state.create test_log in
  (* Start server in the background *)
  don't_wait_for (Server_core.serve_with_transport server_state server_transport);
  (* Create client connection *)
  let%bind client_conn_result =
    Async_rpc_kernel.Rpc.Connection.create client_transport ~connection_state:(fun _ ->
      ())
  in
  let client_conn =
    match client_conn_result with
    | Ok conn -> conn
    | Error exn -> failwith ("Failed to create client connection: " ^ Exn.to_string exn)
  in
  (* Test: Client joins the game *)
  let%bind join_result =
    Rpc.Rpc.dispatch
      Protocol.Rpc_calls.send_request
      client_conn
      (Protocol.Request.Join { player_name = "TestPlayer" })
  in
  (match join_result with
   | Ok (Ok ()) -> printf "Join successful\n"
   | Ok (Error msg) -> printf "Join failed: %s\n" msg
   | Error err -> printf "RPC error: %s\n" (Error.to_string_hum err));
  (* Get game state *)
  let%bind state_result =
    Rpc.State_rpc.dispatch (Protocol.Rpc_calls.get_game_state ()) client_conn ()
  in
  let pipe, initial_state =
    match state_result with
    | Ok (Ok (initial_state, pipe, _metadata)) -> pipe, initial_state
    | Ok (Error err) -> failwith ("State RPC failed: " ^ Error.to_string_hum err)
    | Error err -> failwith ("State RPC dispatch failed: " ^ Error.to_string_hum err)
  in
  printf
    "Got initial state. Your ID: %s, Players: %d\n"
    (Player_id.to_string initial_state.your_id)
    (List.length initial_state.all_players);
  (* Test: Move player *)
  let%bind move_result =
    Rpc.Rpc.dispatch
      Protocol.Rpc_calls.send_request
      client_conn
      (Protocol.Request.Move { direction = Up })
  in
  (match move_result with
   | Ok (Ok ()) -> printf "Move successful\n"
   | Ok (Error msg) -> printf "Move failed: %s\n" msg
   | Error err -> printf "RPC error: %s\n" (Error.to_string_hum err));
  (* Wait for state update *)
  let%bind update_result = Pipe.read pipe in
  (match update_result with
   | `Eof -> printf "Update pipe closed\n"
   | `Ok update ->
     (match update with
      | Protocol.Update.Player_moved { player_id; new_position } ->
        printf
          "Player %s moved to (%d, %d)\n"
          (Player_id.to_string player_id)
          new_position.x
          new_position.y
      | _ -> printf "Got other update\n"));
  (* Clean up *)
  let%bind () = Async_rpc_kernel.Rpc.Connection.close client_conn in
  Clock.after (Time_float.Span.of_ms 100.0)
;;

(* Give server time to clean up *)

let%expect_test "client-server communication via pipe transport" =
  let%bind () = test_client_server_with_pipe_transport () in
  [%expect
    {|
    "RPC connection established"
    ("Player joined"(player_name TestPlayer)(player_id 1))
    Join successful
    Got initial state. Your ID: 1, Players: 1
    ("Player moved"(player_id 1)(direction Up))
    Move successful
    Player 1 moved to (0, -1)
    ("Player disconnected"(player_id 1))
    |}];
  return ()
;;

(** The direct server tests from before still work *)
let%expect_test "server handles client join directly" =
  let server_state = Server_core.Server_state.create test_log in
  let connection_state = Server_core.Connection_state.create () in
  let%bind response =
    Server_core.handle_request
      server_state
      connection_state
      (Protocol.Request.Join { player_name = "Alice" })
  in
  (match response with
   | Ok () ->
     printf "Join successful\n";
     (match Server_core.Connection_state.player_id connection_state with
      | Some id -> printf "Player ID set to: %s\n" (Player_id.to_string id)
      | None -> printf "Error: Player ID not set\n")
   | Error msg -> printf "Join failed: %s\n" msg);
  [%expect
    {|
    ("Player joined"(player_name Alice)(player_id 1))
    Join successful
    Player ID set to: 1
    |}];
  return ()
;;

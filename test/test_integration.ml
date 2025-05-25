open! Core
open Async
open Lan_rogue

(** Integration tests for client-server communication.

    For now, we'll test the server logic directly without going through the full RPC
    transport layer. This allows us to test the game logic in a deterministic way. *)

let%expect_test "server handles client join" =
  let server_state = Server.Server_state.create () in
  let connection_state = Server.Connection_state.create () in
  (* Simulate a join request *)
  let%bind response =
    Server.handle_request
      server_state
      connection_state
      (Protocol.Request.Join { player_name = "Alice" })
  in
  (match response with
   | Protocol.Response.Ok ->
     printf "Join successful\n";
     (match connection_state.player_id with
      | Some id -> printf "Player ID set to: %s\n" id
      | None -> printf "Error: Player ID not set\n")
   | Protocol.Response.Error msg -> printf "Join failed: %s\n" msg);
  [%expect
    {|
    Player Alice (player_1) joined
    Join successful
    Player ID set to: player_1
  |}];
  return ()
;;

let%expect_test "server handles player movement" =
  let server_state = Server.Server_state.create () in
  let connection_state = Server.Connection_state.create () in
  (* First join *)
  let%bind _ =
    Server.handle_request
      server_state
      connection_state
      (Protocol.Request.Join { player_name = "Bob" })
  in
  (* Then move *)
  let%bind response =
    Server.handle_request
      server_state
      connection_state
      (Protocol.Request.Move { direction = Protocol.Direction.Up })
  in
  (match response with
   | Protocol.Response.Ok -> printf "Move successful\n"
   | Protocol.Response.Error msg -> printf "Move failed: %s\n" msg);
  [%expect
    {|
    Player Bob (player_1) joined
    Player player_1 moved Up
    Move successful
  |}];
  return ()
;;

let%expect_test "server rejects movement without join" =
  let server_state = Server.Server_state.create () in
  let connection_state = Server.Connection_state.create () in
  (* Try to move without joining *)
  let%bind response =
    Server.handle_request
      server_state
      connection_state
      (Protocol.Request.Move { direction = Protocol.Direction.Down })
  in
  (match response with
   | Protocol.Response.Ok -> printf "Move successful\n"
   | Protocol.Response.Error msg -> printf "Move failed: %s\n" msg);
  [%expect
    {|
    Move failed: Not joined
  |}];
  return ()
;;

let%expect_test "server handles player leave" =
  let server_state = Server.Server_state.create () in
  let connection_state = Server.Connection_state.create () in
  (* First join *)
  let%bind _ =
    Server.handle_request
      server_state
      connection_state
      (Protocol.Request.Join { player_name = "Charlie" })
  in
  (* Then leave *)
  let%bind response =
    Server.handle_request server_state connection_state Protocol.Request.Leave
  in
  (match response with
   | Protocol.Response.Ok ->
     printf "Leave successful\n";
     (match connection_state.player_id with
      | Some _ -> printf "Error: Player ID still set\n"
      | None -> printf "Player ID cleared\n")
   | Protocol.Response.Error msg -> printf "Leave failed: %s\n" msg);
  [%expect
    {|
    Player Charlie (player_1) joined
    Player player_1 left
    Leave successful
    Player ID cleared
  |}];
  return ()
;;

(** TODO: In the future, we can add tests using Pipe_transport for full RPC integration
    testing. This will require creating a proper test harness that can handle the async
    RPC protocol. *)

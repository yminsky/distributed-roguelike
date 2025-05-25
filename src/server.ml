open! Core
open Async

(** TCP server that uses Server_core for the actual game logic. *)

let default_port = 8080

(* Re-export from Server_core for compatibility *)
module Connection_state = Server_core.Connection_state
module Server_state = Server_core.Server_state

let handle_request = Server_core.handle_request
let create_implementations = Server_core.create_implementations

let start_server ~port =
  let server_state = Server_state.create () in
  printf "Starting game server on port %d\n%!" port;
  let%bind server =
    Tcp.Server.create
      ~on_handler_error:`Raise
      (Tcp.Where_to_listen.of_port port)
      (fun inet_addr reader writer ->
         printf "Client connected from %s\n%!" (Socket.Address.Inet.to_string inet_addr);
         (* Create transport from reader/writer *)
         let transport =
           Rpc.Transport.of_reader_writer
             reader
             writer
             ~max_message_size:(64 * 1024 * 1024)
         in
         Server_core.serve_with_transport server_state transport)
  in
  printf "Game server listening on port %d\n%!" port;
  Tcp.Server.close_finished server
;;

let main_loop ~port = start_server ~port

let command =
  let open Command.Let_syntax in
  Command.async
    ~summary:"Game server"
    [%map_open
      let port =
        flag
          "-port"
          (optional_with_default default_port int)
          ~doc:(Printf.sprintf "PORT Server port (default: %d)" default_port)
      in
      fun () -> main_loop ~port]
;;

open! Core
open! Import
open Async

let default_port = 8080

let start_server ~port =
  let server_state = Server_core.Server_state.create () in
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
      fun () -> start_server ~port]
;;

open! Core
open Async

let main_loop () =
  printf "Game server placeholder - will implement actual server logic\n%!";
  return ()

let command =
  Command.async
    ~summary:"Game server"
    (Command.Param.return main_loop)

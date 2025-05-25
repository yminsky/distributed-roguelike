open! Core
open Lan_rogue

(** Print a map to stdout for expect tests *)
val print_map : width:int -> height:int -> walls:Position.Set.t -> title:string -> unit

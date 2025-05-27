(** Non-player characters (NPCs) in the game world *)

open! Core
open! Import

type t =
  { id : string
  ; position : Position.t
  ; hit_points : int
  ; max_hit_points : int
  ; sigil : char
  ; name : string
  }
[@@deriving sexp, bin_io, compare, equal]

val create : id:string -> position:Position.t -> name:string -> sigil:char -> hit_points:int -> t
val take_damage : t -> damage:int -> t option (** Returns None if NPC dies *)
val is_alive : t -> bool
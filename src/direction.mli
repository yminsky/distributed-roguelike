(** Cardinal directions for movement in the game *)

open! Core
open! Import

type t =
  | Up
  | Down
  | Left
  | Right
[@@deriving sexp, bin_io, compare, equal]

val to_string : t -> string
val to_delta : t -> int * int
val apply_to_position : t -> Position.t -> Position.t

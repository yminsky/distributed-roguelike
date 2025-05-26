open! Core
open! Import

type t =
  | Up
  | Down
  | Left
  | Right
[@@deriving sexp, bin_io, compare, equal]

let to_string = function
  | Up -> "Up"
  | Down -> "Down"
  | Left -> "Left"
  | Right -> "Right"
;;

let to_delta = function
  | Up -> 0, -1
  | Down -> 0, 1
  | Left -> -1, 0
  | Right -> 1, 0
;;

let apply_to_position t pos =
  let dx, dy = to_delta t in
  { x = pos.x + dx; y = pos.y + dy }
;;

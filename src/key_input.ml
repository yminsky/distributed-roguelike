open! Core
open! Import

type t =
  | ASCII of char
  | Arrow of Direction.t
[@@deriving sexp, bin_io, compare]

let of_notty_key = function
  | `ASCII c -> Some (ASCII c)
  | `Arrow `Up -> Some (Arrow Up)
  | `Arrow `Down -> Some (Arrow Down)
  | `Arrow `Left -> Some (Arrow Left)
  | `Arrow `Right -> Some (Arrow Right)
  | _ -> None
;;

let to_string = function
  | ASCII c -> Printf.sprintf "ASCII '%c'" c
  | Arrow dir -> Printf.sprintf "Arrow %s" (Direction.to_string dir)
;;

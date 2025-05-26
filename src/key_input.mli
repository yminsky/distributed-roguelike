(** Key input representation for terminal-based controls *)

open! Core
open! Import

type t =
  | ASCII of char
  | Arrow of Direction.t
[@@deriving sexp, bin_io, compare]

val of_notty_key
  :  [> `ASCII of char | `Arrow of [> `Up | `Down | `Left | `Right ] ]
  -> t option

val to_string : t -> string

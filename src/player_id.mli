(** Unique identifier for players, assigned by the server *)

open! Core
open! Import

type t [@@deriving sexp, bin_io, compare, equal]

include Comparable.S with type t := t

val of_int : int -> t
val to_int : t -> int
val to_string : t -> string

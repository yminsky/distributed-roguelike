open! Core
open! Import

type t = int [@@deriving sexp, bin_io, compare, equal]

include functor Comparable.Make

let of_int i = i
let to_int t = t
let to_string t = Int.to_string t

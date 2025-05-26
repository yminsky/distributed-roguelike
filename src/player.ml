open! Core
open! Import

type t =
  { id : Player_id.t
  ; position : Position.t
  ; name : string
  ; sigil : char
  }
[@@deriving sexp, bin_io]

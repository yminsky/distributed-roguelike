open! Core

type t =
  { x : int
  ; y : int
  }
[@@deriving sexp, bin_io, compare, equal]

include functor Comparable.Make

module Export = struct
  type position = t =
    { x : int
    ; y : int
    }
end

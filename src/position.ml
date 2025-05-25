open! Core

type t =
  { x : int
  ; y : int
  }
[@@deriving sexp, bin_io, compare, equal]

include Comparable.Make (struct
    type nonrec t = t [@@deriving sexp, compare]
  end)

module Export = struct
  type position = t =
    { x : int
    ; y : int
    }
end

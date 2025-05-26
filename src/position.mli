(** Position in 2D space *)

open! Core

type t =
  { x : int
  ; y : int
  }
[@@deriving sexp, bin_io, compare, equal]

include Comparable.S with type t := t

(** Submodule for convenient field access *)
module Export : sig
  (** Type alias that allows direct field access when opened *)
  type position = t =
    { x : int
    ; y : int
    }
end

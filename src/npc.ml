open! Core
open! Import

type t =
  { id : string
  ; position : Position.t
  ; hit_points : int
  ; max_hit_points : int
  ; sigil : char
  ; name : string
  }
[@@deriving sexp, bin_io, compare, equal]

let create ~id ~position ~name ~sigil ~hit_points =
  { id; position; hit_points; max_hit_points = hit_points; sigil; name }
;;

let take_damage t ~damage =
  let new_hp = t.hit_points - damage in
  if new_hp <= 0 then None else Some { t with hit_points = new_hp }
;;

let is_alive t = t.hit_points > 0
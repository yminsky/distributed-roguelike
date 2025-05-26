(** Shadow-casting based visibility calculation for roguelike field-of-view.

    This module implements recursive shadow-casting algorithm to determine which tiles are
    visible from a given position, taking walls into account. *)

(* TODO: The implementation actually uses ray-casting with Bresenham's algorithm,
   not shadow-casting. Either update the docs or implement proper shadow-casting. *)

open! Core
open! Import

(* TODO: This module uses Protocol.Position.t instead of just Position.t,
   creating unnecessary coupling to the Protocol module. *)

(** Compute visible tiles from a given position using shadow-casting.

    @param from The viewing position
    @param walls Set of positions that block vision
    @param max_radius Maximum viewing distance (manhattan distance)
    @return Set of positions visible from the viewing position *)
val compute_visible_tiles
  :  from:Protocol.Position.t
  -> walls:Protocol.Position.Set.t
  -> max_radius:int
  -> Protocol.Position.Set.t

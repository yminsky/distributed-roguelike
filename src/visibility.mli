(** Shadow-casting based visibility calculation for roguelike field-of-view.

    This module implements recursive shadow-casting algorithm to determine which tiles are
    visible from a given position, taking walls into account. *)

open! Core
open! Import

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

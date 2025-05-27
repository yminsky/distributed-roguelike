(** Non-player characters (NPCs) in the game world.

    This module provides the core abstraction for NPCs that can be extended to support
    different NPC types (enemies, merchants, quest-givers, etc.). The interface is
    designed to be minimal but sufficient for the game framework's needs while keeping NPC
    internals private. *)

open! Core
open! Import

(** Abstract type representing an NPC. The internal representation is hidden to allow for
    future extensibility with different NPC types. *)
type t [@@deriving sexp, bin_io]

(** Unique identifier for NPCs *)
module Id : sig
  type t [@@deriving sexp, bin_io, compare, equal]

  include Comparable.S with type t := t

  val create : unit -> t
  val to_string : t -> string
  val of_string : string -> t
end

(** Actions that NPCs can take during their turn *)
module Action : sig
  type t =
    | Move of Direction.t
    | Attack of
        { target : Player_id.t
        ; damage : int
        }
    | Wait
    | Speak of { message : string }
  [@@deriving sexp, bin_io]
end

(** Updates that can be applied to NPCs from external sources *)
module Update : sig
  type t =
    | Move_to of Position.t
    | Take_damage of
        { amount : int
        ; from : Player_id.t option
        }
    | Heal of int
    | Time_passed (** For any time-based state changes *)
  [@@deriving sexp, bin_io]
end

(** Information about the game world that NPCs need to make decisions *)
module World_view : sig
  type t =
    { players : (Player_id.t * Position.t) list (** Player positions *)
    ; other_npcs : (Id.t * Position.t) list (** Other NPC positions *)
    ; walls : Position.t list (** Wall positions *)
    }
  [@@deriving sexp, bin_io]
end

(** Create a new NPC. For now, this creates a basic NPC with the given parameters. In the
    future, this will be replaced with factory functions for specific NPC types. *)
val create
  :  id:Id.t
  -> position:Position.t
  -> name:string (** Display name for the NPC (e.g., "Goblin", "Merchant") *)
  -> sigil:char
  -> hit_points:int
  -> t

(** Essential queries the game framework needs *)

val id : t -> Id.t

(** Current location in the game world *)
val position : t -> Position.t

val sigil : t -> char

(** Display name (e.g., "Goblin", "Merchant") *)
val name : t -> string

val is_alive : t -> bool

(** Core behavior - decide what action to take this turn based on a view of the world.
    This is where NPC AI logic lives. *)
val think : t -> world_view:World_view.t -> Action.t

(** Apply an update to the NPC. Returns None if the NPC dies as a result. *)
val update : t -> Update.t -> t option

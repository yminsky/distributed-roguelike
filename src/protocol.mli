(** Protocol definitions for client-server communication in LAN Rogue *)

open! Core
open! Import
open Async

module Direction : sig
  type t =
    | Up
    | Down
    | Left
    | Right
  [@@deriving sexp, bin_io, compare, equal]

  val to_string : t -> string
  val to_delta : t -> int * int
  val apply_to_position : t -> Position.t -> Position.t
end

module Key_input : sig
  type t =
    | ASCII of char
    | Arrow of Direction.t
  [@@deriving sexp, bin_io, compare]

  val of_notty_key
    :  [> `ASCII of char | `Arrow of [> `Up | `Down | `Left | `Right ] ]
    -> t option

  val to_string : t -> string
end

module Player_id : sig
  type t [@@deriving sexp, bin_io, compare, equal]

  include Comparable.S with type t := t

  val of_int : int -> t
  val to_int : t -> int
  val to_string : t -> string
end

module Player : sig
  type t =
    { id : Player_id.t
    ; position : Position.t
    ; name : string
    ; sigil : char
    }
  [@@deriving sexp, bin_io]
end

module Request : sig
  type t =
    | Join of { player_name : string }
    | Move of { direction : Direction.t }
    | Leave
  [@@deriving sexp, bin_io]
end

module Update : sig
  type t =
    | Player_joined of Player.t
    | Player_moved of
        { player_id : Player_id.t
        ; new_position : Position.t
        }
    | Player_left of Player_id.t
  [@@deriving sexp, bin_io]
end

module Initial_state : sig
  type t =
    { your_id : Player_id.t
    ; all_players : Player.t list
    ; walls : Position.t list
    }
  [@@deriving sexp, bin_io]
end

module Response : sig
  type t = (unit, string) Result.t [@@deriving sexp, bin_io]
end

module Rpc_calls : sig
  val send_request : (Request.t, Response.t) Rpc.Rpc.t
  val get_game_state : unit -> (unit, Initial_state.t, Update.t, Error.t) Rpc.State_rpc.t
end

(** Protocol definitions for client-server communication in LAN Rogue *)

open! Core
open! Import
open Async

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

(** Multiplayer rogue-like game server that manages player state and handles RPC requests. *)

open! Core
open Async

val command : Command.t

(** Internal modules exposed for testing *)
module Connection_state : sig
  type t =
    { mutable player_id : Protocol.Player_id.t option
    ; mutable connection : Rpc.Connection.t option
    }

  val create : unit -> t
end

module Server_state : sig
  type t

  val create : unit -> t
end

val create_implementations
  :  Server_state.t
  -> Connection_state.t Rpc.Implementation.t list

val handle_request
  :  Server_state.t
  -> Connection_state.t
  -> Protocol.Request.t
  -> Protocol.Response.t Deferred.t

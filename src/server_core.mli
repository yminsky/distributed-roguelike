(** Core server implementation that works with any RPC transport. *)

open! Core
open Async_kernel
module Rpc = Async_rpc_kernel.Rpc

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

val handle_request
  :  Server_state.t
  -> Connection_state.t
  -> Protocol.Request.t
  -> Protocol.Response.t Deferred.t

val create_implementations
  :  Server_state.t
  -> Connection_state.t Rpc.Implementation.t list

(** Serve a single client connection using the given transport. Returns when the
    connection closes. *)
val serve_with_transport : Server_state.t -> Rpc.Transport.t -> unit Deferred.t

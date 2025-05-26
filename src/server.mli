(** Multiplayer rogue-like game server that manages player state and handles RPC requests.

    TCP server that uses Server_core for the actual game logic. *)

open! Core
open! Import

val command : Command.t

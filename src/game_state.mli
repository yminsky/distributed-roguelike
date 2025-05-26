(** Core game state management with multiplayer support, collision detection, and
    spawning. *)

open! Core
open! Import

type t

(** Maze configuration options *)
module Maze_config : sig
  type t =
    | No_maze (** Empty level with no walls *)
    | Test_maze (** Simple 7x7 room for testing *)
    | Generated_maze of Maze_generation.Config.t * int
    (** Generated maze with config and seed *)
    | Generated_dungeon of Dungeon_generation.Config.t * int
    (** Generated dungeon with config and seed *)
end

(** Create game state with specified maze configuration. Defaults to No_maze if not
    specified. *)
val create : ?maze_config:Maze_config.t -> unit -> t

(** Add a new player with unique spawn position and sigil. Returns Error if server is full
    or no sigils available. *)
val add_player
  :  t
  -> player_id:Protocol.Player_id.t
  -> player_name:string
  -> (t * Protocol.Player.t, string) Result.t

val remove_player : t -> player_id:Protocol.Player_id.t -> t

(** Move a player in the given direction. Returns Error if player not found or collision
    detected. On success, returns the new state and the update to broadcast. *)
val move_player
  :  t
  -> player_id:Protocol.Player_id.t
  -> direction:Protocol.Direction.t
  -> (t * Protocol.Update.t, string) Result.t

val get_players : t -> Protocol.Player.t list
val get_player : t -> player_id:Protocol.Player_id.t -> Protocol.Player.t option
val get_walls : t -> Protocol.Position.t list

(** Convert keyboard input to movement direction. Returns None for quit keys ('q') or
    unmappable input. *)
val key_to_action : Protocol.Key_input.t -> Protocol.Direction.t option

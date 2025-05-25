(** Core game state management with multiplayer support, collision detection, and
    spawning. *)

open! Core

type t

(** Create empty game state with max_players of 10. 
    If use_test_maze is true, creates a simple test maze with walls. *)
val create : ?use_test_maze:bool -> unit -> t

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

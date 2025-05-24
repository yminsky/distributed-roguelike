open! Core

type t

val create : ?max_players:int -> unit -> t

val add_player 
  : t 
  -> player_id:Protocol.Player_id.t 
  -> player_name:string 
  -> (t * Protocol.Player.t, string) Result.t

val remove_player : t -> player_id:Protocol.Player_id.t -> t

val move_player 
  : t 
  -> player_id:Protocol.Player_id.t 
  -> direction:Protocol.Direction.t 
  -> (t, string) Result.t

val get_players : t -> Protocol.Player.t list

val get_player : t -> player_id:Protocol.Player_id.t -> Protocol.Player.t option

val key_to_action
  : Protocol.Key_input.t
  -> Protocol.Direction.t option
(** Rendering engine for the game world using Notty terminal graphics. *)

open! Core
open! Import

module World_view : sig
  (** Configuration for what portion of the game world to render. *)
  type t =
    { players : Player.t list
    ; walls : Position.t list
    ; center_pos : Position.t (** Position to center the view on *)
    ; view_width : int
    ; view_height : int
    ; visible_positions : Position.Set.t
    (** Positions currently visible to the viewing player *)
    ; messages : string list (** Recent messages to display *)
    }
end

(** Render just the game grid with player positions. *)
val render_grid : World_view.t -> Notty.image

(** Render the complete UI including grid, status bar, and help text. *)
val render_ui : World_view.t -> Notty.image

(** Build a World_view from game state for a specific player.

    @param players All players in the game
    @param walls All wall positions
    @param viewing_player_id The player whose perspective we're viewing from
    @param view_width Width of the viewing area
    @param view_height Height of the viewing area
    @return World_view configured for the viewing player *)
val build_world_view
  :  players:Player.t list
  -> walls:Position.t list
  -> viewing_player_id:Player_id.t
  -> view_width:int
  -> view_height:int
  -> messages:string list
  -> World_view.t

(** Rendering engine for the game world using Notty terminal graphics. *)

open! Core

module World_view : sig
  (** Configuration for what portion of the game world to render. *)
  type t =
    { players : Protocol.Player.t list
    ; walls : Protocol.Position.t list
    ; center_pos : Protocol.Position.t (** Position to center the view on *)
    ; view_width : int
    ; view_height : int
    ; visible_positions : Protocol.Position.Set.t
    (** Positions currently visible to the viewing player *)
    }
end

(** Render just the game grid with player positions. *)
val render_grid : World_view.t -> Notty.image

(** Render the complete UI including grid, status bar, and help text. *)
val render_ui : World_view.t -> Notty.image

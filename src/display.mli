open! Core

module World_view : sig
  type t =
    { players : Protocol.Player.t list
    ; center_pos : Protocol.Position.t
    ; view_width : int
    ; view_height : int
    }
end

val render_grid : World_view.t -> Notty.image
val render_ui : World_view.t -> Notty.image

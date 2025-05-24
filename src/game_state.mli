open! Core

module Local_state : sig
  type t = { player_pos : Protocol.Position.t }

  val create : unit -> t
  val move_player : t -> [ `Up | `Down | `Left | `Right ] -> t
end

module Action : sig
  type t =
    | Move of [ `Up | `Down | `Left | `Right ]
    | Quit
  [@@deriving sexp]
end

val apply_action : Local_state.t -> Action.t -> Local_state.t
val key_to_action : [> `ASCII of char ] -> Action.t option

val to_world_view
  :  Local_state.t
  -> view_width:int
  -> view_height:int
  -> Display.World_view.t

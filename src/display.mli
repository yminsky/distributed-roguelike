open! Core

type world_view = {
  player_pos : Protocol.position;
  view_width : int;
  view_height : int;
}

val render_grid : world_view -> Notty.image

val render_ui : world_view -> Notty.image
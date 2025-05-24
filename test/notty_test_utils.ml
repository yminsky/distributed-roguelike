open! Core

(* Convert a Notty image to a plain text string representation *)
let render_to_string image = Format.asprintf "%a" (Notty.Render.pp Notty.Cap.dumb) image

(* Convenience function for rendering game state with a single player *)
let render_state_to_string ?(width = 21) ?(height = 11) state ~player_id =
  let players = Lan_rogue.Game_state.get_players state in
  let center_pos = match Lan_rogue.Game_state.get_player state ~player_id with
    | Some player -> player.position
    | None -> Lan_rogue.Protocol.Position.{ x = 0; y = 0 }
  in
  let world_view = Lan_rogue.Display.World_view.{
    players;
    center_pos;
    view_width = width;
    view_height = height;
  } in
  let image = Lan_rogue.Display.render_ui world_view in
  render_to_string image
;;

open! Core

(* Convert a Notty image to a plain text string representation *)
let render_to_string image = Format.asprintf "%a" (Notty.Render.pp Notty.Cap.dumb) image

(* Convenience function for rendering game state *)
let render_state_to_string ?(width = 21) ?(height = 11) state =
  let world_view =
    Lan_rogue.Game_state.to_world_view state ~view_width:width ~view_height:height
  in
  let image = Lan_rogue.Display.render_ui world_view in
  render_to_string image
;;

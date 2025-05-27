open! Core

(* Convert a Notty image to a plain text string representation *)
let render_to_string image = Format.asprintf "%a" (Notty.Render.pp Notty.Cap.dumb) image

(* Convenience function for rendering game state with a single player *)
let render_state_to_string ?(width = 21) ?(height = 11) state ~player_id =
  let players = Lan_rogue.Game_state.get_players state in
  let walls = Lan_rogue.Game_state.get_walls state in
  let npcs = Lan_rogue.Game_state.get_npcs state in
  let world_view =
    Lan_rogue.Display.build_world_view
      ~players
      ~walls
      ~npcs
      ~viewing_player_id:player_id
      ~view_width:width
      ~view_height:height
      ~messages:[]
  in
  let image = Lan_rogue.Display.render_ui world_view in
  render_to_string image
;;

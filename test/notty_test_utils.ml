open! Core

(* Convert a Notty image to a plain text string representation *)
let render_to_string ?(width = 60) ?(height = 20) image =
  let content = Format.asprintf "%a" (Notty.Render.pp Notty.Cap.dumb) image in
  (* Clean up the output and ensure proper dimensions *)
  let lines = String.split_lines content in
  let padded_lines =
    List.take lines height
    |> List.mapi ~f:(fun i line ->
      if i < List.length lines
      then (
        let len = String.length line in
        if len >= width
        then String.prefix line width
        else line ^ String.make (width - len) ' ')
      else String.make width ' ')
  in
  String.concat ~sep:"\n" padded_lines
;;

(* Convenience function for rendering game state *)
let render_state_to_string ?(width = 21) ?(height = 11) state =
  let world_view =
    Lan_rogue.Game_state.to_world_view state ~view_width:width ~view_height:height
  in
  let image = Lan_rogue.Display.render_ui world_view in
  render_to_string ~width ~height image
;;

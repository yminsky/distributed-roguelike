open! Core

module World_view = struct
  type t =
    { player_pos : Protocol.Position.t
    ; view_width : int
    ; view_height : int
    }
end

let render_grid (world_view : World_view.t) =
  let { World_view.player_pos = { x = px; y = py }; view_width; view_height } =
    world_view
  in
  let half_width = view_width / 2 in
  let half_height = view_height / 2 in
  let images = ref [] in
  for row = 0 to view_height - 1 do
    let world_y = py - half_height + row in
    let line_images = ref [] in
    for col = 0 to view_width - 1 do
      let world_x = px - half_width + col in
      let ch =
        if world_x = px && world_y = py
        then '@' (* Player character *)
        else if world_x mod 10 = 0 || world_y mod 10 = 0
        then '.' (* Grid markers every 10 units *)
        else ' ' (* Empty space *)
      in
      let color =
        if world_x = px && world_y = py
        then Notty.A.(fg lightgreen)
        else if world_x mod 10 = 0 || world_y mod 10 = 0
        then Notty.A.(fg lightblack)
        else Notty.A.empty
      in
      line_images := Notty.I.(string color (String.of_char ch)) :: !line_images
    done;
    images := Notty.I.(hcat (List.rev !line_images)) :: !images
  done;
  Notty.I.(vcat (List.rev !images))
;;

let render_ui (world_view : World_view.t) =
  let grid = render_grid world_view in
  let { World_view.player_pos = { x; y }; _ } = world_view in
  let status =
    Notty.I.(
      string
        Notty.A.(fg white)
        (sprintf "Position: (%d, %d) | Use WASD to move, Q to quit" x y))
  in
  Notty.I.(grid <-> Notty.I.(string Notty.A.empty "") <-> status)
;;

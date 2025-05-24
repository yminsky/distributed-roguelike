open! Core

let grid_marker_spacing = 10

module World_view = struct
  type t =
    { players : Protocol.Player.t list
    ; center_pos : Protocol.Position.t
    ; view_width : int
    ; view_height : int
    }
end

let render_grid (world_view : World_view.t) =
  let { World_view.center_pos = { x = cx; y = cy }; view_width; view_height; players } =
    world_view
  in
  let half_width = view_width / 2 in
  let half_height = view_height / 2 in
  (* Create position -> player lookup *)
  let player_map =
    List.fold players ~init:[] ~f:(fun acc player -> (player.position, player) :: acc)
  in
  let render_empty_cell world_x world_y =
    if world_x mod grid_marker_spacing = 0 || world_y mod grid_marker_spacing = 0
    then '.', Notty.A.(fg lightblack) (* Grid markers *)
    else ' ', Notty.A.empty
  in
  let render_cell world_x world_y =
    let world_pos = Protocol.Position.{ x = world_x; y = world_y } in
    let ch, color =
      match List.Assoc.find player_map world_pos ~equal:Protocol.Position.equal with
      | Some player -> player.sigil, Notty.A.(fg lightgreen)
      | None -> render_empty_cell world_x world_y
    in
    Notty.I.(string color (String.of_char ch))
  in
  let render_row row =
    let world_y = cy - half_height + row in
    let cols = List.range 0 view_width in
    let line_images =
      List.map cols ~f:(fun col ->
        let world_x = cx - half_width + col in
        render_cell world_x world_y)
    in
    Notty.I.(hcat line_images)
  in
  let rows = List.range 0 view_height in
  let images = List.map rows ~f:render_row in
  Notty.I.(vcat images)
;;

let render_ui (world_view : World_view.t) =
  let grid = render_grid world_view in
  let { World_view.center_pos = { x; y }; players; _ } = world_view in
  let player_count = List.length players in
  let status =
    Notty.I.(
      string
        Notty.A.(fg white)
        (sprintf
           "Center: (%d, %d) | Players: %d | Use WASD to move, Q to quit"
           x
           y
           player_count))
  in
  Notty.I.(grid <-> Notty.I.(string Notty.A.empty "") <-> status)
;;

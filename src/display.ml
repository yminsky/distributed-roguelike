open! Core
open! Import

module World_view = struct
  type t =
    { players : Protocol.Player.t list
    ; walls : Position.t list
    ; center_pos : Position.t
    ; view_width : int
    ; view_height : int
    ; visible_positions : Position.Set.t
    }
end

let render_grid (world_view : World_view.t) =
  let open Notty in
  let { World_view.center_pos = { x = cx; y = cy }
      ; view_width
      ; view_height
      ; players
      ; walls
      ; visible_positions
      }
    =
    world_view
  in
  let half_width = view_width / 2 in
  let half_height = view_height / 2 in
  (* Create position -> player lookup *)
  let player_map =
    List.fold players ~init:[] ~f:(fun acc player -> (player.position, player) :: acc)
  in
  (* Create a set of wall positions for efficient lookup *)
  let wall_set = Set.of_list (module Position) walls in
  let render_empty_cell _world_x _world_y =
    '.', A.(fg lightblack)
    (* All floor tiles are periods *)
  in
  let render_cell world_x world_y =
    let world_pos = { x = world_x; y = world_y } in
    if not (Set.mem visible_positions world_pos)
    then I.(string A.(fg black) " ") (* Not visible - render as black space *)
    else (
      let ch, color =
        match List.Assoc.find player_map world_pos ~equal:Position.equal with
        | Some player -> player.sigil, A.(fg lightgreen)
        | None ->
          if Set.mem wall_set world_pos
          then '#', A.(fg white) (* Wall character *)
          else render_empty_cell world_x world_y
      in
      I.(string color (String.of_char ch)))
  in
  let render_row row =
    let world_y = cy - half_height + row in
    let cols = List.range 0 view_width in
    let line_images =
      List.map cols ~f:(fun col ->
        let world_x = cx - half_width + col in
        render_cell world_x world_y)
    in
    I.(hcat line_images)
  in
  let rows = List.range 0 view_height in
  let images = List.map rows ~f:render_row in
  I.(vcat images)
;;

let render_ui (world_view : World_view.t) =
  let open Notty in
  let grid = render_grid world_view in
  let { World_view.center_pos = { x; y }; players; _ } = world_view in
  let player_count = List.length players in
  let status =
    I.(
      string
        A.(fg white)
        (sprintf
           "Center: (%d, %d) | Players: %d | Use WASD to move, Q to quit"
           x
           y
           player_count))
  in
  I.(grid <-> I.(string A.empty "") <-> status)
;;

let default_visibility_radius = 25

let build_world_view ~players ~walls ~viewing_player_id ~view_width ~view_height =
  let viewing_player =
    List.find players ~f:(fun player ->
      Protocol.Player_id.equal player.Protocol.Player.id viewing_player_id)
  in
  let center_pos =
    match viewing_player with
    | Some player -> player.Protocol.Player.position
    | None -> { x = 0; y = 0 }
  in
  let visible_positions =
    match viewing_player with
    | None -> Position.Set.empty
    | Some player ->
      Visibility.compute_visible_tiles
        ~from:player.Protocol.Player.position
        ~walls:(Position.Set.of_list walls)
        ~max_radius:default_visibility_radius
  in
  World_view.{ players; walls; center_pos; view_width; view_height; visible_positions }
;;

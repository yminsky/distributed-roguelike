open! Core

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
    List.fold players ~init:[] ~f:(fun acc player ->
      (player.position, player) :: acc)
  in
  
  let images = ref [] in
  for row = 0 to view_height - 1 do
    let world_y = cy - half_height + row in
    let line_images = ref [] in
    for col = 0 to view_width - 1 do
      let world_x = cx - half_width + col in
      let world_pos = Protocol.Position.{ x = world_x; y = world_y } in
      
      let (ch, color) =
        match List.Assoc.find player_map world_pos ~equal:Protocol.Position.equal with
        | Some player -> 
          (player.sigil, Notty.A.(fg lightgreen))
        | None ->
          if world_x mod 10 = 0 || world_y mod 10 = 0
          then ('.', Notty.A.(fg lightblack)) (* Grid markers every 10 units *)
          else (' ', Notty.A.empty) (* Empty space *)
      in
      line_images := Notty.I.(string color (String.of_char ch)) :: !line_images
    done;
    images := Notty.I.(hcat (List.rev !line_images)) :: !images
  done;
  Notty.I.(vcat (List.rev !images))
;;

let render_ui (world_view : World_view.t) =
  let grid = render_grid world_view in
  let { World_view.center_pos = { x; y }; players; _ } = world_view in
  let player_count = List.length players in
  let status =
    Notty.I.(
      string
        Notty.A.(fg white)
        (sprintf "Center: (%d, %d) | Players: %d | Use WASD to move, Q to quit" x y player_count))
  in
  Notty.I.(grid <-> Notty.I.(string Notty.A.empty "") <-> status)
;;

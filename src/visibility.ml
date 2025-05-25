open! Core

let compute_visible_tiles ~from ~walls:_ ~max_radius =
  (* Trivial implementation: everything within max_radius is visible *)
  let positions = ref [] in
  let radius_squared = max_radius * max_radius in
  for dx = -max_radius to max_radius do
    for dy = -max_radius to max_radius do
      if (dx * dx) + (dy * dy) <= radius_squared
      then (
        let pos = Protocol.Position.{ x = from.x + dx; y = from.y + dy } in
        positions := pos :: !positions)
    done
  done;
  Protocol.Position.Set.of_list !positions
;;

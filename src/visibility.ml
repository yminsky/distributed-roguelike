open! Core
open! Import

(* Bresenham's line algorithm to get all points on a line between two positions *)
let line_between ~from ~to_pos =
  let x0, y0 = from.x, from.y in
  let x1, y1 = to_pos.x, to_pos.y in
  let dx = abs (x1 - x0) in
  let dy = abs (y1 - y0) in
  let sx = if x0 < x1 then 1 else -1 in
  let sy = if y0 < y1 then 1 else -1 in
  let rec loop x y err acc =
    let pos = { x; y } in
    let acc = pos :: acc in
    if x = x1 && y = y1
    then List.rev acc
    else (
      let e2 = 2 * err in
      let err, x = if e2 > -dy then err - dy, x + sx else err, x in
      let err, y = if e2 < dx then err + dx, y + sy else err, y in
      loop x y err acc)
  in
  loop x0 y0 (dx - dy) []
;;

(* Check if there's a clear line of sight from 'from' to 'target' *)
let has_line_of_sight ~from ~target ~walls =
  let line = line_between ~from ~to_pos:target in
  (* Check all positions except the first (from) and last (target) *)
  let intermediate_positions =
    match line with
    | [] | [ _ ] | [ _; _ ] -> []
    | _ :: rest -> List.take rest (List.length rest - 1)
  in
  not (List.exists intermediate_positions ~f:(fun pos -> Set.mem walls pos))
;;

let compute_visible_tiles ~from ~walls ~max_radius =
  (* First, get all positions within radius (using circular distance) *)
  let radius_squared = max_radius * max_radius in
  let positions_in_radius =
    List.concat_map
      (List.range (-max_radius) (max_radius + 1))
      ~f:(fun dx ->
        List.filter_map
          (List.range (-max_radius) (max_radius + 1))
          ~f:(fun dy ->
            if (dx * dx) + (dy * dy) <= radius_squared
            then Some { x = from.x + dx; y = from.y + dy }
            else None))
  in
  (* Filter to only include positions with line of sight *)
  let visible_positions =
    List.filter positions_in_radius ~f:(fun target ->
      Position.equal from target || has_line_of_sight ~from ~target ~walls)
  in
  Position.Set.of_list visible_positions
;;

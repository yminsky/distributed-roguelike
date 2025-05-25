open! Core

module Config = struct
  type t =
    { width : int
    ; height : int
    }

  let default = { width = 21; height = 21 }

  let create ~width ~height =
    if width % 2 = 0 || height % 2 = 0
    then failwith "Maze dimensions must be odd"
    else if width < 5 || height < 5
    then failwith "Maze dimensions must be at least 5x5"
    else { width; height }
  ;;
end

(** Direction for maze carving *)
module Position = Protocol.Position

module Direction = struct
  type t =
    | North
    | South
    | East
    | West

  let all = [ North; South; East; West ]

  let move pos = function
    | North -> Position.{ x = pos.Position.x; y = pos.Position.y - 2 }
    | South -> Position.{ x = pos.Position.x; y = pos.Position.y + 2 }
    | East -> Position.{ x = pos.Position.x + 2; y = pos.Position.y }
    | West -> Position.{ x = pos.Position.x - 2; y = pos.Position.y }
  ;;

  let wall_between from to_pos =
    Position.
      { x = (from.Position.x + to_pos.Position.x) / 2
      ; y = (from.Position.y + to_pos.Position.y) / 2
      }
  ;;
end

let generate ~config ~seed =
  let { Config.width; height } = config in
  Random.init seed;
  (* Start with all walls *)
  let walls = ref Position.Set.empty in
  for x = 0 to width - 1 do
    for y = 0 to height - 1 do
      walls := Set.add !walls Position.{ x; y }
    done
  done;
  (* Carve out the maze using recursive backtracker *)
  let visited = ref Position.Set.empty in
  let is_valid_cell pos =
    pos.Position.x >= 1
    && pos.Position.x < width - 1
    && pos.Position.y >= 1
    && pos.Position.y < height - 1
    && pos.Position.x % 2 = 1
    && pos.Position.y % 2 = 1
  in
  let rec carve_from pos =
    (* Mark current position as visited and remove wall *)
    visited := Set.add !visited pos;
    walls := Set.remove !walls pos;
    (* Get unvisited neighbors in random order *)
    let neighbors =
      Direction.all
      |> List.filter_map ~f:(fun dir ->
        let next = Direction.move pos dir in
        if is_valid_cell next && not (Set.mem !visited next)
        then Some (dir, next)
        else None)
      |> List.permute ~random_state:(Random.State.make [| Random.int 1000000 |])
    in
    (* Visit each unvisited neighbor *)
    List.iter neighbors ~f:(fun (_dir, next) ->
      if not (Set.mem !visited next)
      then (
        (* Remove wall between current and next *)
        let wall = Direction.wall_between pos next in
        walls := Set.remove !walls wall;
        (* Recursively carve from the neighbor *)
        carve_from next))
  in
  (* Start carving from position (1,1) *)
  carve_from Position.{ x = 1; y = 1 };
  !walls
;;

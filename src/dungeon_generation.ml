open! Core
open! Import

module Config = struct
  type t =
    { width : int
    ; height : int
    ; room_attempts : int
    ; min_room_size : int
    ; max_room_size : int
    }
  [@@deriving sexp]

  let default =
    { width = 50; height = 50; room_attempts = 30; min_room_size = 4; max_room_size = 10 }
  ;;

  let create ~width ~height ~room_attempts ~min_room_size ~max_room_size =
    if width < 20
    then Or_error.error_string "Dungeon width must be at least 20"
    else if height < 20
    then Or_error.error_string "Dungeon height must be at least 20"
    else if room_attempts <= 0
    then Or_error.error_string "Room attempts must be positive"
    else if min_room_size < 3
    then Or_error.error_string "Minimum room size must be at least 3"
    else if max_room_size <= min_room_size
    then Or_error.error_string "Maximum room size must be greater than minimum room size"
    else Ok { width; height; room_attempts; min_room_size; max_room_size }
  ;;

  let width t = t.width
  let height t = t.height
  let room_attempts t = t.room_attempts
  let min_room_size t = t.min_room_size
  let max_room_size t = t.max_room_size
end

module Room = struct
  type t =
    { x : int
    ; y : int
    ; width : int
    ; height : int
    }

  (** Check if two rooms overlap (including a 1-tile border) *)
  let overlaps r1 r2 =
    let r1_right = r1.x + r1.width in
    let r1_bottom = r1.y + r1.height in
    let r2_right = r2.x + r2.width in
    let r2_bottom = r2.y + r2.height in
    (* Add 1 tile border to prevent rooms from touching *)
    not
      (r1_right + 1 < r2.x
       || r2_right + 1 < r1.x
       || r1_bottom + 1 < r2.y
       || r2_bottom + 1 < r1.y)
  ;;

  (** Get the center position of a room *)
  let center room =
    let cx = room.x + (room.width / 2) in
    let cy = room.y + (room.height / 2) in
    { x = cx; y = cy }
  ;;

  (** Get all floor positions in a room *)
  let floor_positions room =
    List.concat_map
      (List.range room.x (room.x + room.width))
      ~f:(fun x ->
        List.map (List.range room.y (room.y + room.height)) ~f:(fun y -> { x; y }))
  ;;
end

(** Create an L-shaped corridor between two positions *)
let create_corridor ~from ~(to_ : position) =
  let x1, y1 = from.x, from.y in
  let x2, y2 = to_.x, to_.y in
  (* Randomly choose whether to go horizontal-first or vertical-first *)
  let go_horizontal_first = Random.bool () in
  let corridor_positions =
    if go_horizontal_first
    then (
      (* Horizontal first, then vertical *)
      let horizontal_positions =
        let xs = if x2 > x1 then List.range x1 x2 else List.range x2 x1 |> List.rev in
        List.map xs ~f:(fun x -> { x; y = y1 })
      in
      let vertical_positions =
        let ys = if y2 > y1 then List.range y1 y2 else List.range y2 y1 |> List.rev in
        List.map ys ~f:(fun y -> { x = x2; y })
      in
      horizontal_positions @ vertical_positions)
    else (
      (* Vertical first, then horizontal *)
      let vertical_positions =
        let ys = if y2 > y1 then List.range y1 y2 else List.range y2 y1 |> List.rev in
        List.map ys ~f:(fun y -> { x = x1; y })
      in
      let horizontal_positions =
        let xs = if x2 > x1 then List.range x1 x2 else List.range x2 x1 |> List.rev in
        List.map xs ~f:(fun x -> { x; y = y2 })
      in
      vertical_positions @ horizontal_positions)
  in
  (* Always include the final position *)
  corridor_positions @ [ { x = x2; y = y2 } ]
;;

let generate ~config ~seed =
  let width = Config.width config in
  let height = Config.height config in
  let room_attempts = Config.room_attempts config in
  let min_room_size = Config.min_room_size config in
  let max_room_size = Config.max_room_size config in
  Random.init seed;
  (* Start with no walls - we'll add them as boundaries *)
  let walls = ref Position.Set.empty in
  let floors = ref Position.Set.empty in
  (* Place rooms *)
  let rooms = ref [] in
  for _ = 1 to room_attempts do
    let room_width = min_room_size + Random.int (max_room_size - min_room_size + 1) in
    let room_height = min_room_size + Random.int (max_room_size - min_room_size + 1) in
    let room_x = 1 + Random.int (width - room_width - 1) in
    let room_y = 1 + Random.int (height - room_height - 1) in
    let new_room =
      Room.{ x = room_x; y = room_y; width = room_width; height = room_height }
    in
    (* Check if it overlaps with existing rooms *)
    let overlaps_any = List.exists !rooms ~f:(fun room -> Room.overlaps new_room room) in
    if not overlaps_any
    then (
      rooms := new_room :: !rooms;
      (* Add room floors *)
      List.iter (Room.floor_positions new_room) ~f:(fun pos ->
        floors := Set.add !floors pos))
  done;
  (* Connect rooms with corridors *)
  (* Use a simple approach: connect each room to the next one in the list *)
  (* This guarantees connectivity *)
  let rec connect_rooms = function
    | [] | [ _ ] -> ()
    | room1 :: room2 :: rest ->
      let center1 = Room.center room1 in
      let center2 = Room.center room2 in
      let corridor = create_corridor ~from:center1 ~to_:center2 in
      List.iter corridor ~f:(fun pos -> floors := Set.add !floors pos);
      connect_rooms (room2 :: rest)
  in
  (* Additionally, add some random connections for variety *)
  if List.length !rooms > 2
  then (
    let rooms_array = Array.of_list !rooms in
    let num_extra_connections = Random.int (List.length !rooms / 3) + 1 in
    for _ = 1 to num_extra_connections do
      let idx1 = Random.int (Array.length rooms_array) in
      let idx2 = Random.int (Array.length rooms_array) in
      if idx1 <> idx2
      then (
        let center1 = Room.center rooms_array.(idx1) in
        let center2 = Room.center rooms_array.(idx2) in
        let corridor = create_corridor ~from:center1 ~to_:center2 in
        List.iter corridor ~f:(fun pos -> floors := Set.add !floors pos))
    done);
  connect_rooms !rooms;
  (* Now create walls: border walls and walls adjacent to floors *)
  (* No border walls - only walls adjacent to floors *)
  (* Add walls adjacent to floors (but not on floors) *)
  Set.iter !floors ~f:(fun floor_pos ->
    let adjacent_positions =
      [ { x = floor_pos.x - 1; y = floor_pos.y }
      ; { x = floor_pos.x + 1; y = floor_pos.y }
      ; { x = floor_pos.x; y = floor_pos.y - 1 }
      ; { x = floor_pos.x; y = floor_pos.y + 1 }
      ]
    in
    List.iter adjacent_positions ~f:(fun pos ->
      (* Only add wall if it's within bounds and not already a floor *)
      if pos.x >= 0
         && pos.x < width
         && pos.y >= 0
         && pos.y < height
         && not (Set.mem !floors pos)
      then walls := Set.add !walls pos));
  !walls
;;

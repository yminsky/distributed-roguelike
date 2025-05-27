open! Core
open! Import

module Maze_config = struct
  type t =
    | No_maze
    | Test_maze
    | Generated_maze of Maze_generation.Config.t * int
    | Generated_dungeon of Dungeon_generation.Config.t * int
end

type t =
  { players : Player.t Player_id.Map.t
  ; max_players : int
  ; walls : Position.t list
  ; maze_config : Maze_config.t  (* Store config to know maze type *)
  }

let default_max_players = 10

let create_test_maze_walls () =
  (* Create a simple test maze with a central room and corridors
     The spawn point at (0,0) is guaranteed to be in the central room *)
  let walls = ref [] in
  (* Create a square box from (-3,-3) to (3,3) *)
  for x = -3 to 3 do
    walls := { x; y = -3 } :: !walls;
    walls := { x; y = 3 } :: !walls
  done;
  for y = -2 to 2 do
    walls := { x = -3; y } :: !walls;
    walls := { x = 3; y } :: !walls
  done;
  (* Remove some walls to create openings *)
  let walls_set = Set.of_list (module Position) !walls in
  let walls_set = Set.remove walls_set { x = 0; y = -3 } in
  let walls_set = Set.remove walls_set { x = 0; y = 3 } in
  let walls_set = Set.remove walls_set { x = -3; y = 0 } in
  let walls_set = Set.remove walls_set { x = 3; y = 0 } in
  Set.to_list walls_set
;;

let create ?(maze_config = Maze_config.No_maze) () =
  let walls =
    match maze_config with
    | No_maze -> []
    | Test_maze -> create_test_maze_walls ()
    | Generated_maze (config, seed) ->
      Maze_generation.generate ~config ~seed |> Set.to_list
    | Generated_dungeon (config, seed) ->
      Dungeon_generation.generate ~config ~seed |> Set.to_list
  in
  { players = Player_id.Map.empty; max_players = default_max_players; walls; maze_config }
;;

let player_sigils = [| '@'; '#'; '$'; '%'; '&'; '*'; '+'; '='; '?'; '!' |]

let next_available_sigil t =
  let used_sigils =
    Map.data t.players |> List.map ~f:(fun p -> p.sigil) |> Set.of_list (module Char)
  in
  Array.find player_sigils ~f:(fun sigil -> not (Set.mem used_sigils sigil))
;;

let find_spawn_position t =
  let occupied_positions = Map.data t.players |> List.map ~f:(fun p -> p.position) in
  let wall_set = Set.of_list (module Position) t.walls in
  
  match t.maze_config with
  | No_maze ->
    (* For no maze, start from origin and spiral outward *)
    let rec find_position radius =
      if radius > 50 then failwith "No spawn position found"
      else
        let positions = 
          List.concat_map (List.range (-radius) (radius + 1)) ~f:(fun dx ->
            List.filter_map (List.range (-radius) (radius + 1)) ~f:(fun dy ->
              if abs dx = radius || abs dy = radius 
              then Some { x = dx; y = dy }
              else None))
        in
        match List.find positions ~f:(fun pos ->
          not (List.mem occupied_positions pos ~equal:Position.equal))
        with
        | Some pos -> pos
        | None -> find_position (radius + 1)
    in
    find_position 0
    
  | Test_maze ->
    (* For test maze, we know the valid positions *)
    let valid_positions = [
      { x = 0; y = 0 };
      { x = -1; y = 0 }; { x = 1; y = 0 };
      { x = 0; y = -1 }; { x = 0; y = 1 };
      { x = -1; y = -1 }; { x = 1; y = -1 };
      { x = -1; y = 1 }; { x = 1; y = 1 };
      { x = -2; y = 0 }; { x = 2; y = 0 };
      { x = 0; y = -2 }; { x = 0; y = 2 };
      { x = -2; y = -1 }; { x = -2; y = 1 };
      { x = 2; y = -1 }; { x = 2; y = 1 };
      { x = -1; y = -2 }; { x = 1; y = -2 };
      { x = -1; y = 2 }; { x = 1; y = 2 };
      { x = -2; y = -2 }; { x = 2; y = -2 };
      { x = -2; y = 2 }; { x = 2; y = 2 };
    ] in
    (match List.find valid_positions ~f:(fun pos ->
      not (List.mem occupied_positions pos ~equal:Position.equal))
    with
    | Some pos -> pos
    | None -> failwith "Test maze full")
    
  | Generated_maze _ | Generated_dungeon _ ->
    (* For generated mazes, scan systematically from center outward *)
    let max_radius = 100 in
    let rec scan_positions radius =
      if radius > max_radius then failwith "No spawn position found in generated maze"
      else
        (* Generate positions at this radius *)
        let positions = 
          List.concat_map (List.range (-radius) (radius + 1)) ~f:(fun x ->
            List.concat_map (List.range (-radius) (radius + 1)) ~f:(fun y ->
              if abs x = radius || abs y = radius
              then [{ x; y }]
              else []))
        in
        (* Find first valid position *)
        match List.find positions ~f:(fun pos ->
          not (Set.mem wall_set pos) &&
          not (List.mem occupied_positions pos ~equal:Position.equal))
        with
        | Some pos -> pos
        | None -> scan_positions (radius + 1)
    in
    scan_positions 0
;;

let add_player t ~player_id ~player_name =
  if Map.length t.players >= t.max_players
  then Error (sprintf "Server full (max %d players)" t.max_players)
  else (
    match next_available_sigil t with
    | None -> Error "No available sigils"
    | Some sigil ->
      let position = find_spawn_position t in
      let player = Player.{ id = player_id; position; name = player_name; sigil } in
      let players = Map.set t.players ~key:player_id ~data:player in
      Ok ({ t with players }, player))
;;

let remove_player t ~player_id = { t with players = Map.remove t.players player_id }

let move_player t ~player_id ~(direction : Direction.t) =
  match Map.find t.players player_id with
  | None -> Error "Player not found"
  | Some player ->
    let new_pos = Direction.apply_to_position direction player.position in
    (* Check for collisions with walls *)
    let wall_collision = List.exists t.walls ~f:(Position.equal new_pos) in
    if wall_collision
    then Error "Cannot move into a wall"
    else (
      (* Check for collisions with other players *)
      let player_collision =
        Map.exists t.players ~f:(fun other_player ->
          (not (Player_id.equal other_player.id player_id))
          && Position.equal other_player.position new_pos)
      in
      if player_collision
      then Error "Cannot move into another player"
      else (
        let updated_player = { player with position = new_pos } in
        let players = Map.set t.players ~key:player_id ~data:updated_player in
        let update = Protocol.Update.Player_moved { player_id; new_position = new_pos } in
        Ok ({ t with players }, update)))
;;

let get_players t = Map.data t.players
let get_player t ~player_id = Map.find t.players player_id
let get_walls t = t.walls

(* Key mapping for client controls *)
let key_to_action : Key_input.t -> Direction.t option = function
  | ASCII 'w' | ASCII 'W' -> Some Up
  | ASCII 'a' | ASCII 'A' -> Some Left
  | ASCII 's' | ASCII 'S' -> Some Down
  | ASCII 'd' | ASCII 'D' -> Some Right
  | Arrow Up -> Some Up
  | Arrow Down -> Some Down
  | Arrow Left -> Some Left
  | Arrow Right -> Some Right
  | _ -> None
;;
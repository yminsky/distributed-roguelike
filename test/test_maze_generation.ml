open! Core
open Lan_rogue

let%expect_test "generate default maze" =
  let config = Maze_generation.Config.default in
  let walls = Maze_generation.generate ~config ~seed:42 in
  (* Check dimensions *)
  let width = Maze_generation.Config.width config in
  let height = Maze_generation.Config.height config in
  printf "Maze dimensions: %dx%d\n" width height;
  [%expect {| Maze dimensions: 21x21 |}];
  (* Visualize the maze *)
  printf "\nGenerated maze:\n";
  for y = 0 to height - 1 do
    for x = 0 to width - 1 do
      let pos = Position.{ x; y } in
      if Set.mem walls pos then printf "#" else printf "."
    done;
    printf "\n"
  done;
  [%expect
    {|
    Generated maze:
    #####################
    #.#.........#.......#
    #.###.#####.#.###.###
    #...#.#...#.#.#.#...#
    ###.###.#.#.#.#.###.#
    #.#.....#.#.#.#.#...#
    #.#######.#.#.#.#.###
    #.......#.#.#...#...#
    #.#.#####.#.###.###.#
    #.#.#.....#.......#.#
    #.#.#.#############.#
    #.#.#.#.............#
    #.###.#.###.#######.#
    #.....#...#...#...#.#
    #.#######.###.###.#.#
    #.......#...#.#...#.#
    #######.#####.#.###.#
    #.....#...#...#...#.#
    #.#######.#.###.#.#.#
    #...........#...#...#
    #####################
    |}]
;;

let%expect_test "maze has continuous border" =
  let config = Maze_generation.Config.default in
  let walls = Maze_generation.generate ~config ~seed:123 in
  let width = Maze_generation.Config.width config in
  let height = Maze_generation.Config.height config in
  (* Check top and bottom borders *)
  let top_border_complete =
    List.for_all (List.range 0 width) ~f:(fun x -> Set.mem walls Position.{ x; y = 0 })
  in
  let bottom_border_complete =
    List.for_all (List.range 0 width) ~f:(fun x ->
      Set.mem walls Position.{ x; y = height - 1 })
  in
  (* Check left and right borders *)
  let left_border_complete =
    List.for_all (List.range 0 height) ~f:(fun y -> Set.mem walls Position.{ x = 0; y })
  in
  let right_border_complete =
    List.for_all (List.range 0 height) ~f:(fun y ->
      Set.mem walls Position.{ x = width - 1; y })
  in
  printf "Top border complete: %b\n" top_border_complete;
  printf "Bottom border complete: %b\n" bottom_border_complete;
  printf "Left border complete: %b\n" left_border_complete;
  printf "Right border complete: %b\n" right_border_complete;
  [%expect
    {|
    Top border complete: true
    Bottom border complete: true
    Left border complete: true
    Right border complete: true
    |}]
;;

let%expect_test "different seeds produce different mazes" =
  let config = Maze_generation.Config.default in
  let walls1 = Maze_generation.generate ~config ~seed:1 in
  let walls2 = Maze_generation.generate ~config ~seed:2 in
  let are_different = not (Set.equal walls1 walls2) in
  printf "Different seeds produce different mazes: %b\n" are_different;
  [%expect {| Different seeds produce different mazes: true |}]
;;

let%expect_test "same seed produces same maze" =
  let config = Maze_generation.Config.default in
  let walls1 = Maze_generation.generate ~config ~seed:42 in
  let walls2 = Maze_generation.generate ~config ~seed:42 in
  let are_same = Set.equal walls1 walls2 in
  printf "Same seed produces same maze: %b\n" are_same;
  [%expect {| Same seed produces same maze: true |}]
;;

let%expect_test "create config with valid dimensions" =
  match Maze_generation.Config.create ~width:7 ~height:7 with
  | Ok config ->
    printf
      "Created config: %dx%d\n"
      (Maze_generation.Config.width config)
      (Maze_generation.Config.height config)
  | Error err ->
    printf "Error: %s\n" (Error.to_string_hum err);
    [%expect.unreachable];
    [%expect.unreachable];
    [%expect.unreachable];
    [%expect.unreachable];
    [%expect.unreachable];
    [%expect.unreachable];
    [%expect {| Created config: 7x7 |}]
;;

let%expect_test "create config with even dimensions fails" =
  match Maze_generation.Config.create ~width:8 ~height:7 with
  | Ok _ -> printf "Unexpected success\n"
  | Error err ->
    printf "Error: %s\n" (Error.to_string_hum err);
    [%expect {| Error: Maze dimensions must be odd |}]
;;

let%expect_test "create config with too small dimensions fails" =
  match Maze_generation.Config.create ~width:3 ~height:3 with
  | Ok _ -> printf "Unexpected success\n"
  | Error err ->
    printf "Error: %s\n" (Error.to_string_hum err);
    [%expect {| Error: Maze dimensions must be at least 5x5 |}]
;;

let%expect_test "small maze generation" =
  match Maze_generation.Config.create ~width:7 ~height:7 with
  | Error _ -> printf "Failed to create config\n"
  | Ok config ->
    let walls = Maze_generation.generate ~config ~seed:42 in
    printf "7x7 maze:\n";
    for y = 0 to 6 do
      for x = 0 to 6 do
        let pos = Position.{ x; y } in
        if Set.mem walls pos then printf "#" else printf "."
      done;
      printf "\n"
    done;
    [%expect
      {|
      7x7 maze:
      #######
      #.#...#
      #.###.#
      #...#.#
      ###.#.#
      #.....#
      #######
      |}]
;;

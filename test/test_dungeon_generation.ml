open! Core
open Lan_rogue

let%expect_test "generate default dungeon" =
  let config = Dungeon_generation.Config.default in
  let walls = Dungeon_generation.generate ~config ~seed:42 in
  (* Check dimensions *)
  let width = Dungeon_generation.Config.width config in
  let height = Dungeon_generation.Config.height config in
  printf "Dungeon dimensions: %dx%d\n" width height;
  [%expect {| Dungeon dimensions: 50x50 |}];
  (* Count rooms (approximate by finding large open areas) *)
  let floor_count = (width * height) - Set.length walls in
  printf "Floor tiles: %d (out of %d total)\n" floor_count (width * height);
  (* Visualize a portion of the dungeon *)
  let excerpt_width = 30 in
  let excerpt_height = 20 in
  printf "\n";
  (* Create a subset of walls for the excerpt *)
  let excerpt_walls =
    Set.filter walls ~f:(fun pos -> pos.x < excerpt_width && pos.y < excerpt_height)
  in
  Test_utils.print_map
    ~width:excerpt_width
    ~height:excerpt_height
    ~walls:excerpt_walls
    ~title:(sprintf "Dungeon excerpt (top-left %dx%d)" excerpt_width excerpt_height);
  [%expect
    {|
    Floor tiles: 1846 (out of 2500 total)

    Dungeon excerpt (top-left 30x20):
    ..............................
    ..............................
    ...........###################
    ..........#...................
    .####.....#..........#########
    #....#....#..........##....#..
    #....#....#..........##....#..
    #....#....#..........##....#..
    #....######..........##....###
    #.............................
    #....######..........##....###
    #....#....#..........##....#..
    #....#....#..........#.##.#...
    .##.#.....#.####.####...#.#..#
    ..#.#.....#.#..#.########.####
    ..#.#.....#.#..#..............
    ..#.#.....#.#..#.########.####
    ..#.#.....#.#..#.#......#.#..#
    ..#.#.....#.#..#.#.######.#...
    ..#.#.....#.#..#.##.....#.#...
    |}]
;;

let%expect_test "dungeon has no forced borders" =
  let config = Dungeon_generation.Config.default in
  let walls = Dungeon_generation.generate ~config ~seed:123 in
  let width = Dungeon_generation.Config.width config in
  let height = Dungeon_generation.Config.height config in
  (* Check that borders are not automatically walled *)
  let has_any_edge_floor =
    List.exists (List.range 0 width) ~f:(fun x ->
      (not (Set.mem walls Position.{ x; y = 0 }))
      || not (Set.mem walls Position.{ x; y = height - 1 }))
    || List.exists (List.range 0 height) ~f:(fun y ->
      (not (Set.mem walls Position.{ x = 0; y }))
      || not (Set.mem walls Position.{ x = width - 1; y }))
  in
  printf "Has floor tiles at edges: %b\n" has_any_edge_floor;
  [%expect {| Has floor tiles at edges: true |}]
;;

let%expect_test "create config with valid parameters" =
  (match
     Dungeon_generation.Config.create
       ~width:40
       ~height:40
       ~room_attempts:20
       ~min_room_size:3
       ~max_room_size:8
   with
   | Ok config ->
     printf
       "Created config: %dx%d, attempts=%d, room_size=%d-%d\n"
       (Dungeon_generation.Config.width config)
       (Dungeon_generation.Config.height config)
       (Dungeon_generation.Config.room_attempts config)
       (Dungeon_generation.Config.min_room_size config)
       (Dungeon_generation.Config.max_room_size config)
   | Error err -> printf "Error: %s\n" (Error.to_string_hum err));
  [%expect {| Created config: 40x40, attempts=20, room_size=3-8 |}]
;;

let%expect_test "create config with invalid width" =
  (match
     Dungeon_generation.Config.create
       ~width:10
       ~height:40
       ~room_attempts:20
       ~min_room_size:3
       ~max_room_size:8
   with
   | Ok _ -> printf "Unexpected success\n"
   | Error err -> printf "Error: %s\n" (Error.to_string_hum err));
  [%expect {| Error: Dungeon width must be at least 20 |}]
;;

let%expect_test "create config with invalid room size" =
  (match
     Dungeon_generation.Config.create
       ~width:40
       ~height:40
       ~room_attempts:20
       ~min_room_size:5
       ~max_room_size:4
   with
   | Ok _ -> printf "Unexpected success\n"
   | Error err -> printf "Error: %s\n" (Error.to_string_hum err));
  [%expect {| Error: Maximum room size must be greater than minimum room size |}]
;;

let%expect_test "small dungeon generation" =
  let width = 70 in
  let height = 70 in
  match
    Dungeon_generation.Config.create
      ~width
      ~height
      ~room_attempts:10
      ~min_room_size:3
      ~max_room_size:31
  with
  | Error _ -> printf "Failed to create config\n"
  | Ok config ->
    let walls = Dungeon_generation.generate ~config ~seed:42 in
    Test_utils.print_map
      ~width
      ~height
      ~walls
      ~title:(sprintf "%dx%d dungeon" width height);
    [%expect
      {|
      70x70 dungeon:
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      ...........#######################....................................
      ..........#.......................#...................................
      ..........#.......................#...................................
      ..........#.......................#...................................
      ..........#.......................#...................................
      ..........#.......................#...................................
      ..........#.......................#...................................
      ..........#.......................#.#######################...........
      ..........#.......................##.......................#..........
      ..........#.......................##.......................#..........
      ..........#.......................##.......................#..........
      ..........#.......................##.......................#..........
      ..........#.......................##.......................#..........
      ..........#.......................##.......................#..........
      ..........#.......................##.......................#..........
      ..........#.......................##.......................#..........
      ..........#.......................##.......................#..........
      ..........#.......................#.###########.###########...........
      ..........#.......................#...........#.#.....................
      ..........#.......................#...........#.#.....................
      ..........#.......................#...........#.#.....................
      ..........#.......................#...........#.#.....................
      ..........#.......................#...........#.#.....................
      ..........#.......................#...........#.#.....................
      ..........#.......................#...........#.#.....................
      ..........#.......................#...........#.#.....................
      ...........###########.###########............#.#.....................
      .....................#.#......................#.#.....................
      .....................#.#......................#.#.....................
      .....................#.#......................#.#.....................
      .....................#.#......................#.#.....................
      .....................#.#...#####..............#.#.....................
      .....................#.#..#.....#.............#.#.....................
      .....................#.#..#.....#.............#.#.....................
      .....................#.#..#.....#.............#.#.....................
      .....................#.#..#.....#.............#.#.....................
      .....................#.#..#.....#.............#.#.....................
      .....................#.#..#.....#.............#.#.....................
      .....................#.#..#.....#.............#.#.....................
      ................######.####.....#.............#.#####################.
      ............####................#............#.......................#
      ...........#.........#.####.....#............#.......................#
      ...........#.........#.#..#.....#............#.......................#
      ...........#.........#.#..#.....#............#.......................#
      ...........#.........#.#..#.....#............#.......................#
      ...........#.........#.####.....##############.......................#
      ...........#.........................................................#
      ...........#.........######.....##############.......................#
      ...........#.........#.....#####.............#.......................#
      ...........#.........#.......................#.......................#
      ...........#.........#.......................#.......................#
      ...........#.........#.......................#.......................#
      ............#########.........................#######################.
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      ......................................................................
      |}];
    [%expect {| |}];
    [%expect {| |}]
;;

let%expect_test "deterministic generation" =
  let config = Dungeon_generation.Config.default in
  let walls1 = Dungeon_generation.generate ~config ~seed:42 in
  let walls2 = Dungeon_generation.generate ~config ~seed:42 in
  let are_same = Set.equal walls1 walls2 in
  printf "Same seed produces same dungeon: %b\n" are_same;
  [%expect {| Same seed produces same dungeon: true |}];
  let walls3 = Dungeon_generation.generate ~config ~seed:43 in
  let are_different = not (Set.equal walls1 walls3) in
  printf "Different seeds produce different dungeons: %b\n" are_different;
  [%expect {| Different seeds produce different dungeons: true |}]
;;

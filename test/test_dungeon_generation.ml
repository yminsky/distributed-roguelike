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
  printf "\nDungeon excerpt (top-left 30x20):\n";
  for y = 0 to 19 do
    for x = 0 to 29 do
      let pos = Position.{ x; y } in
      if Set.mem walls pos then printf "#" else printf "."
    done;
    printf "\n"
  done;
  [%expect
    {|
    Floor tiles: 790 (out of 2500 total)

    Dungeon excerpt (top-left 30x20):
    ##############################
    ##############################
    ##############################
    ###########...................
    ###########..........#########
    #....######..........##....###
    #....######..........##....###
    #....######..........##....###
    #....######..........##....###
    #.............................
    #....######..........##....###
    #....######..........##....###
    #....######..........####.####
    ###.#######.####.########.####
    ###.#######.####.########.####
    ###.#######.####..............
    ###.#######.####.########.####
    ###.#######.####.########.####
    ###.#######.####.########.####
    ###.#######.####.##.....#.####
    |}]
;;

let%expect_test "dungeon has continuous border" =
  let config = Dungeon_generation.Config.default in
  let walls = Dungeon_generation.generate ~config ~seed:123 in
  let width = Dungeon_generation.Config.width config in
  let height = Dungeon_generation.Config.height config in
  (* Check borders *)
  let top_border_complete =
    List.for_all (List.range 0 width) ~f:(fun x -> Set.mem walls Position.{ x; y = 0 })
  in
  let bottom_border_complete =
    List.for_all (List.range 0 width) ~f:(fun x ->
      Set.mem walls Position.{ x; y = height - 1 })
  in
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

let%expect_test "create config with valid parameters" =
  match
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
  | Error err ->
    printf "Error: %s\n" (Error.to_string_hum err);
    [%expect.unreachable];
  [%expect.unreachable];
  [%expect {| Created config: 40x40, attempts=20, room_size=3-8 |}]
;;

let%expect_test "create config with invalid width" =
  match
    Dungeon_generation.Config.create
      ~width:10
      ~height:40
      ~room_attempts:20
      ~min_room_size:3
      ~max_room_size:8
  with
  | Ok _ -> printf "Unexpected success\n"
  | Error err ->
    printf "Error: %s\n" (Error.to_string_hum err);
    [%expect {| Error: Dungeon width must be at least 20 |}]
;;

let%expect_test "create config with invalid room size" =
  match
    Dungeon_generation.Config.create
      ~width:40
      ~height:40
      ~room_attempts:20
      ~min_room_size:5
      ~max_room_size:4
  with
  | Ok _ -> printf "Unexpected success\n"
  | Error err ->
    printf "Error: %s\n" (Error.to_string_hum err);
    [%expect {| Error: Maximum room size must be greater than minimum room size |}]
;;

let%expect_test "small dungeon generation" =
  match
    Dungeon_generation.Config.create
      ~width:30
      ~height:20
      ~room_attempts:5
      ~min_room_size:3
      ~max_room_size:6
  with
  | Error _ -> printf "Failed to create config\n"
  | Ok config ->
    let walls = Dungeon_generation.generate ~config ~seed:42 in
    printf "30x20 dungeon:\n";
    for y = 0 to 19 do
      for x = 0 to 29 do
        let pos = Position.{ x; y } in
        if Set.mem walls pos then printf "#" else printf "."
      done;
      printf "\n"
    done;
    [%expect
      {|
      30x20 dungeon:
      ##############################
      ##########....################
      ##########....################
      ##########....################
      ##########...................#
      ##########....##########.....#
      ##########....#..............#
      ###############.########.....#
      ###############.########.....#
      ##############...#########.###
      ##############.............###
      ##############...#############
      ##############################
      ##############################
      ##############################
      ##############################
      ##############################
      ##############################
      ##############################
      ##############################
      |}]
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

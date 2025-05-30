open! Core
open Lan_rogue

let%expect_test "game state creation and movement" =
  let initial_state = Game_state.create () in
  (* Add a player to test single-player functionality *)
  let state, player =
    match
      Game_state.add_player
        initial_state
        ~player_id:(Player_id.of_int 1)
        ~player_name:"Player"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add player"
  in
  printf
    "Initial state: %s\n"
    (Sexp.to_string_hum
       (sexp_of_list sexp_of_int [ player.position.x; player.position.y ]));
  [%expect {| Initial state: (0 0) |}];
  let moved_right =
    match
      Game_state.move_player state ~player_id:(Player_id.of_int 1) ~direction:Right
    with
    | Ok (s, _update) -> s
    | Error _ -> failwith "Failed to move right"
  in
  let player_after_right =
    Game_state.get_player moved_right ~player_id:(Player_id.of_int 1) |> Option.value_exn
  in
  printf
    "After moving right: %s\n"
    (Sexp.to_string_hum
       (sexp_of_list
          sexp_of_int
          [ player_after_right.position.x; player_after_right.position.y ]));
  [%expect {| After moving right: (1 0) |}];
  let moved_up =
    match
      Game_state.move_player moved_right ~player_id:(Player_id.of_int 1) ~direction:Up
    with
    | Ok (s, _update) -> s
    | Error _ -> failwith "Failed to move up"
  in
  let player_after_up =
    Game_state.get_player moved_up ~player_id:(Player_id.of_int 1) |> Option.value_exn
  in
  printf
    "After moving up: %s\n"
    (Sexp.to_string_hum
       (sexp_of_list
          sexp_of_int
          [ player_after_up.position.x; player_after_up.position.y ]));
  [%expect {| After moving up: (1 -1) |}]
;;

let%expect_test "key to action conversion" =
  let test_key key =
    match Game_state.key_to_action (ASCII key) with
    | Some direction -> printf "%c -> %s\n" key (Direction.to_string direction)
    | None -> printf "%c -> None\n" key
  in
  test_key 'w';
  test_key 'd';
  test_key 's';
  test_key 'a';
  test_key 'q';
  test_key 'x';
  (* Test arrow keys *)
  let test_arrow arrow =
    match Game_state.key_to_action (Arrow arrow) with
    | Some direction ->
      printf
        "Arrow %s -> %s\n"
        (Direction.to_string arrow)
        (Direction.to_string direction)
    | None -> printf "Arrow %s -> None\n" (Direction.to_string arrow)
  in
  test_arrow Up;
  test_arrow Down;
  test_arrow Left;
  test_arrow Right;
  [%expect
    {|
    w -> Up
    d -> Right
    s -> Down
    a -> Left
    q -> None
    x -> None
    Arrow Up -> Up
    Arrow Down -> Down
    Arrow Left -> Left
    Arrow Right -> Right
    |}]
;;

let%expect_test "wall collision detection" =
  let state = Game_state.create ~maze_config:Test_maze () in
  let state, player =
    match
      Game_state.add_player state ~player_id:(Player_id.of_int 1) ~player_name:"Player"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add player"
  in
  printf "Player spawned at (%d, %d)\n" player.position.x player.position.y;
  (* Try to move up multiple times to hit a wall *)
  let rec move_until_wall state direction count =
    if count > 10
    then state
    else (
      match Game_state.move_player state ~player_id:(Player_id.of_int 1) ~direction with
      | Ok (new_state, _) ->
        printf "Moved %s successfully\n" (Direction.to_string direction);
        move_until_wall new_state direction (count + 1)
      | Error msg ->
        printf "Movement blocked: %s\n" msg;
        state)
  in
  (* First move right to position (1, 0), then up to hit wall at (1, -3) *)
  let state =
    match
      Game_state.move_player state ~player_id:(Player_id.of_int 1) ~direction:Right
    with
    | Ok (new_state, _) ->
      printf "Moved Right successfully\n";
      new_state
    | Error msg ->
      printf "Failed to move right: %s\n" msg;
      state
  in
  (* Now try moving up until we hit the wall at (1, -3) *)
  let _ = move_until_wall state Up 0 in
  [%expect
    {|
    Player spawned at (0, 0)
    Moved Right successfully
    Moved Up successfully
    Moved Up successfully
    Movement blocked: Cannot move into a wall
    |}]
;;

let%expect_test "visual rendering with walls" =
  let state = Game_state.create ~maze_config:Test_maze () in
  let state, _ =
    match
      Game_state.add_player state ~player_id:(Player_id.of_int 1) ~player_name:"Player"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add player"
  in
  let render_state state =
    Notty_test_utils.render_state_to_string
      ~width:50
      ~height:21
      state
      ~player_id:(Player_id.of_int 1)
  in
  print_endline (render_state state);
  [%expect
    {|
                            ...
                            ...
                            ...
                            ...
                            ...
                             .
     .                       .                       .
     .......              ###.###              .......
     .............        #.....#        .............
     ...................  #.....#  ...................
    .........................@........................
     ...................  #.....#  ...................
     .............        #.....#        .............
     .......              ###.###              .......
     .                       .                       .
                             .
                            ...
                            ...
                            ...
                            ...
                            ...

    Center: (0, 0) | Players: 1 | Use WASD to move, Q to quit
    |}]
;;

let%expect_test "debug visibility symmetry" =
  let state = Game_state.create ~maze_config:Test_maze () in
  let state, _ =
    match
      Game_state.add_player state ~player_id:(Player_id.of_int 1) ~player_name:"Player"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add player"
  in
  (* Test with a smaller view to focus on the issue *)
  let render_state state =
    Notty_test_utils.render_state_to_string
      ~width:25
      ~height:15
      state
      ~player_id:(Player_id.of_int 1)
  in
  print_endline (render_state state);
  (* Let's check what positions are actually visible *)
  let walls = Game_state.get_walls state in
  let visible =
    Visibility.compute_visible_tiles
      ~from:Position.{ x = 0; y = 0 }
      ~walls:(Position.Set.of_list walls)
      ~max_radius:10
  in
  (* Check specific positions that should be symmetrically visible *)
  let check_pos x y =
    let pos = Position.{ x; y } in
    let is_visible = Set.mem visible pos in
    printf "(%2d,%2d): %s\n" x y (if is_visible then "visible" else "blocked")
  in
  printf "\nChecking key positions:\n";
  (* Check the openings *)
  check_pos (-5) 0;
  (* Left opening *)
  check_pos 5 0;
  (* Right opening *)
  check_pos 0 (-3);
  (* Top opening *)
  check_pos 0 3;
  (* Bottom opening *)
  (* Check beyond openings *)
  check_pos (-6) 0;
  (* Beyond left opening *)
  check_pos 6 0;
  (* Beyond right opening *)
  check_pos 0 (-4);
  (* Beyond top opening *)
  check_pos 0 4;
  (* Beyond bottom opening *)
  (* Check diagonal visibility through openings *)
  printf "\nChecking diagonal visibility:\n";
  check_pos (-6) 1;
  (* Should this be visible? *)
  check_pos (-6) (-1);
  check_pos 6 1;
  check_pos 6 (-1);
  check_pos 1 (-4);
  check_pos (-1) (-4);
  check_pos 1 4;
  check_pos (-1) 4;
  [%expect
    {|
               ...
               ...
                .
                .
             ###.###
    .        #.....#        .
    .......  #.....#  .......
    ............@............
    .......  #.....#  .......
    .        #.....#        .
             ###.###
                .
                .
               ...
               ...

    Center: (0, 0) | Players: 1 | Use WASD to move, Q to quit

    Checking key positions:
    (-5, 0): visible
    ( 5, 0): visible
    ( 0,-3): visible
    ( 0, 3): visible
    (-6, 0): visible
    ( 6, 0): visible
    ( 0,-4): visible
    ( 0, 4): visible

    Checking diagonal visibility:
    (-6, 1): visible
    (-6,-1): visible
    ( 6, 1): visible
    ( 6,-1): visible
    ( 1,-4): blocked
    (-1,-4): blocked
    ( 1, 4): blocked
    (-1, 4): blocked
    |}]
;;

let%expect_test "visibility blocked by walls" =
  let state = Game_state.create ~maze_config:Test_maze () in
  let state, _ =
    match
      Game_state.add_player state ~player_id:(Player_id.of_int 1) ~player_name:"Player"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add player"
  in
  (* Move player to (-4, 0) - just inside the left wall opening *)
  let state = ref state in
  for _ = 1 to 4 do
    state
    := match
         Game_state.move_player !state ~player_id:(Player_id.of_int 1) ~direction:Left
       with
       | Ok (s, _) -> s
       | Error _ -> !state
  done;
  printf "Player moved to position near wall\n";
  let render_state state =
    Notty_test_utils.render_state_to_string
      ~width:25
      ~height:15
      state
      ~player_id:(Player_id.of_int 1)
  in
  print_endline (render_state !state);
  [%expect
    {|
    Player moved to position near wall
    ..............
    ..............
    .............
    .............
    .............     #
    .............#  ...#
    .............#.....#
    ............@............
    .............#.....#
    .............#  ...#
    .............     #
    .............
    .............
    ..............
    ..............

    Center: (-4, 0) | Players: 1 | Use WASD to move, Q to quit
    |}]
;;

let%expect_test "visual state transitions" =
  let render_state state =
    Notty_test_utils.render_state_to_string
      ~width:60
      ~height:11
      state
      ~player_id:(Player_id.of_int 1)
  in
  printf "=== Initial State ===\n";
  let state = Game_state.create () in
  let state, _ =
    match
      Game_state.add_player state ~player_id:(Player_id.of_int 1) ~player_name:"Player"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add player"
  in
  print_endline (render_state state);
  printf "\n=== After moving right twice ===\n";
  let state =
    match
      Game_state.move_player state ~player_id:(Player_id.of_int 1) ~direction:Right
    with
    | Ok (s, _update) -> s
    | Error _ -> failwith "Failed to move right"
  in
  let state =
    match
      Game_state.move_player state ~player_id:(Player_id.of_int 1) ~direction:Right
    with
    | Ok (s, _update) -> s
    | Error _ -> failwith "Failed to move right"
  in
  print_endline (render_state state);
  printf "\n=== After moving down once ===\n";
  let state =
    match
      Game_state.move_player state ~player_id:(Player_id.of_int 1) ~direction:Down
    with
    | Ok (s, _update) -> s
    | Error _ -> failwith "Failed to move down"
  in
  print_endline (render_state state);
  [%expect
    {|
    === Initial State ===
          .................................................
          .................................................
          .................................................
          .................................................
          .................................................
         .........................@.........................
          .................................................
          .................................................
          .................................................
          .................................................
          .................................................

    Center: (0, 0) | Players: 1 | Use WASD to move, Q to quit

    === After moving right twice ===
          .................................................
          .................................................
          .................................................
          .................................................
          .................................................
         .........................@.........................
          .................................................
          .................................................
          .................................................
          .................................................
          .................................................

    Center: (2, 0) | Players: 1 | Use WASD to move, Q to quit

    === After moving down once ===
          .................................................
          .................................................
          .................................................
          .................................................
          .................................................
         .........................@.........................
          .................................................
          .................................................
          .................................................
          .................................................
          .................................................

    Center: (2, 1) | Players: 1 | Use WASD to move, Q to quit
    |}]
;;

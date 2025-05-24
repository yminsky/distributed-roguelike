open! Core
open Lan_rogue

let%expect_test "game state creation and movement" =
  let initial_state = Game_state.Local_state.create () in
  printf
    "Initial state: %s\n"
    (Sexp.to_string_hum
       (sexp_of_list
          sexp_of_int
          [ initial_state.player_pos.x; initial_state.player_pos.y ]));
  [%expect {| Initial state: (0 0) |}];
  let moved_right =
    Game_state.apply_action initial_state (Game_state.Action.Move `Right)
  in
  printf
    "After moving right: %s\n"
    (Sexp.to_string_hum
       (sexp_of_list sexp_of_int [ moved_right.player_pos.x; moved_right.player_pos.y ]));
  [%expect {| After moving right: (1 0) |}];
  let moved_up = Game_state.apply_action moved_right (Game_state.Action.Move `Up) in
  printf
    "After moving up: %s\n"
    (Sexp.to_string_hum
       (sexp_of_list sexp_of_int [ moved_up.player_pos.x; moved_up.player_pos.y ]));
  [%expect {| After moving up: (1 -1) |}]
;;

let%expect_test "key to action conversion" =
  let test_key key =
    match Game_state.key_to_action (`ASCII key) with
    | Some action ->
      printf "%c -> %s\n" key (Sexp.to_string_hum (Game_state.Action.sexp_of_t action))
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
    match Game_state.key_to_action (`Arrow arrow) with
    | Some action ->
      printf
        "Arrow %s -> %s\n"
        (match arrow with
         | `Up -> "Up"
         | `Down -> "Down"
         | `Left -> "Left"
         | `Right -> "Right")
        (Sexp.to_string_hum (Game_state.Action.sexp_of_t action))
    | None ->
      printf
        "Arrow %s -> None\n"
        (match arrow with
         | `Up -> "Up"
         | `Down -> "Down"
         | `Left -> "Left"
         | `Right -> "Right")
  in
  test_arrow `Up;
  test_arrow `Down;
  test_arrow `Left;
  test_arrow `Right;
  [%expect
    {|
    w -> (Move Up)
    d -> (Move Right)
    s -> (Move Down)
    a -> (Move Left)
    q -> Quit
    x -> None
    Arrow Up -> (Move Up)
    Arrow Down -> (Move Down)
    Arrow Left -> (Move Left)
    Arrow Right -> (Move Right)
    |}]
;;

let%expect_test "visual state transitions" =
  let render_state state =
    Notty_test_utils.render_state_to_string ~width:60 ~height:11 state
  in
  printf "=== Initial State ===\n";
  let state = Game_state.Local_state.create () in
  print_endline (render_state state);
  printf "\n=== After moving right twice ===\n";
  let state = Game_state.apply_action state (Game_state.Action.Move `Right) in
  let state = Game_state.apply_action state (Game_state.Action.Move `Right) in
  print_endline (render_state state);
  printf "\n=== After moving down once ===\n";
  let state = Game_state.apply_action state (Game_state.Action.Move `Down) in
  print_endline (render_state state);
  [%expect
    {|
    === Initial State ===
    .         .         .         .         .         .
    .         .         .         .         .         .
    .         .         .         .         .         .
    .         .         .         .         .         .
    .         .         .         .         .         .
    ..............................@.............................
    .         .         .         .         .         .
    .         .         .         .         .         .
    .         .         .         .         .         .
    .         .         .         .         .         .
    .         .         .         .         .         .

    Center: (0, 0) | Players: 1 | Use WASD to move, Q to quit

    === After moving right twice ===
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .
    ..............................@.............................
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .

    Center: (2, 0) | Players: 1 | Use WASD to move, Q to quit

    === After moving down once ===
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .
    ............................................................
            .         .         . @       .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .
            .         .         .         .         .         .

    Center: (2, 1) | Players: 1 | Use WASD to move, Q to quit
    |}]
;;

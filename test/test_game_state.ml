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
  let test_key key _expected =
    match Game_state.key_to_action (`ASCII key) with
    | Some action ->
      printf "%c -> %s\n" key (Sexp.to_string_hum (Game_state.Action.sexp_of_t action))
    | None -> printf "%c -> None\n" key
  in
  test_key 'w' (Some (Game_state.Action.Move `Up));
  test_key 'd' (Some (Game_state.Action.Move `Right));
  test_key 's' (Some (Game_state.Action.Move `Down));
  test_key 'a' (Some (Game_state.Action.Move `Left));
  test_key 'q' (Some Game_state.Action.Quit);
  test_key 'x' None;
  [%expect
    {|
    w -> (Move Up)
    d -> (Move Right)
    s -> (Move Down)
    a -> (Move Left)
    q -> Quit
    x -> None |}]
;;

let%expect_test "visual state transitions" =
  let render_state state =
    Notty_test_utils.render_state_to_string ~width:21 ~height:11 state
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
    .         .         .
    .         .         .
    .         .         .
    .         .         .
    .         .         .
    ..........@..........
    .         .         .
    .         .         .
    .         .         .
    .         .         .
    .         .         .

    === After moving right twice ===
            .         .
            .         .
            .         .
            .         .
            .         .
    ..........@..........
            .         .
            .         .
            .         .
            .         .
            .         .

    === After moving down once ===
            .         .
            .         .
            .         .
            .         .
    .....................
            . @       .
            .         .
            .         .
            .         .
            .         .
            .         .
    |}]
;;

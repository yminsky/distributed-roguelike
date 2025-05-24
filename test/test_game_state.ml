open! Core
open Lan_rogue

let%expect_test "game state creation and movement" =
  let initial_state = Game_state.create () in
  (* Add a player to test single-player functionality *)
  let (state, player) = (match Game_state.add_player initial_state ~player_id:"player1" ~player_name:"Player" with
    | Ok result -> result | Error _ -> failwith "Failed to add player") in
  printf
    "Initial state: %s\n"
    (Sexp.to_string_hum
       (sexp_of_list
          sexp_of_int
          [ player.position.x; player.position.y ]));
  [%expect {| Initial state: (0 0) |}];
  let moved_right =
    (match Game_state.move_player state ~player_id:"player1" ~direction:Right with
    | Ok s -> s | Error _ -> failwith "Failed to move right")
  in
  let player_after_right = Game_state.get_player moved_right ~player_id:"player1" |> Option.value_exn in
  printf
    "After moving right: %s\n"
    (Sexp.to_string_hum
       (sexp_of_list sexp_of_int [ player_after_right.position.x; player_after_right.position.y ]));
  [%expect {| After moving right: (1 0) |}];
  let moved_up = (match Game_state.move_player moved_right ~player_id:"player1" ~direction:Up with
    | Ok s -> s | Error _ -> failwith "Failed to move up") in
  let player_after_up = Game_state.get_player moved_up ~player_id:"player1" |> Option.value_exn in
  printf
    "After moving up: %s\n"
    (Sexp.to_string_hum
       (sexp_of_list sexp_of_int [ player_after_up.position.x; player_after_up.position.y ]));
  [%expect {| After moving up: (1 -1) |}]
;;

let%expect_test "key to action conversion" =
  let test_key key =
    match Game_state.key_to_action (ASCII key) with
    | Some direction ->
      printf "%c -> %s\n" key (match direction with
        | Up -> "Up"
        | Down -> "Down" 
        | Left -> "Left"
        | Right -> "Right")
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
        (match arrow with
         | Up -> "Up"
         | Down -> "Down"
         | Left -> "Left"
         | Right -> "Right")
        (match direction with
         | Up -> "Up"
         | Down -> "Down"
         | Left -> "Left"
         | Right -> "Right")
    | None ->
      printf
        "Arrow %s -> None\n"
        (match arrow with
         | Up -> "Up"
         | Down -> "Down"
         | Left -> "Left"
         | Right -> "Right")
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

let%expect_test "visual state transitions" =
  let render_state state =
    Notty_test_utils.render_state_to_string ~width:60 ~height:11 state ~player_id:"player1"
  in
  printf "=== Initial State ===\n";
  let state = Game_state.create () in
  let (state, _) = (match Game_state.add_player state ~player_id:"player1" ~player_name:"Player" with
    | Ok result -> result | Error _ -> failwith "Failed to add player") in
  print_endline (render_state state);
  printf "\n=== After moving right twice ===\n";
  let state = (match Game_state.move_player state ~player_id:"player1" ~direction:Right with
    | Ok s -> s | Error _ -> failwith "Failed to move right") in
  let state = (match Game_state.move_player state ~player_id:"player1" ~direction:Right with
    | Ok s -> s | Error _ -> failwith "Failed to move right") in
  print_endline (render_state state);
  printf "\n=== After moving down once ===\n";
  let state = (match Game_state.move_player state ~player_id:"player1" ~direction:Down with
    | Ok s -> s | Error _ -> failwith "Failed to move down") in
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

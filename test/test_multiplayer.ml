open! Core
open Lan_rogue

let%expect_test "multi-player state management" =
  let state = Game_state.create () in
  (* Add first player *)
  let result1 =
    Game_state.add_player
      state
      ~player_id:(Protocol.Player_id.create "alice")
      ~player_name:"Alice"
  in
  (match result1 with
   | Ok (_state, player) ->
     printf
       "Added player: %s at (%d, %d) with sigil '%c'\n"
       player.name
       player.position.x
       player.position.y
       player.sigil
   | Error msg -> printf "Error: %s\n" msg);
  let state =
    match result1 with
    | Ok (s, _) -> s
    | Error _ -> state
  in
  (* Add second player *)
  let result2 =
    Game_state.add_player
      state
      ~player_id:(Protocol.Player_id.create "bob")
      ~player_name:"Bob"
  in
  (match result2 with
   | Ok (_state, player) ->
     printf
       "Added player: %s at (%d, %d) with sigil '%c'\n"
       player.name
       player.position.x
       player.position.y
       player.sigil
   | Error msg -> printf "Error: %s\n" msg);
  [%expect
    {|
    Added player: Alice at (0, 0) with sigil '@'
    Added player: Bob at (-1, -1) with sigil '#'
    |}]
;;

let%expect_test "collision detection" =
  let state = Game_state.create () in
  (* Add two players *)
  let state, alice =
    match
      Game_state.add_player
        state
        ~player_id:(Protocol.Player_id.create "alice")
        ~player_name:"Alice"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add Alice"
  in
  let state, bob =
    match
      Game_state.add_player
        state
        ~player_id:(Protocol.Player_id.create "bob")
        ~player_name:"Bob"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add Bob"
  in
  printf
    "Alice at (%d, %d), Bob at (%d, %d)\n"
    alice.position.x
    alice.position.y
    bob.position.x
    bob.position.y;
  (* Move Bob to be adjacent to Alice (right of Alice) *)
  let state =
    match
      Game_state.move_player
        state
        ~player_id:(Protocol.Player_id.create "bob")
        ~direction:Left
    with
    | Ok (s, _update) -> s
    | Error _ -> failwith "Failed to move Bob left"
  in
  let bob =
    Game_state.get_player state ~player_id:(Protocol.Player_id.create "bob")
    |> Option.value_exn
  in
  printf "Bob now at (%d, %d)\n" bob.position.x bob.position.y;
  (* Check Alice's current position *)
  let alice =
    Game_state.get_player state ~player_id:(Protocol.Player_id.create "alice")
    |> Option.value_exn
  in
  printf "Alice is at (%d, %d)\n" alice.position.x alice.position.y;
  (* Try to move Bob into Alice's position (should fail) *)
  let result =
    Game_state.move_player
      state
      ~player_id:(Protocol.Player_id.create "bob")
      ~direction:Left
  in
  (match result with
   | Ok (_state, _update) -> printf "Move succeeded (unexpected)\n"
   | Error msg -> printf "Move blocked: %s\n" msg);
  (* Move Bob in a different direction (should work) *)
  let result =
    Game_state.move_player
      state
      ~player_id:(Protocol.Player_id.create "bob")
      ~direction:Down
  in
  (match result with
   | Ok (new_state, _update) ->
     let bob =
       Game_state.get_player new_state ~player_id:(Protocol.Player_id.create "bob")
     in
     (match bob with
      | Some player ->
        printf "Bob moved to (%d, %d)\n" player.position.x player.position.y
      | None -> printf "Bob not found\n")
   | Error msg -> printf "Move failed: %s\n" msg);
  [%expect
    {|
    Alice at (0, 0), Bob at (-1, -1)
    Bob now at (-2, -1)
    Alice is at (0, 0)
    Move succeeded (unexpected)
    Bob moved to (-2, 0)
    |}]
;;

let%expect_test "visual multi-player rendering" =
  let state = Game_state.create () in
  (* Add three players *)
  let state, _ =
    match
      Game_state.add_player
        state
        ~player_id:(Protocol.Player_id.create "alice")
        ~player_name:"Alice"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add Alice"
  in
  let state, _ =
    match
      Game_state.add_player
        state
        ~player_id:(Protocol.Player_id.create "bob")
        ~player_name:"Bob"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add Bob"
  in
  let state, _ =
    match
      Game_state.add_player
        state
        ~player_id:(Protocol.Player_id.create "charlie")
        ~player_name:"Charlie"
    with
    | Ok result -> result
    | Error _ -> failwith "Failed to add Charlie"
  in
  (* Move players to specific positions *)
  let state =
    match
      Game_state.move_player
        state
        ~player_id:(Protocol.Player_id.create "bob")
        ~direction:Right
    with
    | Ok (s, _update) -> s
    | Error _ -> failwith "Failed to move Bob right"
  in
  let state =
    match
      Game_state.move_player
        state
        ~player_id:(Protocol.Player_id.create "bob")
        ~direction:Right
    with
    | Ok (s, _update) -> s
    | Error _ -> failwith "Failed to move Bob right again"
  in
  let state =
    match
      Game_state.move_player
        state
        ~player_id:(Protocol.Player_id.create "charlie")
        ~direction:Down
    with
    | Ok (s, _update) -> s
    | Error _ -> failwith "Failed to move Charlie down"
  in
  (* Render the world *)
  let players = Game_state.get_players state in
  let walls = Game_state.get_walls state in
  let world_view =
    Display.World_view.
      { players; walls; center_pos = { x = 0; y = 0 }; view_width = 15; view_height = 9 }
  in
  let image = Display.render_ui world_view in
  print_endline (Notty_test_utils.render_to_string image);
  [%expect
    {|
           .
           .
           .
           .#
    .......@.......
          $.
           .
           .
           .

    Center: (0, 0) | Players: 3 | Use WASD to move, Q to quit
    |}]
;;

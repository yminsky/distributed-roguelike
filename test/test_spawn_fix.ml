open! Core
open Lan_rogue

let%expect_test "spawn positions in test maze work correctly" =
  let state = Game_state.create ~maze_config:Test_maze () in
  
  (* Add a player - should succeed *)
  let result = Game_state.add_player state ~player_id:(Player_id.of_int 1) ~player_name:"Alice" in
  (match result with
   | Ok (_state, player) ->
     printf "Player spawned at (%d, %d)\n" player.position.x player.position.y
   | Error msg ->
     printf "Failed to spawn: %s\n" msg);
  
  [%expect {|
    Player spawned at (0, 0)
    |}]
;;

let%expect_test "spawn positions spread out in no-maze mode" =
  let state = Game_state.create () in
  
  (* Add multiple players *)
  let rec add_players state n =
    if n = 0
    then ()
    else
      match Game_state.add_player state ~player_id:(Player_id.of_int n) ~player_name:(sprintf "P%d" n) with
      | Ok (new_state, player) ->
        printf "P%d spawned at (%d, %d)\n" n player.position.x player.position.y;
        add_players new_state (n - 1)
      | Error msg ->
        printf "Failed to add P%d: %s\n" n msg
  in
  
  add_players state 5;
  
  [%expect {|
    P5 spawned at (0, 0)
    P4 spawned at (-1, -1)
    P3 spawned at (-1, 0)
    P2 spawned at (-1, 1)
    P1 spawned at (0, -1)
    |}]
;;

let%expect_test "spawn positions work in generated maze" =
  let config = Maze_generation.Config.create ~width:31 ~height:31 |> Or_error.ok_exn in
  let state = Game_state.create ~maze_config:(Generated_maze (config, 42)) () in
  
  (* Add a few players and check they spawn on non-wall positions *)
  let rec add_and_check state n =
    if n = 0
    then printf "All players spawned successfully!\n"
    else
      match Game_state.add_player state ~player_id:(Player_id.of_int n) ~player_name:(sprintf "P%d" n) with
      | Ok (new_state, player) ->
        let walls = Game_state.get_walls new_state in
        let is_wall = List.exists walls ~f:(fun w -> Position.equal w player.position) in
        if is_wall
        then printf "ERROR: P%d spawned on wall at (%d, %d)\n" n player.position.x player.position.y
        else printf "P%d spawned on valid floor at (%d, %d)\n" n player.position.x player.position.y;
        add_and_check new_state (n - 1)
      | Error msg ->
        printf "Failed to add P%d: %s\n" n msg
  in
  
  add_and_check state 3;
  
  [%expect {|
    P3 spawned on valid floor at (-1, -1)
    P2 spawned on valid floor at (-1, 0)
    P1 spawned on valid floor at (-1, 1)
    All players spawned successfully!
    |}]
;;
open! Core
open Async

let handle_input player_pos_ref term =
  let rec loop () =
    let%bind result = Notty_async.Term.events term |> Pipe.read in
    match result with
    | `Eof -> return `Quit
    | `Ok event ->
      (match event with
       | `Key (key, []) ->
         (match Game_state.key_to_action key with
          | Some direction ->
            let new_pos = match direction with
              | `Up -> Protocol.Position.{ x = !player_pos_ref.x; y = !player_pos_ref.y - 1 }
              | `Down -> Protocol.Position.{ x = !player_pos_ref.x; y = !player_pos_ref.y + 1 }
              | `Left -> Protocol.Position.{ x = !player_pos_ref.x - 1; y = !player_pos_ref.y }
              | `Right -> Protocol.Position.{ x = !player_pos_ref.x + 1; y = !player_pos_ref.y }
            in
            player_pos_ref := new_pos;
            return `Continue
          | None -> 
            (match key with
             | `ASCII ('q' | 'Q') -> return `Quit
             | _ -> loop ()))
       | _ -> loop ())
  in
  loop ()
;;

let main_loop () =
  let player_pos = ref Protocol.Position.{ x = 0; y = 0 } in
  let%bind term = Notty_async.Term.create () in
  let rec render_loop () =
    let world_view =
      Display.World_view.{ 
        players = [Protocol.Player.{
          id = "local_player";
          position = !player_pos;
          name = "You";
          sigil = '@';
        }];
        center_pos = !player_pos;
        view_width = 60;
        view_height = 20;
      }
    in
    let ui = Display.render_ui world_view in
    let%bind () = Notty_async.Term.image term ui in
    let%bind () = after (Time_float.Span.of_ms 50.0) in
    render_loop ()
  in
  let%bind () = Notty_async.Term.cursor term (Some (0, 0)) in
  don't_wait_for (render_loop ());
  let rec input_loop () =
    let%bind result = handle_input player_pos term in
    match result with
    | `Quit -> return ()
    | `Continue -> input_loop ()
  in
  input_loop ()
;;

let command =
  Async.Command.async ~summary:"Game client" (Async.Command.Param.return main_loop)
;;

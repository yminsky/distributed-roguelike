open! Core
open! Async

let handle_input player_pos_ref term =
  let rec loop () =
    let%bind result = Notty_async.Term.events term |> Pipe.read in
    match result with
    | `Eof -> return `Quit
    | `Ok event ->
      (match event with
       | `Key (`ASCII 'q', []) | `Key (`ASCII 'Q', []) -> return `Quit
       | `Key (`ASCII 'w', []) | `Key (`ASCII 'W', []) ->
         (player_pos_ref := Protocol.{ !player_pos_ref with y = !player_pos_ref.y - 1 });
         return `Continue
       | `Key (`ASCII 's', []) | `Key (`ASCII 'S', []) ->
         (player_pos_ref := Protocol.{ !player_pos_ref with y = !player_pos_ref.y + 1 });
         return `Continue
       | `Key (`ASCII 'a', []) | `Key (`ASCII 'A', []) ->
         (player_pos_ref := Protocol.{ !player_pos_ref with x = !player_pos_ref.x - 1 });
         return `Continue
       | `Key (`ASCII 'd', []) | `Key (`ASCII 'D', []) ->
         (player_pos_ref := Protocol.{ !player_pos_ref with x = !player_pos_ref.x + 1 });
         return `Continue
       | _ -> loop ())
  in
  loop ()
;;

let main_loop () =
  let player_pos = ref Protocol.{ x = 0; y = 0 } in
  let%bind term = Notty_async.Term.create () in
  let rec render_loop () =
    let world_view =
      Display.{ player_pos = !player_pos; view_width = 60; view_height = 20 }
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

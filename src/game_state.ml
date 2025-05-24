open! Core

module Local_state = struct
  type t = { player_pos : Protocol.Position.t }

  let create () = { player_pos = { x = 0; y = 0 } }

  let move_player t direction =
    let { Protocol.Position.x; y } = t.player_pos in
    let new_pos =
      match direction with
      | `Up -> Protocol.Position.{ x; y = y - 1 }
      | `Down -> Protocol.Position.{ x; y = y + 1 }
      | `Left -> Protocol.Position.{ x = x - 1; y }
      | `Right -> Protocol.Position.{ x = x + 1; y }
    in
    { player_pos = new_pos }
  ;;
end

module Action = struct
  type t =
    | Move of [ `Up | `Down | `Left | `Right ]
    | Quit
  [@@deriving sexp]
end

let apply_action state action =
  match action with
  | Action.Move direction -> Local_state.move_player state direction
  | Action.Quit -> state (* No state change for quit *)
;;

let key_to_action = function
  | `ASCII 'w' | `ASCII 'W' -> Some (Action.Move `Up)
  | `ASCII 's' | `ASCII 'S' -> Some (Action.Move `Down)
  | `ASCII 'a' | `ASCII 'A' -> Some (Action.Move `Left)
  | `ASCII 'd' | `ASCII 'D' -> Some (Action.Move `Right)
  | `ASCII 'q' | `ASCII 'Q' -> Some Action.Quit
  | _ -> None
;;

let to_world_view state ~view_width ~view_height =
  Display.World_view.
    { player_pos = state.Local_state.player_pos; view_width; view_height }
;;

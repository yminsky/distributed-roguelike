open! Core

type t =
  { players : (Protocol.Player_id.t, Protocol.Player.t) List.Assoc.t
  ; max_players : int
  }

let create ?(max_players = 10) () = { players = []; max_players }
let player_sigils = [| '@'; '#'; '$'; '%'; '&'; '*'; '+'; '='; '?'; '!' |]

let next_available_sigil t =
  let used_sigils =
    List.map t.players ~f:(fun (_, p) -> p.sigil) |> Set.of_list (module Char)
  in
  Array.find player_sigils ~f:(fun sigil -> not (Set.mem used_sigils sigil))
;;

let find_spawn_position t =
  let occupied_positions = List.map t.players ~f:(fun (_, p) -> p.position) in
  (* Try positions in a spiral around origin *)
  let rec try_positions radius =
    if radius > 20
    then failwith "Cannot find spawn position"
    else (
      let positions = ref [] in
      for dx = -radius to radius do
        for dy = -radius to radius do
          if abs dx = radius || abs dy = radius
          then positions := Protocol.Position.{ x = dx; y = dy } :: !positions
        done
      done;
      match
        List.find !positions ~f:(fun pos ->
          not (List.exists occupied_positions ~f:(Protocol.Position.equal pos)))
      with
      | Some pos -> pos
      | None -> try_positions (radius + 1))
  in
  try_positions 0
;;

let add_player t ~player_id ~player_name =
  if List.length t.players >= t.max_players
  then Error "Server full (max 10 players)"
  else (
    match next_available_sigil t with
    | None -> Error "No available sigils"
    | Some sigil ->
      let position = find_spawn_position t in
      let player =
        Protocol.Player.{ id = player_id; position; name = player_name; sigil }
      in
      let players =
        (player_id, player) :: List.Assoc.remove t.players player_id ~equal:String.equal
      in
      Ok ({ t with players }, player))
;;

let remove_player t ~player_id =
  { t with players = List.Assoc.remove t.players player_id ~equal:String.equal }
;;

let move_player t ~player_id ~(direction : Protocol.Direction.t) =
  match List.Assoc.find t.players player_id ~equal:String.equal with
  | None -> Error "Player not found"
  | Some player ->
    let new_pos = Protocol.Direction.apply_to_position direction player.position in
    (* Check for collisions with other players *)
    let collision =
      List.exists t.players ~f:(fun (other_id, other_player) ->
        (not (String.equal other_id player_id))
        && Protocol.Position.equal other_player.position new_pos)
    in
    if collision
    then Error "Cannot move into another player"
    else (
      let updated_player = { player with position = new_pos } in
      let players =
        (player_id, updated_player)
        :: List.Assoc.remove t.players player_id ~equal:String.equal
      in
      Ok { t with players })
;;

let get_players t = List.map t.players ~f:(fun (_, player) -> player)
let get_player t ~player_id = List.Assoc.find t.players player_id ~equal:String.equal

(* Key mapping for client controls *)
let key_to_action : Protocol.Key_input.t -> Protocol.Direction.t option = function
  | ASCII 'w' | ASCII 'W' -> Some Up
  | ASCII 'a' | ASCII 'A' -> Some Left
  | ASCII 's' | ASCII 'S' -> Some Down
  | ASCII 'd' | ASCII 'D' -> Some Right
  | Arrow Up -> Some Up
  | Arrow Down -> Some Down
  | Arrow Left -> Some Left
  | Arrow Right -> Some Right
  | ASCII 'q' | ASCII 'Q' -> None (* quit *)
  | ASCII _ -> None
;;

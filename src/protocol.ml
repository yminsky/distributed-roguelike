open! Core

module Position = struct
  type t =
    { x : int
    ; y : int
    }
  [@@deriving sexp, bin_io, compare, equal]
end

module Direction = struct
  type t =
    | Up
    | Down
    | Left
    | Right
  [@@deriving sexp, bin_io, compare, equal]

  let to_string = function
    | Up -> "Up"
    | Down -> "Down"
    | Left -> "Left"
    | Right -> "Right"
  ;;

  let to_delta = function
    | Up -> 0, -1
    | Down -> 0, 1
    | Left -> -1, 0
    | Right -> 1, 0
  ;;

  let apply_to_position t pos =
    let dx, dy = to_delta t in
    Position.{ x = pos.x + dx; y = pos.y + dy }
  ;;
end

module Key_input = struct
  type t =
    | ASCII of char
    | Arrow of Direction.t
  [@@deriving sexp, bin_io, compare]

  let of_notty_key = function
    | `ASCII c -> Some (ASCII c)
    | `Arrow `Up -> Some (Arrow Up)
    | `Arrow `Down -> Some (Arrow Down)
    | `Arrow `Left -> Some (Arrow Left)
    | `Arrow `Right -> Some (Arrow Right)
    | _ -> None
  ;;

  let to_string = function
    | ASCII c -> Printf.sprintf "ASCII '%c'" c
    | Arrow dir -> Printf.sprintf "Arrow %s" (Direction.to_string dir)
  ;;
end

module Player_id = struct
  type t = string [@@deriving sexp, bin_io, compare, equal]
end

module Player = struct
  type t =
    { id : Player_id.t
    ; position : Position.t
    ; name : string
    ; sigil : char
    }
  [@@deriving sexp, bin_io]
end

module Request = struct
  type t =
    | Join of { player_name : string }
    | Move of { direction : Direction.t }
    | Leave
  [@@deriving sexp, bin_io]
end

module Update = struct
  type t =
    | Player_joined of Player.t
    | Player_moved of
        { player_id : Player_id.t
        ; new_position : Position.t
        }
    | Player_left of Player_id.t
  [@@deriving sexp, bin_io]
end

module Initial_state = struct
  type t =
    { your_id : Player_id.t
    ; all_players : Player.t list
    }
  [@@deriving sexp, bin_io]
end

module Response = struct
  type t =
    | Ok
    | Error of string
  [@@deriving sexp, bin_io]
end

module Rpc_calls = struct
  let send_request =
    Async_rpc_kernel.Rpc.Rpc.create
      ~name:"game_request"
      ~version:1
      ~bin_query:Request.bin_t
      ~bin_response:Response.bin_t
      ~include_in_error_count:Only_on_exn
  ;;

  let get_game_state =
    Async_rpc_kernel.Rpc.State_rpc.create
      ~name:"game_state"
      ~version:1
      ~bin_query:Unit.bin_t
      ~bin_state:Initial_state.bin_t
      ~bin_update:Update.bin_t
      ~bin_error:Error.bin_t
  ;;
end

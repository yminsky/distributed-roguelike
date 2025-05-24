open! Core

module Position = struct
  type t = { x : int; y : int } [@@deriving sexp, bin_io]
end

module Player_id = struct
  type t = string [@@deriving sexp, bin_io, compare]
end

module Player = struct
  type t = {
    id : Player_id.t;
    position : Position.t;
    name : string;
  } [@@deriving sexp, bin_io]
end

module Request = struct
  type t =
    | Join of { player_name : string }
    | Move of { direction : [ `Up | `Down | `Left | `Right ] }
    | Leave
  [@@deriving sexp, bin_io]
end

module Update = struct
  type t =
    | Player_joined of Player.t
    | Player_moved of { player_id : Player_id.t; new_position : Position.t }
    | Player_left of Player_id.t
  [@@deriving sexp, bin_io]
end

module Initial_state = struct
  type t = {
    your_id : Player_id.t;
    all_players : Player.t list;
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

  let get_game_state =
    Async_rpc_kernel.Rpc.State_rpc.create
      ~name:"game_state"
      ~version:1
      ~bin_query:Unit.bin_t
      ~bin_state:Initial_state.bin_t
      ~bin_update:Update.bin_t
      ~bin_error:Error.bin_t
end

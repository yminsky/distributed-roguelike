open! Core
open! Async

type position = { x : int; y : int } [@@deriving sexp, bin_io]

type player_id = string [@@deriving sexp, bin_io, compare]

type player = {
  id : player_id;
  position : position;
  name : string;
} [@@deriving sexp, bin_io]

module Request = struct
  type t =
    | Join of { player_name : string }
    | Move of { direction : [ `Up | `Down | `Left | `Right ] }
    | Leave
  [@@deriving sexp, bin_io]
end

module Response = struct
  type t =
    | Welcome of { your_id : player_id; initial_state : player list }
    | Player_joined of player
    | Player_moved of { player_id : player_id; new_position : position }
    | Player_left of player_id
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

  let get_updates =
    Async_rpc_kernel.Rpc.Pipe_rpc.create
      ~name:"game_updates"
      ~version:1
      ~bin_query:Unit.bin_t
      ~bin_response:Response.bin_t
      ~bin_error:Error.bin_t
end

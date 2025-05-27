open! Core
open! Import
open Async

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
    ; walls : Position.t list
    ; npcs : Npc.t list
    }
  [@@deriving sexp, bin_io]
end

module Response = struct
  type t = (unit, string) Result.t [@@deriving sexp, bin_io]
end

module Rpc_calls = struct
  let send_request =
    Rpc.Rpc.create
      ~name:"game_request"
      ~version:1
      ~bin_query:Request.bin_t
      ~bin_response:Response.bin_t
      ~include_in_error_count:Only_on_exn
  ;;

  let get_game_state =
    (* TODO: Consider whether wrapping in a function is necessary here,
       or if we could just expose the RPC directly *)
    let rpc =
      Rpc.State_rpc.create
        ~name:"game_state"
        ~version:1
        ~bin_query:Unit.bin_t
        ~bin_state:Initial_state.bin_t
        ~bin_update:Update.bin_t
        ~bin_error:Error.bin_t
    in
    fun () -> rpc ()
  ;;
end

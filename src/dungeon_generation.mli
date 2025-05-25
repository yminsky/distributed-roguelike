(** Room-and-corridor dungeon generation for roguelike maps. *)

open! Core

(** Configuration for dungeon generation using room placement and corridor connection.

    This generator creates traditional roguelike dungeons with rectangular rooms connected
    by corridors. Unlike maze generation, this produces open spaces suitable for combat
    and exploration. *)
module Config : sig
  type t [@@deriving sexp]

  (** Default configuration: suitable for a medium-sized dungeon *)
  val default : t

  (** Create a configuration with the given parameters. Returns an error if parameters are
      invalid. *)
  val create
    :  width:int (** Total width of the dungeon (must be >= 20) *)
    -> height:int (** Total height of the dungeon (must be >= 20) *)
    -> room_attempts:int (** Number of times to try placing rooms (must be > 0) *)
    -> min_room_size:int (** Minimum room dimension (must be >= 3) *)
    -> max_room_size:int (** Maximum room dimension (must be > min_room_size) *)
    -> t Or_error.t

  (** Accessor functions *)
  val width : t -> int

  val height : t -> int
  val room_attempts : t -> int
  val min_room_size : t -> int
  val max_room_size : t -> int
end

(** Generate a dungeon with the given configuration.

    The generated dungeon satisfies these invariants:

    1. **Enclosed**: The dungeon is surrounded by walls on all sides.

    2. **Fully Connected**: All rooms are reachable from any other room through corridors.
       There are no isolated rooms.

    3. **Non-overlapping rooms**: Rooms do not overlap with each other, though they may
       share walls.

    4. **Within Bounds**: All walls and floors are within the specified dimensions.

    5. **Deterministic**: Given the same config and seed, always generates the exact same
       dungeon.

    The algorithm:
    - Places rectangular rooms randomly, rejecting overlaps
    - Connects all rooms using corridors
    - Ensures full connectivity using a graph-based approach

    @param config Generation parameters
    @param seed Random seed for reproducible generation
    @return Set of wall positions *)
val generate : config:Config.t -> seed:int -> Position.Set.t

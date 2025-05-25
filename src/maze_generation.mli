(** Procedural maze generation. *)

open! Core

(** Configuration for maze generation using recursive backtracker algorithm.

    The recursive backtracker creates perfect mazes (no loops) with long, winding
    passages. Every location is reachable with exactly one path between any two points. *)
module Config : sig
  type t [@@deriving sexp]

  (** Default configuration: 21x21 maze *)
  val default : t

  (** Create a configuration with the given dimensions. Returns an error if width or
      height is even or less than 5. *)
  val create : width:int -> height:int -> t Or_error.t

  (** Get the width of the maze *)
  val width : t -> int

  (** Get the height of the maze *)
  val height : t -> int
end

(** Generate a maze with the given configuration.

    The generated maze should satisfy these invariants:

    1. **Enclosed**: The maze is surrounded by walls on all sides, preventing escape.
       There should be a continuous wall border at the edges of the dimensions.

    2. **Fully Connected**: All non-wall positions (floors) should be reachable from any
       other floor position. There should be no isolated sections.

    3. **Within Bounds**: All wall positions should be within the dimensions specified in
       the configuration.

    4. **Deterministic**: Given the same config and seed, the function should always
       generate the exact same maze.

    Note: Some algorithms (like Recursive Backtracker) guarantee perfect mazes (no loops),
    while others (like Rooms and Corridors) may have multiple paths between points. Both
    are acceptable as long as connectivity is maintained.

    @param config Generation parameters
    @param seed Random seed for reproducible generation
    @return Set of wall positions *)
val generate : config:Config.t -> seed:int -> Protocol.Position.Set.t

(** Other maze generation algorithms that could be implemented in the future:

    1. **Room and Corridor**
       - Classic roguelike approach: place rooms, connect with corridors
       - Config needs: area dimensions, room size constraints, room count/density
       - Good for: dungeon crawlers, buildings, traditional roguelikes

    2. **Cellular Automata**
       - Organic, cave-like structures using Conway-style rules
       - Config needs: dimensions, initial wall density, rule parameters, iterations
       - Good for: natural caves, outdoor areas, organic levels

    3. **Binary Space Partition (BSP)**
       - Recursively subdivides space into rooms
       - Config needs: dimensions, min room size, split ratios
       - Good for: buildings, dungeons with rectangular rooms

    4. **Drunkard's Walk**
       - Random walker carves out paths
       - Config needs: dimensions, number of walkers, steps per walker
       - Good for: natural caves, winding passages

    5. **Voronoi Diagrams**
       - Creates organic room shapes based on seed points
       - Config needs: dimensions, number of seed points, connection rules
       - Good for: alien/organic architecture, crystal caves

    6. **Wave Function Collapse**
       - Assembles maze from small pattern tiles that must match adjacently
       - Config needs: tile set definition, constraints, dimensions
       - Good for: complex rule-based generation, themed dungeons *)

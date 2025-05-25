(** Procedural maze generation. *)

open! Core

(** Configuration for maze generation.

    The type t will need to be a variant that captures the different algorithms and their
    specific parameters. Here are the main approaches:

    1. **Room and Corridor**
       - Classic roguelike approach: place rooms, connect with corridors
       - Config needs: area dimensions, room size constraints, room count/density
       - Good for: dungeon crawlers, buildings, traditional roguelikes
       - Example: Rogue, NetHack

    2. **Recursive Backtracker**
       - Creates perfect mazes (no loops) with long, winding passages
       - Config needs: just dimensions (width/height must be odd)
       - Good for: puzzle games, labyrinth levels
       - Characteristics: Every location reachable, exactly one path between points

    3. **Cellular Automata**
       - Organic, cave-like structures using Conway-style rules
       - Config needs: dimensions, initial wall density, rule parameters, iterations
       - Good for: natural caves, outdoor areas, organic levels
       - Example: Terraria caves

    4. **Binary Space Partition (BSP)**
       - Recursively subdivides space into rooms
       - Config needs: dimensions, min room size, split ratios
       - Good for: buildings, dungeons with rectangular rooms
       - Guarantees: No overlapping rooms, can ensure connectivity

    5. **Drunkard's Walk**
       - Random walker carves out paths
       - Config needs: dimensions, number of walkers, steps per walker
       - Good for: natural caves, winding passages
       - Simple but can leave disconnected areas

    6. **Voronoi Diagrams**
       - Creates organic room shapes based on seed points
       - Config needs: dimensions, number of seed points, connection rules
       - Good for: alien/organic architecture, crystal caves
       - Unique aesthetic, mathematically interesting

    7. **Wave Function Collapse**
       - Assembles maze from small pattern tiles that must match adjacently
       - Config needs: tile set definition, constraints, dimensions
       - Good for: complex rule-based generation, themed dungeons
       - Can encode complex architectural rules

    The actual Config.t type would likely be a variant like:
    {[
      type t =
        | Rooms_and_corridors of {
            width: int;
            height: int;
            room_attempts: int;
            min_room_size: int;
            max_room_size: int
          }
        | Recursive_backtracker of {
            width: int;  (* must be odd *)
            height: int  (* must be odd *)
          }
        | Cellular_automata of {
            width: int;
            height: int;
            initial_density: float;
            iterations: int
          }
        | BSP of {
            width: int;
            height: int;
            min_room_size: int;
            split_ratio: float
          }
        | Drunkards_walk of {
            width: int;
            height: int;
            walkers: int;
            steps_per_walker: int
          }
        | ...
    ]} *)
module Config : sig
  type t

  (** Default configuration - could be rooms and corridors with sensible defaults *)
  val default : t
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

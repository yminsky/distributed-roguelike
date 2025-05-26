# LAN Rogue - Ideas and Next Steps

## Core Features to Implement

### 1. Maze System
- **Wall Representation**: Add wall tiles to the game state
  - Could use a 2D array or sparse representation for walls
  - Need collision detection to prevent walking through walls
- **Visibility System**:
  - Ray-casting or shadow-casting algorithms for line-of-sight
  - Only render tiles visible from player's position
  - Consider "fog of war" for previously seen areas
- **Maze Generation**:
  - Classic algorithms: Recursive backtracking, Kruskal's, Prim's
  - Could generate different maze styles per level
  - Support for rooms and corridors

#### Spawn Point Safety Problem

When adding walls, we need to ensure players spawn in accessible areas. Options:

1. **Designated spawn areas**: Mark specific regions as valid spawn points, guaranteed to be accessible
2. **Flood-fill validation**: After placing walls, flood-fill from a known "inside" point to identify all reachable spaces
3. **Wall generation that guarantees connectivity**: Use maze generation algorithms that ensure all spaces remain connected
4. **Explicit room/corridor structure**: Define rooms and corridors as first-class concepts, then spawn only in rooms

**Implementation plan**:
- Start with hardcoded test maze with known safe spawn points
- Add basic wall representation and collision detection
- Later add proper maze generation with connectivity guarantees

### Visibility System Design

#### Core Questions

1. **What should players see?**
   - Only what's in direct line of sight?
   - Previously explored areas ("fog of war")?
   - Different visibility for different players?

2. **How does multiplayer visibility work?**
   - Does each player have their own visibility?
   - Can players share visibility information?
   - Do we show other players even if they're out of sight?

#### Implementation Approaches

**Option 1: Simple Radius-Based Visibility**
```ocaml
(* Everything within radius R of player is visible *)
let is_visible ~player_pos ~tile_pos ~radius =
  let dx = tile_pos.x - player_pos.x in
  let dy = tile_pos.y - player_pos.y in
  (dx * dx) + (dy * dy) <= (radius * radius)
```
- Pros: Dead simple, fast
- Cons: Can see through walls, unrealistic

**Option 2: Ray-Casting (Bresenham's Line)**
```ocaml
(* Cast rays from player to each tile on screen edge *)
let cast_ray ~from ~to_pos ~walls =
  (* Use Bresenham's algorithm to trace line *)
  (* Stop if we hit a wall *)
  ...
```
- Pros: Walls block vision properly
- Cons: Can have artifacts, walls can "hide" tiles behind them incorrectly

**Option 3: Shadow-Casting (Recommended)**
- Cast shadows from walls to determine dark areas
- More complex but gives best results
- Can handle partial visibility elegantly
- Reference: http://www.roguebasin.com/index.php?title=FOV_using_recursive_shadowcasting

**Option 4: Flood-Fill Based**
```ocaml
(* Start at player, flood-fill to adjacent visible tiles *)
let compute_visibility ~player_pos ~walls ~max_radius =
  (* BFS from player position *)
  (* Stop at walls or max radius *)
  ...
```
- Pros: Simple to understand, handles corners well
- Cons: Can be slower for large areas

#### Multiplayer Considerations

**Approach 1: Server Computes Per-Player Visibility**
- Server tracks what each player can see
- Only send visible entities in updates
- Pros: Prevents cheating, reduces network traffic
- Cons: More server computation

**Approach 2: Client-Side Visibility**
- Send all data, let client filter
- Pros: Simple server, smooth client experience
- Cons: Cheating possible, more network traffic

**Approach 3: Hybrid**
- Server sends nearby entities only (rough filtering)
- Client does precise visibility calculation
- Balance between security and performance

#### Fog of War Options

1. **No Memory**: Can only see current line-of-sight
2. **Perfect Memory**: Once seen, always remembered
3. **Partial Memory**: Remember terrain but not entities
4. **Decay**: Memory fades over time

#### Recommended Implementation Plan

1. **Phase 1**: Simple radius visibility (ignore walls)
   - Get the rendering pipeline working
   - Test multiplayer with different visibility per player

2. **Phase 2**: Add wall occlusion with ray-casting
   - Implement Bresenham's line algorithm
   - Handle edge cases (corners, diagonal walls)

3. **Phase 3**: Upgrade to shadow-casting if needed
   - Better quality visibility
   - Handle complex scenarios

4. **Phase 4**: Add fog of war
   - Track explored areas per player
   - Render unexplored as black, explored-but-not-visible as gray

#### Data Structure Considerations

```ocaml
type visibility_state = {
  visible_tiles : Position.Set.t;
  explored_tiles : Position.Set.t;
  visibility_radius : int;
}

(* Per-player visibility in game state *)
type t = {
  players : (Player_id.t, player_data) List.Assoc.t;
  visibility : (Player_id.t, visibility_state) List.Assoc.t;
  (* ... *)
}
```

### 2. NPC System
- **Basic NPCs**: Stationary or wandering creatures
- **AI Behaviors**:
  - Pathfinding (A* for intelligent movement)
  - Different behavior patterns (aggressive, passive, fleeing)
- **Combat System**: Turn-based or real-time interactions
- **NPC Types**: Enemies, merchants, quest-givers

#### NPC Architecture Design

**Design Philosophy**

Before diving into implementation details, let's consider what NPCs
fundamentally need to do in our game:

1. **Exist in Space**: NPCs occupy positions in the game world and
   need to move around
2. **Make Decisions**: NPCs need to decide what to do each turn based
   on game state
3. **Be Interactable**: Players can interact with NPCs in various ways
   (combat, dialogue, trading)
4. **Have State**: NPCs need to track their own state (health,
   inventory, conversation flags)
5. **Be Persistent**: NPCs should survive across game sessions

The game framework needs to:

- Know where each NPC is located (for rendering and collision
  detection)
- Update NPC states each turn (movement, actions)
- Handle player-NPC interactions
- Remove dead NPCs from the game
- Serialize/deserialize NPC state

**Interaction System**

Interactions could be modeled as:

```ocaml
module Action = struct
  type t =
    | Move of Position.t
    | Attack of { target : Entity_id.t; damage : int }
    | Speak of { message : string; target : Entity_id.t option }
    | Trade of { items : Item.t list; target : Entity_id.t }
    | Give_item of { item : Item.t; target : Entity_id.t }
    | Use_item of Item.t
    | Pick_up of Item_id.t
    | Wait
end

module Entity_id = struct
  type t =
    | Player of Player_id.t
    | Npc of Npc_id.t
end
```

This unification has several advantages:
- Both PCs and NPCs can perform the same actions
- Simpler to implement and reason about
- Makes NPCs feel more like "real" participants in the world
- Easier to add new actions that work for both entity types
- Could even allow for interesting mechanics like mind control or
  possession where a player controls an NPC

**Option 1: First-Class Module Approach**

Based on the fundamental needs, here's a minimal interface:

```ocaml
module type NPC = sig
  type t [@@deriving sexp]

  (* Essential queries the framework needs *)
  val id : t -> Npc_id.t
  val position : t -> Position.t
  val is_alive : t -> bool
  val sigil : t -> char  (* For rendering *)

  (* Core behavior *)
  val think : t -> game_state -> Npc_action.t

  (* State updates - return None if NPC dies *)
  val update : t -> Npc_update.t -> t option
  val interact : t -> Player_id.t -> interaction_request -> t * interaction_response
end

(* Where updates could be: *)
module Npc_update = struct
  type t =
    | Move_to of Position.t
    | Take_damage of int
    | Heal of int
    | Time_passed  (* For any time-based state changes *)
end
```

This minimal interface focuses on what the framework absolutely needs while keeping NPC internals private.

**Option 1b: Even Simpler Functional Approach**

```ocaml
(* NPCs as pure data with external behavior functions *)
type npc = {
  id : Npc_id.t;
  kind : Npc_kind.t;
  position : Position.t;
  health : int;
  internal_state : Sexp.t;  (* Opaque state for each NPC type *)
} [@@deriving sexp]

(* Behavior is determined by kind *)
val think : npc -> game_state -> Npc_action.t
val interact : npc -> Player_id.t -> interaction_request -> npc * interaction_response
val update : npc -> Npc_update.t -> npc option

(* Then use first-class modules *)
type npc = (module NPC)

(* Example implementation *)
module Goblin : NPC = struct
  type t = {
    id : Npc_id.t;
    position : Position.t;
    health : int;
    aggro_player : Player_id.t option;
  }

  let think t game_state =
    match t.aggro_player with
    | None -> Npc_action.Wander
    | Some player_id ->
      match find_player game_state player_id with
      | None -> Npc_action.Wander
      | Some player -> Npc_action.Chase player.position
end
```

**Option 2: Variant + Behavior Pattern Approach**

```ocaml
(* Define behavior interfaces *)
module type Movement_behavior = sig
  val get_move : npc_state -> game_state -> Position.t option
end

module type Combat_behavior = sig
  val get_target : npc_state -> game_state -> Player_id.t option
  val get_attack : npc_state -> Player_id.t -> Attack.t
end

(* Core NPC type with pluggable behaviors *)
type npc = {
  id : Npc_id.t;
  variant : Npc_variant.t;  (* Goblin | Merchant | Guard | etc. *)
  position : Position.t;
  health : int;
  state : npc_state;
  movement : (module Movement_behavior);
  combat : (module Combat_behavior) option;
}

(* Behaviors can be mixed and matched *)
module Aggressive_movement : Movement_behavior = struct
  let get_move state game =
    (* Chase nearest player *)
end

module Merchant_movement : Movement_behavior = struct
  let get_move state game =
    (* Stay in place or patrol between waypoints *)
end
```

**Option 3: Simple Variant Approach (Recommended for Starting)**

```ocaml
(* Start simple, refactor later if needed *)
type npc_kind =
  | Goblin of { aggro_range : int; damage : int }
  | Merchant of { items : Item.t list; prices : (Item.t * int) list }
  | Guard of { patrol_route : Position.t list; alert_range : int }
  | Minotaur of { speaking_style : Speaking_style.t }

type npc = {
  id : Npc_id.t;
  kind : npc_kind;
  position : Position.t;
  health : int;
  max_health : int;
}

(* Behavior is a simple function *)
val npc_think : npc -> game_state -> Npc_action.t

let npc_think npc game_state =
  match npc.kind with
  | Goblin { aggro_range; _ } ->
    let nearby_players = find_players_in_range game_state npc.position aggro_range in
    begin match nearby_players with
    | [] -> Wander (random_adjacent_position npc.position)
    | player :: _ -> Chase player.position
    end
  | Merchant _ -> Stand_still
  | Guard { patrol_route; _ } -> Patrol patrol_route
  | Minotaur _ -> Speak_cryptically
```

**Recommendation**: Start with Option 3 (simple variants) and migrate
to Option 1 (first-class modules) once we have more NPC types and
complex behaviors. The first-class module approach provides better
extensibility but might be overengineering for initial implementation.

**Key Design Principles**:
1. NPCs should be deterministic given the same game state (for testing)
2. NPC state updates should be pure functions
3. All NPC types should serialize/deserialize for save games
4. Keep NPC logic separate from rendering logic
5. Server authoritative - NPCs only exist and think on server side

### 3. Game Mechanics
- **Items and Inventory**: Collectibles, equipment, consumables
- **Character Stats**: Health, abilities, experience
- **Win/Loss Conditions**: Objectives, permadeath mechanics
- **Level Progression**: Multiple floors/areas to explore

## Theme Ideas

### 1. "The OxCaml Labyrinth"
- Players are functional programmers lost in the legendary OxCaml labyrinth
- The Minotaur is replaced by the "Monadic Minotaur" who speaks only in category theory
- Collect "type signatures" to unlock doors
- NPCs include:
  - "Tail-Recursive Spirits" that help you optimize your path
  - "Garbage Collectors" that clean up items but might take yours too
  - "The Borrow Checker" (a lost Rust programmer) who won't let you pass without proving ownership
- Boss: The dreaded "Circular Dependency Dragon"

### 2. "Matrix Multiplication Mines"
- Set in the deep GPU mines where your son toils away
- Players are "Performance Engineers" navigating through layers of nested loops
- Enemies include:
  - "Cache Misses" that teleport randomly
  - "Memory Leaks" that grow larger over time
  - "Unoptimized Algorithms" that move incredibly slowly but hit hard
- Collect "FLOPS" as currency and "Tensor Cores" as power-ups
- Final boss: "The Unparallelizable Problem"

### 3. "Academic Underworld"
- A journey through the layers of academic CS hell
- Each level represents a different course nightmare:
  - "Proof by Induction Purgatory" (math level)
  - "The Halting Problem Hotel" (theory level)
  - "Segfault Swamp" (systems level)
  - "NP-Complete Nightmare" (algorithms level)
- NPCs include stressed grad students who give cryptic hints
- Collect "Problem Sets" but beware - they weigh you down!
- Boss encounters are "Final Exams" with time limits

### 4. "Jane Street Trading Floor Dungeon"
- Navigate the mysterious underground trading floors
- Enemies are "Market Volatilities" and "Rogue Algorithms"
- Collect "Basis Points" as experience
- NPCs include:
  - "Quants" who speak in equations
  - "Traders" who offer risky item trades
  - "The Compliance Officer" who blocks certain paths
- Special mechanic: Market conditions change the dungeon layout in real-time
- Boss: "The Black Swan Event"

### 5. "The Great Type System War"
- A battle between statically and dynamically typed languages
- Players choose their allegiance at the start
- Locations include:
  - "The Inference Engine" (puzzle rooms)
  - "Runtime Error Valley" (dangerous for static typers)
  - "Compile-Time Castle" (challenging for dynamic typers)
- NPCs are anthropomorphized programming languages with personality quirks:
  - OCaml: Elegant but slightly smug
  - Python: Friendly but keeps trying to duck-type everything
  - Haskell: Won't stop talking about monads
  - JavaScript: Chaotic neutral, does unexpected things
- Final boss: "The Any Type" - shapeshifts between different forms

## Implementation Priority

1. **Phase 1**: Basic maze with walls and visibility
2. **Phase 2**: Simple NPCs with basic AI
3. **Phase 3**: Items and combat system
4. **Phase 4**: Theme implementation and polish
5. **Phase 5**: Advanced features (procedural generation, complex AI)

## Technical Considerations

- Keep the architecture modular to easily swap themes
- Design the protocol to handle future features (NPCs, items, etc.)
- Consider performance with many entities on screen
- Plan for save/load functionality in multiplayer context

## Next Steps - Post-Visibility Implementation

### High Impact, Moderate Complexity

#### 1. Basic Combat System
- Add health points to players
- Implement a simple melee attack (spacebar or 'f' key)
- Players can damage each other when adjacent
- Respawn system when players die
- This would add actual gameplay beyond just exploration

#### 2. NPCs/Monsters
- Start with simple stationary monsters
- Then add basic AI (move toward nearest player)
- Different monster types with varying health/damage
- Monsters spawn when dungeon is generated
- This gives players something to do together

#### 3. Items and Loot
- Health potions that spawn in rooms
- Simple equipment (weapons that increase damage)
- Inventory system (even just a single equipped weapon slot)
- Items visible on the ground as different symbols

### Quality of Life Improvements

#### 4. Player Communication
- Simple chat system (press 'Enter' to type message)
- Messages appear in a log area below the map
- Player names shown above their characters
- "Player X has joined/left" notifications

#### 5. Better Spawn System
- Spawn players in a guaranteed safe room
- Ensure spawn area is always accessible
- Maybe a special "spawn room" that's always generated

#### 6. Minimap
- Small overview map showing explored areas
- Different from main view - shows full dungeon layout you've seen
- Helps with navigation in larger dungeons

### Technical Improvements

#### 7. Save/Load Dungeon Seeds
- Allow server to specify a seed via command line
- Save the seed to a file for replaying same dungeon
- Useful for testing and competitions

#### 8. Performance Optimizations
- Only send visible entities to each client
- Delta updates instead of full state
- Compress network messages

#### 9. Configuration Files
- Server config file for dungeon parameters
- Client config for key bindings
- Player preferences (color schemes, etc.)

### Advanced Features

#### 10. Multiple Floors
- Stairs up/down to navigate between levels
- Deeper levels have harder monsters
- Persistent state across floors

#### 11. Fog of War Persistence
- Remember what areas you've explored
- Show previously seen (but not currently visible) areas in gray
- Shared team visibility option

#### 12. Special Room Types
- Treasure rooms with better loot
- Monster dens with many enemies
- Puzzle rooms with switches/doors
- Boss rooms with unique challenges

### Recommended Starting Point

I'd suggest starting with **Basic Combat System** or **Simple NPCs/Monsters**. Here's why:

1. **Immediate Gameplay Value**: Right now players can only walk around. Combat would add actual gameplay.
2. **Builds on Existing Systems**: You already have collision detection and player positions - combat is a natural extension.
3. **Multiplayer Interaction**: Players can work together against monsters or compete with each other.
4. **Reasonable Scope**: A basic combat system can be implemented incrementally.

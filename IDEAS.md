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

TODO: I'm not convinced of this idea, really. I don't know that we
need a "response" type.  I think we could have one type, which is a
thing that a PC or an NPC can do, either to another PC or another NPC.
Given that both NPCs and PCs are essentially autonomous, wy not a
single action type?

```ocaml
(* TODO: Even here, every type should be called t, and should be
   contained within a mdoule with a meaningful name *)
type interaction_request =
  | Talk
  | Trade
  | Attack of { damage : int }
  | Give_item of Item.t

type interaction_response =
  | Dialogue of string list  (* Lines of dialogue *)
  | Trade_window of { items : Item.t list; prices : (Item.t * int) list }
  | Combat_reaction of { counter_damage : int option }
  | Accept_item
  | Refuse of string  (* Reason for refusal *)
  | No_response
```

**Option 1: First-Class Module Approach (Revised)**

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

**Recommendation**: Start with Option 3 (simple variants) and migrate to Option 1 (first-class modules) once we have more NPC types and complex behaviors. The first-class module approach provides better extensibility but might be overengineering for initial implementation.

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

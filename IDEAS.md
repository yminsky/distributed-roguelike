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
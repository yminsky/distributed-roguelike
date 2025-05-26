# LAN Rogue

A distributed multiplayer roguelike game for LAN play, built with
OCaml and Jane Street libraries.

## Features

- **Multiplayer Support**: Multiple players can connect and explore
  together
- **Procedural Generation**: Random dungeons with rooms and corridors
  on each server restart
- **Real-time Updates**: See other players move in real-time
- **Field of View**: Shadow-casting visibility system - walls block
  your view
- **Terminal UI**: Clean ASCII graphics with Notty-based display

## Gameplay

### Controls
- **Movement**: Arrow keys or WASD
- **Quit**: Q or Ctrl-C

### Display
- `@`, `#`, `$`, etc. - Players (each gets a unique sigil)
- `#` - Walls
- `.` - Floor/walkable space
- The view centers on your character with a status bar showing your position

### Game Mechanics
- **Visibility**: You can only see areas in your line of sight (10 tile radius)
- **Collision**: Cannot walk through walls or other players
- **Spawning**: Players spawn near the center, avoiding walls and other players

## Map Generation

The server generates a new dungeon on each startup with:
- **Rooms**: Rectangular rooms of varying sizes
- **Corridors**: Connecting passages between rooms
- **Guaranteed Connectivity**: All areas are reachable

Alternative map types (configurable in code):
- Empty world with no walls
- Simple test maze
- Procedural perfect mazes using recursive backtracker

## Architecture

### Server (`game_server`)
- Maintains authoritative game state
- Validates all player movements
- Broadcasts updates to all connected clients
- Generates the dungeon on startup

### Client (`game_client`)
- Connects to game server via TCP/IP
- Renders player's view with visibility/fog of war
- Sends movement commands to server
- Displays real-time updates from other players

### Protocol
- Built on Async RPC for reliable communication
- Binary protocol for efficient state synchronization
- Automatic reconnection and disconnect handling

## Building and Running

### Build the Project
```bash
dune build @default
```

### Start the Server
```bash
dune exec ./bin/game_server.exe
# Or with custom port:
dune exec ./bin/game_server.exe -- -port 9000
```

### Connect Clients
```bash
# Connect to local server
dune exec ./bin/game_client.exe

# Connect to remote server
dune exec ./bin/game_client.exe -- -host 192.168.1.100

# With custom name and port
dune exec ./bin/game_client.exe -- -host 192.168.1.100 -port 9000 -name "Alice"
```

## Command-Line Options

### Server Options
- `-port PORT` - Server port (default: 8080)

### Client Options
- `-host HOST` - Server hostname or IP address (default: 127.0.0.1)
- `-port PORT` - Server port (default: 8080)
- `-name NAME` - Your player name (default: "Player")

## Development

### Running Tests
```bash
dune build @runtest
```

### Code Formatting
```bash
dune build @fmt --auto-promote
```

### Project Structure
- `src/` - Core game logic and networking
  - `protocol.ml` - Network protocol definitions
  - `game_state.ml` - Game state management and collision detection
  - `server.ml` - Server implementation
  - `client.ml` - Client implementation
  - `display.ml` - Terminal UI with Notty
  - `dungeon_generation.ml` - Room-and-corridor dungeon generator
  - `maze_generation.ml` - Perfect maze generator
  - `visibility.mli` - Field-of-view calculations
- `bin/` - Executable entry points
- `test/` - Test suite

## Dependencies

Built with Jane Street OCaml libraries:
- `core` - Enhanced standard library
- `async` - Asynchronous programming framework
- `async_rpc_kernel` - RPC protocol implementation
- `notty` - Terminal graphics library
- `ppx_jane` - Syntax extensions

## Future Enhancements

Potential features for expansion:
- Combat system and enemies
- Items and inventory
- Persistent player progress
- Multiple dungeon levels
- More terrain types and obstacles
- Chat system for player communication

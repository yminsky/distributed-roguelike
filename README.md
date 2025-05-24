# LAN Rogue

A simple distributed multiplayer rogue-like game for LAN play, built
with OCaml and Jane Street libraries.

## Project Goals

- **Simple multiplayer**: Multiple players can connect and play together on the same LAN
- **Rogue-like client**: Text-based interface with character movement
- **Centralized server**: Game server maintains authoritative game state
- **Real-time updates**: Players see each other's movements in real-time

## Game Design

### World
- Single infinite room/world
- Players spawn near origin (0,0)
- Grid-based movement system

### Gameplay
- Walk around the world using arrow keys or WASD
- See other players represented as characters on the map
- Simple ASCII/text representation

## Architecture

### Server (`game_server`)
- Maintains authoritative world state
- Tracks all player positions
- Broadcasts state updates to clients
- Handles player connections/disconnections

### Client (`game_client`)
- Connects to game server
- Renders local view of the world
- Sends movement commands to server
- Receives and displays updates from server

## Dependencies

Built using Jane Street OCaml libraries:
- `core` - Standard library replacement
- `async` - Asynchronous programming
- `bin_prot` - Binary protocol for networking
- Additional libraries as needed

## Usage

```bash
# Start the server
dune exec ./game_server.exe

# Connect clients (from other machines)
dune exec ./game_client.exe -- --server <server-ip>
```

## Build and Testing

```bash
dune build @default @runtest
```

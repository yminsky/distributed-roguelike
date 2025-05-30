# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when
working with code in this repository.

## Project Overview

LAN Rogue is a distributed multiplayer roguelike game built with
OCaml. It uses a client-server architecture where multiple
terminal-based clients connect to a centralized game server over
TCP/IP.

## Common Development Commands

```bash
# Build the project
dune build @default

# Check if changes to .mli files break the build
dune build @check

# Run tests
dune build @runtest

# Start the game server
dune exec ./bin/game_server.exe

# Start a game client (replace localhost with server IP if remote)
dune exec ./bin/game_client.exe -- -server localhost

# Format code (uses janestreet profile)
dune build @fmt --auto-promote

# Or use the simpler promote command after building
dune build @fmt && dune promote

# Run a specific test file
dune exec test/<test_name>.exe
```

## Development Modes

When working on new features, use one of these two modes:

### Design Mode
When designing new modules or interfaces:
1. Start by writing `.mli` files to define the interface
2. Show the interface to the user for feedback
3. Run only: `dune build @check @fmt && dune promote`
4. Don't implement `.ml` files yet - focus on getting the API right

### Implementation Mode
When implementing already-designed interfaces:
1. Write the `.ml` implementations
2. Write or update tests
3. Run full build: `dune build @default @runtest @fmt && dune promote`
4. Ensure all tests pass before committing

## Development Tips

- **Always format code before committing**: Run `dune build @fmt` followed by
  `dune promote` (or `dune build @fmt --auto-promote`) to ensure consistent
  code formatting using the janestreet profile.

- When making types abstract in `.mli` files, use `dune build @check` to find
  all places where the implementation details are used. This is more reliable
  than text-based searches.
  
- **Design-first approach**: For complex features, start in Design Mode to get
  the interfaces right before diving into implementation. This helps catch
  design issues early and makes the codebase more maintainable.

- **Use `include functor` syntax**: When including Jane Street functors like
  `Comparable.Make`, use the concise `include functor Comparable.Make` syntax
  instead of manually creating a module argument. This feature automatically
  uses the surrounding module's type `t` and derived functions.

## Architecture

The codebase follows a clean separation between networking, game
logic, and display:

- **Protocol Layer** (`protocol.ml`): Defines RPC communication
  between client and server using Async.Rpc
- **Game State** (`game_state.ml`): Core game logic including player
  management, movement, and collision detection
- **Server** (`server.ml`): Manages authoritative game state and
  broadcasts updates to all clients
- **Client** (`client.ml`): Handles user input and RPC communication
  with server
- **Display** (`display.ml`): Terminal rendering using Notty library

Key architectural decisions:

- Server maintains authoritative game state
- Clients receive state updates via `State_rpc` implementation
- Movement is validated server-side to prevent cheating
- Each player has a unique sigil for identification

## Testing

Tests are located in the `test/` directory and use Jane Street's
expect test framework:

- `test_game_state.ml`: Unit tests for game logic
- `test_multiplayer.ml`: Integration tests for client-server
  communication
- `notty_test_utils.ml`: Utilities for testing terminal display output

## Dependencies

The project uses Jane Street libraries extensively:
- `core` and `async` for standard library and async programming
- `async_rpc_kernel` for RPC communication
- `notty` for terminal UI
- Various ppx libraries for preprocessing (ppx_jane includes ppx_let,
  ppx_sexp_conv, etc.)

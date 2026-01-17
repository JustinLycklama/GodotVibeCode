# Vibe Code - Project Overview

## What is Vibe Code?

Vibe Code is a 2D puzzle-platformer hybrid built in Godot 4.2.1. Blocks with different symbols fall from the sky and form platforms that the player can walk and jump on. When three or more blocks with the same symbol align, they are cleared and converted into resources.

## Core Concept

Blocks with different symbols (#, $, %, !) continuously spawn from the top of the screen and fall in a grid-locked manner. When three or more blocks with the same symbol align horizontally or vertically, they are removed from the game and the corresponding resource counter increases. Blocks above cleared matches fall down to fill gaps, potentially creating chain reactions.

The player character can walk on the settled blocks like platformer tiles, jumping between them to navigate the play area.

## Project Structure

```
VibeCode/
├── scenes/
│   ├── main.tscn          # Main game scene with player, ground, spawner, and UI
│   ├── game_block.tscn    # Falling block prefab (StaticBody2D)
│   └── block_spawner.tscn # Block spawning system
├── scripts/
│   ├── game_block.gd      # Block grid-based falling & settlement logic
│   ├── block_spawner.gd   # Spawning controller
│   ├── match_manager.gd   # Match detection & resource tracking (autoload singleton)
│   ├── box_controller.gd  # Player character controller with jump
│   └── resource_ui.gd     # Resource display UI
├── addons/
│   └── godot_mcp/         # Claude Code integration addon
└── documentation/         # Project documentation
```

## Key Technical Details

- **Grid**: 5 columns, 50 pixels spacing (no gaps between blocks)
- **Block Size**: 50x50 pixels
- **Play Area**: 1600 x 650 pixels
- **Block Symbols**: #, $, %, !
- **Spawn Rate**: Every 2 seconds (configurable)
- **Fall Speed**: 200 pixels/second
- **Resources Per Match**: 10 per block cleared

## Autoloads

- **MatchManager**: Singleton that manages block registry, grid state, match detection, and resource tracking

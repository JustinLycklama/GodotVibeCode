# Vibe Code - Project Overview

## What is Vibe Code?

Vibe Code is a 2D Match-3 puzzle game built in Godot 4.2.1. Similar to games like Bejeweled or Candy Crush, players interact with falling blocks that must be matched in lines of three or more to clear them.

## Core Concept

Blocks with different symbols (#, $, %, !) continuously spawn from the top of the screen and fall due to gravity. When three or more blocks with the same symbol align horizontally or vertically, they are detected as a match.

## Project Structure

```
VibeCode/
├── scenes/
│   ├── main.tscn          # Main game scene
│   ├── game_block.tscn    # Falling block prefab
│   └── block_spawner.tscn # Block spawning system
├── scripts/
│   ├── game_block.gd      # Block physics & settlement logic
│   ├── block_spawner.gd   # Spawning controller
│   ├── match_manager.gd   # Match detection (autoload singleton)
│   └── box_controller.gd  # Player character controller
├── addons/
│   └── godot_mcp/         # Claude Code integration addon
└── documentation/         # Project documentation
```

## Key Technical Details

- **Grid**: 5 columns, 60 pixels column spacing
- **Block Size**: 50x50 pixels
- **Play Area**: 1600 x 650 pixels
- **Block Symbols**: #, $, %, !
- **Spawn Rate**: Every 2 seconds (configurable)

## Autoloads

- **MatchManager**: Singleton that manages block registry and match detection

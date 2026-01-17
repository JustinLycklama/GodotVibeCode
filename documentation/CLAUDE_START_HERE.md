# Claude - Start Here

Read this file at the beginning of each session to get oriented.

## Quick Summary

**Vibe Code** is a puzzle-platformer hybrid in Godot 4.2.1. Blocks with symbols (#, $, %, !) fall from the sky and form platforms. When 3+ matching symbols align horizontally or vertically, they're cleared and converted into resources. The player can walk and jump on settled blocks.

## Current State

- Grid-based block system (no physics wobble)
- Blocks are solid platforms (StaticBody2D) - player can stand on them
- Player can move left/right and jump (up arrow)
- Match detection removes blocks and adds resources
- Gravity cascade: blocks fall to fill gaps after matches
- Resource UI displays counts in top-right corner
- **All core mechanics working!**

## Key Files to Know

| File | Purpose |
|------|---------|
| `scripts/match_manager.gd` | Grid state, match detection, resources (autoload) |
| `scripts/game_block.gd` | Individual block falling & settlement |
| `scripts/block_spawner.gd` | Spawns blocks at intervals |
| `scripts/box_controller.gd` | Player movement & jump |
| `scripts/resource_ui.gd` | Resource display UI |
| `scenes/main.tscn` | Main game scene |

## Documentation Files

- `PROJECT_OVERVIEW.md` - What the project is
- `FEATURES.md` - What's implemented and what's planned (with checkboxes)
- `ARCHITECTURE.md` - How the code is structured, data flow, constants

## Controls

- **Left/Right arrows**: Move player
- **Up arrow**: Jump (when on floor)

## Session Notes

Add notes here about recent changes or ongoing work:

- Converted from physics-based to grid-based blocks
- Added player jump ability
- Blocks now collidable (player can walk on them)
- Implemented resource system (replaces score)
- Added cascade/gravity system for falling blocks
- Resource UI showing all 4 resource types

---

*Last updated: January 2026*

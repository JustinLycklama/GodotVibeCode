# Claude - Start Here

Read this file at the beginning of each session to get oriented.

## Quick Summary

**Vibe Code** is a Match-3 puzzle game in Godot 4.2.1. Blocks with symbols fall from the top, and when 3+ matching symbols align horizontally or vertically, they're detected as a match.

## Current State

- Blocks spawn and fall with physics
- Match detection works (matched blocks turn yellow)
- Player character can move left/right
- **Next step**: Implement block elimination after matching

## Key Files to Know

| File | Purpose |
|------|---------|
| `scripts/match_manager.gd` | Core match detection logic (autoload) |
| `scripts/game_block.gd` | Individual block behavior |
| `scripts/block_spawner.gd` | Spawns blocks at intervals |
| `scripts/box_controller.gd` | Player movement |
| `scenes/main.tscn` | Main game scene |

## Documentation Files

- `PROJECT_OVERVIEW.md` - What the project is
- `FEATURES.md` - What's implemented and what's planned
- `ARCHITECTURE.md` - How the code is structured

## Session Notes

Add notes here about recent changes or ongoing work:

---

*Last updated: January 2026*

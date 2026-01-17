# Vibe Code - Architecture

## Scene Hierarchy

### main.tscn
```
Main (Node2D)
├── Player (CharacterBody2D) @ position 250,250
│   ├── ColorRect (blue box, 100x100)
│   └── CollisionShape2D
├── Ground (StaticBody2D) @ position 800,625
│   ├── ColorRect (red platform, 1600x50)
│   └── CollisionShape2D
└── BlockSpawner (Node2D) @ position 900,100
    └── Timer
```

### game_block.tscn
```
GameBlock (RigidBody2D)
├── ColorRect (50x50, green default)
├── Label (displays symbol)
└── CollisionShape2D (50x50)
```

## Script Responsibilities

### match_manager.gd (Autoload)
The central coordinator for match detection:
- Maintains a dictionary of all active blocks keyed by instance ID
- `register_block(block)` - Called when a block enters the scene
- `unregister_block(block)` - Called when a block is removed
- `get_grid_position(world_pos)` - Converts world coords to grid coords
- `check_for_matches()` - Scans all blocks for horizontal and vertical matches
- `_check_horizontal_matches()` / `_check_vertical_matches()` - Internal match logic

### game_block.gd
Individual block behavior:
- Tracks its symbol and color
- Monitors velocity to detect when it has "settled"
- Registers with MatchManager on ready, unregisters on exit
- Calls `MatchManager.check_for_matches()` when it settles

### block_spawner.gd
Continuous block generation:
- References `game_block.tscn` scene
- Uses Timer to spawn at regular intervals
- Randomly selects column and symbol for each new block

### box_controller.gd
Player movement:
- Simple left/right movement with arrow keys
- Applies gravity
- Uses `move_and_slide()` for physics-based movement

## Grid System

The game uses a virtual grid for match detection:
- **Column width**: 60 pixels
- **Row height**: 60 pixels (inferred from block size + spacing)
- **Grid origin**: Based on BlockSpawner position

Grid position is calculated by dividing world position by cell size and rounding.

## Data Flow

```
BlockSpawner
    │
    ▼ (instantiates)
GameBlock ──────────► MatchManager.register_block()
    │
    │ (physics tick)
    ▼
Block settles ──────► MatchManager.check_for_matches()
    │
    ▼
Match found ────────► Block.modulate = yellow
```

## Constants Reference

| Constant | Value | Location |
|----------|-------|----------|
| MOVE_SPEED | 300 | box_controller.gd |
| GRAVITY | 800 | box_controller.gd |
| SPAWN_INTERVAL | 2.0 | block_spawner.gd |
| NUM_COLUMNS | 5 | block_spawner.gd |
| COLUMN_SPACING | 60 | block_spawner.gd |
| SYMBOLS | ["#","$","%","!"] | block_spawner.gd |
| SETTLE_THRESHOLD | 5.0 | game_block.gd |
| SETTLE_TIME | 0.3 | game_block.gd |

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
├── BlockSpawner (Node2D) @ position 900,100
│   └── Timer
└── ResourceUI (CanvasLayer)
    └── Panel (top-right corner)
        └── Label (displays resource counts)
```

### game_block.tscn
```
GameBlock (StaticBody2D)
├── ColorRect (50x50, green default)
├── Label (displays symbol)
└── CollisionShape2D (50x50)
```

## Script Responsibilities

### match_manager.gd (Autoload)
The central coordinator for grid state, match detection, and resources:
- **Grid Management**:
  - `grid: Dictionary` - Maps `Vector2i(col, row)` to block references
  - `is_cell_occupied(col, row)` - Check if a cell has a block
  - `place_block(block, col, row)` - Register block at grid position
  - `get_landing_row(col)` - Find lowest empty row in column
  - `grid_to_world(col, row)` - Convert grid coords to world position
- **Match Detection**:
  - `request_match_check()` - Queue a deferred match check
  - `_do_match_check()` - Find and process all matches
  - `_find_horizontal_matches()` / `_find_vertical_matches()` - Internal match logic
- **Block Removal & Gravity**:
  - `_remove_block(block)` - Remove from grid and destroy
  - `_apply_gravity(columns)` - Make floating blocks fall
- **Resource Tracking**:
  - `resources: Dictionary` - Maps symbol to count (e.g., `{"#": 0, "$": 0, ...}`)
  - `add_resource(symbol, amount)` - Add to resource counter
  - `get_resources()` - Get current resource dictionary
  - `resources_changed` signal - Emitted when resources update

### game_block.gd
Individual block behavior:
- Tracks `symbol`, `block_color`, `grid_col`, `grid_row`
- Falls at fixed speed (200 px/sec) until reaching landing position
- Snaps to grid position when landing
- Registers with MatchManager on ready, unregisters on exit
- `start_falling()` - Called to make block fall again after gravity applied
- `is_settled()` - Check if block has landed

### block_spawner.gd
Continuous block generation:
- References `game_block.tscn` scene
- Uses Timer to spawn at regular intervals
- Randomly selects column and symbol for each new block
- Sets `grid_col` on spawned blocks

### box_controller.gd
Player movement:
- Left/right movement with arrow keys
- Jump with up arrow (only when on floor)
- Applies gravity
- Uses `move_and_slide()` for physics-based movement

### resource_ui.gd
Resource display:
- Connects to `MatchManager.resources_changed` signal
- Updates label text when resources change
- Displays all resource types and their counts

## Grid System

The game uses a grid-locked system for blocks:
- **Column spacing**: 50 pixels (same as block size, no gaps)
- **Block size**: 50x50 pixels
- **Grid origin**: `FIRST_COLUMN_X = 800`, `GROUND_TOP_Y = 600`
- **Row 0**: Bottom row, just above ground
- **Rows increase upward**: Row 1 is above row 0, etc.

Grid position formula:
- World X = `FIRST_COLUMN_X + col * COLUMN_SPACING`
- World Y = `GROUND_TOP_Y - (row * BLOCK_SIZE) - (BLOCK_SIZE / 2.0)`

## Data Flow

```
BlockSpawner
    │
    ▼ (instantiates with grid_col)
GameBlock ──────────► MatchManager.register_block()
    │
    │ (_process: fall until landing)
    ▼
Block settles ──────► MatchManager.place_block()
    │                 MatchManager.request_match_check()
    ▼
Match found ────────► _remove_block() for each matched block
    │                 add_resource() for each symbol
    │                 resources_changed signal emitted
    ▼
_apply_gravity() ───► Floating blocks call start_falling()
    │
    ▼
ResourceUI ─────────► _on_resources_changed() updates display
```

## Constants Reference

| Constant | Value | Location |
|----------|-------|----------|
| COLUMN_COUNT | 5 | match_manager.gd |
| COLUMN_SPACING | 50.0 | match_manager.gd, block_spawner.gd |
| BLOCK_SIZE | 50.0 | match_manager.gd |
| CENTER_X | 900.0 | match_manager.gd |
| GROUND_TOP_Y | 600.0 | match_manager.gd |
| FIRST_COLUMN_X | 800.0 | match_manager.gd |
| FALL_SPEED | 200.0 | game_block.gd |
| RESOURCES_PER_MATCH | 10 | match_manager.gd |
| speed | 300.0 | box_controller.gd |
| gravity | 800.0 | box_controller.gd |
| jump_velocity | -400.0 | box_controller.gd |
| spawn_interval | 2.0 | block_spawner.gd |
| SYMBOLS | ["#","$","%","!"] | block_spawner.gd |

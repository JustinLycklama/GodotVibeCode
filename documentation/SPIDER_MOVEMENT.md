# Spider-Style Surface Traversal - Technical Specification

## Overview

The player uses spider-like movement, following surface contours smoothly rather than traditional platformer physics. The player is always attached to a surface and moves along it - like an ant walking on blocks, going up walls, across tops, and down the other side without pausing.

**Location:** `scripts/box_controller.gd`

## Core Concept

```
Right arrow held continuously:

    ┌───┐         3. continue right on top
    │   │ ←─────────────────────
    │   │         2. climb up wall
    └───┘            │
  ─────────────      │  1. walk right on floor
              ←──────┘
```

## Surface States

```gdscript
enum Surface { FLOOR, WALL_LEFT, WALL_RIGHT, FALLING }
```

| State | Description | Surface Normal |
|-------|-------------|----------------|
| FLOOR | Standing on horizontal surface | Points UP |
| WALL_RIGHT | Clinging to wall on player's right | Points LEFT |
| WALL_LEFT | Clinging to wall on player's left | Points RIGHT |
| FALLING | No surface contact | N/A |

**Key Insight:** `WALL_RIGHT` means "the wall is on your right" (you hit it while moving right), NOT "you're on the right side of a wall".

## Movement Mapping

| Surface | Right Arrow | Left Arrow |
|---------|-------------|------------|
| FLOOR | Move right (+X) | Move left (-X) |
| WALL_RIGHT | Climb UP (-Y) | Climb DOWN (+Y) |
| WALL_LEFT | Climb DOWN (+Y) | Climb UP (-Y) |
| FALLING | No control | No control |

**Movement Functions:**
```gdscript
func _move_on_floor() -> void:
    velocity = Vector2(move_direction * speed, 0)

func _move_on_wall_right() -> void:
    # Right = climb up, Left = climb down
    velocity = Vector2(0, -move_direction * speed)

func _move_on_wall_left() -> void:
    # Left = climb up, Right = climb down
    velocity = Vector2(0, move_direction * speed)

func _fall() -> void:
    velocity = Vector2(0, fall_speed)
```

## State Transitions

### FLOOR Transitions

**To WALL_RIGHT:** Hit wall while pressing RIGHT
```gdscript
if is_on_wall() and move_direction > 0:
    var collision := get_last_slide_collision()
    if collision and collision.get_normal().x < -0.5:  # Wall on right
        current_surface = Surface.WALL_RIGHT
```

**To WALL_LEFT:** Hit wall while pressing LEFT
```gdscript
if is_on_wall() and move_direction < 0:
    var collision := get_last_slide_collision()
    if collision and collision.get_normal().x > 0.5:  # Wall on left
        current_surface = Surface.WALL_LEFT
```

**Important:** Only transition to wall if actively pressing toward the wall. This prevents glitchy re-transitions when stepping onto blocks.

**Corner Wrap (floor disappears):**
```gdscript
if not is_on_floor() and move_direction != 0:
    if move_direction > 0 and _is_wall_at_direction(1):
        current_surface = Surface.WALL_RIGHT  # Wrap around, climb down
    elif move_direction < 0 and _is_wall_at_direction(-1):
        current_surface = Surface.WALL_LEFT
    else:
        current_surface = Surface.FALLING
```

### WALL_RIGHT Transitions (wall on right, block to player's right)

**To FLOOR (reached top):** When `is_on_wall()` becomes false while climbing UP
```gdscript
if move_direction > 0:  # Pressing right = climbing up
    if not is_on_wall():
        # Find block to our RIGHT, below current position
        var block_x := global_position.x + PLAYER_HALF + BLOCK_HALF
        var block_y := global_position.y + PLAYER_HALF + BLOCK_HALF
        var grid_pos := MatchManager.world_to_grid(Vector2(block_x, block_y))

        if MatchManager.is_cell_occupied(grid_pos.x, grid_pos.y):
            # Step onto block - minimal position adjustment
            var block_world := MatchManager.grid_to_world(grid_pos.x, grid_pos.y)
            global_position.x += 4  # Small nudge onto block
            global_position.y = block_world.y - BLOCK_HALF - PLAYER_HALF + 1
            current_surface = Surface.FLOOR
```

**To FLOOR (reached bottom):** When `is_on_floor()` while climbing DOWN
```gdscript
if move_direction < 0:  # Pressing left = climbing down
    if is_on_floor():
        current_surface = Surface.FLOOR
```

### WALL_LEFT Transitions (wall on left, block to player's left)

**To FLOOR (reached top):** When `is_on_wall()` becomes false while climbing UP
```gdscript
if move_direction < 0:  # Pressing left = climbing up
    if not is_on_wall():
        # Find block to our LEFT, below current position
        var block_x := global_position.x - PLAYER_HALF - BLOCK_HALF
        var block_y := global_position.y + PLAYER_HALF + BLOCK_HALF
        var grid_pos := MatchManager.world_to_grid(Vector2(block_x, block_y))

        if MatchManager.is_cell_occupied(grid_pos.x, grid_pos.y):
            # Step onto block - minimal position adjustment
            var block_world := MatchManager.grid_to_world(grid_pos.x, grid_pos.y)
            global_position.x -= 4  # Small nudge onto block
            global_position.y = block_world.y - BLOCK_HALF - PLAYER_HALF + 1
            current_surface = Surface.FLOOR
```

### FALLING Transitions

**To FLOOR:** When `is_on_floor()` becomes true
**To WALL_RIGHT/LEFT:** When `is_on_wall()` with appropriate collision normal

## Critical Implementation Details

### Block Detection for Wall-to-Floor Transition

When climbing up a wall and reaching the top, we must find the block we were climbing:

1. **X Position:** Look in the direction of the wall
   - WALL_RIGHT: `global_position.x + PLAYER_HALF + BLOCK_HALF` (look RIGHT)
   - WALL_LEFT: `global_position.x - PLAYER_HALF - BLOCK_HALF` (look LEFT)

2. **Y Position:** Look BELOW current position (we've climbed past the block)
   - `global_position.y + PLAYER_HALF + BLOCK_HALF`
   - This ensures we find row 0 when at top of first block, not row 1

3. **Position Adjustment:** Keep movement natural
   - Only adjust X by a small amount (±4 pixels)
   - Snap Y to stand on top of block

### Preventing Transition Glitches

**Problem:** After stepping onto a block, `is_on_wall()` or `is_on_floor()` can return incorrect values for one frame, causing immediate re-transition back to wall state.

**Solution:** Only allow wall transitions when actively pressing toward the wall:
```gdscript
# WRONG - transitions even when not pressing toward wall
if is_on_wall():
    current_surface = Surface.WALL_RIGHT

# CORRECT - only transition if pressing toward wall
if is_on_wall() and move_direction > 0:
    if collision.get_normal().x < -0.5:  # Confirm wall is on right
        current_surface = Surface.WALL_RIGHT
```

### Visual Rotation

```gdscript
func _update_rotation() -> void:
    match current_surface:
        Surface.FLOOR, Surface.FALLING:
            rotation_degrees = 0
        Surface.WALL_RIGHT:
            rotation_degrees = -90
        Surface.WALL_LEFT:
            rotation_degrees = 90
```

## Constants

```gdscript
const PLAYER_HALF := 23.0   # Half player size
const BLOCK_HALF := 25.0    # Half block size (from MatchManager.BLOCK_SIZE / 2)
@export var speed: float = 300.0
@export var fall_speed: float = 400.0
```

## Grid Helper Functions Used

- `MatchManager.world_to_grid(Vector2) -> Vector2i` - Convert world position to grid coordinates
- `MatchManager.grid_to_world(col, row) -> Vector2` - Convert grid coordinates to world position (block center)
- `MatchManager.is_cell_occupied(col, row) -> bool` - Check if block exists at grid position

## Debugging Tips

To visualize where grid checks are happening:
```gdscript
func _spawn_debug_marker(pos: Vector2, color: Color) -> void:
    var marker := ColorRect.new()
    marker.size = Vector2(10, 10)
    marker.color = color
    marker.position = pos - Vector2(5, 5)
    get_tree().current_scene.add_child(marker)
    get_tree().create_timer(2.0).timeout.connect(marker.queue_free)
```

## Transition Diagram

```
                    ┌─────────────┐
         hit wall   │             │  reached top
        ┌──────────→│  WALL_RIGHT │──────────────┐
        │ (right)   │             │              │
        │           └─────────────┘              │
        │                 ↑                      ↓
   ┌────┴────┐      wall  │              ┌──────────┐
   │         │  disappears│              │          │
   │  FLOOR  │←───────────┴──────────────│  FLOOR   │
   │         │        reached bottom     │ (on top) │
   └────┬────┘                           └──────────┘
        │           ┌─────────────┐
        │ hit wall  │             │  reached top
        └──────────→│  WALL_LEFT  │──────────────┘
          (left)    │             │
                    └─────────────┘
```

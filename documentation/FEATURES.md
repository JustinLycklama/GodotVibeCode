# Vibe Code - Features

## Implemented Features

### Block Spawning System
- Blocks spawn continuously from the top of the screen
- Random column selection across 5 columns
- Random symbol assignment from pool (#, $, %, !)
- Configurable spawn interval (default: 2 seconds)
- Location: `scripts/block_spawner.gd`

### Physics-Based Blocks
- Blocks are RigidBody2D with gravity
- Settlement detection: blocks are considered "settled" after velocity drops below 5 px/s for 0.3 seconds
- Blocks register/unregister with MatchManager automatically
- Location: `scripts/game_block.gd`

### Match Detection System
- Central MatchManager singleton tracks all active blocks
- Converts world positions to grid coordinates
- Detects horizontal matches (3+ consecutive same symbols in a row)
- Detects vertical matches (3+ consecutive same symbols in a column)
- Deferred checking for performance (batches settlement events)
- Matched blocks turn yellow as visual feedback
- Location: `scripts/match_manager.gd`

### Player Controller
- Movable blue box character
- Left/Right arrow key movement (300 pixels/second)
- Gravity applied (800 pixels/second²)
- Location: `scripts/box_controller.gd`

### Game Environment
- Ground platform at bottom of screen
- Play area boundaries established

---

## Not Yet Implemented

### Core Gameplay
- [ ] Block elimination/removal after matching
- [ ] Cascade system (blocks fall to fill gaps after elimination)
- [ ] Combo detection (chain reactions)

### Scoring
- [ ] Point system
- [ ] Score display UI
- [ ] High score tracking

### Game Flow
- [ ] Game over conditions
- [ ] Level progression
- [ ] Difficulty scaling (faster spawn rates, etc.)

### Player Interaction
- [ ] Player interaction with blocks (pushing, catching)
- [ ] Special abilities or power-ups

### Polish
- [ ] Sound effects
- [ ] Music
- [ ] Animations (block pop, particle effects)
- [ ] Visual themes/skins

### UI
- [ ] Main menu
- [ ] Pause menu
- [ ] Score display
- [ ] Game over screen

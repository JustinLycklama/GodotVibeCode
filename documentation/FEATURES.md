# Vibe Code - Features

## Implemented Features

### Block Spawning System
- [x] Blocks spawn continuously from the top of the screen
- [x] Random column selection across 5 columns
- [x] Random symbol assignment from pool (#, $, %, !)
- [x] Configurable spawn interval (default: 2 seconds)
- Location: `scripts/block_spawner.gd`

### Grid-Based Block System
- [x] Blocks fall at a fixed speed (200 px/sec) - no physics wobble
- [x] Blocks snap to discrete grid positions when landing
- [x] Grid tracks block positions for collision detection
- [x] Blocks are StaticBody2D with collision shapes - player can stand on them
- [x] No gaps between blocks (50px spacing = block size)
- Location: `scripts/game_block.gd`, `scripts/match_manager.gd`

### Match Detection System
- [x] Central MatchManager singleton tracks all active blocks
- [x] Maintains grid dictionary mapping positions to blocks
- [x] Detects horizontal matches (3+ consecutive same symbols in a row)
- [x] Detects vertical matches (3+ consecutive same symbols in a column)
- [x] Deferred checking for performance (batches settlement events)
- Location: `scripts/match_manager.gd`

### Block Elimination & Cascade
- [x] Matched blocks are removed from the game (queue_free)
- [x] Blocks above cleared matches fall down to fill gaps
- [x] Chain reactions supported (falling blocks can create new matches)
- Location: `scripts/match_manager.gd`, `scripts/game_block.gd`

### Resource System
- [x] Four resource types corresponding to symbols: #, $, %, !
- [x] Each cleared block adds 10 to its resource counter
- [x] Resources tracked in MatchManager singleton
- [x] Signal emitted when resources change
- Location: `scripts/match_manager.gd`

### Resource UI
- [x] Panel in top-right corner displays all resource counts
- [x] Updates in real-time when resources change
- [x] Shows format: "symbol: count" for each resource type
- Location: `scripts/resource_ui.gd`, `scenes/main.tscn`

### Player Controller
- [x] Movable blue box character
- [x] Left/Right arrow key movement (300 pixels/second)
- [x] Jump with Up arrow key (velocity: -400)
- [x] Gravity applied (800 pixels/second²)
- [x] Can walk and jump on settled blocks (platformer-style)
- Location: `scripts/box_controller.gd`

### Game Environment
- [x] Ground platform at bottom of screen
- [x] Play area boundaries established
- [x] Blocks form solid platforms player can traverse

---

## Not Yet Implemented

### Core Gameplay
- [ ] Combo detection (bonus for chain reactions)
- [ ] Special block types (bombs, wildcards, etc.)

### Resource Usage
- [ ] Spending resources on abilities/upgrades
- [ ] Resource goals/objectives

### Game Flow
- [ ] Game over conditions (blocks reach top?)
- [ ] Level progression
- [ ] Difficulty scaling (faster spawn rates, etc.)
- [ ] Win conditions

### Player Interaction
- [ ] Player interaction with blocks (pushing, catching)
- [ ] Special abilities or power-ups
- [ ] Resource-powered abilities

### Polish
- [ ] Sound effects
- [ ] Music
- [ ] Animations (block pop, particle effects)
- [ ] Visual themes/skins

### UI
- [ ] Main menu
- [ ] Pause menu
- [ ] Game over screen
- [ ] Tutorial/instructions

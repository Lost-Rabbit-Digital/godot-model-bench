You are an expert Godot 4.7 GDScript programmer. Implement a 2D NPC character with a finite-state machine (FSM) that patrols between waypoints, detects the player, and chases/attacks.

CONTEXT / HARD CONSTRAINTS
- One script, loaded by path with load() at runtime by the harness.
  Do NOT rely on class_name globals (a class_name line is optional and harmless,
  but never reference another script's class by name, never preload it).
- Strongly typed GDScript: every variable, parameter, and function return type annotated.
- No autoloads, no @export, no RNG.
- Extends CharacterBody2D (2D movement).
- The harness instantiates your NPC, adds it to the SceneTree root, and drives
  it by setting a target (player) position via set_target(Vector2) and calling tick_physics(delta).

=====================================================================
FILE: npc_controller.gd — the NPC with FSM
=====================================================================

class_name NPCController          # optional
extends CharacterBody2D

# --- State enum ---
# Idle: standing still, scanning for player
# Patrol: moving between patrol points
# Chase: running toward the player
# Attack: in melee range, playing attack
enum State { IDLE, PATROL, CHASE, ATTACK }

# --- Constants you must use ---
const SPEED_WALK: float = 60.0        # patrol speed
const SPEED_CHASE: float = 140.0      # chase speed
const DETECTION_RANGE: float = 120.0  # distance at which player is spotted
const ATTACK_RANGE: float = 28.0      # distance at which NPC attacks
const ATTACK_COOLDOWN: float = 1.0    # seconds between attacks
const PATROL_POINTS: PackedVector2Array = [
    Vector2(100.0, 0.0),
    Vector2(300.0, 0.0),
    Vector2(300.0, 200.0),
    Vector2(100.0, 200.0),
]

# --- Public API (must match EXACTLY) ---
# var state: State              # current FSM state (readable)
# var target_position: Vector2   # the player position set by set_target()
# var current_patrol: int = 0    # index into PATROL_POINTS

func set_target(pos: Vector2) -> void:
    # Set target_position = pos. This triggers detection logic on next tick.

func tick_physics(delta: float) -> void:
    # MAIN FSM STEP. Called by the harness each physics frame.
    # 1. Compute distance to target_position.
    # 2. State transitions:
    #    - If target within DETECTION_RANGE: switch to CHASE (if not already).
    #    - If target within ATTACK_RANGE while chasing: switch to ATTACK.
    #    - If target moves out of DETECTION_RANGE while chasing/attacking:
    #      switch to PATROL (return to nearest patrol point).
    #    - If idle and no target seen: patrol to next waypoint (switch to PATROL).
    # 3. Per-state behavior:
    #    - IDLE: do nothing (velocity = zero).
    #    - PATROL: move toward PATROL_POINTS[current_patrol] at SPEED_WALK.
    #      When within 8.0 pixels, advance current_patrol to next (wrap around).
    #    - CHASE: move toward target_position at SPEED_CHASE.
    #    - ATTACK: stop moving (velocity = zero), fire attack. Use an internal
    #      cooldown timer: only attack if enough time passed since last attack.
    #      Emit `attacked` signal on each successful attack.
    # 4. Call move_and_slide() at the end.

signal attacked(target_pos: Vector2)

# --- Helper methods the harness may call ---
func get_state() -> State:
    # Return the current state enum value.

func get_npc_position() -> Vector2:
    # Return global_position.

=====================================================================
func get_patrol_index() -> int:
    # Return current_patrol.

=====================================================================
OUTPUT FORMAT (strict)
=====================================================================
Output npc_controller.gd's complete source in one fenced code block tagged gdscript.
No prose before or after the fence.

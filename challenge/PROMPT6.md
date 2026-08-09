You are an expert Godot 4.7 GDScript programmer. Implement a 2D character with procedural (code-driven) animation — idle breathing, walk bob, and a melee lunge — with NO AnimationPlayer and NO .tscn files.

CONTEXT / HARD CONSTRAINTS
- One script, loaded by path with load() at runtime by the harness.
  Do NOT rely on class_name globals.
- Strongly typed GDScript: every variable, parameter, and function return type annotated.
- No autoloads, no @export, no RNG.
- Extends Node2D.
- The harness instantiates your character, adds it to the SceneTree root, and drives it
  by calling tick_animation(delta) and set_moving(bool) / trigger_attack().
- The character draws itself in _draw() using canvas primitives (draw_rect, draw_circle, etc.).
  You are a flat 2D sprite — a colored capsule/rectangle body + two eyes.

=====================================================================
FILE: char_animator.gd — procedural character animation
=====================================================================

class_name CharAnimator          # optional
extends Node2D

# --- Constants you must use ---
const BODY_COLOR: Color = Color(0.2, 0.6, 1.0)
const EYE_COLOR: Color = Color(0.05, 0.05, 0.05)
const BODY_W: float = 20.0
const BODY_H: float = 36.0
const EYE_RADIUS: float = 3.0

# Animation parameters
const BREATH_SCALE: float = 1.05      # body scale at breath peak (idle)
const BREATH_SPEED: float = 2.5      # seconds per full breath cycle
const WALK_BOBBLE: float = 4.0       # vertical px offset at walk peak
const WALK_SPEED: float = 6.0        # breaths/walks per second
const LUNGE_DIST: float = 18.0       # horizontal lunge distance
const LUNGE_SPEED: float = 12.0      # tweens per second

# --- Public API (must match EXACTLY) ---

func set_moving(moving: bool) -> void:
    # Set whether the character is walking. Updates internal _moving flag.

func trigger_attack() -> void:
    # Trigger a melee lunge: the body shifts right by LUNGE_DIST over
    # (1.0 / LUNGE_SPEED) seconds, then snaps back. If already lunging,
    # do nothing. Emits `attacked` signal when the lunge fires.

signal attacked()

func tick_animation(delta: float) -> void:
    # Called every frame by the harness. Updates internal animation timers
    # and calls update() / queue_redraw() so _draw() reflects the current pose.
    # - Advance _anim_time by delta.
    # - If not attacking: compute breath/walk offsets from _anim_time.
    # - If attacking: drive the lunge tween progress from a timer.

func get_body_scale() -> Vector2:
    # Return the current body scale (including breath swell + lunge squash/stretch).

func get_body_offset() -> Vector2:
    # Return the current body offset (walk bobble + lunge shift).

func get_eye_offset() -> float:
    # Return the horizontal gaze direction of the eyes based on movement/lunge.
    # Returns a value in [-1, 1] — look direction. During lunge, eyes look ahead (+1).

=====================================================================
OUTPUT FORMAT (strict)
=====================================================================
Output char_animator.gd's complete source in one fenced code block tagged gdscript.
No prose before or after the fence.

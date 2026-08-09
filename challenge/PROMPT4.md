You are an expert Godot 4.7 GDScript programmer. Implement a small, self-contained 2D HUD / juice UI panel for a health-bar + score-counter + juicy button, built entirely in code (no .tscn files).

CONSTRAINTS
- Two scripts, both loaded by path with load() at runtime by the harness.
  Do NOT rely on class_name globals (a class_name line is optional and harmless,
  but never reference another script's class by name).
- Strongly typed GDScript: every variable, parameter, and function return type annotated.
- No autoloads, no @export, no RNG.
- You must produce EXACTLY TWO files, in this order.

=====================================================================
FILE 1: juice_hud.gd — the HUD container (Control-based)
=====================================================================

class_name JuiceHUD          # optional
extends Control

# --- Children you build in _ready ---
#   var _health_bar := null     # a TextureProgressBar OR a custom ProgressBar
#   var _ghost := null          # a ProgressBar (or ColorRect) that drains behind _health_bar
#   var _score_label := null    # a Label
#   var _button := null         # a Button with hover/press juice

# --- Public API (method names, signatures, and semantics must match EXACTLY) ---

func set_health(value: float) -> void:
    # Clamp to [0.0, 100.0], set _health_bar.value, and animate _ghost to the
    # same value with a 0.4s delay (the "paper-ghost" drain effect). The ghost
    # must lag behind the live bar then catch down slowly.

func add_score(amount: int) -> void:
    # Increase internal score by `amount`, then animate the score label's text
    # from its current displayed number to the new total. Use create_tween()
    # with tween_method on a numeric counter.

func pulse() -> void:
    # Juicy pulse: scale the whole HUD to 1.15x, stay 0.15s, snap back to 1.0x
    # with a short overshoot (0.1s back). Use create_tween() with a tiny
    # overshoot ease-out.

func get_health() -> float:
    # Return the current live health value (0..100).

func get_score() -> int:
    # Return the current integer score.

func _ready() -> void:
    # Build the children IN THIS ORDER and exactly like this:
    #   1. _health_bar := ProgressBar.new()
    #      _health_bar.name = "HealthBar"
    #      _health_bar.min_value = 0.0; _health_bar.max_value = 100.0
    #      _health_bar_anchor_right = 1.0;  _health_bar.anchor_bottom = 0.0
    #      _health_bar.position = Vector2(8.0, 8.0)
    #      _health_bar.size = Vector2(180.0, 18.0)
    #      add_child(_health_bar)
    #
    #   2. _ghost := ProgressBar.new()  (the drain overlay)
    #      _ghost.name = "GhostBar"
    #      _ghost.anchors and size MUST match _health_bar exactly
    #      _ghost.modulate = Color(1, 1, 1, 0.25)   # faint white overlay
    #      _ghost.value = _health_bar.value
    #      add_child(_ghost)
    #      (ghost must be added AFTER health_bar so it overlaps it)
    #
    #   3. _score_label := Label.new()
    #      _score_label.name = "ScoreLabel"
    #      _score_label.position = Vector2(8.0, 36.0)
    #      _score_label.text = "Score: 0"
    #      add_child(_score_label)
    #
    #   4. _button := Button.new()
    #      _button.name = "JuiceButton"
    #      _button.text = "Press Me"
    #      _button.position = Vector2(8.0, 64.0)
    #      _button.size = Vector2(100.0, 30.0)
    #      add_child(_button)
    #      # Hover juice: scale to 1.1x on mouse_enter, back to 1.0x on mouse_exit
    #      _button.mouse_default_cursor_shape = CursorShape.POINTING_HAND
    #      _button.connect("mouse_entered", Callable(self, "_on_button_entered"))
    #      _button.connect("mouse_exited",  Callable(self, "_on_button_exited"))
    #
    # The HUD root Control should have a transparent or visible background
    # (set custom_minimum_size or just let it be 0 — the runner adds it to
    # a transparent viewport).

func _on_button_entered() -> void:
    # Scale tween: 1.0 -> 1.1 in 0.1s, ease out
    # Use create_tween().tween_property(_button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_button_exited() -> void:
    # Scale tween: 1.1 -> 1.0 in 0.1s, ease out

=====================================================================
FILE 2: hud_sparkle.gd — a tiny VFX helper
=====================================================================

class_name HudSparkle          # optional
extends Node2D

# A simple sparkle that fades out and shrinks over 0.5s.
# The runner spawns these at _button global positions to test
# 2D particle-like code.

const LIFETIME: float = 0.5

func _init(color: Color = Color(1, 1, 1, 1)) -> void:
    # Create a small white square (1x1 ColorRect-sized quad via _draw)
    # or a tiny circle. Just draw something visible.

func _draw() -> void:
    # Draw a filled circle of radius 3.0 in `color`

func _process(delta: float) -> void:
    # Age: _t += delta; queue_redraw() each frame
    # When _t >= LIFETIME: queue_free()

func set_color(c: Color) -> void:
    # Store and re-draw

=====================================================================
OUTPUT FORMAT (strict)
=====================================================================
Output juice_hud.gd's complete source in one fenced code block tagged gdscript,
then hud_sparkle.gd's complete source in a second fenced code block.
No prose before, between, or after the fences.

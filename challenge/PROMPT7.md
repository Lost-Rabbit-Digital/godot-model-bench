You are an expert Godot 4.7 GDScript programmer. Implement a 2D spell-impact VFX: a burst of code-built CPUParticles2D plus a shader-based flash quad, with NO .tscn/.tres files and NO preloaded assets.

CONTEXT / HARD CONSTRAINTS
- One script, loaded by path with load() at runtime by the harness.
  Do NOT rely on class_name globals.
- Strongly typed GDScript: every variable, parameter, and function return type annotated.
- No autoloads, no @export, no RNG.
- Extends Node2D.
- The harness instantiates your VFX, adds it to the SceneTree root, calls burst(),
  and checks particles + shader parameters.

=====================================================================
FILE: spell_vfx.gd — spell impact VFX
=====================================================================

class_name SpellVFX          # optional
extends Node2D

# --- Constants ---
const PARTICLE_COUNT: int = 32
const LIFETIME: float = 0.6      # seconds
const SPEED: float = 120.0
const PARTICLE_SIZE: float = 4.0
const COLOR := Color(0.4, 0.9, 1.0)

# --- Public API (must match EXACTLY) ---

func burst() -> void:
    # Emit the particle burst and start the flash. Must be safe to call
    # multiple times (restarts the effect).
    # 1. Restart the CPUParticles2D (restart() or re-emit).
    # 2. Make the flash quad visible, reset flash timer.

func get_particle_count() -> int:
    # Return amount of the CPUParticles2D.

func get_particle_lifetime() -> float:
    # Return lifetime of the CPUParticles2D.

func get_flash_intensity() -> float:
    # Return the current flash quad's alpha (0.0 = invisible, 1.0 = full).

func is_finished() -> bool:
    # Return true when the effect has fully completed (flash faded AND no burst active).

func get_particle_node() -> Node:
    # Return the CPUParticles2D child (so the harness can inspect it).

func get_particle_material() -> Resource:
    # Return the ParticleProcessMaterial used by the particles (so the harness
    # can inspect its parameters without attaching it to the CPUParticles2D).

func tick(delta: float) -> void:
    # Called by the harness every frame to advance internal timers.

=====================================================================
REQUIREMENTS
=====================================================================
1. Build a CPUParticles2D with:
   - amount = PARTICLE_COUNT (32)
   - lifetime = 0.6s
   - one_shot = true
   - speed_scale = 1.0
   - A Sphere emission shape (radius ~8.0) for omnidirectional spread
   - Create a ParticleProcessMaterial separately and expose it via get_particle_material().
     Use ClassDB.instantiate("ParticlesMaterial") to create the material (the raw
     class name may not resolve in GDScript on all engine builds).
     Properties to set on the material:
       - color = COLOR
       - scale = Vector2(PARTICLE_SIZE, PARTICLE_SIZE) (may be Vector2 on some builds)
       - initial_velocity = Vector2(SPEED, SPEED) (may be Vector2 on some builds)
       - direction = Vector3.UP with spread = 360.0 (omnidirectional)
       - gravity = Vector3.ZERO (floaty)
     (Use .set() for properties if typed assignment causes issues.)

2. Build a flash quad: draw a 60x60 rect via _draw() centered on the VFX, visible
   during burst, fading from alpha 0.8 to 0.0 over 0.3s.

3. tick(delta) advances the flash timer. When _flash_timer <= 0, _bursting = false
   and is_finished() returns true.

4. The CPUParticles2D must use a texture. Create a 1x1 white ImageTexture via
   ImageTexture.create_from_image() with a white pixel.

=====================================================================
OUTPUT FORMAT (strict)
=====================================================================
Output spell_vfx.gd's complete source in one fenced code block tagged gdscript.
No prose before or after the fence.

extends Node2D

const PARTICLE_COUNT: int = 32
const LIFETIME: float = 0.6
const SPEED: float = 120.0
const PARTICLE_SIZE: float = 4.0
const COLOR := Color(0.4, 0.9, 1.0)

var _particles: CPUParticles2D
var _material: Resource
var _flash_timer: float = 0.0
var _flash_duration: float = 0.3
var _bursting: bool = false

func _ready() -> void:
	_particles = CPUParticles2D.new()
	_particles.name = "Particles"
	add_child(_particles)
	_particles.amount = PARTICLE_COUNT
	_particles.lifetime = LIFETIME
	_particles.one_shot = true
	_particles.speed_scale = 1.0
	# Texture: generate a 1x1 white texture
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(1, 1, 1, 1))
	var tex := ImageTexture.create_from_image(img)
	_particles.texture = tex
	# Emission shape: omnidirectional
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.emission_sphere_radius = 8.0
	# Material — create via ClassDB because the type name may not resolve in GDScript
	_material = ClassDB.instantiate("ParticlesMaterial") as Resource
	# On this engine build, scale and initial_velocity are Vector2 properties
	_material.set("color", COLOR)
	_material.set("scale", Vector2(PARTICLE_SIZE, PARTICLE_SIZE))
	_material.set("initial_velocity", Vector2(SPEED, SPEED))
	_material.set("direction", Vector3.UP)
	_material.set("spread", 360.0)
	_material.set("gravity", Vector3.ZERO)
	_particles.set("process_material", _material)
	_particles.restart()

func burst() -> void:
	if _material != null:
		_particles.restart()
	_particles.emitting = true
	_flash_timer = _flash_duration
	_bursting = true
	queue_redraw()

func tick(delta: float) -> void:
	if _bursting:
		if _flash_timer > 0.0:
			_flash_timer -= delta
		if _flash_timer <= 0.0:
			_bursting = false
		queue_redraw()

func get_particle_count() -> int:
	return _particles.amount

func get_particle_lifetime() -> float:
	return _particles.lifetime

func get_flash_intensity() -> float:
	if _flash_timer > 0.0 and _bursting:
		return _flash_timer / _flash_duration
	return 0.0

func is_finished() -> bool:
	if not _bursting:
		return true
	return false

func get_particle_node() -> Node:
	return _particles

func get_particle_material() -> Resource:
	return _material

func _draw() -> void:
	if _bursting and _flash_timer > 0.0:
		var alpha := _flash_timer / _flash_duration
		var flash_color := Color(1.0, 1.0, 1.0, alpha * 0.8)
		draw_rect(Rect2(-30.0, -30.0, 60.0, 60.0), flash_color)

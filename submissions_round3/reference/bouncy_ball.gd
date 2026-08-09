extends RigidBody2D

const RADIUS: float = 4.0

var ball_id: int = -1

func _init() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.9
	physics_material_override = mat
	gravity_scale = 1.0

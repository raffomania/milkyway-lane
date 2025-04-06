extends Sprite2D

@export
var target: Planet
var max_velocity = 150.0
var min_speed = 5.0
var velocity := 0.0
var max_acceleration := 50.0

func _process(delta: float) -> void:
	if !is_instance_valid(target):
		return

	var target_position = target.global_position + (Vector2.RIGHT * target.radius * 1.1)
	var to_target = target_position - global_position
	var distance_to_target = to_target.length()

	var target_rotation = to_target.angle() + PI / 2
	var rotation_strength = abs(angle_difference(target_rotation, global_rotation)) * delta * 2

	var braking_distance = (velocity ** 2) / (2 * max_acceleration)
	var should_accelerate = 1 if distance_to_target > braking_distance else -1
	var acceleration_strength = should_accelerate / rotation_strength
	var acceleration = clamp(max_acceleration * acceleration_strength, -max_acceleration, max_acceleration)

	velocity += acceleration * delta
	
	velocity = clamp(velocity, min_speed, max_velocity)

	rotation = rotate_toward(global_rotation, target_rotation, rotation_strength)
	position += velocity * Vector2.UP.rotated(rotation) * delta

	if distance_to_target < 30:
		target = target.target

extends Sprite2D

@export
var target: Node2D
var max_speed = 50.0
var velocity := 0.0
var acceleration := 10.0


func _process(delta: float) -> void:
	var to_target = target.global_position - global_position
	var distance_to_target = to_target.length()

	if distance_to_target > 100:
		velocity += acceleration * delta
	else:
		velocity -= acceleration * delta

	velocity = clamp(velocity, 0, max_speed)

	var target_rotation = to_target.angle() + PI / 2
	rotation = rotate_toward(global_rotation, target_rotation, delta)
	position += velocity * Vector2.UP.rotated(rotation) * delta

extends Node2D

@export
var target: Planet
@export
var time_to_live: float
var max_velocity = 150.0
var min_speed = 0.0
var velocity := 0.0
var max_acceleration := 50.0
var is_dead := false
var death_direction: Vector2
var death_rotation: float

var cargo: Cargo

func _ready() -> void:
    time_to_live = time_to_live + randf() * 10
    var timer = Timer.new()
    timer.wait_time = time_to_live
    timer.one_shot = true
    timer.timeout.connect(self.die_slowly)
    add_child(timer)
    timer.start()

func _process(delta: float) -> void:
    if is_dead:
        position += velocity * death_direction * delta
        rotation += death_rotation * delta
        return

    if !is_instance_valid(target):
        target = get_tree().get_nodes_in_group("planets")[0]

        if !is_instance_valid(target):
            return

    var to_target = target_position() - global_position
    var distance_to_target = to_target.length()

    var target_rotation = to_target.angle() + PI / 2
    var rotation_strength = abs(angle_difference(target_rotation, global_rotation)) * 4

    var braking_distance = ((velocity ** 2) / (2 * max_acceleration)) + 2
    var acceleration_dir = clamp(distance_to_target - braking_distance, -1, 1)
    var acceleration_strength = acceleration_dir
    var acceleration = clamp(max_acceleration * acceleration_strength, max(-max_acceleration, -velocity), max_acceleration)

    velocity += acceleration * delta
    velocity = clamp(velocity, min_speed, max_velocity)
    position += velocity * Vector2.UP.rotated(rotation) * delta

    rotation = rotate_toward(global_rotation, target_rotation, rotation_strength * delta)

    if cargo != null:
        cargo.global_target_position = $CargoHold.global_position

    if distance_to_target < 5:
        on_reach_target()

func target_position() -> Vector2:
    if cargo == null and len(target.output_slots) > 0:
        return target.to_global(target.output_dock_position())
    else:
        return target.to_global(target.input_dock_position())

func on_reach_target() -> void:
    # load off old cargo
    if cargo != null and target.can_take_input():
        target.add_input(cargo)
        cargo.removed.disconnect(self.cargo_expired)
        cargo = null

    # take new cargo
    if cargo == null:
        cargo = target.take_output()
        if cargo != null:
            cargo.removed.connect(self.cargo_expired)
            cargo.reparent(get_node("/root/Main"))

    target = target.random_target()


func cargo_expired(_c: Cargo) -> void:
    cargo = null


func die_slowly() -> void:
    is_dead = true
    death_direction = Vector2.UP.rotated(rotation)
    death_rotation = randf_range(-.2, .2)
    var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "modulate", Color(.4, .4, .4, 1), 5.0)
    tween.parallel().tween_property(self, "velocity", randf() * 10, 5.0)
    tween.parallel().tween_property(self, "rotation", death_rotation * 4, 5.0)

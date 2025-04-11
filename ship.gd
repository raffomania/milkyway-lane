extends Node2D

class_name Ship

class State:
    pass

class Moving:
    extends State

    var target: Planet

    func to_idle() -> Idle:
        return Idle.new(self.target)

class Dead:
    extends State

    var death_direction: Vector2
    var death_rotation: float

class Idle:
    extends State

    const check_interval := 2.0
    var target: Planet
    var check_cooldown := check_interval
    var drift_offset: Vector2

    func _init(new_target: Planet):
        self.target = new_target
        self.drift_offset = Vector2.RIGHT.rotated(randf_range(0, PI * 2)) * randf_range(target.radius, target.radius + 60)

    func to_idle():
        return self

const max_lifetime := 60.0
var time_to_live: float
var max_velocity = 150.0
var min_speed = 0.0
var velocity := 0.0
var max_acceleration := 50.0

var state: State

var cargo: Cargo

func _ready() -> void:
    time_to_live += randf_range(-10, 10)
    var timer = Timer.new()
    timer.wait_time = time_to_live
    timer.one_shot = true
    timer.timeout.connect(self.die_slowly)
    add_child(timer)
    timer.start()

    var original_scale = scale
    scale.x = 0
    var t = create_tween()
    t.tween_property(self, "scale", original_scale, 0.5)

func _process(delta: float) -> void:
    if state is Dead:
        position += velocity * state.death_direction * delta
        rotation += state.death_rotation * delta
        return

    if state is Moving:
        if !is_instance_valid(state.target):
            state.target = get_tree().get_nodes_in_group("planets")[0]

            if !is_instance_valid(state.target):
                return

    if state is Idle:
        state.check_cooldown -= delta
        if state.check_cooldown <= 0:
            state.check_cooldown = state.check_interval
            check_target()

    if state is Moving or state is Idle:
        var to_target
        var distance_to_target
        if state is Moving:
            to_target = target_position(state.target) - global_position
            distance_to_target = to_target.length() - state.target.radius

            if distance_to_target < 5:
                check_target()
        elif state is Idle:
            var target_global_position = target_position(state.target)
            to_target = target_global_position + state.drift_offset - global_position
            distance_to_target = to_target.length()


        var target_rotation = to_target.angle() + PI / 2
        var rotation_strength = abs(angle_difference(target_rotation, global_rotation)) * 4

        var braking_distance = ((velocity ** 2) / (2 * max_acceleration)) + 2
        var acceleration_dir = clamp(distance_to_target - braking_distance, -1, 1)
        var acceleration_strength = acceleration_dir
        var acceleration = clamp(max_acceleration * acceleration_strength, max(-max_acceleration, -velocity), max_acceleration)

        if distance_to_target > 4:
            velocity += acceleration * delta
            velocity = clamp(velocity, min_speed, max_velocity)
            position += velocity * Vector2.UP.rotated(rotation) * delta

        rotation = rotate_toward(global_rotation, target_rotation, rotation_strength * delta)

    if cargo != null:
        cargo.global_target_position = $CargoHold.global_position

func target_position(target: Planet) -> Vector2:
    return target.global_position

func check_target() -> void:
    if state is not Moving and state is not Idle:
        return

    # load off old cargo
    if cargo != null and state.target.can_take_input(cargo.type):
        state.target.add_input(cargo)
        remove_current_cargo()

    # take new cargo
    if cargo == null:
        take_cargo(state.target.take_output())

    var new_target
    if cargo != null:
        new_target = state.target.target_for_cargo(cargo.type)
    else:
        new_target = state.target.random_target()

    if new_target == null:
        state = state.to_idle()
    else:
        if state is Idle:
            state = Moving.new()
        state.target = new_target

func remove_current_cargo() -> void:
    cargo.removed.disconnect(self.cargo_expired)
    cargo = null

func take_cargo(c: Cargo) -> void:
    if c == null:
        return

    cargo = c
    cargo.removed.connect(self.cargo_expired)

func cargo_expired(_c: Cargo) -> void:
    cargo = null

func die_slowly() -> void:
    state = Dead.new()
    state.death_direction = Vector2.UP.rotated(rotation)
    state.death_rotation = randf_range(-.2, .2)
    var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "modulate", Color(.4, .4, .4, 1), 5.0)
    tween.parallel().tween_property(self, "velocity", randf() * 10, 5.0)
    tween.parallel().tween_property(self, "rotation", state.death_rotation * 4, 5.0)

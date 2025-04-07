@tool
class_name Planet

extends Node2D

@export
var target: Planet:
    set(val):
        target = val
        if val == self:
            push_warning(val, " has itself as target")

@export
var texture: Texture2D:
    set(val):
        texture = val
        $Sprite.texture = texture

@export
var radius := 50.0:
    set(val):
        radius = val
        $Sprite.scale = Vector2.ONE * (2 * radius / texture.get_size().x)
        queue_redraw()

@export
var spawning_resource: PackedScene
@export
var spawning_ships: PackedScene
@export
var output_slots := 0
@export
var spawn_time := 15.0
@export
var input_slots := 0
var inputs_added := 0
var current_inputs := 0

var slot_size = 8.0

var outputs_spawned := 0
var current_outputs := 0

func _ready() -> void:
    add_to_group("planets")

    if Engine.is_editor_hint():
        return

    var spawn_timer = Timer.new()
    spawn_timer.wait_time = spawn_time
    spawn_timer.timeout.connect(self.spawn_output)
    add_child(spawn_timer)
    spawn_timer.start()

    var input_timer = Timer.new()
    input_timer.wait_time = spawn_time
    input_timer.timeout.connect(func():
        if spawning_resource == null:
            return
        var resource: Node2D = spawning_resource.instantiate()
        self.add_input(resource)
    )
    add_child(input_timer)
    input_timer.start()

func _draw() -> void:
    for i in range(output_slots):
        draw_circle(slot_position(i), slot_size, Color.GRAY, false)

    for i in range(input_slots):
        draw_circle(slot_position(i).rotated(PI), slot_size, Color.GRAY, false)

func slot_position(i: int):
    return (Vector2.RIGHT).rotated(i / radius * slot_size * 3) * radius

func spawn_output() -> void:
    if spawning_resource != null:
        spawn_resource()
    elif spawning_ships != null:
        spawn_ship()

func spawn_resource() -> void:
    if spawning_resource == null or current_outputs >= output_slots:
        return

    var free_slot = outputs_spawned % output_slots
    var resource: Node2D = spawning_resource.instantiate()
    resource.position = slot_position(free_slot)
    resource.rotation = resource.position.angle()
    resource.removed.connect(remove_resource)
    add_child(resource)

    outputs_spawned += 1
    current_outputs += 1

func add_input(resource: Node2D) -> void:
    if current_inputs >= input_slots:
        return

    var free_slot = inputs_added % input_slots
    resource.position = slot_position(free_slot).rotated(PI)
    resource.rotation = resource.position.angle()
    resource.removed.connect(remove_input)
    add_child(resource)

    inputs_added += 1
    current_inputs += 1

func spawn_ship() -> void:
    if spawning_ships == null:
        return

    var ship: Node2D = spawning_ships.instantiate()
    add_child(ship)

func remove_resource() -> void:
    current_outputs -= 1

func remove_input() -> void:
    current_inputs -= 1

class_name Planet

extends Node2D

@onready
var directives: Array[Directive] = child_directives()

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
var output_slots: Array[Cargo] = []
@export
var spawn_time := 15.0
@export
var consume_time := 10.0
@export
var input_slots: Array[Cargo.Type] = []
var current_inputs: Array[Cargo] = []

var slot_size := 12.0

func _ready() -> void:
    add_to_group("planets")

    var spawn_timer = Timer.new()
    spawn_timer.wait_time = spawn_time
    spawn_timer.timeout.connect(self.spawn)
    add_child(spawn_timer)
    spawn_timer.start()

    var consume_timer = Timer.new()
    consume_timer.wait_time = consume_time
    consume_timer.timeout.connect(self.consume_input)
    add_child(consume_timer)
    consume_timer.start()

    current_inputs.resize(len(input_slots))

    spawn.call_deferred()
    await get_tree().create_timer(0.2).timeout
    spawn.call_deferred()
    await get_tree().create_timer(0.2).timeout
    spawn.call_deferred()
    await get_tree().create_timer(0.2).timeout
    spawn.call_deferred()

func child_directives() -> Array[Directive]:
    var result: Array[Directive] = []
    for child in get_children():
        var directive := child as Directive
        if directive != null:
            result.append(directive)

    return result

func _draw() -> void:
    # for i in range(len(output_slots)):
    #     draw_circle(slot_position(i), slot_size, Color.GRAY, false)
    for i in range(len(input_slots)):
        draw_circle(slot_position(i).rotated(PI), slot_size, Color.GRAY, false)

func slot_position(i: int) -> Vector2:
    return (Vector2.RIGHT).rotated(i / radius * slot_size * 3) * (radius + slot_size / 2)

func output_dock_position() -> Vector2:
    var i = (len(output_slots) - 1) * .5
    return (Vector2.RIGHT).rotated(i / radius * slot_size * 3) * radius * 1.4

func input_dock_position() -> Vector2:
    var i = (len(input_slots) - 1) * .5
    return (Vector2.RIGHT).rotated(PI + (i / radius * slot_size * 3)) * radius * 1.4

func spawn() -> void:
    if spawning_resource != null:
        spawn_output()
    if spawning_ships != null:
        spawn_ship()

func consume_input() -> void:
    var available = current_inputs.filter(func(i): return i != null)
    if !available.is_empty():
        var cargo = available.pick_random()
        cargo.remove()
        remove_input(cargo)

func spawn_output() -> void:
    var free_slot = find_free_output_slot()
    if spawning_resource == null or free_slot == -1:
        return

    var output: Node2D = spawning_resource.instantiate()
    output.global_target_position = to_global(slot_position(free_slot))
    output.rotation = output.position.angle()
    output.removed.connect(remove_output)
    output.position = global_position
    get_node("/root/Main").add_child(output)
    output_slots[free_slot] = output


func find_free_output_slot() -> int:
    return output_slots.find_custom(func(o): return o == null)

func random_transportable_output() -> Cargo:
    var available_outputs = output_slots.filter(func(o):
        if o == null:
            return false
        var directive_available = directives.any(func(d): return d.includes_cargo_type(o.type))
        return directive_available
    )

    if !available_outputs.is_empty():
        return available_outputs.pick_random()
    else:
        return null

func free_input_slot(type: Cargo.Type) -> int:
    for i in range(len(input_slots)):
        if input_slots[i] == type:
            if current_inputs[i] == null:
                return i
    
    return -1

func can_take_input(type: Cargo.Type) -> bool:
    return free_input_slot(type) != -1

func add_input(input: Node2D) -> void:
    var free_slot = free_input_slot(input.type)
    if free_slot == -1:
        return

    input.global_target_position = to_global(slot_position(free_slot).rotated(PI))
    input.removed.connect(remove_input)

    current_inputs[free_slot] = input

func spawn_ship() -> void:
    if spawning_ships == null:
        return

    var ship: Node2D = spawning_ships.instantiate()
    get_node("/root/Main").add_child(ship)
    ship.global_position = global_position
    ship.state = ship.Moving.new()
    ship.state.target = self
    ship.check_target()

func random_target() -> Planet:
    if len(directives) == 0:
        return null

    return directives.pick_random().planet

func target_for_cargo(type: Cargo.Type) -> Planet:
    var available = directives.filter(func(d: Directive): return d.includes_cargo_type(type))
    if !available.is_empty():
        return available.pick_random().planet

    return null

func remove_output(cargo: Cargo) -> void:
    output_slots[output_slots.find(cargo)] = null
    cargo.removed.disconnect(self.remove_output)

func remove_input(cargo: Cargo) -> void:
    var i = current_inputs.find(cargo)
    if i != -1:
        current_inputs[i] = null

func take_output() -> Cargo:
    var output = random_transportable_output()
    if output == null:
        return null

    remove_output(output)
    return output

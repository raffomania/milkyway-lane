class_name Planet

extends Node2D

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

@export_group("output")
@export
var spawn_time := 15.0
@export
var spawning_cargo_type: Cargo.MaybeType
@export
var output_slots: int = 0
@export
var ship_count: int = 0
@export_group("input")
@export
var consume_time := 10.0
@export
var input_slots: Array[Cargo.Type] = []
var current_inputs: Array[Cargo] = []

const slot_size := 35.0

@onready
var directives: Array[Directive] = child_directives()
@onready
var arrow_width = $"Arrow".texture.get_size().x * $"Arrow".scale.x

var current_outputs: Array[Cargo] = []
var current_spawn_time := spawn_time

func _ready() -> void:
    add_to_group("planets")

    for i in range(len(input_slots)):
        var slot = preload("res://cargo/cargo_outline.tscn").instantiate()
        slot.type = input_slots[i]
        slot.outline_color = Color.WHITE
        slot.position = input_slot_position(i)
        add_child(slot)


    var output_type = Cargo.maybe_type_to_type(spawning_cargo_type)
    if output_type != null:
        for i in range(output_slots):
            var output_indicator = preload("res://cargo/cargo_outline.tscn").instantiate()
            output_indicator.type = output_type
            output_indicator.position = output_slot_position(i)
            add_child(output_indicator)
    else:
        if output_slots > 0:
            push_error(self, " has ", output_slots, " output slots but cargo type is not set")

    if input_slots.is_empty() and output_slots == 0:
        $Arrow.hide()

    if ship_count > 0:
        var ship_timer = Timer.new()
        ship_timer.wait_time = Ship.max_lifetime / ship_count
        ship_timer.timeout.connect(func(): self.spawn_ship(Ship.max_lifetime))
        add_child(ship_timer)
        ship_timer.start()

    var consume_timer = Timer.new()
    consume_timer.wait_time = consume_time
    consume_timer.timeout.connect(self.consume_input)
    add_child(consume_timer)
    consume_timer.start()

    current_inputs.resize(len(input_slots))
    current_outputs.resize(output_slots)

    await get_tree().create_timer(0.1).timeout
    for i in range(ship_count):
        spawn_ship((i + 1) * Ship.max_lifetime / ship_count)
        await get_tree().create_timer(1.0).timeout

    spawn_output.call_deferred()

func _process(delta: float) -> void:
    var spawn_speed_factor = 1 + len(current_inputs)
    current_spawn_time -= delta * spawn_speed_factor

    if current_spawn_time <= 0.0:
        spawn_output()
        current_spawn_time = spawn_time
    

func child_directives() -> Array[Directive]:
    var result: Array[Directive] = []
    for child in get_children():
        var directive := child as Directive
        if directive != null:
            result.append(directive)

    return result

func output_slot_position(i: int) -> Vector2:
    var mid = (output_slots - 1) * .5
    return Vector2((arrow_width + slot_size) / 2, slot_size * (mid - i))

func input_slot_position(i: int) -> Vector2:
    var mid = (len(input_slots) - 1) * .5
    return Vector2(- (arrow_width + slot_size) / 2, slot_size * (mid - i))

func consume_input() -> void:
    var available = current_inputs.filter(func(i): return i != null)
    if !available.is_empty():
        var cargo = available.pick_random()
        cargo.remove()
        remove_input(cargo)

func spawn_output() -> void:
    var type = Cargo.maybe_type_to_type(spawning_cargo_type)
    if type == null:
        return

    var free_slot = find_free_output_slot()
    if free_slot == -1:
        return

    var output: Node2D = preload("res://cargo/cargo.tscn").instantiate()
    output.type = type
    output.global_position = global_position
    output.global_target_position = to_global(output_slot_position(free_slot))
    output.removed.connect(remove_output)
    get_node("/root/Main").add_child(output)
    current_outputs[free_slot] = output


func find_free_output_slot() -> int:
    return current_outputs.find_custom(func(o): return o == null)

func random_transportable_output() -> Cargo:
    var available_outputs = current_outputs.filter(func(o):
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

    input.global_target_position = to_global(input_slot_position(free_slot))
    input.removed.connect(remove_input)

    current_inputs[free_slot] = input

func spawn_ship(time_to_live: float) -> void:
    if ship_count <= 0:
        return

    var ship: Node2D = preload("res://ship.tscn").instantiate()
    ship.global_position = global_position
    ship.state = ship.Moving.new()
    ship.state.target = self
    ship.time_to_live = time_to_live
    get_node("/root/Main").add_child(ship)
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
    current_outputs[current_outputs.find(cargo)] = null
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

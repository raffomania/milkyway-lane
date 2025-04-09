class_name Planet

extends Node2D

@export
var targets: Array[Planet]

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
var input_slots := 0
@export
var target_line_color: Color
var inputs_added := 0
var current_inputs := 0

var targets_lines: Array[PackedVector2Array]

var slot_size := 12.0

func _ready() -> void:
    add_to_group("planets")

    var spawn_timer = Timer.new()
    spawn_timer.wait_time = spawn_time
    spawn_timer.timeout.connect(self.spawn)
    add_child(spawn_timer)
    spawn_timer.start()

    for target in targets:
        var line = Curve2D.new()
        var local_target_pos = to_local(target.global_position)
        var distance = local_target_pos.length()
        var perpendicular_angle = local_target_pos.angle() + PI * .5
        var start = Vector2.RIGHT.rotated(local_target_pos.angle() - PI * .05) * (radius + slot_size * 3)
        var end = local_target_pos + Vector2.LEFT.rotated(local_target_pos.angle() - PI * .05) * (target.radius + target.slot_size * 3)
        var control = local_target_pos.normalized() * distance * .15 + Vector2.LEFT.rotated(perpendicular_angle) * distance * .02
        line.add_point(start, Vector2.ZERO, control)
        line.add_point(end, control.rotated(PI), Vector2.ZERO)
        targets_lines.append(line.tessellate(4, 1))

    spawn.call_deferred()

func _draw() -> void:
    for i in range(len(output_slots)):
        draw_circle(slot_position(i), slot_size, Color.GRAY, false)

    for i in range(input_slots):
        draw_circle(slot_position(i).rotated(PI), slot_size, Color.GRAY, false)

    var line_width = 5
    for lines in targets_lines:
        if !lines.is_empty():
            draw_circle(lines[0], line_width * .5, target_line_color, true, -1, true)
        for i in range(len(lines) - 1):
            draw_line(lines[i], lines[i + 1], target_line_color, line_width, true)
            if i == (len(lines) - 2):
                var arrow_line_end = (lines[i] - lines[i + 1]).normalized() * line_width * 2
                draw_line(lines[i + 1], lines[i + 1] + arrow_line_end.rotated(PI * .2), target_line_color, line_width, true)
                draw_line(lines[i + 1], lines[i + 1] + arrow_line_end.rotated(-PI * .2), target_line_color, line_width, true)
                draw_circle(lines[i + 1], line_width * .5, target_line_color, true, -1, true)

func slot_position(i: int) -> Vector2:
    return (Vector2.RIGHT).rotated(i / radius * slot_size * 3) * radius

func output_dock_position() -> Vector2:
    var i = (len(output_slots) - 1) * .5
    return (Vector2.RIGHT).rotated(i / radius * slot_size * 3) * radius * 1.4

func input_dock_position() -> Vector2:
    var i = (input_slots - 1) * .5
    return (Vector2.RIGHT).rotated(PI + (i / radius * slot_size * 3)) * radius * 1.4

func spawn() -> void:
    if spawning_resource != null:
        spawn_output()
    elif spawning_ships != null:
        spawn_ship()

func spawn_output() -> void:
    var free_slot = find_free_output_slot()
    if spawning_resource == null or free_slot == -1:
        return

    var output: Node2D = spawning_resource.instantiate()
    output.global_target_position = to_global(slot_position(free_slot))
    output.rotation = output.position.angle()
    output.removed.connect(remove_output)
    add_child(output)
    output_slots[free_slot] = output

func find_free_output_slot() -> int:
    return output_slots.find_custom(func(o): return o == null)

func find_output() -> Cargo:
    var index = output_slots.find_custom(func(o): return o != null)

    if index != -1:
        return output_slots[index]
    else:
        return null

func can_take_input() -> bool:
    return current_inputs < input_slots

func add_input(input: Node2D) -> void:
    if !can_take_input():
        return

    if input.get_parent() != null:
        input.reparent(self)
    else:
        add_child(input)

    var free_slot = inputs_added % input_slots
    input.global_target_position = to_global(slot_position(free_slot).rotated(PI))
    input.rotation = input.position.angle()
    input.removed.connect(remove_input)

    inputs_added += 1
    current_inputs += 1

func spawn_ship() -> void:
    if spawning_ships == null:
        return

    var ship: Node2D = spawning_ships.instantiate()
    ship.target = self.random_target()
    get_node("/root/Main").add_child(ship)
    ship.global_position = global_position

func random_target() -> Planet:
    if targets.is_empty():
        return

    return targets.pick_random()

func remove_output(cargo: Cargo) -> void:
    output_slots[output_slots.find(cargo)] = null
    cargo.removed.disconnect(self.remove_output)

func remove_input(_cargo: Cargo) -> void:
    current_inputs -= 1

func take_output() -> Cargo:
    var output = find_output()
    if output == null:
        return null

    remove_output(output)
    return output

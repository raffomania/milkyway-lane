class_name Directive

extends Node2D

@export
var cargo_types: Array[Cargo.Type]
@export
var arrow_color: Color = Color(0.5952, 0.85188, 0.93, 1)

@onready
var parent: Planet = $".."

var arrow_curve: Curve2D
var arrow_lines: PackedVector2Array
var indicator_size := 25

var state: State = Idle.new()

class State:
    pass

class Dragging:
    extends State

class Idle:
    extends State

    var planet: Planet


func assign_target_planet(target: Planet):
    state = Idle.new()
    state.planet = target
    var angle_to_target = to_local(target.global_position).angle()
    var end_position = target.global_position + Vector2.LEFT.rotated(angle_to_target + PI * .03) * (target.radius)

    update_curve(end_position)
    spawn_cargo_type_children(state)

func update_curve(global_target_pos: Vector2):
    global_position = parent.global_position
    arrow_curve = Curve2D.new()
    var local_target_pos = to_local(global_target_pos)
    var perpendicular_angle = local_target_pos.angle() + PI * .5
    var start = _indicator_position(len(cargo_types), global_target_pos)
    var distance = start.distance_to(local_target_pos)
    var control = local_target_pos.normalized() * distance * .5 + Vector2.LEFT.rotated(perpendicular_angle) * distance * .15
    arrow_curve.add_point(start, Vector2.ZERO, control)
    arrow_curve.add_point(local_target_pos, Vector2.ZERO, Vector2.ZERO)
    arrow_lines = arrow_curve.tessellate(3, 1)

    queue_redraw()

func _input(event: InputEvent) -> void:
    if state is not Dragging:
        return

    if event is InputEventMouseMotion:
        update_curve(get_viewport().get_camera_2d().get_global_mouse_position())

func spawn_cargo_type_children(idle: Idle):
    for i in len(cargo_types):
        var sprite = preload("res://cargo/cargo_sprite.tscn").instantiate()
        sprite.type = cargo_types[i]
        sprite.modulate.a = 0.5
        sprite.outline_color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")
        sprite.position = _indicator_position(i, idle.planet.global_position)
        add_child(sprite)

func _draw() -> void:
    var line_width = 3
    var lines = arrow_lines

    if !lines.is_empty():
        draw_circle(lines[0], line_width * .5, arrow_color, true, -1, true)
    for i in range(len(lines) - 1):
        draw_line(lines[i], lines[i + 1], arrow_color, line_width, true)
        if i == (len(lines) - 2):
            var arrow_line_end = (lines[i] - lines[i + 1]).normalized() * line_width * 4
            draw_line(lines[i + 1], lines[i + 1] + arrow_line_end.rotated(PI * .2), arrow_color, line_width, true)
            draw_line(lines[i + 1], lines[i + 1] + arrow_line_end.rotated(-PI * .2), arrow_color, line_width, true)
            draw_circle(lines[i + 1], line_width * .5, arrow_color, true, -1, true)

func includes_cargo_type(type: Cargo.Type) -> bool:
    return cargo_types.has(type)

func _indicator_position(i: int, target_global_position: Vector2) -> Vector2:
    return Vector2.RIGHT.rotated(to_local(target_global_position).angle() - PI * 0.04) * (parent.radius + indicator_size * i)

class_name Directive

extends Node2D

@export
var planet: Planet
@export
var cargo_types: Array[Cargo.Type]
@export
var arrow_color: Color = Color(0.5952, 0.85188, 0.93, 1)

@onready
var parent: Planet = $".."

var arrow_curve: Curve2D
var arrow_lines: PackedVector2Array
var indicator_size := 40

func _ready() -> void:
    arrow_curve = Curve2D.new()
    var local_target_pos = to_local(planet.global_position)
    var distance = local_target_pos.length()
    var perpendicular_angle = local_target_pos.angle() + PI * .5
    var start = Vector2.RIGHT.rotated(local_target_pos.angle() - PI * .05) * (parent.radius + parent.slot_size * 3)
    var end = local_target_pos + Vector2.LEFT.rotated(local_target_pos.angle() - PI * .05) * (planet.radius + planet.slot_size * 3)
    var control = local_target_pos.normalized() * distance * .15 + Vector2.LEFT.rotated(perpendicular_angle) * distance * .02
    arrow_curve.add_point(start, Vector2.ZERO, control)
    arrow_curve.add_point(end, control.rotated(PI), Vector2.ZERO)
    arrow_lines = arrow_curve.tessellate(4, 1)

    for i in len(cargo_types):
        var type_texture = Cargo.texture_for_type(cargo_types[i])

        var sprite = Sprite2D.new()
        sprite.texture = type_texture
        sprite.scale = Vector2.ONE * (indicator_size * .7) / type_texture.get_size().x
        sprite.position = _indicator_position(i)
        add_child(sprite)

func _draw() -> void:
    var line_width = 5
    var lines = arrow_lines

    if !lines.is_empty():
        draw_circle(lines[0], line_width * .5, arrow_color, true, -1, true)
    for i in range(len(lines) - 1):
        draw_line(lines[i], lines[i + 1], arrow_color, line_width, true)
        if i == (len(lines) - 2):
            var arrow_line_end = (lines[i] - lines[i + 1]).normalized() * line_width * 2
            draw_line(lines[i + 1], lines[i + 1] + arrow_line_end.rotated(PI * .2), arrow_color, line_width, true)
            draw_line(lines[i + 1], lines[i + 1] + arrow_line_end.rotated(-PI * .2), arrow_color, line_width, true)
            draw_circle(lines[i + 1], line_width * .5, arrow_color, true, -1, true)

    for i in len(cargo_types):
        var clear_color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")
        draw_circle(_indicator_position(i), indicator_size * .5, clear_color, true)

func includes_cargo_type(type: Cargo.Type) -> bool:
    return cargo_types.has(type)

func _indicator_position(i: int) -> Vector2:
    var position_offset = i - (len(cargo_types) - 1) * .5
    return arrow_curve.sample_baked((arrow_curve.get_baked_length() * .5) - position_offset * indicator_size * .8)

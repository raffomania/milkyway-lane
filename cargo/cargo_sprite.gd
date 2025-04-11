extends Sprite2D

var type: Cargo.Type
var outline_color: Color:
    set(val):
        material.set_shader_parameter("outline_color", val)
        outline_color = val

func _ready() -> void:
    var tween = create_tween()
    var original_scale = Vector2(scale)
    scale = Vector2.ZERO
    tween.tween_property(self, "scale", original_scale * 1.2, .1)
    tween.tween_property(self, "scale", original_scale, .2)

    texture = Cargo.texture_for_type(type)
class_name Planet

extends Sprite2D

var radius := 50.0
@export
var target: Planet:
    set(val):
        target = val
        if val == self:
            push_warning(val, " has itself as target")

func _ready() -> void:
    add_to_group("planets")

    radius = texture.get_size().x * scale.x * .5

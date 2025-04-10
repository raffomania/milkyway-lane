class_name Cargo

extends Sprite2D

enum Type {
    Ore,
    Fuel,
    Food
}

static func texture_for_type(cargo_type: Cargo.Type) -> Texture2D:
    match cargo_type:
        Type.Ore: return preload("res://cargo/metal.svg")
        Type.Fuel: return preload("res://cargo/energy.svg")
        Type.Food: return preload("res://cargo/energy.svg")

    return preload("res://simple space/PNG/Retina/icon_crossSmall.png")

signal removed(cargo: Cargo)

@export
var type: Type
var global_target_position: Vector2

func _ready() -> void:
    var tween = create_tween()
    var original_scale = Vector2(scale)
    scale = Vector2.ZERO
    tween.tween_property(self, "scale", original_scale * 1.2, .1)
    tween.tween_property(self, "scale", original_scale, .2)

    # var timer = Timer.new()
    # timer.wait_time = decay_time
    # timer.one_shot = true
    # timer.timeout.connect(self.remove)
    # add_child(timer)
    # timer.start()

func _process(delta: float) -> void:
    # decay_time -= delta
    # if decay_time <= 5.0:
    #     var l = .5 + decay_time / 10.0
    #     modulate = Color(l, l, l, 1)
    if global_target_position != null:
        global_position = global_position.lerp(global_target_position, delta * 8)

func remove() -> void:
    var tween = create_tween()
    tween.tween_property(self, "scale", scale * 1.2, .2)
    tween.tween_property(self, "scale", Vector2.ZERO, .1)
    await tween.finished
    removed.emit(self)
    queue_free()
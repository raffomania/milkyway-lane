extends Camera2D

var target_zoom := Vector2.ONE

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_released("mouse_scroll_down"):
        target_zoom *= 0.85
    elif event.is_action_released("mouse_scroll_up"):
        target_zoom *= 1.15

func _process(delta: float) -> void:
    zoom = lerp(zoom, target_zoom, delta * 30)

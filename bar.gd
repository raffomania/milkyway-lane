extends Control

func _get_minimum_size() -> Vector2:
    return Vector2(10, 100)

func _draw() -> void:
    draw_rect(Rect2(position, size), Color.GRAY)

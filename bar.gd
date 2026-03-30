extends Control

func _get_minimum_size():
    return Vector2(50, 100)

func _draw():
    draw_rect(Rect2(position, size), Color.WHITE)

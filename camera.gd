extends Camera2D

var focus := 0

@onready
var focus_points

func _ready() -> void:
    focus_points = get_tree().get_nodes_in_group("focus_points")
    update_focus()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action("ui_focus_next"):
        focus = (focus + 1) % len(focus_points)
    if event.is_action("ui_focus_prev"):
        focus = focus - 1

    if focus < 0:
        focus += len(focus_points)

    update_focus()

func update_focus() -> void:
    global_position = focus_points[focus].global_position

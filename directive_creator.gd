extends Node

var creating_directive: Directive

func start_creating(planet: Planet):
    creating_directive = preload("res://directive.tscn").instantiate()
    creating_directive.state = Directive.Dragging.new()
    planet.add_child(creating_directive)

func finish_creating(planet: Planet):
    creating_directive.assign_target_planet(planet)
    creating_directive.parent.available_directives.append(creating_directive)
    creating_directive = null

func click_planet(planet: Planet):
    if is_instance_valid(creating_directive):
        # TODO check if a directive for these two planets already exists
        if creating_directive.parent != planet:
            finish_creating(planet)

        # Keep creating the current directive, this was a click on the starting planet
        return
    else:
        start_creating(planet)

func _unhandled_input(event: InputEvent) -> void:
    if event is not InputEventMouseButton or not event.is_action_released("left_click"):
        return

    # check if user clicked on a planet
    var camera = get_viewport().get_camera_2d()
    var click_pos = camera.get_global_mouse_position()
    for planet in get_tree().get_nodes_in_group("planets"):
        if click_pos.distance_squared_to(planet.global_position) < planet.radius ** 2:
            click_planet(planet)
            return

    # User clicked into nothing, destroy wip directive if present
    if is_instance_valid(creating_directive):
        creating_directive.queue_free()

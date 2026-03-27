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
        if creating_directive.parent != planet:
            finish_creating(planet)

        # Keep creating the current directive, this was a click on the starting planet
        return
    else:
        start_creating(planet)
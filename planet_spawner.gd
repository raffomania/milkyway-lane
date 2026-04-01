extends Node

@onready
var home_planet = $'../1/Home'

@onready
var grid = $'../Grid'

func _input(event: InputEvent) -> void:
    if event.is_action_released('ui_up'):
        spawn()

func spawn() -> void:
    var radius = random_radius()
    var position = new_planet_position(radius)
    if position == null:
        return

    var planet: Planet = preload("res://planet.tscn").instantiate()

    planet.global_position = position
    planet.texture = random_texture()
    planet.input_slots = random_input_slots()
    var min_outputs = 1 if planet.input_slots.is_empty() else 0
    planet.output_slots = randi_range(min_outputs, 2)
    if planet.output_slots > 0:
        planet.spawning_cargo_type = Cargo.type_to_maybe_type(Cargo.random_type())
    else:
        planet.spawning_cargo_type = Cargo.MaybeType.Nothing

    $'../1'.add_child(planet)

    planet.radius = radius

    home_planet.ship_count += 1

func new_planet_position(radius: float) -> Variant:
    # Take the viewport bounds and add a little margin so planets
    # don't spawn at the edge of the screen
    var bounds_margin = Vector2.ONE * 120
    var position = grid.global_bounds.position + bounds_margin
    var size = grid.global_bounds.size - bounds_margin * 2

    var planets = get_tree().get_nodes_in_group("planets")

    # Try to randomly find a position on the map
    # where no planet exists yet
    for try in range(50_000):
        var offset = Vector2(randi_range(0, size.x), randi_range(0, size.y))
        var random_position = position + offset

        # If position is in an empty space on the map, return it
        var collides = planets.any(func(planet): return planet.position.distance_to(random_position) < radius + planet.radius + 70)
        if not collides:
            return random_position

    print("can't find new planet position, giving up")
    return null

func random_texture() -> Texture2D:
    return [
        preload("res://planets/Planets/planet00.png"),
        preload("res://planets/Planets/planet01.png"),
        preload("res://planets/Planets/planet02.png"),
        preload("res://planets/Planets/planet03.png"),
        preload("res://planets/Planets/planet04.png"),
        preload("res://planets/Planets/planet05.png"),
        preload("res://planets/Planets/planet06.png"),
        preload("res://planets/Planets/planet07.png"),
        preload("res://planets/Planets/planet08.png"),
        preload("res://planets/Planets/planet09.png"),
    ].pick_random()

func random_radius() -> float:
    return randf_range(50, 100)

func random_input_slots() -> Array[Cargo.Type]:
    var slots: Array[Cargo.Type] = []

    # Only spawn inputs that can be filled by
    # outputs from existing planets
    var available = existing_output_types()
    if available.is_empty():
        return slots

    # Pick a random type for each input slot
    var count = randi_range(0, 3)
    for _i in range(count):
        slots.append(existing_output_types().pick_random())

    return slots


func existing_output_types() -> Array[Cargo.Type]:
    # Check all planets for their output
    # and return a deduplicated list of output
    # types
    var types: Array[Cargo.Type] = []
    for planet in get_tree().get_nodes_in_group("planets"):
        var type = Cargo.maybe_type_to_type(planet.spawning_cargo_type)
        if type != null and not types.has(type):
            types.append(type)

    return types

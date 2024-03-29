extends Node

func spawn_tiles():
	var tile_scene = preload("res://tile.tscn")
	const suits = ["crak", "boo", "dot", "honor"]  # TODO BUG TERRIBLE! THIS IS NOT SHARED WITH ONE IN mahjongg.gd!!!
	for suit in suits.slice(0, 3):
		for value in 9:
			for i in 4:  # Four of each tile
				var tile = tile_scene.instantiate()
				tile.suit = suit
				tile.value = value
				#tile.position = Vector2(300 + 50 * (value + i), 200 + 100 * suits.find(suit))
				tile.position = Vector2(randi_range(100, 1500), randi_range(100, 700))
				tile.rest_point = tile.position
				tile.frozen = true
				tile.add_to_group("tiles")
				add_child(tile)
	
	# Winds and Dragons
	# TODO these don't really have a "value", but it's convenient to match the normal tiles for now
	for value in 7:
		for i in 4:
			var tile = tile_scene.instantiate()
			tile.suit = "honor"
			tile.value = value
			tile.position = Vector2(randi_range(100, 1500), randi_range(100, 700))
			tile.rest_point = tile.position
			tile.frozen = true
			tile.add_to_group("tiles")
			add_child(tile)
	# Flowers and Jokers
	for i in 16:
		var tile = tile_scene.instantiate()
		# TODO we don't have textures for these yet, so just use the ? tile for now I guess
		tile.suit = "honor"
		tile.value = 8
		tile.position = Vector2(randi_range(100, 1500), randi_range(100, 700))
		tile.rest_point = tile.position
		tile.frozen = true
		tile.add_to_group("tiles")
		add_child(tile)
	
func build_wall():
	print("Building wall...")
	#get_tree().call_group("tiles", "freeze")  # TODO this is done as they're instantiated.
	
	# Put tiles face down
	get_tree().call_group("tiles", "turn_face_down")
	
	# Get all the tiles in an array.
	var tiles = get_tree().get_nodes_in_group("tiles")
	
	#randomize()  # Apparently you have to do this to generate a new seed each time :shrug:
	tiles.shuffle()
	
	# The wall is a square with a length of 19 tiles and height of 2 tiles.
	const wall_length = 19
	#const wall_center = Vector2(1600/2, 900/2)
	const horiz_wall_offset = Vector2(0, -660)
	const wall_first_spot_lower_horiz = Vector2(300, 750)  # TODO pick something less arbitrary later
	const wall_first_spot_upper = wall_first_spot_lower_horiz + Vector2(0, -20)
	const tile_offset = Vector2(52, 0)
	
	print("length of tiles[] = ", tiles.size())
	print("expected = ", 19 * 2 * 4)
	
	# Do the horizontal walls first.
	for n in 2:
		var perspective = "bottom"
		
		for i in wall_length:
			# Move each tile in the array to its spot on the wall.
			# TODO make a wall building animation that is representative of real life
			# TODO make tiles face down
			var tile = tiles.pop_front()
			tile.rest_point = wall_first_spot_lower_horiz + tile_offset * i + horiz_wall_offset * n
			tile.unfreeze()
			tile.change_perspective(perspective)
			#await get_tree().create_timer(0.03).timeout # waits for 1 second
		
		# Do it again, but slightly offset to show two levels
		for i in wall_length:
			var tile = tiles.pop_front()
			tile.move_to_front()
			tile.rest_point = wall_first_spot_upper + tile_offset * i + horiz_wall_offset * n
			tile.unfreeze()
			tile.change_perspective(perspective)
			#await get_tree().create_timer(0.03).timeout # waits for 1 second
 
	# Now, do the vertical walls.
	# They build from top to bottom (because lower ones occlude upper ones).
	const vert_wall_offset = Vector2(1066, 0)
	const wall_first_spot_left = Vector2(234, 50)  # TODO pick something less arbitrary later
	const vert_tile_offset = Vector2(0, 55 - 16)
	var perspectives = ["left", "right"]
	
	for n in 2:
		var perspective = perspectives[n]
		
		for i in wall_length:
			# Move each tile in the array to its spot on the wall.
			# TODO make a wall building animation that is representative of real life
			# TODO make tiles face down
			var tile = tiles.pop_front()
			tile.move_to_front()
			tile.rest_point = wall_first_spot_left + vert_tile_offset * i + vert_wall_offset * n
			tile.unfreeze()
			tile.change_perspective(perspective)
			#await get_tree().create_timer(0.03).timeout # waits for 1 second
		
		# Do it again, but slightly offset to show two levels
		for i in wall_length:
			var tile = tiles.pop_front()
			tile.move_to_front()
			tile.rest_point = wall_first_spot_left + vert_tile_offset * i + vert_wall_offset * n
			tile.unfreeze()
			tile.change_perspective(perspective)
			#await get_tree().create_timer(0.03).timeout # waits for 1 second
	
# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.new_game.connect(_on_new_game)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func _on_new_game():
	print("[mahjongg] Starting a new game...")
	remove_child($TitleScreen)
	spawn_tiles()
	build_wall()

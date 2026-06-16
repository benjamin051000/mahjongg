extends Node

const DEBUG_WALL := true

func spawn_tiles():
	const tile_scene = preload("res://tile.tscn")
	const suits = Common.Suit
	# Start with the three numerical suits.
	for suit in [suits.CRAK, suits.BOO, suits.DOT]:
		for value in range(1, 10):
			for i in 4: # Four of each tile
				var tile = tile_scene.instantiate()
				tile.suit = suit
				tile.value = value
				#tile.position = Vector2(300 + 50 * value, 200 + 100 * suit)
				tile.position = Vector2i(randi_range(100, 1500), randi_range(100, 800))
				tile.rest_point = tile.position
				tile.frozen = false
				tile.faceup = true
				tile.add_to_group("tiles")
				add_child(tile)
	
	# Winds and Dragons
	# TODO these don't really have a "value", but it's convenient to match the normal tiles for now
	for value in range(1, 8):
		for i in 4:
			var tile = tile_scene.instantiate()
			tile.suit = Common.Suit.HONOR
			tile.value = value
			#tile.position = Vector2(300 + 50 * (value + i), 200 + 100 * tile.suit)
			tile.position = Vector2i(randi_range(100, 1500), randi_range(100, 800))
			tile.rest_point = tile.position
			tile.frozen = false
			tile.faceup = true
			tile.add_to_group("tiles")
			add_child(tile)
	
	# Flowers and Jokers
	for i in 16:
		var tile = tile_scene.instantiate()
		# TODO we don't have textures for these yet, so just use the ? tile for now I guess
		tile.suit = Common.Suit.HONOR
		tile.value = 9  # NOTE: Recall that values are 1-9, indexing happens internally.
		#tile.position = Vector2(300 + 50 * (i + 1), 200 + 100 * (tile.suit + 1))
		tile.position = Vector2i(randi_range(100, 1500), randi_range(100, 800))
		tile.rest_point = tile.position
		tile.frozen = false
		tile.faceup = true
		tile.add_to_group("tiles")
		add_child(tile)

func build_horizontal_wall(
	wall_length: int, # Number of tiles in a wall
	tiles: Array, # Array referencing Tile nodes
	x: int, # Starting x-coord of wall (NOTE which appears to be the center of the tile)
	bottom_tile_y: int, # Y-coord of the bottom row
	second_level_offset: int, # y-offset of top level
	x_y_offset: Vector2i,  # Size of tile, used as offset. TODO can we implicitly get this from the Tile size?
	bottom_not_top: bool, # true == bottom, false == top
) -> Array[Node]:
	var tiles_in_this_wall: Array[Node] = []

	# WARNING: This consumes the tiles array! TODO send a copy, or just reference it.
	# Two levels tall. First one has no offset because it's the "origin".
	var level_offsets = [Vector2i.ZERO, Vector2i(0, second_level_offset)]
	if not bottom_not_top:
		level_offsets.reverse()
		
	for i in wall_length:
		for level_offset in level_offsets:
			# Move each tile in the array to its spot on the wall.
			var tile = tiles.pop_front()
			tiles_in_this_wall.append(tile)

			tile.rest_point = Vector2i(x, bottom_tile_y) + x_y_offset*i + level_offset
			if level_offset and DEBUG_WALL:
				tile.rest_point += Vector2(0, -15)
			# Ensure the top level appears on top of the bottom level.
			if level_offset:
				tile.move_to_front()
			
			#tile.frozen = false
			await get_tree().create_timer(0.01).timeout

	if bottom_not_top:
		tiles_in_this_wall.reverse()
		return tiles_in_this_wall
	else:
		return tiles_in_this_wall
	
func build_vertical_wall(
	wall_length: int,
	tiles: Array,
	x: int,  # x-coord of wall
	y: int,  # Starting y-coord of wall
	second_level_offset: int, 
	x_y_offset: Vector2i,
	left_not_right: bool, # true == left, false == right
) -> Array[Node]:
	var tiles_in_this_wall: Array[Node] = []
	
	var level_offsets = [Vector2i.ZERO, Vector2i(0, second_level_offset)]
	#if not left_not_right:
	level_offsets.reverse()
	
	for i in wall_length:
		for level_offset in level_offsets:
			var tile = tiles.pop_front()
			tiles_in_this_wall.append(tile)
			
			tile.rest_point = Vector2i(x, y) + x_y_offset*i + level_offset
			
			if level_offset and DEBUG_WALL:
				tile.rest_point += Vector2(-15 if left_not_right else 15, 0)
			
			# HACK: These get built top-to-bottom, so *every* time a new one gets placed,
			# it's supposed to be in the front (from our perspective).
			tile.move_to_front()
			tile.frozen = false
			tile.perspective = Common.TilePerspective.LEFT
			
			
			await get_tree().create_timer(0.01).timeout
	
	if left_not_right:
		tiles_in_this_wall.reverse()
		return tiles_in_this_wall
	else:
		# Extra step: we need to bring the right ones to the front.
		for i in range(0, tiles_in_this_wall.size(), 2):
			# Going through the even ones only
			tiles_in_this_wall[i].move_to_front()
			await get_tree().process_frame
		return tiles_in_this_wall


func build_wall() -> Array[Node]:
	# TODO I want this to be done when the animations finish... needs to wait on
	# an event or something signalling that each tile is at rest.
	
	get_tree().call_group("tiles", "set_faceup", false)
	var tiles = get_tree().get_nodes_in_group("tiles")
	tiles.shuffle()
	
	# Right now we're hard-coded to 1600x900, so assume those values when making adjustments.
	# TODO this will certainly bite me in the ass later. Oh well :shrug:
	# TODO Tiles is not consumed after these... I assume it's an array of refs so 
	# it's probably cheap to copy into these functions
	# UH MAYBE NOT ACTUALLY
	var bottom_idxs = await build_horizontal_wall(Common.wall_length, tiles, 325, 900-140, -20, Vector2i(52, 0), true) # lower
	var left_idxs = await build_vertical_wall(Common.wall_length, tiles,   325-21*3, 50, -20, Vector2i(0, 52-12), true) # left
	var top_idxs = await build_horizontal_wall(Common.wall_length, tiles, 325, 60, -20, Vector2i(52, 0), false) # upper
	var right_idxs = await build_vertical_wall(Common.wall_length, tiles,   1600-325+17*3, 50, -20, Vector2i(0, 52-12), false) # right
	
	# We need the new ordering of the tiles in further steps. Return it here
	return bottom_idxs + left_idxs + top_idxs + right_idxs

func create_hands():
	const hand_scene = preload("res://hand.tscn")
	var your_hand = hand_scene.instantiate()
	your_hand.position = Vector2i(800, 855)
	add_child(your_hand)

func spawn_dice() -> int:
	const dice_scene = preload("res://dice.tscn")
	var dice: Array = [dice_scene.instantiate(), dice_scene.instantiate()]
		
	for i in 2:
		dice[i].add_to_group("dice")
		dice[i].position = Vector2i(800 + 30*i, 450)
		add_child(dice[i])
	
	# A simple button to replace dice functionality for now.
	var roll_dice_btn = Button.new()
	roll_dice_btn.text = "Roll dice"
	roll_dice_btn.position = Vector2i(500, 400)
	add_child(roll_dice_btn)
	await roll_dice_btn.pressed
	# This allows for the proper distribution of two 1d6 dice.
	var dice_roll = randi_range(1, 6) + randi_range(1, 6)
	roll_dice_btn.text = "Rolled: " + str(dice_roll)
	return dice_roll
	


###########################################################
# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.new_game.connect(_on_new_game)
	spawn_tiles()
	#main_menu_animation()

func _on_new_game():
	print("[mahjongg] Starting a new game...")
	remove_child($TitleScreen)
	var tiles_wall_order = await build_wall()
	# TODO this is just a bandaid solution... build_wall should probably be 
	# awaitable and have some sort of signal that pops when it's done building.
	await get_tree().create_timer(0.5).timeout
	create_hands()
	var first_col_offset = await spawn_dice()
	deal(tiles_wall_order, first_col_offset)
	
func deal(tiles_wall_order: Array, first_col_offset: int):
	# TODO the first player is always you, but it should (in the future) be the
	# player with the highest dice roll.
	
	#var tiles: Array = get_tree().get_nodes_in_group("tiles")
	for tile in tiles_wall_order:
		tile.faceup = true
		await get_tree().create_timer(0.2).timeout
		#tile.faceup = false
		#await get_tree().create_timer(0.5).timeout
		

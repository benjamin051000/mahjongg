extends Node2D

# Straight from mahjongg.gd
func spawn_tiles():
	const tile_scene = preload("res://tile.tscn")
	const suits = ["crak", "boo", "dot", "honor"]  # TODO BUG TERRIBLE! THIS IS NOT SHARED WITH ONE IN mahjongg.gd!!!
	for suit in suits.slice(0, 3):
		var tile = tile_scene.instantiate()
		tile.suit = suit
		tile.value = 1
		#tile.position = Vector2(300 + 50 * (value + i), 200 + 100 * suits.find(suit))
		tile.position = Vector2(randi_range(100, 1500), randi_range(100, 700))
		tile.rest_point = tile.position
		tile.frozen = true
		tile.add_to_group("tiles")
		add_child(tile)
	
	# Winds and Dragons
	# TODO these don't really have a "value", but it's convenient to match the normal tiles for now
	for value in range(1, 7+1):
		var tile = tile_scene.instantiate()
		tile.suit = "honor"
		tile.value = value
		tile.position = Vector2(randi_range(100, 1500), randi_range(100, 700))
		tile.rest_point = tile.position
		tile.frozen = true
		tile.add_to_group("tiles")
		add_child(tile)
	# Flowers and Jokers
	for i in 1:
		var tile = tile_scene.instantiate()
		# TODO we don't have textures for these yet, so just use the ? tile for now I guess
		tile.suit = "honor"
		tile.value = 8
		tile.position = Vector2(randi_range(100, 1500), randi_range(100, 700))
		tile.rest_point = tile.position
		tile.frozen = true
		tile.add_to_group("tiles")
		add_child(tile)

# Called when the node enters the scene tree for the first time.
func _ready():
	test_tile_perspective()


func test_tile_perspective():
	spawn_tiles()
	
	get_tree().call_group("tiles", "set_faceup", true)
	$StepLabel.text = "up"
	await get_tree().create_timer(1).timeout
	for persp in Common.TilePerspective.values():
		get_tree().call_group("tiles", "set_perspective", persp)
		get_tree().call_group("tiles", "set_faceup", true)
		$StepLabel.text = "up " + Common.TilePerspective.keys()[persp]
		await get_tree().create_timer(1).timeout 
	
	get_tree().call_group("tiles", "set_faceup", false)
	$StepLabel.text = "down"
	await get_tree().create_timer(1).timeout
	for persp in Common.TilePerspective.values():
		get_tree().call_group("tiles", "set_perspective", persp)
		get_tree().call_group("tiles", "set_faceup", false)
		$StepLabel.text = "down " + Common.TilePerspective.keys()[persp]
		await get_tree().create_timer(1).timeout 
	
	$StepLabel.text = "repetition test..."
	await get_tree().create_timer(1).timeout 
	
	# Test back and forth
	for persp in Common.TilePerspective.values():
		get_tree().call_group("tiles", "set_perspective", persp)
		for i in 2:
			get_tree().call_group("tiles", "set_faceup", true)
			$StepLabel.text = "up " + Common.TilePerspective.keys()[persp]
			await get_tree().create_timer(1).timeout 
			get_tree().call_group("tiles", "set_faceup", false)
			$StepLabel.text = "down " + Common.TilePerspective.keys()[persp]
			await get_tree().create_timer(1).timeout 
	
	get_tree().quit()

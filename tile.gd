class_name Tile 
extends Sprite2D


# TODO use this, maybe via a subclass of Tile for normal and honor tiles?
#enum HonorValue {
	## Winds
	#E_WIND = 0,
	#S_WIND,
	#W_WIND,
	#N_WIND,
	## Dragons
	#W_DRAG,
	#G_DRAG,
	#R_DRAG
#}

########################################
# Tile properties that visually affect the sprite
var suit: Common.Suit:
	set(new):
		suit = new
		_update_sprite()

var value: int:
	set(new):
		assert(new >= 1 and new <= 9)
		value = new
		_update_sprite()

var faceup: bool: set = set_faceup
# This is a named func because it's used by `call_group("tiles", "set_faceup", false)` in mahjongg.gd.
func set_faceup(new: bool):
	faceup = new
	_update_sprite()

# The "orientation" of the tile (see perspective dicts)
var perspective: Common.TilePerspective: set = set_perspective
func set_perspective(new):
		perspective = new
		_update_sprite()
########################################

# Interaction and location parameters (do not affect the sprite visually)
var selected = false
var in_hand = false

# Debug flag to skip the lerping.
const INSTANT_MOVEMENT := false

var rest_point: Vector2:  # Where the tile returns when `selected == false`
	set(new):
		assert(Vector2.ZERO <= new and new <= Vector2(1600,900))  # TODO fetch screen size dynamically
		rest_point = new
		# _physics_process will handle usage of this, no need to call anything.
		
var frozen: bool  # Disables click and drag

func _update_sprite():
	if faceup:
		_turn_face_up()
	else:
		_turn_face_down()

func _turn_face_down():
	const face_down_offset = 2
	var perspective_offset = _get_perspective_offset()
	frame_coords = Vector2(perspective_offset, face_down_offset)


func _turn_face_up():
	# The face up tiles start at row index 3.
	const face_up_initial_offset = 3
	# Additional offset based off the perspective (which side of the tile can you see?)
	var perspective_offset = _get_perspective_offset()
	# Additional offset (from crak (crak == O regradless of perspective)) for the suit (see suit enum for indices)
	
	var y = face_up_initial_offset + perspective_offset + suit  # TODO check that suit casts implicitly to int
	frame_coords = Vector2(value - 1, y)  # Convert value to index
	

func _get_perspective_offset() -> int:
	# Returns the offset, in rows (x vals) from the very first face up tile
	# that matches the given tile set. OR, if face-down, returns the row
	const tp = Common.TilePerspective
	if faceup:
		# These are rows in the spritesheet, which are "y" values.
		# These are the crak rows
		var sprite_perspective_offsets_faceup = {
			tp.BOTTOM: 5,
			tp.TOP: 0,
			tp.LEFT: 10,
			tp.RIGHT: 10
		}
		return sprite_perspective_offsets_faceup[perspective] 
	else:
		# All the face down sprites are in a single row, so these are x values
		var sprite_perspective_offsets_facedown = {
			tp.BOTTOM: 0,
			tp.TOP: 2,
			tp.LEFT: 6,
			tp.RIGHT: 6
		}
		return sprite_perspective_offsets_facedown[perspective]

# Called when the node enters the scene tree for the first time.
func _ready():	
	SignalBus.tile_added_to_hand.connect(_on_hand_collect_tile_into_hand)
	SignalBus.tile_removed_from_hand.connect(_on_hand_remove_tile_from_hand)
	SignalBus.hand_reorder_tiles.connect(_on_hand_reorder_tiles)
	
#	rest_nodes = get_tree().get_nodes_in_group("zone")
#	rest_point = rest_nodes[0].global_position  # Default resting position (may not be necessary)
#	rest_nodes[0].select()  # Update color indicators


func _on_control_gui_input(_event):
	if Input.is_action_just_pressed("click") and not frozen:  # TODO does one of the nodes already have a frozen flag?
		selected = true
		move_to_front()
		faceup = true
		print("--------------------------")
		print("suit: ", Common.Suit.keys()[suit])
		print("value: ", value)
		print("faceup? ", faceup)
		print("perspective: ", perspective)
		print("frame_coords: ", frame_coords)
		print("--------------------------")



func _physics_process(delta):
	if selected:
		if INSTANT_MOVEMENT:
			global_position = get_global_mouse_position()
		else:
			global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)
		#rotation = lerp_angle(rotation, 0, 10 * delta)
#		look_at(get_global_mouse_position())
	#elif in_hand:
	else:
		if INSTANT_MOVEMENT:
			global_position = rest_point
		else:
			global_position = lerp(global_position, rest_point, 10 * delta)
#		rotation = lerp_angle(rotation, 0, 10 * delta)


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			selected = false
#			var shortest_dist = 75
#			for child in rest_nodes:
#				var distance = global_position.distance_to(child.global_position)
#				if distance < shortest_dist:
#					child.select()
#					rest_point = child.global_position
#					shortest_dist = distance


func _on_hand_collect_tile_into_hand(tile: Area2D, lerp_to: Vector2) -> void:
	# Skip if the signal isn't for me.
	if tile != $Area2D:
		return
	
	move_to_front()
	
	in_hand = true

	
	print("[Tile] updating rest point...")
	rest_point = lerp_to
	
	await get_tree().create_timer(0.5).timeout
	perspective = Common.TilePerspective.TOP
	await get_tree().create_timer(0.1).timeout
	faceup = true
	


func _on_hand_remove_tile_from_hand(tile: Area2D):
	# Skip if it isn't for me.
	if tile != $Area2D:
		return

	print("[Tile] out of hand")
	in_hand = false


func _on_hand_reorder_tiles(area: Area2D, new_rest_point: Vector2):
	if area != $Area2D:
		return
	rest_point = new_rest_point

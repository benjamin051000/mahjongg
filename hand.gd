extends Area2D

#signal collect_tile_into_hand(lerp_to: Vector2)
#signal remove_tile_from_hand
# Use the SignalBus from now on!

# TODO what if you draw flowers? There are 8 total (?)
# Well, flowers immediately go face up. So those probably don't count.
const MAX_HAND_SIZE = 14

# TODO find a way to fetch this dynamically
const TILE_PADDING = 4 # on both sides of one tile (so 2x in-between two tiles)
const WIDTH_PER_TILE = 52 + TILE_PADDING * 2
@warning_ignore("integer_division")
const hand_pad = TILE_PADDING + 52 / 2

# This will assist us in reorganizing the tiles when a tile leaves the hand
# (and all tiles on the right must shift left)
class TileInfo:
	var area: Area2D
	var rest_point: Vector2
	func _init(area_: Area2D, rest_point_: Vector2):
		self.area = area_
		self.rest_point = rest_point_
	
var tiles_in_hand = []

var hand_size = 0

func _on_area_entered(area: Area2D) -> void:
	hand_size += 1
	print("hand size:", hand_size)
	
	var x_start_of_hand = position.x - $ColorRect.size.x / 2
	var next_open_slot_x = x_start_of_hand - hand_pad + hand_size * WIDTH_PER_TILE
	var rest_point = Vector2(next_open_slot_x, position.y)  # TODO the next available slot
	
	tiles_in_hand.append(TileInfo.new(area, rest_point))
	SignalBus.tile_added_to_hand.emit(area, rest_point)  # TODO use the class?


func _on_area_exited(area: Area2D):
	hand_size -= 1
	print("hand size:", hand_size)
	SignalBus.tile_removed_from_hand.emit(area)
	# Which tile was this in the list? 
	var removed_tile_idx: int
	for i in range(tiles_in_hand.size()):
		if tiles_in_hand[i].area == area:
			removed_tile_idx = i
			break
	
	var last_rest_point = tiles_in_hand[removed_tile_idx].rest_point
	
	# After this, removed_tile_idx now contains the next Tile.
	tiles_in_hand.remove_at(removed_tile_idx)
	print("removed tile index ", removed_tile_idx)
	# Shift all the tiles to the right of this one by one to the left.
	# TODO what if it's the last tile?
	for i in range(removed_tile_idx, tiles_in_hand.size()):
		print("updating tile ", i)
		var temp = tiles_in_hand[i].rest_point
		tiles_in_hand[i].rest_point = last_rest_point
		last_rest_point = temp
		
		SignalBus.hand_reorder_tiles.emit(tiles_in_hand[i].area, tiles_in_hand[i].rest_point)
	

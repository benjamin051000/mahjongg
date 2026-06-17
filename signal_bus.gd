extends Node
@warning_ignore("unused_signal")
signal tile_added_to_hand(tile: Area2D, new_resting_point: Vector2)
@warning_ignore("unused_signal")
signal hand_reorder_tiles(tile: Area2D, new_resting_point: Vector2) # TODO combine these?
@warning_ignore("unused_signal")
signal tile_removed_from_hand(tile: Area2D)

@warning_ignore("unused_signal")
signal new_game

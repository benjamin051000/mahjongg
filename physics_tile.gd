extends RigidBody2D

var selected = false
#var rest_point
#var rest_nodes = []

# Called when the node enters the scene tree for the first time.
#func _ready():
#	rest_nodes = get_tree().get_nodes_in_group("zone")
#	rest_point = rest_nodes[0].global_position  # Default resting position (may not be necessary)
#	rest_nodes[0].select()  # Update color indicators

func _on_control_gui_input(_event):
	if Input.is_action_just_pressed("click"):
		selected = true
		
#		move_to_front()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)
		rotation = lerp_angle(rotation, 0, 10 * delta)
		freeze = true
#		look_at(get_global_mouse_position())
#	else:
#		global_position = lerp(global_position, rest_point, 10 * delta)
#		rotation = lerp_angle(rotation, 0, 10 * delta)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			selected = false
			freeze = false
#			var shortest_dist = 75
#			for child in rest_nodes:
#				var distance = global_position.distance_to(child.global_position)
#				if distance < shortest_dist:
#					child.select()
#					rest_point = child.global_position
#					shortest_dist = distance



extends Area2D
signal yes_clicked

func _input_event(viewport, event, shape_idx):
	if get_parent().can_interact and event is InputEventMouseButton and event.pressed:
		print("Yes button clicked")
		emit_signal("yes_clicked")

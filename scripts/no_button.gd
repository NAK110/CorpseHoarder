extends Area2D
signal no_clicked

func _input_event(viewport, event, shape_idx):
	if get_parent().can_interact and event is InputEventMouseButton and event.pressed:
		emit_signal("no_clicked")

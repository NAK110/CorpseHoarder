extends Area2D
signal no_clicked

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("No button clicked")
		emit_signal("no_clicked")

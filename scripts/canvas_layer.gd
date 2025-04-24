extends CanvasLayer

@onready var image1 = $TextureRect
@onready var image2 = $TextureRect2

func _ready():
	var tween = create_tween()
	image2.modulate.a = 0.0  # Start invisible
	tween.tween_property(image1, "modulate:a", 0.0, 1.5)  # Fade out
	tween.tween_property(image2, "modulate:a", 1.0, 1.5)  # Fade in

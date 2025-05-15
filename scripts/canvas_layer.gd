extends CanvasLayer

@onready var yes_button = $yes_button
@onready var no_button = $no_button

var characters = []
var angry_variants = {}
var current_index = 0
var is_youKai = false  # Tracks if the current character is a youKai

func _ready():
	randomize()

	characters = [$Grandpa, $Grandpa]
	angry_variants = {
		$Grandpa: $AngryGrandpa
	}

	for npc in characters:
		npc.visible = false
		if angry_variants.has(npc):
			angry_variants[npc].visible = false

	yes_button.yes_clicked.connect(_on_yes_clicked)
	no_button.no_clicked.connect(_on_no_clicked)

	show_next_character()

func show_next_character():
	if current_index >= characters.size():
		print("All characters shown.")
		return

	var npc = characters[current_index]
	npc.modulate.a = 1.0
	npc.scale = Vector2.ONE
	npc.position = Vector2(-npc.texture.get_width(), 12)
	npc.visible = true

	# Randomly decide if this is secretly a youKai
	is_youKai = angry_variants.has(npc) and (randi() % 2 == 0)

	var target_pos = Vector2(244, 12)
	var tween = create_tween()
	tween.tween_property(npc, "position", target_pos, 3.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

func _on_yes_clicked():
	print("Yes clicked")
	handle_decision(true)

func _on_no_clicked():
	print("No clicked")
	handle_decision(false)

func handle_decision(choice: bool):
	var npc = characters[current_index]

	if is_youKai:
		# Transform into youKai
		npc.visible = false
		var youKai = angry_variants[npc]
		youKai.position = npc.position
		youKai.visible = true
		youKai.modulate.a = 1.0
		youKai.scale = Vector2(0.9, 0.9)

		var tween = create_tween()
		tween.tween_property(youKai, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(youKai, "scale", Vector2(1, 1), 0.1).set_delay(0.05)

		tween.connect("finished", func():
			var dir = 1 if choice else -1  # yes = right, no = left
			move_and_continue(youKai, Vector2(100 * dir, -10))
		)
	else:
		var dir = 1 if choice else -1
		move_and_continue(npc, Vector2(100 * dir, -10))

func move_and_continue(target: Control, move_offset: Vector2):
	var tween = create_tween()
	tween.tween_property(target, "position", target.position + move_offset, 2.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", _on_fade_complete)

func _on_fade_complete():
	var prev = characters[current_index]
	prev.visible = false
	if angry_variants.has(prev):
		angry_variants[prev].visible = false

	current_index += 1
	show_next_character()

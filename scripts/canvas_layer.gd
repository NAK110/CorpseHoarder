extends CanvasLayer

@onready var yes_button = $yes_button
@onready var no_button = $no_button
@onready var flash_effect = $FlashEffect
@onready var ghost_counter = $KarmaPanel/GhostCounter
@onready var yokai_counter = $KarmaPanel/YokaiCounter
@onready var total_karma_counter = $KarmaPanel/TotalKarma
@onready var round_left = $KarmaPanel/RoundLeft
@onready var game_overPanel = $GameOverPanel
@onready var gameover_karmaResult = $GameOverPanel/TotalKarmaResult
@onready var play_again_button = $GameOverPanel/PlayAgain
@onready var game_result = $GameOverPanel/GameResult
@onready var mainLayer = $MainLayer
@onready var yokaiScream = $yokaiScream

var characters = []
var angry_variants = {}
var current_index = 0
var is_youKai = false  # Tracks if the current character is a youKai
var ghosts_let_in := 0
var yokai_let_in := 0
var total_karma := 0
var round_count := 0
var can_interact := false


func _ready():
	randomize()
	update_karma_labels()
	characters = [$Grandpa, $Grandpa]
	angry_variants = {
		$Grandpa: $AngryGrandpa
	}
	game_overPanel.visible = false
	for npc in characters:
		npc.visible = false
		if angry_variants.has(npc):
			angry_variants[npc].visible = false

	yes_button.yes_clicked.connect(_on_yes_clicked)
	no_button.no_clicked.connect(_on_no_clicked)
	play_again_button.pressed.connect(_on_play_again_pressed)

	show_next_character()

func _on_character_arrived():
	can_interact = true

func show_next_character():
	if current_index >= characters.size():
		round_count += 1
		update_karma_labels()
		
		if round_count >= 2:
			#print("Game End")
			show_gameOver()
			return
		
		current_index = 0
		characters.shuffle()
		show_next_character()
		return

	var npc = characters[current_index]
	npc.modulate.a = 1.0
	npc.scale = Vector2.ONE
	npc.position = Vector2(-npc.texture.get_width(), 12)
	npc.visible = true

	is_youKai = angry_variants.has(npc) and (randi() % 2 == 0)

	var target_pos = Vector2(244, 12)
	var tween = create_tween()
	tween.tween_property(npc, "position", target_pos, 3.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	can_interact = false  # disable button input
	tween.connect("finished", _on_character_arrived)

func _on_yes_clicked():
	# Check if interaction is allowed
	if not can_interact:
		return
	
	print("Yes clicked")
	handle_decision(true)

func _on_no_clicked():
	# Check if interaction is allowed
	if not can_interact:
		return
	
	print("No clicked")
	handle_decision(false)
	
func _on_play_again_pressed():
	game_overPanel.visible = false
	ghosts_let_in = 0
	yokai_let_in = 0
	total_karma = 0
	round_count = 0
	current_index = 0
	update_karma_labels()
	show_next_character()

	
func update_karma_labels():
	ghost_counter.text = "Ghosts Let In: %d" % ghosts_let_in
	yokai_counter.text = "Yokai Let In: %d" % yokai_let_in
	total_karma_counter.text = "Total Karma: %d" % total_karma
	round_left.text = "Rounds Left: %d" % clamp(2 - round_count, 0, 2)
	
func show_gameOver(): 
	if total_karma < 0: 
		game_result.text = "You Lose!"
	else: 
		game_result.text = "You Win!"
	gameover_karmaResult.text = "Total Karma: %d" % total_karma
	game_overPanel.visible = true

func trigger_flash():
	flash_effect.visible = true
	flash_effect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(flash_effect, "modulate:a", 1.0, 0.1)  # quick flash in
	tween.tween_property(flash_effect, "modulate:a", 0.0, 0.2).set_delay(0.05)  # fade out
	tween.connect("finished", func():
		flash_effect.visible = false
	)

func handle_decision(choice: bool):
	# Disable interaction as soon as a decision is made
	can_interact = false
	
	trigger_flash()
	
	var npc = characters[current_index]

	if is_youKai:
		npc.visible = false
		var youKai = angry_variants[npc]
		youKai.position = npc.position
		youKai.visible = true
		yokaiScream.play()
		#await get_tree().create_timer(5.0).timeout
		#yokaiScream.stop()
		youKai.modulate.a = 1.0
		youKai.scale = Vector2(0.9, 0.9)

		var tween = create_tween()
		tween.tween_property(youKai, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(youKai, "scale", Vector2(1, 1), 0.1).set_delay(0.05)

		tween.connect("finished", func():
			var dir = 1 if choice else -1
			move_and_continue(youKai, Vector2(100 * dir, -10))
		)

		# Only punish if the player clicked YES
		if choice:
			yokai_let_in += 1
			total_karma -= 10

	else:
		# Only reward if the player clicked YES
		if choice:
			ghosts_let_in += 1
			total_karma += 10
		var dir = 1 if choice else -1
		move_and_continue(npc, Vector2(100 * dir, -10))

	update_karma_labels()
	
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

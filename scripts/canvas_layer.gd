extends CanvasLayer

@onready var yes_button = $yes_button
@onready var no_button = $no_button
@onready var flash_effect = $FlashEffect
@onready var ghost_counter = $KarmaPanel/GhostCounter
@onready var yokai_counter = $KarmaPanel/YokaiCounter
@onready var total_karma_counter = $KarmaPanel/TotalKarma
@onready var game_overPanel = $GameOverPanel
@onready var gameover_karmaResult = $GameOverPanel/TotalKarmaResult
@onready var play_again_button = $GameOverPanel/PlayAgain
@onready var game_result = $GameOverPanel/GameResult
@onready var mainLayer = $MainLayer
@onready var yokaiScream = $yokaiScream
@onready var bgm_main = $BGM_Main
@onready var bgm_final = $BGM_Final

# Character configuration using dictionary for cleaner organization
var character_config = {
	"herbalist": {
		"npc": null,
		"angry": null,
		"encounter": "herbalist_encounter"
	},
	"matchmaker": {
		"npc": null,
		"angry": null,
		"encounter": "matchmaker_encounter"
	},
	"blacksmith": {
		"npc": null,
		"angry": null,
		"encounter": "blacksmith_encounter"
	},
	"fisherman": {
		"npc": null,
		"angry": null,
		"encounter": "fisherman_encounter"
	},
	"weaver": {
		"npc": null,
		"angry": null,
		"encounter": "weaver_encounter"
	},
	"seamstress": {
		"npc": null,
		"angry": null,
		"encounter": "seamstress_encounter"
	}
}

var character_order = []
var current_character_key = ""
var current_index = 0
var is_youKai = false
var ghosts_let_in := 0
var yokai_let_in := 0
var total_karma := 0
var can_interact := false
var dialogue_active := false
var pending_choice := false
var game_ending := false
var character_transitioning := false
var choice_dialogue_active := false
var ending_choices_active := false  # NEW: Track when ending choices are shown

# Constants for better maintainability
const GHOST_KARMA_REWARD = 10
const YOKAI_KARMA_PENALTY = -10
const CHARACTER_MOVE_DURATION = 3.0
const FADE_DURATION = 2.0

func _ready():
	initialize_characters()
	setup_connections()
	initialize_game()
	bgm_main.play()

func initialize_characters():
	# Map character references to config
	character_config["herbalist"]["npc"] = $Herbalist
	character_config["herbalist"]["angry"] = $AngryHerbalist
	character_config["matchmaker"]["npc"] = $Matchmaker
	character_config["matchmaker"]["angry"] = $AngryMatchmaker
	character_config["blacksmith"]["npc"] = $BlackSmith
	character_config["blacksmith"]["angry"] = $AngryBlackSmith
	character_config["fisherman"]["npc"] = $FisherMan
	character_config["fisherman"]["angry"] = $AngryFisherMan
	character_config["weaver"]["npc"] = $Weaver
	character_config["weaver"]["angry"] = $AngryWeaver
	character_config["seamstress"]["npc"] = $Seamstress
	character_config["seamstress"]["angry"] = $AngrySeamstress
	
	# Initialize character order in specific sequence
	character_order = ["herbalist", "matchmaker", "blacksmith", "fisherman", "weaver", "seamstress"]
	
	# Hide all characters initially
	for key in character_config:
		var config = character_config[key]
		config["npc"].visible = false
		config["angry"].visible = false

func setup_connections():
	yes_button.yes_clicked.connect(_on_yes_clicked)
	no_button.no_clicked.connect(_on_no_clicked)
	play_again_button.pressed.connect(_on_play_again_pressed)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)

func initialize_game():
	game_ending = false
	character_transitioning = false
	choice_dialogue_active = false
	ending_choices_active = false  # NEW: Reset ending choices flag
	Dialogic.start("game_intro")
	randomize()
	update_karma_labels()
	game_overPanel.visible = false
	show_next_character()

func _on_character_arrived():
	character_transitioning = false
	can_interact = true
	start_character_dialogue()

func start_character_dialogue():
	dialogue_active = true
	can_interact = false
	
	var encounter_timeline = character_config[current_character_key]["encounter"]
	Dialogic.start(encounter_timeline)

func _on_dialogic_signal(argument: String):
	if argument == "buttonClick":
		pending_choice = true
		dialogue_active = false
		can_interact = true
		print("Waiting for yes/no choice...")
	elif argument == "final_karma_check":  # NEW: Handle final karma check signal
		handle_final_karma_check()
	elif argument == "show_ending_choices":  # NEW: Handle ending choices signal
		ending_choices_active = true
		print("Ending choices are now active - waiting for final choice...")

func _on_dialogic_timeline_ended():
	if game_ending and ending_choices_active:  # NEW: Check if ending choices were shown
		# Player made their final choice, show game over
		await get_tree().create_timer(0.5).timeout
		show_gameOver()
		return
	elif game_ending:
		# This was the ending_intro, continue with the chosen ending
		return
		
	if choice_dialogue_active:
		# This was a choice response dialogue, now move character and proceed
		choice_dialogue_active = false
		await get_tree().create_timer(0.5).timeout
		
		# Move the character and continue to next
		var npc = character_config[current_character_key]["npc"]
		var current_character = npc
		if is_youKai:
			current_character = character_config[current_character_key]["angry"]
		
		var last_choice = get_meta("last_choice", false)
		var dir = 1 if last_choice else -1
		move_and_continue(current_character, Vector2(100 * dir, -10))
	elif not pending_choice:
		dialogue_active = false
		# This was an encounter dialogue, don't auto-proceed
		pass

func show_next_character():
	# Check if all characters have been shown
	if current_index >= character_order.size():
		show_ending_dialogue()
		return

	# Prevent overlapping by ensuring previous character is hidden
	hide_all_characters()
	
	current_character_key = character_order[current_index]
	var npc = character_config[current_character_key]["npc"]
	
	# Reset and show character
	npc.modulate.a = 1.0
	npc.scale = Vector2.ONE
	npc.position = Vector2(-npc.texture.get_width(), 12)
	npc.visible = true

	# Randomly decide yokai status (even for seamstress)
	is_youKai = randi() % 2 == 0

	# Switch to final background music when seamstress appears
	if current_character_key == "seamstress":
		bgm_main.stop()
		bgm_final.play()

	var target_pos = Vector2(244, 12)
	character_transitioning = true
	var tween = create_tween()
	tween.tween_property(npc, "position", target_pos, CHARACTER_MOVE_DURATION).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	can_interact = false
	tween.connect("finished", _on_character_arrived)

func hide_all_characters():
	# Hide all characters to prevent overlapping
	for key in character_config:
		var config = character_config[key]
		config["npc"].visible = false
		config["angry"].visible = false

func _on_yes_clicked():
	if not can_interact or not pending_choice or character_transitioning:
		return
	
	handle_choice(true)

func _on_no_clicked():
	if not can_interact or not pending_choice or character_transitioning:
		return
	
	handle_choice(false)

func handle_choice(choice: bool):
	print("Choice made: ", "Yes" if choice else "No")
	pending_choice = false
	can_interact = false
	choice_dialogue_active = true
	
	# Start appropriate dialogue timeline
	var timeline_suffix = get_timeline_suffix(choice)
	var timeline_name = current_character_key + timeline_suffix
	Dialogic.start(timeline_name)
	
	trigger_flash()
	handle_karma_and_visuals(choice)

func get_timeline_suffix(choice: bool) -> String:
	if is_youKai:
		return "_fake_yes" if choice else "_fake_no"
	else:
		return "_real_yes" if choice else "_real_no"

func handle_karma_and_visuals(choice: bool):
	var npc = character_config[current_character_key]["npc"]
	var current_character = npc

	if is_youKai:
		# Transform to yokai
		npc.visible = false
		var youKai = character_config[current_character_key]["angry"]
		youKai.position = npc.position
		youKai.visible = true
		yokaiScream.play()
		current_character = youKai
		
		# Yokai transformation animation
		youKai.modulate.a = 1.0
		youKai.scale = Vector2(0.9, 0.9)

		var tween = create_tween()
		tween.tween_property(youKai, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(youKai, "scale", Vector2(1, 1), 0.1).set_delay(0.05)

		# Only punish if the player clicked YES (let yokai in)
		if choice:
			yokai_let_in += 1
			total_karma += YOKAI_KARMA_PENALTY
	else:
		# Handle real ghost
		if choice:
			ghosts_let_in += 1
			total_karma += GHOST_KARMA_REWARD

	update_karma_labels()
	
	# Store the choice for later use in movement
	set_meta("last_choice", choice)

func move_and_continue(target: Control, move_offset: Vector2):
	character_transitioning = true
	var tween = create_tween()
	tween.tween_property(target, "position", target.position + move_offset, FADE_DURATION).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", _on_fade_complete)

func _on_fade_complete():
	# Hide current character and its angry variant
	var config = character_config[current_character_key]
	config["npc"].visible = false
	config["angry"].visible = false
	character_transitioning = false
	
	proceed_to_next_character()

func proceed_to_next_character():
	current_index += 1
	show_next_character()

func _on_play_again_pressed():
	reset_game()

func reset_game():
	game_overPanel.visible = false
	ghosts_let_in = 0
	yokai_let_in = 0
	total_karma = 0
	current_index = 0
	dialogue_active = false
	pending_choice = false
	game_ending = false
	character_transitioning = false
	choice_dialogue_active = false
	ending_choices_active = false  # NEW: Reset ending choices flag
	
	# Hide all characters
	hide_all_characters()
	
	update_karma_labels()
	show_next_character()

func show_ending_dialogue():
	game_ending = true
	# Make sure all characters are hidden
	hide_all_characters()
	# Start the ending intro timeline which will trigger final_karma_check
	Dialogic.start("ending_intro")
	print("Starting ending sequence...")

func handle_final_karma_check():
	# Determine which ending based on karma
	var ending_timeline = ""
	
	if ghosts_let_in == 6 and yokai_let_in == 0:
		# All correct - let all real ghosts in, rejected all yokai
		ending_timeline = "ending_all_right"
	elif ghosts_let_in == 0 and yokai_let_in == 6:
		# All wrong - let all yokai in, rejected all real ghosts
		ending_timeline = "ending_all_wrong"
	elif total_karma == 0:
		# Perfect balance
		ending_timeline = "ending_tie"
	elif total_karma < 0:
		# Bad ending
		ending_timeline = "ending_bad_karma"
	else:
		# Good ending
		ending_timeline = "ending_good_karma"
	
	print("Final karma check - starting timeline: ", ending_timeline)
	Dialogic.start(ending_timeline)

func update_karma_labels():
	ghost_counter.text = "Ghosts Let In: %d" % ghosts_let_in
	yokai_counter.text = "Yokai Let In: %d" % yokai_let_in
	total_karma_counter.text = "Total Karma: %d" % total_karma
	
func show_gameOver(): 
	game_result.text = "You Win!" if total_karma >= 0 else "You Lose!"
	gameover_karmaResult.text = "Total Karma: %d" % total_karma
	game_overPanel.visible = true

func trigger_flash():
	flash_effect.visible = true
	flash_effect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(flash_effect, "modulate:a", 1.0, 0.1)
	tween.tween_property(flash_effect, "modulate:a", 0.0, 0.2).set_delay(0.05)
	tween.connect("finished", func():
		flash_effect.visible = false
	)

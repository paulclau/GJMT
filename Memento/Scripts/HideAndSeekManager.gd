extends Node3D

enum State { INACTIVE, EYES_CLOSED, SEEKING, RESULT, FREE_ROAM }

@export_group("References")
@export var player: Player
@export var start_position: Marker3D
@export var trigger_area: InterationArea
@export var npcs: Array[HideSeekNPC] = []
@export var teleport_points: Array[Marker3D] = []

@export_group("UI")
@export var screen_fade: ColorRect
@export var countdown_label: Label
@export var seek_timer_label: Label
@export var result_label: Label
@export var found_popup_label: Label
@export var found_popup_duration: float = 1.2
@export var found_popup_fade_time: float = 0.3

@export_group("Timing")
@export var eyes_closed_duration: float = 5.0
@export var seek_time_limit: float = 60.0
@export var fade_duration: float = 1.0
@export var result_display_duration: float = 3.0

var state: State = State.INACTIVE
var found_count: int = 0
var seek_time_remaining: float = 0.0
var found_popup_tween: Tween = null

func _ready() -> void:
	trigger_area.interact = Callable(self, "_on_trigger_interact")
	trigger_area.action_name = "play hide and seek"
	_set_trigger_interactable(true)
	for npc in npcs:
		npc.manager = self
	if screen_fade:
		screen_fade.color.a = 0.0
		screen_fade.hide()
	if countdown_label:
		countdown_label.hide()
	if seek_timer_label:
		seek_timer_label.hide()
	if result_label:
		result_label.hide()
	if found_popup_label:
		found_popup_label.modulate.a = 0.0
		found_popup_label.hide()

func _process(_delta: float) -> void:
	if state != State.SEEKING:
		return
	seek_time_remaining = max(seek_time_remaining - get_process_delta_time(), 0.0)
	_update_seek_label()
	if seek_time_remaining <= 0.0:
		_end_game(false)

# TRIGGER
func _on_trigger_interact() -> void:
	if state == State.INACTIVE:
		_start_game()
	elif state == State.FREE_ROAM:
		_finish_game()

# GAME FLOW
func _start_game() -> void:
	if state != State.INACTIVE:
		return
	var resource = load("res://Dialouge/Classroom.dialogue")
	DialogueManager.show_dialogue_balloon(resource, "start")
	state = State.EYES_CLOSED  # set before any await, blocks re-entry
	found_count = 0
	for npc in npcs:
		npc.reset_found()
		npc.set_interactable(false)
	_set_trigger_interactable(false)
	player.freeze_movement(true)
	await _fade_to_black()
	await _run_countdown(eyes_closed_duration, countdown_label, "Get ready...")
	_teleport_npcs()
	await _fade_from_black()
	_start_seeking()

func _start_seeking() -> void:
	state = State.SEEKING
	seek_time_remaining = seek_time_limit
	if seek_timer_label:
		seek_timer_label.show()
	player.freeze_movement(false)
	
	for npc in npcs:
		npc.set_interactable(true)
	
	_update_seek_label()

func npc_found(_npc: HideSeekNPC) -> void:
	if state != State.SEEKING:
		return
	found_count += 1
	if found_count == 1:
		$"../FmodEventEmitter2D".set_parameter("Mind Progress", "2")
	if found_count == 2:
		$"../FmodEventEmitter2D".set_parameter("Mind Progress", "3")
	if found_count == 3:
		$"../FmodEventEmitter2D".set_parameter("Mind Progress", "4")
	_show_found_popup()
	
	if found_count >= npcs.size():
		_end_game(true)

func _end_game(won: bool) -> void:
	state = State.RESULT
	
	if seek_timer_label:
		seek_timer_label.hide()
	if result_label:
		result_label.text = "You Win!" if won else "You Lose!"
		result_label.show()
	
	await get_tree().create_timer(result_display_duration).timeout
	
	if result_label:
		result_label.hide()
	var resource = load("res://Dialouge/Classroom.dialogue")
	GameState.SeekWin = won
	DialogueManager.show_dialogue_balloon(resource, "seekend")
	_enter_free_roam()

# Player keeps moving freely, NPCs become talkable, trigger switches to
# "finish" — round only resets once the player ends it themselves.
func _enter_free_roam() -> void:
	state = State.FREE_ROAM
	trigger_area.action_name = "finish hide and seek"
	_set_trigger_interactable(true)
	
	for npc in npcs:
		npc.set_interactable(true)

func _finish_game() -> void:
	if not is_instance_valid(start_position):
		push_error("HideAndSeekManager: start_position is not assigned!")
		return
	_set_trigger_interactable(false)
	player.freeze_movement(true)
	await _fade_to_black()
	
	player.velocity = Vector3.ZERO
	player.global_position = start_position.global_position
	player.global_rotation = start_position.global_rotation
	
	for npc in npcs:
		npc.reset_position()
		npc.set_interactable(false)
	trigger_area.action_name = "play hide and seek"
	state = State.INACTIVE
	await _fade_from_black()
	player.freeze_movement(false)
	_set_trigger_interactable(true)

func _set_trigger_interactable(active: bool) -> void:
	trigger_area.monitoring = active
	if not active:
		InteractionManager.unregister_area(trigger_area)

# TELEPORT
func _teleport_npcs() -> void:
	var points := teleport_points.duplicate()
	points.shuffle()
	
	for i in npcs.size():
		if i < points.size():
			npcs[i].global_position = points[i].global_position
		else:
			push_warning("HideAndSeekManager: not enough teleport_points for all NPCs.")

# FADE
func _fade_to_black() -> void:
	if not screen_fade:
		return
	screen_fade.show()
	var tween := create_tween()
	tween.tween_property(screen_fade, "color:a", 1.0, fade_duration)
	await tween.finished

func _fade_from_black() -> void:
	if not screen_fade:
		return
	var tween := create_tween()
	tween.tween_property(screen_fade, "color:a", 0.0, fade_duration)
	await tween.finished
	screen_fade.hide()

# COUNTDOWN
func _run_countdown(duration: float, label: Label, prefix: String) -> void:
	if not label:
		await get_tree().create_timer(duration).timeout
		return
	
	label.show()
	var start_time := Time.get_ticks_msec()
	var remaining := duration
	
	while remaining > 0.0:
		var elapsed := (Time.get_ticks_msec() - start_time) / 1000.0
		remaining = duration - elapsed
		label.text = "%s %d" % [prefix, ceil(max(remaining, 0.0))]
		await get_tree().process_frame
	label.hide()

func _update_seek_label() -> void:
	if seek_timer_label:
		seek_timer_label.text = "%d" % ceil(seek_time_remaining)

# FOUND POPUP
func _show_found_popup() -> void:
	if not found_popup_label:
		return
	
	found_popup_label.text = "Found %d/%d!" % [found_count, npcs.size()]
	found_popup_label.show()
	if found_popup_tween and found_popup_tween.is_valid():
		found_popup_tween.kill()
	found_popup_tween = create_tween()
	found_popup_tween.tween_property(found_popup_label, "modulate:a", 1.0, found_popup_fade_time)
	found_popup_tween.tween_interval(found_popup_duration)
	found_popup_tween.tween_property(found_popup_label, "modulate:a", 0.0, found_popup_fade_time)
	found_popup_tween.tween_callback(found_popup_label.hide)

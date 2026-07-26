extends CanvasLayer

signal loading_screen_ready

@export var animation_player: AnimationPlayer
@export var progress_bar: ProgressBar

func _ready() -> void:
	if progress_bar:
		progress_bar.min_value = 0.0
		progress_bar.max_value = 1.0
		progress_bar.value = 0.0

	await animation_player.animation_finished
	loading_screen_ready.emit()

func _on_progress_changed(new_value: float) -> void:
	if progress_bar:
		progress_bar.value = new_value

func _on_load_finished() -> void:
	if progress_bar:
		progress_bar.value = 1.0
	animation_player.play_backwards("transition")
	await animation_player.animation_finished
	queue_free()

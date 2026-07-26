extends Node3D

@export var target_scene_path: String
@export var prompt_text: String = "travel"

@onready var interaction_area: InterationArea = $InteractionArea

func _ready() -> void:
	interaction_area.action_name = prompt_text
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact() -> void:
	if target_scene_path.is_empty():
		push_warning("SceneTransitionArea: no target_scene_path set.")
		return
	SceneLoader.load_scene(target_scene_path)

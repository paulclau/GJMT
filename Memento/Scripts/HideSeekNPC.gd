extends Node3D
class_name HideSeekNPC

@onready var interaction_area: InterationArea = $InteractionArea

var manager: Node = null # assigned by HideAndSeekManager at startup
var found: bool = false
var start_position: Vector3
var start_rotation: Vector3

func _ready() -> void:
	start_position = global_position
	start_rotation = rotation
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.action_name = "tag"

func _on_interact() -> void:
	if found:
		return
	found = true
	interaction_area.monitoring = false # stop it from re-triggering once tagged
	if is_instance_valid(manager):
		manager.npc_found(self)

func reset_found() -> void:
	found = false
	interaction_area.monitoring = true

func reset_position() -> void:
	global_position = start_position
	rotation = start_rotation

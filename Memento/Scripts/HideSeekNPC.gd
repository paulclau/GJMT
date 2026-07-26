extends Node3D
class_name HideSeekNPC

@onready var interaction_area: InterationArea = $InteractionArea

var manager: Node = null
var found: bool = false
var start_position: Vector3
var start_rotation: Vector3

func _ready() -> void:
	start_position = global_position
	start_rotation = rotation
	_set_tag_mode()
	set_interactable(false)

func _on_tag_interact() -> void:
	if found:
		return
	found = true
	if is_instance_valid(manager):
		manager.npc_found(self)
	_set_dialogue_mode()

# just in case for a future dialogue system
func _on_dialogue_interact() -> void:
	print("(dialogue not implemented yet)")

func _set_tag_mode() -> void:
	interaction_area.action_name = "tag"
	interaction_area.interact = Callable(self, "_on_tag_interact")

func _set_dialogue_mode() -> void:
	interaction_area.action_name = "talk"
	interaction_area.interact = Callable(self, "_on_dialogue_interact")

# Disable is instant, enable waits a physics frame so monitoring has
# actually kicked in before we check overlap and register
func set_interactable(active: bool) -> void:
	interaction_area.monitoring = active
	if not active:
		InteractionManager.unregister_area(interaction_area)
		return
	_register_when_overlapping()

func _register_when_overlapping() -> void:
	await get_tree().physics_frame
	for body in interaction_area.get_overlapping_bodies():
		if body is CharacterBody3D:
			InteractionManager.register_area(interaction_area)
			break

func reset_found() -> void:
	found = false
	_set_tag_mode()

func reset_position() -> void:
	global_position = start_position
	rotation = start_rotation

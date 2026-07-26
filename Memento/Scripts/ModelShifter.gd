extends Node3D

@export var broken_model: PackedScene;

var has_broken: bool = false
var broken_model_instance: Node3D

func _ready() -> void:
	# Pre-instantiate up front
	broken_model_instance = broken_model.instantiate()
	get_parent().call_deferred("add_child", broken_model_instance)
	broken_model_instance.transform = self.transform
	broken_model_instance.hide()
	broken_model_instance.process_mode = Node.PROCESS_MODE_DISABLED

func _on_area_3d_body_entered(body: Node3D) -> void:
	if has_broken:
		return
	if not body is CharacterBody3D:
		return
	
	_break_pinata()

func _break_pinata() -> void:
	has_broken = true
	
	broken_model_instance.process_mode = Node.PROCESS_MODE_INHERIT
	broken_model_instance.show()
	
	self.queue_free()

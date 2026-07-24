extends Area3D
class_name InterationArea

@export var action_name: String = "interact"

var interact: Callable = func():
	pass

func _on_body_entered(_body: Node3D) -> void:
	if _body is CharacterBody3D:
		InteractionManager.register_area(self)


func _on_body_exited(_body: Node3D) -> void:
	if _body is CharacterBody3D:
		InteractionManager.unregister_area(self)

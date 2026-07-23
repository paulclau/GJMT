extends Node3D
class_name PlayerVisuals

@onready var model : PlayerModel

@onready var mesh = $MeshInstance3D

func accept_model(_model : PlayerModel):
	model = _model
	mesh.skeleton = _model.get_path()

# this script generates a set of pillows surrounding the player.
extends Node

var pillow_scene = preload("res://Scenes/Pillow/Pillow.tscn")
var player_ref:Player;
var _player_position:Vector3;
var _current_velocity:Vector3;
var pillows = [];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(!pillow_scene):
		print("Error: No Pillow scene Set")
		return;
	
	player_ref = get_tree().get_first_node_in_group("player");
	
	if(!player_ref):
		print("Error: NO PLAYER WTH")
		return;
	
	_player_position = player_ref.global_position;
	_current_velocity = player_ref.velocity;
	
	create_pillow();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!player_ref):
		return;
	_player_position = player_ref.global_position;
	_current_velocity = player_ref.velocity;
	if(_current_velocity.length() != 0):
		create_pillow();
	
func create_pillow():
	var player_bounds:AABB = player_ref.get_player_bounds();
	player_bounds = player_bounds.abs();
	var player_halfheight = player_bounds.get_longest_axis_size() / 2;
	
	var PillowPosition = Vector3(
		_player_position.x,
		_player_position.y - player_halfheight - 0.1, # variance of 0.1m
		_player_position.z)
	# check if position is valid
	
	var new_pillow = pillow_scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED) as Node3D;
	get_parent().add_child.call_deferred(new_pillow);
	new_pillow.global_position = PillowPosition;

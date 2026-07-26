# this script generates a set of pillows surrounding the player.
extends Node

var pillow_scene = preload("res://Scenes/Pillow/Pillow.tscn")
var player_ref: Player
var _player_position: Vector3
var _current_velocity: Vector3
var is_spawning: bool = false

@export var SpawnInterval: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not pillow_scene:
		print("Error: No Pillow scene Set")
		return
	
	player_ref = get_tree().get_first_node_in_group("player")
	
	if not player_ref:
		print("Error: NO PLAYER WTH")
		return
	
	_player_position = player_ref.global_position
	_current_velocity = player_ref.velocity
	
	create_pillow()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not player_ref:
		return
	_player_position = player_ref.global_position
	_current_velocity = player_ref.velocity
	
	if _current_velocity.length() > 0 and not is_spawning:
		create_pillow()
	
func create_pillow() -> void:
	is_spawning = true
	
	await get_tree().create_timer(SpawnInterval).timeout
	
	if not is_instance_valid(player_ref):
		is_spawning = false
		return

	var player_bounds: AABB = player_ref.get_player_bounds()
	player_bounds = player_bounds.abs()
	var player_halfheight = player_bounds.get_longest_axis_size() / 2
	
	var current_pos = player_ref.global_position
	var PillowPosition = Vector3(
		current_pos.x,
		current_pos.y - player_halfheight - 0.25,
		current_pos.z
	)
	
	var new_pillow = pillow_scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED) as Node3D
	get_parent().add_child.call_deferred(new_pillow)
	new_pillow.global_rotation = player_ref.global_rotation;
	new_pillow.global_position = PillowPosition
	
	is_spawning = false # Unlock the function

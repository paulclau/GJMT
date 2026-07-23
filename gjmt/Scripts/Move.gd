extends Node
class_name Move

#all move flags and variables here
var player : CharacterBody3D
@export var animation : String
@export var move_name : String


var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float

var has_forced_move : bool = false
var forced_move : String = "none, drop error please"

@export var tracking_angular_speed : float = 10

var enter_state_time : float
var area_awareness : AreaAwareness

static var moves_priority : Dictionary = {
	"idle" : 1,
	"run" : 2,
	"sprint" : 3,
	"jump_run" : 10,
	"jump_sprint" : 10,
	"midair" : 10,
	"landing_run" : 10,
	"landing_sprint" : 10
}

static func moves_priority_sort(a : String, b : String):
	if moves_priority[a] > moves_priority[b]:
		return true
	else:
		return false

func check_relevance(input: InputPackage) -> String:
	if has_forced_move:
		has_forced_move = false
		return forced_move 
	
	#check_combos(input)
	
	return default_lifecycle(input)

func default_lifecycle(_input : InputPackage) -> String:
	return animation

func works_longer_than(time : float) -> bool:
	if get_progress() >= time:
		return true
	return false

func works_less_than(time : float) -> bool:
	if get_progress() < time:
		return true
	return false

func works_between(start : float, finish: float) -> bool:
	var progress = get_progress()
	if progress >= start and progress <= finish:
		return true
	return false

func try_force_move(new_forced_move : String):
	if not has_forced_move:
		has_forced_move = true
		forced_move =  new_forced_move
	elif moves_priority[new_forced_move] >= moves_priority[forced_move]:
		forced_move = new_forced_move

func get_progress() -> float:
	var now = Time.get_unix_time_from_system()
	return now - enter_state_time

func update(_input : InputPackage, _delta : float):
	pass

func on_enter_state():
	pass

func on_exit_state():
	pass

func mark_enter_state():
	enter_state_time = Time.get_unix_time_from_system()

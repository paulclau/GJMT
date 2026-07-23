extends Node3D
class_name PlayerModel

@onready var player = $".."
@onready var area_awareness 
@onready var resources

var current_move : Move

@onready var moves = {
	"idle" : $States/Idle,
	"run" : $States/Run,
	"sprint" : $States/Sprint,
	"jump_run" : $States/JumpRun,
	"jump_sprint" : $States/JumpSprint,
	"midair" : $States/Midair,
	"landing_run" : $States/LandingRun,
	"landing_sprint" : $States/LandingSprint
}

func _ready() -> void:
	current_move = moves["idle"]
	for move in moves.values():
		move.player = player
		move.area_awareness = area_awareness


func update(input : InputPackage, delta : float):
	input = area_awareness.add_context(input)
	var relevance = current_move.check_relevance(input)
	if relevance != "okay":
		switch_to(relevance)
	current_move.update(input, delta)

func switch_to(state : String):
	if current_move.move_name == state:
		return
	
	print(current_move.move_name + " -> " + state)
	current_move.on_exit_state()
	current_move = moves[state]
	current_move.on_enter_state()
	current_move.mark_enter_state()

extends Node3D
@onready var life_timer:Timer;
@export var lifetime:float;
var _b_is_player_ontop = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	life_timer = Timer.new();
	add_child(life_timer);
	life_timer.one_shot = true;
	life_timer.timeout.connect(end_of_life);
	life_timer.start(lifetime);
	
func end_of_life():
	if(_b_is_player_ontop):
		life_timer.start(lifetime);
		return;
	queue_free();

func _on_area_3d_body_entered(body: Node3D) -> void:
	if(body is CharacterBody3D):
		_b_is_player_ontop = true;

func _on_area_3d_body_exited(body: Node3D) -> void:
	if(body is CharacterBody3D):
		_b_is_player_ontop = false;

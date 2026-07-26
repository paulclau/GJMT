extends Node3D
@onready var life_timer:Timer;
@export var lifetime:float;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	life_timer = Timer.new();
	add_child(life_timer);
	life_timer.one_shot = true;
	life_timer.timeout.connect(queue_free);
	life_timer.start(lifetime);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass;

extends Node3D

@onready var label = $Label

const base_text = "[E] to "

var active_areas = []
var can_interact = true


func get_player():
	return get_tree().get_first_node_in_group("player")


func register_area(area):
	if is_instance_valid(area):
		active_areas.push_back(area)


func unregister_area(area):
	var index = active_areas.find(area)
	if index != -1:
		active_areas.remove_at(index)


func _process(_delta):
	# Remove deleted/freed areas
	active_areas = active_areas.filter(
		func(area):
			return is_instance_valid(area)
	)
	var player = get_player()
	if !is_instance_valid(player):
		label.hide()
		return
	if active_areas.size() > 0 and can_interact:
		active_areas.sort_custom(_sort_by_distance_to_player)
		if !is_instance_valid(active_areas[0]):
			label.hide()
			return
		var camera = get_viewport().get_camera_3d()
		if !camera:
			label.hide()
			return
		var area_pos = active_areas[0].global_position
		# Prevent unproject_position errors
		if camera.is_position_behind(area_pos):
			label.hide()
			return
		label.text = base_text + active_areas[0].action_name
		var screen_pos = camera.unproject_position(area_pos)
		label.global_position = screen_pos
		label.global_position.y -= 36
		label.global_position.x -= label.size.x / 2
		label.show()
	else:
		label.hide()


func _sort_by_distance_to_player(area1, area2):
	var player = get_player()
	if !is_instance_valid(player):
		return false
	
	if !is_instance_valid(area1):
		return false
	
	if !is_instance_valid(area2):
		return true
	
	var area1_to_player = player.global_position.distance_to(area1.global_position)
	
	var area2_to_player = player.global_position.distance_to(area2.global_position)
	return area1_to_player < area2_to_player


func _input(event):
	if event.is_action_pressed("interact") and can_interact:
		# Clean invalid areas before interacting
		active_areas = active_areas.filter(
			func(area):
				return is_instance_valid(area)
		)
		
		if active_areas.size() > 0:
			can_interact = false
			label.hide()
			
			if is_instance_valid(active_areas[0]):
				await active_areas[0].interact.call()
				$FmodEventEmitter3D.play()
			can_interact = true

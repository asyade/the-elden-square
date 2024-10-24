class_name Component2D extends Node2D

@onready var parent = get_parent()

func get_component(component_type):
	var results = parent.get_children().filter(func(c): return is_instance_of(c, component_type))
	
	if results.size() == 0:
		return null
	elif results.size() > 1:
		printerr("get_component() returned more than one component");
		return null
	return results[0]

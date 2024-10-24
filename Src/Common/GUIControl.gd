class_name GUIControl extends Control

func get_child_control(control_type):
	var results = get_children().filter(func(c): return is_instance_of(c, control_type))
	
	if results.size() == 0:
		return null
	elif results.size() > 1:
		printerr("get_child_control() returned more than one component");
		return null
	return results[0]

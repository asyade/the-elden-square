class_name ComponentMobAim extends Component2D

enum FocusMode {
	DISTANCE,
}

var current_focus: ComposedCharacter2D:
	set(value):
		current_focus = value
		current_target = current_focus.get_component(TargetableEntity)

var current_target: TargetableEntity
var distance_to_current_focus: float											= -1


func focus_step(delta: float) -> ComposedCharacter2D:
	var targetable_entities = get_tree().get_nodes_in_group("entity_player_1")
	
	if current_focus != null && targetable_entities.find(current_focus) != -1:
		pass
	elif targetable_entities.size() > 0:
		current_focus = targetable_entities[0]

	if current_focus == null:
		distance_to_current_focus = -1
	else:
		distance_to_current_focus = current_focus.global_position.distance_to(global_position)
	
	return current_focus

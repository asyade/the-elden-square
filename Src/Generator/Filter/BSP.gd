class_name BSP extends Node

var world: World
var steps: int = 0

func _init(world: World) -> void:
	self.world = world
	world.sections = [World.Section.new(Rect2i(0, 0, world.size.x, world.size.y), world)]

func step() -> bool:
	self.steps += 1
	var new_sections: Array[World.Section] = []
	var nbr_section_before = world.sections.size()
	
	var nbr_section_not_match_end_criterias: int = 0
	
	var end = world.sections.size()
	while end != 0:
		end -= 1
		var section = world.sections[end]
		var splited = split_section(section)
		for s in splited:
			if !s.match_end_criterias():
				nbr_section_not_match_end_criterias += 1
			s.assign_node()
		new_sections.append_array(splited)
	world.sections = new_sections

	for idx in world.sections.size():
		world.sections[idx].index = idx

	var section_added = world.sections.size() - nbr_section_before
	for node: World.WorldNode in world.all_nodes.values():
		if node.section == null:
			print("Node `%s` does not have any section affected" % node.name)
	
	return nbr_section_not_match_end_criterias > 0

func split_section(section: World.Section) -> Array[World.Section]:
	var min_size = section.section_min_size()
	var can_hsplit = section.rect.size.x >= 2 * min_size.x
	var can_vsplit = section.rect.size.y >= 2 * min_size.y

	var split_dir: int = -1
	if can_vsplit && can_hsplit:
		if world.rng.randf() > 0.5:
			split_dir = 1
		else:
			split_dir = 0
	elif can_hsplit || can_vsplit:
		split_dir = can_hsplit

	if split_dir == -1:
		return [section]
	else:
		var offset;
		if split_dir == 1:
			offset = world.rng.randf_range(min_size.x, section.rect.size.x - min_size.x)
		else:
			offset = world.rng.randf_range(min_size.y, section.rect.size.y - min_size.y)
		return section.split_at(split_dir == 1, offset)

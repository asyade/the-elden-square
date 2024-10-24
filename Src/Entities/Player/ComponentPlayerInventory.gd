class_name ComponentPlayerInventory extends Component2D

var all_icons: SpriteFrames = ResourceLoader.load("res://Assets/Items/all_item_icons.tres")

enum ItemCategory {
	Craft = 0,
	Consumable = 1,
	Weapon = 2,
	PrimaryWeapon = 3,
	SecondaryWeapon = 4,
	Card = 5,
}

var all_items = {
	0: {
		"icon": all_icons.get_frame_texture("default", 99),
		"name": "Wooden Bow",
		"category": ItemCategory.SecondaryWeapon
	},
	10: {
		"icon": all_icons.get_frame_texture("default", 80),
		"name": "Classic Sword",
		"category": ItemCategory.PrimaryWeapon
	},
	20: {
		"icon": all_icons.get_frame_texture("default", 144),
		"name": "Health potion",
		"category": ItemCategory.Consumable,
		"stackable": true
	},
	30: {
		"icon": all_icons.get_frame_texture("default", 208),
		"name": "Meloong",
		"description": "Incrass the range of melee weapon",
		"category": ItemCategory.Card,
		"stackable": true
	},
	31: {
		"icon": all_icons.get_frame_texture("default", 208),
		"name": "Meloong",
		"description": "Incrass the range of melee weapon",
		"category": ItemCategory.Card,
		"stackable": true
	},
	32: {
		"icon": all_icons.get_frame_texture("default", 209),
		"name": "Meloong",
		"description": "Incrass the range of melee weapon",
		"category": ItemCategory.Card,
		"stackable": true
	},
	33: {
		"icon": all_icons.get_frame_texture("default", 210),
		"name": "Meloong",
		"description": "Incrass the range of melee weapon",
		"category": ItemCategory.Card,
		"stackable": true
	},
	34: {
		"icon": all_icons.get_frame_texture("default", 211),
		"name": "Meloong",
		"description": "Incrass the range of melee weapon",
		"category": ItemCategory.Card,
		"stackable": true
	},
	35: {
		"icon": all_icons.get_frame_texture("default", 212),
		"name": "Meloong",
		"description": "Incrass the range of melee weapon",
		"category": ItemCategory.Card,
		"stackable": true
	}
}

class Slot:
	var name: StringName
	var allowed_categories: Array
	var enabled: bool

	var item_id: int
	var icon: Texture2D
	
	func _init(name, allowed_categories = [], enabled = true, item_id = -1) -> void:
		self.name = name
		self.allowed_categories = allowed_categories
		self.enabled = enabled
		self.item_id = item_id
		pass

class StackedSlot:
	var current_idx: int = -1
	var slots: Array

var slots = {
	"left_hand": Slot.new("left_hand", [ItemCategory.PrimaryWeapon]),
	"right_hand": Slot.new("right_hand", [ItemCategory.SecondaryWeapon]),
	"consumable_1": Slot.new("consumable_1", [ItemCategory.Consumable]),
	"consumable_2": Slot.new("consumable_2", [ItemCategory.Consumable]),
	"consumable_3": Slot.new("consumable_3", [ItemCategory.Consumable]),
	"consumable_4": Slot.new("consumable_4", [ItemCategory.Consumable]),
	"card_1": Slot.new("card_1", [ItemCategory.Card]),
	"card_2": Slot.new("card_2", [ItemCategory.Card]),
	"card_3": Slot.new("card_3", [ItemCategory.Card]),
	"card_4": Slot.new("card_4", [ItemCategory.Card]),
}

var items = {
	0: -1,
	10: -1,
	30: -1,
	31: -1,
	32: -1,
	33: -1,
}

func find_slots_for_category(item_category: ItemCategory):
	return slots.values().filter(func(x: Slot): return x.allowed_categories.find(item_category) != -1)

func fill_slot(slot_name: String, item_id: int):
	var slot: Slot = slots[slot_name]
	if !slot:
		printerr("unable to fill slot: slot `%` does not exists" % slot_name)
		return false
	
	if item_id == -1:
		slot.item_id = -1
		slot.icon = null
	else:
		var item = all_items[item_id]
		if !item:
			printerr("unable to fill slot: item with id `%` does not exists" % item_id)
			return false
		print(item.icon)
		slot.item_id = item_id
		slot.icon = item.icon
	return true

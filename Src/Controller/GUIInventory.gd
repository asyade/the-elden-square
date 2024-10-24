class_name GUIInventory extends GUIControl

enum Status {
	CLOSE,
	OPEN,
	ITEM_SLOT_SELECTION,
}

const UI_SLOT_PREFIX = "slot_"

@export var inventory: ComponentPlayerInventory = null

var inventory_is_sync = false

var item_list: ItemList

var ui_slots: Dictionary

var status: Status:
	set(value):
		status = value
		if status == Status.OPEN:
			for slot in ui_slots.values():
				slot.status = SlotBase.UISlotStatus.DISABLED
			sync_inventory()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	item_list = get_node("ItemList")
	item_list.item_activated.connect(item_activated)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !visible || !inventory:
		return
		
	if !ui_slots:
		bind_slots()
		
	if !inventory_is_sync:
		sync_inventory()
		
	var input_direction = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	
	
	pass

func sync_inventory():
	if !inventory:
		return

	inventory_is_sync = true
	
	item_list.clear()
	for item_id in inventory.items.keys():
		var item = inventory.all_items[item_id]
		var item_index = item_list.add_item("", item.icon)
		item_list.set_item_metadata(item_index, item_id)
	
	pass

# Bind ui slot instance of the scene to the actual inventory slots from the player's coumpound
func bind_slots():
	for slot_name in inventory.slots:
		var slot_instance_name = "%s%s" % [UI_SLOT_PREFIX, slot_name]
		var component: SlotBase = get_node(slot_instance_name)
		
		if !component:
			printerr("`%s` is not a direct child of the inventory this slot will not be reachable !" % slot_name)
		else:
			ui_slots[slot_name] = component
			component.slot_name = slot_name
			component.icon = inventory.slots[slot_name].icon
			component.activated.connect(slot_activated)
	pass

var current_selected_item_id = null
func item_activated(index):
	var item_id = item_list.get_item_metadata(index)
	var item = inventory.all_items[item_id]
	if !item:
		printerr("Can't find coresponding item into the inventory")
		return
	var available_slots = inventory.find_slots_for_category(item.category)
	var available_slots_name = available_slots.map(func(x): return x.name)
	current_selected_item_id = item_id
	for ui_slot in ui_slots.keys():
		if available_slots_name.find(ui_slot) != -1:
			ui_slots[ui_slot].status = SlotBase.UISlotStatus.ENABLED
		else:
			ui_slots[ui_slot].status = SlotBase.UISlotStatus.DISABLED

	status = Status.ITEM_SLOT_SELECTION
	pass

func slot_activated(name):
	if inventory.fill_slot(name, current_selected_item_id):
		ui_slots[name].icon = inventory.slots[name].icon
	pass

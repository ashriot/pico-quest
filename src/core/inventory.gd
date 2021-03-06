extends Resource
class_name Inventory

signal inventory_changed
signal gold_changed

export var items = Array() setget set_items, get_items
export var gold: int setget set_gold

func set_gold(value) -> void:
	gold = value
	emit_signal("gold_changed", gold)

func set_items(newitems: Array) -> void:
	for item in newitems:
		var item_resource = ItemDb.get_item(item[0])
		if not item_resource:
			print("ERROR: Could not find an item called: ", item[0])
			return
		item_resource.uses = item[1]
		items.append(item_resource)
	emit_signal("inventory_changed", self)

func get_items():
	return items

func get_item(index):
	return items[index]

func add_item(item_name, uses = -1):
	var item = ItemDb.get_item(item_name)
	if not item:
		print("ERROR: Could not find an item called: ", item_name)
		return
	item.uses = item.max_uses if uses == -1 else uses
	items.append(item)
	items.sort_custom(InventorySorter, "sort_by_name")
	emit_signal("inventory_changed", self)

func remove_item(item: Item):
	print("removing: ", item.name)
	items.erase(item)
	emit_signal("inventory_changed", self)

class InventorySorter:
	static func sort_by_name(a, b):
		if a.name < b.name:
			return true
		return false

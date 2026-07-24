extends Node

## Central store for flags and inventory. Conditions read from this,
## Effects write to this. Keeps ActionAreas fully decoupled from each other.

signal flag_changed(flag_name: String, value: bool)
signal item_added(item_id: String)
signal item_removed(item_id: String)

var _flags: Dictionary = {}       # String -> bool
var _inventory: Array[String] = []


# ============================================================
# FLAGS
# ============================================================
func set_flag(flag_name: String, value: bool = true) -> void:
	_flags[flag_name] = value
	flag_changed.emit(flag_name, value)


func get_flag(flag_name: String) -> bool:
	return _flags.get(flag_name, false)


# ============================================================
# INVENTORY
# ============================================================
func add_item(item_id: String) -> void:
	if not has_item(item_id):
		_inventory.append(item_id)
		item_added.emit(item_id)


func remove_item(item_id: String) -> void:
	if has_item(item_id):
		_inventory.erase(item_id)
		item_removed.emit(item_id)


func has_item(item_id: String) -> bool:
	return _inventory.has(item_id)

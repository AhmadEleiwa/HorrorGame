extends ActionCondition
class_name HasItemCondition

@export var item_id: String = ""

func is_met() -> bool:
	return GameState.has_item(item_id)

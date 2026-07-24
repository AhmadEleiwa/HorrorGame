extends ActionCondition
class_name FlagSetCondition

@export var flag_name: String = ""
@export var required_value: bool = true

func is_met() -> bool:
	return GameState.get_flag(flag_name) == required_value

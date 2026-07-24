extends Resource
class_name ActionCondition

## Base class for any condition an ActionArea checks before running its
## effect. Override `is_met()` in subclasses. Keep conditions stateless
## and side-effect-free — they only read, never write, game state.

func is_met() -> bool:
	push_warning("ActionCondition.is_met() not overridden in %s" % resource_path)
	return true

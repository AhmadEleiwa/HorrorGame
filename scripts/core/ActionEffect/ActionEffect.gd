extends Resource
class_name ActionEffect

## Base class for anything an ActionArea does once triggered and its
## conditions pass. Override `execute()`. Effects may be async (await-able)
## for cutscenes/animations — ActionArea awaits execute() before finishing.

func execute(player: Node) -> void:
	push_warning("ActionEffect.execute() not overridden in %s" % resource_path)

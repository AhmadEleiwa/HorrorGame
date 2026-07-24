extends Resource
class_name PathFormater
static func get_paths(path:NodePath) -> NodePath:
	
	var path_str := str(path)
	while path_str.begins_with("../"):
		path_str = path_str.trim_prefix("../")
	return path_str
	

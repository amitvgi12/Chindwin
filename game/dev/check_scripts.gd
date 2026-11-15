extends SceneTree
## Dev tool, not part of the game. Loads every script under the folders below
## and exits 1 if any of them fails to compile.
##
## Untyped code counts as a failure, because project.godot turns the
## untyped-declaration warning into an error.
##
## Run with: make scripts-check

const ROOTS: Array[String] = ["res://src", "res://test", "res://dev"]


func _initialize() -> void:
	var failed: Array[String] = []
	var count: int = 0
	for root: String in ROOTS:
		for path: String in _scripts_under(root):
			count += 1
			var script: GDScript = load(path) as GDScript
			if script == null or not script.can_instantiate():
				failed.append(path)
	for path: String in failed:
		print("DOES NOT COMPILE: %s" % path)
	print("scripts-check: %d checked, %d failed" % [count, failed.size()])
	quit(1 if not failed.is_empty() else 0)


func _scripts_under(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	if not DirAccess.dir_exists_absolute(dir_path):
		return found
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".gd"):
			found.append(dir_path.path_join(file_name))
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_scripts_under(dir_path.path_join(sub_dir)))
	return found

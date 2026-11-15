class_name Scenario
extends RefCounted
## A map and the soldiers on it, read from a JSON file in data/scenarios/.
## Check `errors` after loading: a scenario with errors must not be used.


class SoldierSpec:
	extends RefCounted
	var side: SimSoldier.BattleSide
	var team_id: int
	var cell: Vector2i


## Translation key for the scenario's display name.
var name_key: String = ""
var width: int = 0
var height: int = 0
var blocked: Array[Vector2i] = []
var soldiers: Array[SoldierSpec] = []
## Problems found while loading, in plain words. Empty means the scenario is usable.
var errors: Array[String] = []


static func load_file(path: String) -> Scenario:
	if not FileAccess.file_exists(path):
		var missing: Scenario = Scenario.new()
		missing.errors.append("file not found: %s" % path)
		return missing
	return from_json_text(FileAccess.get_file_as_string(path))


static func from_json_text(text: String) -> Scenario:
	var scenario: Scenario = Scenario.new()
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		scenario.errors.append("the file is not a JSON object")
		return scenario
	var data: Dictionary = parsed
	scenario.name_key = str(data.get("name_key", ""))
	scenario.width = _as_int(data.get("width"), "width", scenario.errors)
	scenario.height = _as_int(data.get("height"), "height", scenario.errors)
	if scenario.width < 1 or scenario.height < 1:
		scenario.errors.append("width and height must be 1 or more")
		return scenario
	scenario._read_blocked_rects(data.get("blocked_rects", []))
	scenario._read_soldiers(data.get("soldiers", []))
	return scenario


func is_valid() -> bool:
	return errors.is_empty()


func _read_blocked_rects(value: Variant) -> void:
	if not value is Array:
		errors.append("blocked_rects must be a list")
		return
	var rects: Array = value
	var seen: Dictionary[Vector2i, bool] = {}
	for entry: Variant in rects:
		var numbers: Array[int] = _as_int_list(entry, 4, "blocked_rects entry", errors)
		if numbers.is_empty():
			continue
		for y: int in range(numbers[1], numbers[1] + numbers[3]):
			for x: int in range(numbers[0], numbers[0] + numbers[2]):
				var cell: Vector2i = Vector2i(x, y)
				if not seen.has(cell):
					seen[cell] = true
					blocked.append(cell)


func _read_soldiers(value: Variant) -> void:
	if not value is Array:
		errors.append("soldiers must be a list")
		return
	var entries: Array = value
	var occupied: Dictionary[Vector2i, bool] = {}
	for entry: Variant in entries:
		if not entry is Dictionary:
			errors.append("each soldier must be an object")
			continue
		var fields: Dictionary = entry
		var spec: SoldierSpec = SoldierSpec.new()
		var side_name: String = str(fields.get("side", ""))
		if side_name == "player":
			spec.side = SimSoldier.BattleSide.PLAYER
		elif side_name == "enemy":
			spec.side = SimSoldier.BattleSide.ENEMY
		else:
			errors.append("soldier side must be 'player' or 'enemy', got '%s'" % side_name)
			continue
		spec.team_id = _as_int(fields.get("team"), "soldier team", errors)
		var position: Array[int] = _as_int_list(fields.get("cell"), 2, "soldier cell", errors)
		if position.is_empty():
			continue
		spec.cell = Vector2i(position[0], position[1])
		if spec.cell.x < 0 or spec.cell.y < 0 or spec.cell.x >= width or spec.cell.y >= height:
			errors.append("soldier at %s is off the map" % spec.cell)
		elif blocked.has(spec.cell):
			errors.append("soldier at %s stands on a blocked cell" % spec.cell)
		elif occupied.has(spec.cell):
			errors.append("two soldiers share the cell %s" % spec.cell)
		else:
			occupied[spec.cell] = true
			soldiers.append(spec)


## JSON numbers arrive as floats. Accept only whole numbers.
static func _as_int(value: Variant, what: String, problems: Array[String]) -> int:
	if (value is float or value is int) and float(value) == floorf(float(value)):
		return int(value)
	problems.append("%s must be a whole number" % what)
	return 0


static func _as_int_list(
	value: Variant, length: int, what: String, problems: Array[String]
) -> Array[int]:
	var numbers: Array[int] = []
	if not value is Array or (value as Array).size() != length:
		problems.append("%s must be a list of %d whole numbers" % [what, length])
		return numbers
	var before: int = problems.size()
	for item: Variant in value as Array:
		numbers.append(_as_int(item, what, problems))
	if problems.size() > before:
		numbers.clear()
	return numbers

class_name Scenario
extends RefCounted
## A map and the soldiers on it, read from a JSON file in data/scenarios/.
## Check `errors` after loading: a scenario with errors must not be used.


class SoldierSpec:
	extends RefCounted
	var side: SimSoldier.BattleSide
	var team_id: int
	var cell: Vector2i
	## File name, without extension, of a weapon in data/weapons/.
	var weapon_id: String
	var rounds: int


## An ammunition box lying on the map when the scenario begins.
class CacheSpec:
	extends RefCounted
	var cell: Vector2i
	var rounds: int


## A change of weather at a given moment.
class WeatherChange:
	extends RefCounted
	var at_tick: int
	## File name, without extension, of a weather state in data/weather/.
	var weather_id: String


## Translation key for the scenario's display name.
var name_key: String = ""
var width: int = 0
var height: int = 0
## Tall obstacles: stop movement and sight.
var blocked: Array[Vector2i] = []
## Low obstacles: stop movement, not sight, and give cover.
var cover: Array[Vector2i] = []
## Open ground that is slower to cross.
var slopes: Array[Vector2i] = []
## The weather through the mission, earliest first. Empty means no weather.
var weather_schedule: Array[WeatherChange] = []
## Ammunition boxes on the map at the start.
var caches: Array[CacheSpec] = []
## Tracks, each a list of cells. Drawn on the map only; no rule uses them yet.
var tracks: Array[PackedVector2Array] = []
var soldiers: Array[SoldierSpec] = []
## Where the enemy goes when it gives up its position. Only used when
## has_enemy_fallback is true.
var enemy_fallback: Vector2i = Vector2i.ZERO
var has_enemy_fallback: bool = false
## The mission is lost when fewer than this many of the player's men are fit.
var section_broken_below: int = 1
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
	scenario.blocked = scenario._read_rects(data.get("blocked_rects", []), "blocked_rects")
	for cell: Vector2i in scenario._read_rects(data.get("cover_rects", []), "cover_rects"):
		if not scenario.blocked.has(cell):
			scenario.cover.append(cell)
	for cell: Vector2i in scenario._read_rects(data.get("slope_rects", []), "slope_rects"):
		if not scenario.blocked.has(cell) and not scenario.cover.has(cell):
			scenario.slopes.append(cell)
	scenario._read_weather(data.get("weather", []))
	scenario._read_tracks(data.get("tracks", []))
	scenario._read_soldiers(data.get("soldiers", []))
	scenario._read_caches(data.get("caches", []))
	if data.has("section_broken_below"):
		scenario.section_broken_below = _as_int(
			data.get("section_broken_below"), "section_broken_below", scenario.errors
		)
	if data.has("enemy_fallback"):
		scenario._read_enemy_fallback(data.get("enemy_fallback"))
	return scenario


func is_valid() -> bool:
	return errors.is_empty()


## Weapon ids the soldiers ask for that are not in `weapons`.
func missing_weapons(weapons: Dictionary[String, WeaponDef]) -> Array[String]:
	var missing: Array[String] = []
	for spec: SoldierSpec in soldiers:
		if not weapons.has(spec.weapon_id) and not missing.has(spec.weapon_id):
			missing.append(spec.weapon_id)
	return missing


## Weather ids the schedule asks for that are not in `weathers`.
func missing_weather(weathers: Dictionary[String, WeatherDef]) -> Array[String]:
	var missing: Array[String] = []
	for change: WeatherChange in weather_schedule:
		if not weathers.has(change.weather_id) and not missing.has(change.weather_id):
			missing.append(change.weather_id)
	return missing


func _read_caches(value: Variant) -> void:
	if not value is Array:
		errors.append("caches must be a list")
		return
	for entry: Variant in value as Array:
		if not entry is Dictionary:
			errors.append("each cache must be an object")
			continue
		var fields: Dictionary = entry
		var position: Array[int] = _as_int_list(fields.get("cell"), 2, "cache cell", errors)
		if position.is_empty():
			continue
		var spec: CacheSpec = CacheSpec.new()
		spec.cell = Vector2i(position[0], position[1])
		spec.rounds = _as_int(fields.get("rounds"), "cache rounds", errors)
		var off_map: bool = (
			spec.cell.x < 0 or spec.cell.y < 0 or spec.cell.x >= width or spec.cell.y >= height
		)
		if off_map or blocked.has(spec.cell) or cover.has(spec.cell):
			errors.append("cache at %s must be on an open cell" % spec.cell)
		elif spec.rounds < 1:
			errors.append("cache at %s must hold at least one round" % spec.cell)
		else:
			caches.append(spec)


func _read_weather(value: Variant) -> void:
	if not value is Array:
		errors.append("weather must be a list")
		return
	var last_tick: int = -1
	for entry: Variant in value as Array:
		if not entry is Dictionary:
			errors.append("each weather entry must be an object")
			continue
		var fields: Dictionary = entry
		var change: WeatherChange = WeatherChange.new()
		change.at_tick = _as_int(fields.get("at_tick"), "weather at_tick", errors)
		change.weather_id = str(fields.get("state", ""))
		if change.weather_id.is_empty():
			errors.append("each weather entry needs a state")
		elif change.at_tick <= last_tick:
			errors.append("weather entries must be in order of at_tick, each later than the last")
		else:
			last_tick = change.at_tick
			weather_schedule.append(change)
	if not weather_schedule.is_empty() and weather_schedule[0].at_tick != 0:
		errors.append("the first weather entry must be at_tick 0")


## Every cell covered by a list of [x, y, width, height] rectangles.
func _read_rects(value: Variant, what: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not value is Array:
		errors.append("%s must be a list" % what)
		return cells
	var rects: Array = value
	var seen: Dictionary[Vector2i, bool] = {}
	for entry: Variant in rects:
		var numbers: Array[int] = _as_int_list(entry, 4, "%s entry" % what, errors)
		if numbers.is_empty():
			continue
		for y: int in range(numbers[1], numbers[1] + numbers[3]):
			for x: int in range(numbers[0], numbers[0] + numbers[2]):
				var cell: Vector2i = Vector2i(x, y)
				if not seen.has(cell):
					seen[cell] = true
					cells.append(cell)
	return cells


func _read_tracks(value: Variant) -> void:
	if not value is Array:
		errors.append("tracks must be a list")
		return
	for entry: Variant in value as Array:
		if not entry is Array:
			errors.append("each track must be a list of cells")
			continue
		var points: PackedVector2Array = PackedVector2Array()
		for point: Variant in entry as Array:
			var numbers: Array[int] = _as_int_list(point, 2, "track cell", errors)
			if not numbers.is_empty():
				points.append(Vector2(numbers[0], numbers[1]))
		if points.size() >= 2:
			tracks.append(points)


func _read_enemy_fallback(value: Variant) -> void:
	var numbers: Array[int] = _as_int_list(value, 2, "enemy_fallback", errors)
	if numbers.is_empty():
		return
	var cell: Vector2i = Vector2i(numbers[0], numbers[1])
	var off_map: bool = cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height
	if off_map or blocked.has(cell) or cover.has(cell):
		errors.append("enemy_fallback %s must be an open cell on the map" % cell)
		return
	enemy_fallback = cell
	has_enemy_fallback = true


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
		spec.weapon_id = str(fields.get("weapon", ""))
		if spec.weapon_id.is_empty():
			errors.append("each soldier needs a weapon")
			continue
		spec.rounds = _as_int(fields.get("rounds"), "soldier rounds", errors)
		if spec.rounds < 0:
			errors.append("soldier rounds cannot be negative")
			continue
		var position: Array[int] = _as_int_list(fields.get("cell"), 2, "soldier cell", errors)
		if position.is_empty():
			continue
		spec.cell = Vector2i(position[0], position[1])
		if spec.cell.x < 0 or spec.cell.y < 0 or spec.cell.x >= width or spec.cell.y >= height:
			errors.append("soldier at %s is off the map" % spec.cell)
		elif blocked.has(spec.cell) or cover.has(spec.cell):
			errors.append("soldier at %s stands on an obstacle" % spec.cell)
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

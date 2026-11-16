extends GutTest
## Weather as a rule: it limits sight, slows movement on slopes, stops
## weapons, and changes during a mission.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
const ENEMY: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY


func _weather(sight: int, slope_percent: int = 100, stoppage_percent: int = 0) -> WeatherDef:
	var weather: WeatherDef = WeatherDef.new()
	weather.sight_range_cells = sight
	weather.slope_move_percent = slope_percent
	weather.stoppage_chance_percent = stoppage_percent
	weather.stoppage_clear_ticks = 30
	return weather


func _change(at_tick: int, weather_id: String) -> Scenario.WeatherChange:
	var change: Scenario.WeatherChange = Scenario.WeatherChange.new()
	change.at_tick = at_tick
	change.weather_id = weather_id
	return change


## A 20 by 9 field with one player at (1, 4), an enemy `distance` cells to his
## right, and whatever weather the test supplies. Rifles reach 6 cells.
func _sim(
	distance: int,
	weathers: Dictionary[String, WeatherDef],
	schedule: Array[Scenario.WeatherChange],
	slopes: Array[Vector2i] = []
) -> Simulation:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4, 10),
		SimFixture.soldier("enemy", 1, 1 + distance, 4, 0),
	]
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers)
	scenario.weather_schedule = schedule
	scenario.slopes = slopes
	return Simulation.new(
		SimFixture.rules(), scenario, SimFixture.weapons(0, 0), SimFixture.SEED, weathers
	)


func test_a_scenario_with_no_weather_has_none_and_limits_nothing() -> void:
	var sim: Simulation = _sim(6, {}, [])
	assert_null(sim.weather)
	assert_eq(sim.weather_id, "")
	assert_eq(sim.effective_range_cells(sim.soldiers[0]), 6)


func test_the_first_weather_applies_from_the_start() -> void:
	var sim: Simulation = _sim(6, {"wet": _weather(4)}, [_change(0, "wet")])
	assert_eq(sim.weather_id, "wet")
	assert_string_contains(sim.snapshot(), "weather=wet")


func test_nobody_can_shoot_further_than_the_weather_lets_him_see() -> void:
	var sim: Simulation = _sim(6, {"wet": _weather(4)}, [_change(0, "wet")])
	assert_eq(sim.effective_range_cells(sim.soldiers[0]), 4)
	assert_false(sim.can_engage(sim.soldiers[0], sim.soldiers[1]))
	SimFixture.run(sim, 50)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0, "the enemy is six cells off, sight is four")


func test_good_visibility_never_lengthens_a_weapons_range() -> void:
	var sim: Simulation = _sim(7, {"clear": _weather(99)}, [_change(0, "clear")])
	assert_eq(sim.effective_range_cells(sim.soldiers[0]), 6)
	SimFixture.run(sim, 20)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0)


func test_the_weather_changes_on_schedule_and_the_change_is_logged() -> void:
	var weathers: Dictionary[String, WeatherDef] = {"clear": _weather(99), "wet": _weather(4)}
	var schedule: Array[Scenario.WeatherChange] = [_change(0, "clear"), _change(30, "wet")]
	var sim: Simulation = _sim(6, weathers, schedule)
	SimFixture.run(sim, 29)
	assert_eq(sim.weather_id, "clear")
	var shots_in_the_clear: int = SimFixture.shots_by(sim, PLAYER)
	assert_gt(shots_in_the_clear, 0)
	SimFixture.run(sim, 40)
	assert_eq(sim.weather_id, "wet")
	assert_eq(SimFixture.shots_by(sim, PLAYER), shots_in_the_clear, "firing stopped with the rain")
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.WEATHER_CHANGED), 2)


func test_setting_a_weather_that_was_not_loaded_is_refused() -> void:
	var sim: Simulation = _sim(6, {"wet": _weather(4)}, [_change(0, "wet")])
	assert_false(sim.set_weather("snow"))
	assert_eq(sim.weather_id, "wet")
	assert_eq(sim.weather_ids(), ["wet"] as Array[String])


func test_a_slope_takes_longer_to_walk_onto_in_wet_weather() -> void:
	# The slope fills the whole of column 2, so there is no way round it.
	var slopes: Array[Vector2i] = []
	for y: int in 9:
		slopes.append(Vector2i(2, y))
	var sim: Simulation = _sim(15, {"wet": _weather(99, 200)}, [_change(0, "wet")], slopes)
	sim.order_move(1, Vector2i(3, 4))
	SimFixture.run(sim, 9)
	assert_eq(sim.soldiers[0].cell, Vector2i(1, 4), "the slope cell takes ten ticks, not five")
	SimFixture.run(sim, 1)
	assert_eq(sim.soldiers[0].cell, Vector2i(2, 4))
	SimFixture.run(sim, 5)
	assert_eq(sim.soldiers[0].cell, Vector2i(3, 4), "flat ground beyond is normal speed")


func test_with_no_weather_a_slope_is_ordinary_ground() -> void:
	var slopes: Array[Vector2i] = [Vector2i(2, 4)]
	var sim: Simulation = _sim(15, {}, [], slopes)
	sim.order_move(1, Vector2i(2, 4))
	SimFixture.run(sim, 5)
	assert_eq(sim.soldiers[0].cell, Vector2i(2, 4))


func test_a_route_goes_round_a_slope_when_that_is_quicker() -> void:
	# A slope across the whole of row 4 between the man and his target, with
	# flat ground one row up.
	var slopes: Array[Vector2i] = []
	for x: int in range(2, 9):
		slopes.append(Vector2i(x, 4))
	var sim: Simulation = _sim(15, {"wet": _weather(99, 400)}, [_change(0, "wet")], slopes)
	var path: Array[Vector2i] = sim.grid.find_path(Vector2i(1, 4), Vector2i(9, 4))
	var slope_cells_used: int = 0
	for cell: Vector2i in path:
		if sim.grid.is_slope(cell):
			slope_cells_used += 1
	assert_lt(slope_cells_used, 3, "the route leaves the slope instead of walking along it")


func test_a_certain_stoppage_means_no_shot_and_no_round_spent() -> void:
	var sim: Simulation = _sim(4, {"wet": _weather(99, 100, 100)}, [_change(0, "wet")])
	SimFixture.run(sim, 20)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0)
	assert_eq(sim.soldiers[0].rounds, 10)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.STOPPAGE), 1, "one stoppage in 20 ticks")


func test_a_man_needs_the_clearing_time_before_he_tries_again() -> void:
	var sim: Simulation = _sim(4, {"wet": _weather(99, 100, 100)}, [_change(0, "wet")])
	SimFixture.run(sim, 30)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.STOPPAGE), 1)
	SimFixture.run(sim, 1)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.STOPPAGE), 2, "second try on tick 31")


func test_with_no_chance_of_a_stoppage_every_shot_goes_off() -> void:
	var sim: Simulation = _sim(4, {"wet": _weather(99, 100, 0)}, [_change(0, "wet")])
	SimFixture.run(sim, 31)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 4)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.STOPPAGE), 0)


func test_weather_and_slopes_are_read_from_json() -> void:
	var scenario: Scenario = Scenario.from_json_text(
		(
			'{"width": 9, "height": 9, "slope_rects": [[1, 1, 2, 1]], "soldiers": [],'
			+ ' "weather": [{"at_tick": 0, "state": "rain"}, {"at_tick": 50, "state": "dry"}]}'
		)
	)
	assert_eq(scenario.errors, [] as Array[String])
	assert_eq(scenario.slopes, [Vector2i(1, 1), Vector2i(2, 1)] as Array[Vector2i])
	assert_eq(scenario.weather_schedule.size(), 2)
	assert_eq(scenario.weather_schedule[1].weather_id, "dry")
	assert_eq(scenario.weather_schedule[1].at_tick, 50)


func test_a_weather_schedule_that_is_out_of_order_or_starts_late_is_reported() -> void:
	var out_of_order: Scenario = Scenario.from_json_text(
		(
			'{"width": 9, "height": 9, "soldiers": [], "weather":'
			+ ' [{"at_tick": 0, "state": "rain"}, {"at_tick": 0, "state": "dry"}]}'
		)
	)
	assert_false(out_of_order.is_valid())
	var starts_late: Scenario = Scenario.from_json_text(
		'{"width": 9, "height": 9, "soldiers": [], "weather": [{"at_tick": 5, "state": "rain"}]}'
	)
	assert_false(starts_late.is_valid())


func test_every_weather_the_test_range_asks_for_exists_and_has_a_name() -> void:
	var scenario: Scenario = Scenario.load_file("res://data/scenarios/test_range.json")
	assert_gt(scenario.weather_schedule.size(), 1, "the weather changes during the mission")
	assert_gt(scenario.slopes.size(), 0, "the test range has slopes")
	var weathers: Dictionary[String, WeatherDef] = WeatherLibrary.load_for(scenario)
	assert_eq(scenario.missing_weather(weathers), [] as Array[String])
	TranslationServer.set_locale("en")
	for id: String in weathers:
		assert_ne(tr(weathers[id].name_key), weathers[id].name_key, "%s needs a name" % id)

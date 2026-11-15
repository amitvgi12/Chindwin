extends GutTest
## Loading a map and its soldiers from JSON, and refusing bad data.

const TEST_RANGE: String = "res://data/scenarios/test_range.json"


func test_the_shipped_test_range_loads_cleanly() -> void:
	var scenario: Scenario = Scenario.load_file(TEST_RANGE)
	assert_eq(scenario.errors, [] as Array[String])
	assert_eq(scenario.width, 40)
	assert_eq(scenario.height, 20)
	assert_gt(scenario.blocked.size(), 0)


func test_the_test_range_has_two_player_teams_and_one_enemy_picket() -> void:
	var scenario: Scenario = Scenario.load_file(TEST_RANGE)
	var player_teams: Dictionary[int, int] = {}
	var enemies: int = 0
	for spec: Scenario.SoldierSpec in scenario.soldiers:
		if spec.side == SimSoldier.BattleSide.PLAYER:
			player_teams[spec.team_id] = player_teams.get(spec.team_id, 0) + 1
		else:
			enemies += 1
	assert_eq(player_teams.size(), 2, "two player teams")
	assert_gt(enemies, 0, "at least one enemy")


func test_the_scenario_name_is_a_text_key_with_an_english_string() -> void:
	var scenario: Scenario = Scenario.load_file(TEST_RANGE)
	TranslationServer.set_locale("en")
	assert_ne(tr(scenario.name_key), scenario.name_key)


func test_a_rectangle_blocks_every_cell_inside_it() -> void:
	var scenario: Scenario = Scenario.from_json_text(
		'{"width": 5, "height": 5, "blocked_rects": [[1, 1, 2, 3]], "soldiers": []}'
	)
	assert_true(scenario.is_valid())
	assert_eq(scenario.blocked.size(), 6)
	assert_has(scenario.blocked, Vector2i(1, 1))
	assert_has(scenario.blocked, Vector2i(2, 3))


func test_a_missing_file_is_reported() -> void:
	var scenario: Scenario = Scenario.load_file("res://data/scenarios/does_not_exist.json")
	assert_false(scenario.is_valid())


func test_text_that_is_not_json_is_reported() -> void:
	assert_false(Scenario.from_json_text("[1, 2, 3]").is_valid())


func test_a_fractional_size_is_reported() -> void:
	var scenario: Scenario = Scenario.from_json_text('{"width": 5.5, "height": 5}')
	assert_false(scenario.is_valid())


func test_a_soldier_off_the_map_is_reported() -> void:
	var scenario: Scenario = Scenario.from_json_text(
		'{"width": 5, "height": 5, "soldiers": [{"side": "player", "team": 1, "cell": [9, 9]}]}'
	)
	assert_false(scenario.is_valid())
	assert_eq(scenario.soldiers.size(), 0)


func test_a_soldier_on_a_blocked_cell_is_reported() -> void:
	var scenario: Scenario = Scenario.from_json_text(
		(
			'{"width": 5, "height": 5, "blocked_rects": [[1, 1, 1, 1]],'
			+ ' "soldiers": [{"side": "enemy", "team": 1, "cell": [1, 1]}]}'
		)
	)
	assert_false(scenario.is_valid())


func test_two_soldiers_on_one_cell_are_reported() -> void:
	var scenario: Scenario = Scenario.from_json_text(
		(
			'{"width": 5, "height": 5, "soldiers": ['
			+ '{"side": "player", "team": 1, "cell": [2, 2]},'
			+ '{"side": "player", "team": 2, "cell": [2, 2]}]}'
		)
	)
	assert_false(scenario.is_valid())


func test_an_unknown_side_is_reported() -> void:
	var scenario: Scenario = Scenario.from_json_text(
		'{"width": 5, "height": 5, "soldiers": [{"side": "neutral", "team": 1, "cell": [2, 2]}]}'
	)
	assert_false(scenario.is_valid())

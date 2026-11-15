extends GutTest
## Loading a map and its soldiers from JSON, and refusing bad data.

const TEST_RANGE: String = "res://data/scenarios/test_range.json"


func _one_soldier(fields: String) -> Scenario:
	return Scenario.from_json_text('{"width": 5, "height": 5, "soldiers": [{%s}]}' % fields)


func test_the_shipped_test_range_loads_cleanly() -> void:
	var scenario: Scenario = Scenario.load_file(TEST_RANGE)
	assert_eq(scenario.errors, [] as Array[String])
	assert_eq(scenario.width, 40)
	assert_eq(scenario.height, 20)
	assert_gt(scenario.blocked.size(), 0, "has thick jungle")
	assert_gt(scenario.cover.size(), 0, "has cover")
	assert_gt(scenario.tracks.size(), 0, "has a track")


func test_every_weapon_the_test_range_asks_for_exists() -> void:
	var scenario: Scenario = Scenario.load_file(TEST_RANGE)
	var weapons: Dictionary[String, WeaponDef] = WeaponLibrary.load_for(scenario)
	assert_eq(scenario.missing_weapons(weapons), [] as Array[String])
	TranslationServer.set_locale("en")
	for weapon_id: String in weapons:
		var name_key: String = weapons[weapon_id].name_key
		assert_ne(tr(name_key), name_key, "%s needs an English name" % weapon_id)


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
	var scenario: Scenario = SimFixture.scenario(5, 5, [], "[1, 1, 2, 3]")
	assert_true(scenario.is_valid())
	assert_eq(scenario.blocked.size(), 6)
	assert_has(scenario.blocked, Vector2i(1, 1))
	assert_has(scenario.blocked, Vector2i(2, 3))


func test_cover_is_read_and_jungle_wins_where_the_two_overlap() -> void:
	var scenario: Scenario = SimFixture.scenario(5, 5, [], "[1, 1, 1, 1]", "[1, 1, 2, 1]")
	assert_true(scenario.is_valid())
	assert_eq(scenario.cover, [Vector2i(2, 1)] as Array[Vector2i])


func test_a_soldier_gets_his_weapon_and_rounds() -> void:
	var scenario: Scenario = SimFixture.scenario(5, 5, [SimFixture.soldier("player", 1, 2, 2, 17)])
	assert_true(scenario.is_valid())
	assert_eq(scenario.soldiers[0].weapon_id, "player_rifle")
	assert_eq(scenario.soldiers[0].rounds, 17)


func test_a_weapon_with_no_file_is_reported_as_missing() -> void:
	var scenario: Scenario = SimFixture.scenario(5, 5, [SimFixture.soldier("player", 1, 2, 2)])
	var weapons: Dictionary[String, WeaponDef] = WeaponLibrary.load_for(scenario)
	assert_eq(scenario.missing_weapons(weapons), ["player_rifle"] as Array[String])


func test_a_track_is_read_as_a_list_of_cells() -> void:
	var scenario: Scenario = Scenario.from_json_text(
		'{"width": 5, "height": 5, "tracks": [[[0, 2], [4, 2]]], "soldiers": []}'
	)
	assert_true(scenario.is_valid())
	assert_eq(scenario.tracks.size(), 1)
	assert_eq(scenario.tracks[0][1], Vector2(4, 2))


func test_a_missing_file_is_reported() -> void:
	var scenario: Scenario = Scenario.load_file("res://data/scenarios/does_not_exist.json")
	assert_false(scenario.is_valid())


func test_text_that_is_not_json_is_reported() -> void:
	assert_false(Scenario.from_json_text("[1, 2, 3]").is_valid())


func test_a_fractional_size_is_reported() -> void:
	assert_false(Scenario.from_json_text('{"width": 5.5, "height": 5}').is_valid())


func test_a_soldier_off_the_map_is_reported() -> void:
	var scenario: Scenario = SimFixture.scenario(5, 5, [SimFixture.soldier("player", 1, 9, 9)])
	assert_false(scenario.is_valid())
	assert_eq(scenario.soldiers.size(), 0)


func test_a_soldier_on_jungle_or_on_cover_is_reported() -> void:
	var on_jungle: Scenario = SimFixture.scenario(
		5, 5, [SimFixture.soldier("enemy", 1, 1, 1)], "[1, 1, 1, 1]"
	)
	assert_false(on_jungle.is_valid())
	var on_cover: Scenario = SimFixture.scenario(
		5, 5, [SimFixture.soldier("enemy", 1, 1, 1)], "", "[1, 1, 1, 1]"
	)
	assert_false(on_cover.is_valid())


func test_two_soldiers_on_one_cell_are_reported() -> void:
	var both: Array[String] = [
		SimFixture.soldier("player", 1, 2, 2),
		SimFixture.soldier("player", 2, 2, 2),
	]
	assert_false(SimFixture.scenario(5, 5, both).is_valid())


func test_an_unknown_side_is_reported() -> void:
	var fields: String = '"side": "neutral", "team": 1, "cell": [2, 2], "weapon": "x", "rounds": 1'
	assert_false(_one_soldier(fields).is_valid())


func test_a_soldier_with_no_weapon_is_reported() -> void:
	assert_false(
		_one_soldier('"side": "player", "team": 1, "cell": [2, 2], "rounds": 5').is_valid()
	)


func test_negative_or_fractional_rounds_are_reported() -> void:
	var base: String = '"side": "player", "team": 1, "cell": [2, 2], "weapon": "x", "rounds": %s'
	assert_false(_one_soldier(base % "-1").is_valid())
	assert_false(_one_soldier(base % "2.5").is_valid())

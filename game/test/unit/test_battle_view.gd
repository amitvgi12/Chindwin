extends GutTest
## The view: pause, selection, orders from input, and what the corner panel says.
## Rules themselves are tested in test_simulation.gd.

const SCENE: String = "res://scenes/test_range.tscn"

var view: BattleView


func before_each() -> void:
	TranslationServer.set_locale("en")
	var packed: PackedScene = load(SCENE) as PackedScene
	view = packed.instantiate() as BattleView
	add_child_autofree(view)


func _key(key: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	return event


func _click(button: MouseButton, cell: Vector2i) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = view.cell_centre(cell)
	return event


func _first_of_team(team_id: int) -> SimSoldier:
	return view.sim.living(SimSoldier.BattleSide.PLAYER, team_id)[0]


func test_the_game_starts_paused_at_time_zero_with_team_one_selected() -> void:
	assert_true(view.paused)
	assert_eq(view.sim.tick, 0)
	assert_eq(view.selected_team, 1)


func test_time_does_not_pass_while_paused() -> void:
	view.advance(5.0)
	assert_eq(view.sim.tick, 0)


func test_one_tenth_of_a_second_is_one_tick() -> void:
	view.toggle_pause()
	view.advance(0.1)
	assert_eq(view.sim.tick, 1)
	view.advance(0.3)
	assert_eq(view.sim.tick, 4)


func test_a_very_slow_frame_runs_a_limited_number_of_ticks() -> void:
	view.toggle_pause()
	view.advance(60.0)
	assert_eq(view.sim.tick, BattleView.MAX_STEPS_PER_FRAME)
	view.advance(0.1)
	assert_eq(view.sim.tick, BattleView.MAX_STEPS_PER_FRAME + 1, "the backlog was dropped")


func test_a_cell_and_its_centre_point_convert_both_ways() -> void:
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(7, 3), Vector2i(39, 19)] as Array[Vector2i]:
		assert_eq(view.cell_at(view.cell_centre(cell)), cell)
	assert_eq(view.cell_at(Vector2(31.9, 0.0)), Vector2i(0, 0))
	assert_eq(view.cell_at(Vector2(32.0, 0.0)), Vector2i(1, 0))


func test_space_pauses_and_resumes() -> void:
	view.handle_input(_key(KEY_SPACE))
	assert_false(view.paused)
	view.handle_input(_key(KEY_SPACE))
	assert_true(view.paused)


func test_number_keys_select_a_team() -> void:
	view.handle_input(_key(KEY_2))
	assert_eq(view.selected_team, 2)
	view.handle_input(_key(KEY_1))
	assert_eq(view.selected_team, 1)


func test_selecting_a_team_that_does_not_exist_changes_nothing() -> void:
	view.select_team(9)
	assert_eq(view.selected_team, 1)


func test_left_click_on_a_soldier_selects_his_team() -> void:
	view.handle_input(_click(MOUSE_BUTTON_LEFT, _first_of_team(2).cell))
	assert_eq(view.selected_team, 2)


func test_left_click_on_an_enemy_or_empty_ground_keeps_the_selection() -> void:
	var enemy: SimSoldier = view.sim.living(SimSoldier.BattleSide.ENEMY, 1)[0]
	view.handle_input(_click(MOUSE_BUTTON_LEFT, enemy.cell))
	assert_eq(view.selected_team, 1)
	view.handle_input(_click(MOUSE_BUTTON_LEFT, Vector2i(0, 0)))
	assert_eq(view.selected_team, 1)


func test_right_click_orders_only_the_selected_team_and_works_while_paused() -> void:
	view.handle_input(_key(KEY_2))
	view.handle_input(_click(MOUSE_BUTTON_RIGHT, Vector2i(8, 14)))
	assert_true(view.paused, "ordering does not unpause")
	view.toggle_pause()
	view.advance(0.1)
	assert_true(_first_of_team(2).is_moving(), "team 2 is on its way")
	assert_false(_first_of_team(1).is_moving(), "team 1 was not ordered")


func test_right_click_on_a_blocked_cell_orders_nobody() -> void:
	view.handle_input(_click(MOUSE_BUTTON_RIGHT, view.sim.grid.tall_cells()[0]))
	view.toggle_pause()
	view.advance(0.1)
	assert_false(_first_of_team(1).is_moving())


func test_restart_puts_everything_back() -> void:
	view.handle_input(_key(KEY_2))
	view.order_selected_team_to(Vector2i(8, 14))
	view.toggle_pause()
	view.advance(0.3)
	view.handle_input(_key(KEY_R))
	assert_true(view.paused)
	assert_eq(view.sim.tick, 0)
	assert_eq(view.selected_team, 1)
	assert_false(_first_of_team(2).is_moving())


func test_the_corner_panel_reports_state_and_strengths() -> void:
	var text: String = view.hud_text()
	assert_string_contains(text, "Test range")
	assert_string_contains(text, "PAUSED")
	assert_string_contains(text, "Team 1: 5 of 5 fit, 0 pinned, 100 rounds, firing")
	assert_string_contains(text, "Team 2: 5 of 5 fit, 0 pinned, 100 rounds, firing")
	assert_string_contains(text, "Enemy picket: 4 of 4, 0 pinned, 0 withdrew")


func test_no_text_key_is_shown_raw_in_the_corner_panel() -> void:
	assert_false(view.hud_text().contains("HUD_"), "every HUD_ key needs an English string")
	assert_false(view.hud_text().contains("{"), "every placeholder was filled in")


func test_the_paused_banner_shows_only_while_paused() -> void:
	assert_true(view.paused_banner_is_showing())
	view.toggle_pause()
	view.advance(0.1)
	view._process(0.0)
	assert_false(view.paused_banner_is_showing())


func test_f_tells_only_the_selected_team_to_hold_fire() -> void:
	view.handle_input(_key(KEY_2))
	view.handle_input(_key(KEY_F))
	assert_false(view.team_is_firing(2))
	assert_true(view.team_is_firing(1), "team 1 was not told anything")
	view._process(0.0)
	assert_string_contains(
		view.hud_text(), "Team 2: 5 of 5 fit, 0 pinned, 100 rounds, holding fire"
	)
	view.toggle_pause()
	view.advance(0.1)
	assert_false(view.sim.team_may_fire(SimSoldier.BattleSide.PLAYER, 2), "order reached the sim")
	assert_true(view.sim.team_may_fire(SimSoldier.BattleSide.PLAYER, 1))


func test_pressing_f_twice_while_paused_ends_up_firing_again() -> void:
	view.handle_input(_key(KEY_F))
	view.handle_input(_key(KEY_F))
	assert_true(view.team_is_firing(1))
	view.toggle_pause()
	view.advance(0.1)
	assert_true(view.sim.team_may_fire(SimSoldier.BattleSide.PLAYER, 1))


func test_restart_puts_both_teams_back_to_firing() -> void:
	view.handle_input(_key(KEY_F))
	view.handle_input(_key(KEY_R))
	assert_true(view.team_is_firing(1))


func test_a_rifle_carries_its_placeholder_label() -> void:
	assert_eq(tr("WEAPON_RIFLE"), "Rifle (placeholder)")


func test_shift_right_click_adds_a_waypoint_instead_of_replacing_the_route() -> void:
	view.handle_input(_click(MOUSE_BUTTON_RIGHT, Vector2i(8, 9)))
	view.toggle_pause()
	view.advance(0.1)
	var first_leg: int = _first_of_team(1).path.size()
	var waypoint: InputEventMouseButton = _click(MOUSE_BUTTON_RIGHT, Vector2i(8, 3))
	waypoint.shift_pressed = true
	view.handle_input(waypoint)
	view.advance(0.1)
	assert_gt(_first_of_team(1).path.size(), first_leg, "the route got longer")
	assert_eq(_first_of_team(1).destination(), Vector2i(8, 3))


func test_the_status_strip_counts_pinned_men() -> void:
	_first_of_team(1).suppression = 100
	view._process(0.0)
	assert_string_contains(view.hud_text(), "Team 1: 5 of 5 fit, 1 pinned")


func test_the_debrief_reports_a_taken_objective_with_its_cost() -> void:
	var enemies: Array[SimSoldier] = view.sim.living(SimSoldier.BattleSide.ENEMY, 1)
	enemies[0].alive = false
	for index: int in range(1, enemies.size()):
		view.sim.withdraw(enemies[index])
	_first_of_team(1).alive = false
	view.toggle_pause()
	view.advance(0.1)
	view._process(0.0)
	assert_string_contains(view.banner_text(), "The picket has gone")
	assert_string_contains(view.banner_text(), "9 of 10 fit, 1 down")
	assert_string_contains(view.banner_text(), "1 down, 3 got away, 0 still holding")
	assert_string_contains(view.banner_text(), "left of 200")


func test_the_debrief_reports_a_broken_section() -> void:
	for soldier: SimSoldier in view.sim.soldiers:
		if soldier.side == SimSoldier.BattleSide.PLAYER and soldier.id >= 3:
			soldier.alive = false
	view.toggle_pause()
	view.advance(0.1)
	view._process(0.0)
	assert_string_contains(view.banner_text(), "Your section can no longer fight")
	assert_string_contains(view.banner_text(), "3 of 10 fit, 7 down")


func test_time_stops_once_the_mission_has_ended() -> void:
	for soldier: SimSoldier in view.sim.living(SimSoldier.BattleSide.ENEMY, 1):
		soldier.alive = false
	view.toggle_pause()
	view.advance(0.1)
	var ended_at: int = view.sim.tick
	view.advance(0.3)
	assert_eq(view.sim.tick, ended_at)
	view._process(0.0)
	assert_string_contains(view.hud_text(), "ENDED")
	assert_false(view.hud_text().contains("RUNNING"))


func test_b_orders_the_selected_team_to_fall_back() -> void:
	view.handle_input(_click(MOUSE_BUTTON_RIGHT, Vector2i(8, 9)))
	view.toggle_pause()
	for count: int in 60:
		view.advance(0.1)
	var man: SimSoldier = _first_of_team(1)
	assert_ne(man.cell, man.start_cell, "the team has gone forward")
	view.handle_input(_key(KEY_B))
	view.advance(0.1)
	assert_true(man.falling_back)
	for count: int in 80:
		view.advance(0.1)
	assert_eq(man.cell, man.start_cell, "and come back")


func test_h_shows_the_help_page_and_pauses_the_game() -> void:
	view.toggle_pause()
	assert_false(view.help_is_showing())
	view.handle_input(_key(KEY_H))
	assert_true(view.help_is_showing())
	assert_true(view.paused, "the fight does not go on behind the page")
	view.handle_input(_key(KEY_H))
	assert_false(view.help_is_showing())
	assert_true(view.paused, "closing the page leaves the game paused")


func test_o_turns_the_debug_overlay_on_and_off() -> void:
	assert_eq(view.debug_text(), "")
	view.handle_input(_key(KEY_O))
	view._process(0.0)
	assert_string_contains(view.debug_text(), "seed 1944")
	assert_string_contains(view.debug_text(), "tick 0")
	assert_string_contains(view.debug_text(), "(none yet)")
	view.handle_input(_key(KEY_O))
	view._process(0.0)
	assert_eq(view.debug_text(), "")


func test_the_debug_overlay_lists_the_enemys_decisions() -> void:
	view.handle_input(_key(KEY_O))
	view.sim.note_ai("picket 1 falls back: test reason")
	view._process(0.0)
	assert_string_contains(view.debug_text(), "tick 0: picket 1 falls back: test reason")


func test_a_team_with_nobody_left_says_so() -> void:
	for soldier: SimSoldier in view.sim.living(SimSoldier.BattleSide.PLAYER, 2):
		soldier.alive = false
	view._process(0.0)
	assert_string_contains(view.hud_text(), "Team 2: none left")
	assert_false(view.hud_text().contains("Team 2: 0 of 5"))


func test_the_status_strip_names_the_weather_and_how_far_men_can_see() -> void:
	assert_string_contains(view.hud_text(), "Rain: sight 16")


func test_w_changes_the_weather_only_while_the_debug_overlay_is_on() -> void:
	view.handle_input(_key(KEY_W))
	assert_eq(view.sim.weather_id, "rain", "overlay off: nothing happens")
	view.handle_input(_key(KEY_O))
	view.handle_input(_key(KEY_W))
	assert_ne(view.sim.weather_id, "rain")
	view._process(0.0)
	assert_false(view.hud_text().contains("Rain: sight 16"))


func test_g_tells_the_selected_team_to_gather_and_again_to_stop() -> void:
	view.handle_input(_key(KEY_G))
	assert_true(view.team_is_gathering(1))
	assert_false(view.team_is_gathering(2))
	view._process(0.0)
	assert_string_contains(view.hud_text(), "Team 1: 5 of 5 fit, 0 pinned, 100 rounds, gathering")
	view.toggle_pause()
	view.advance(0.1)
	assert_true(_first_of_team(1).told_to_gather, "the order reached the sim")
	view.handle_input(_key(KEY_G))
	view.advance(0.1)
	assert_false(_first_of_team(1).told_to_gather)


func test_restart_stops_any_gathering() -> void:
	view.handle_input(_key(KEY_G))
	view.handle_input(_key(KEY_R))
	assert_false(view.team_is_gathering(1))


func test_the_test_range_has_an_ammunition_box_in_the_open() -> void:
	assert_eq(view.sim.rounds_on_the_ground(), 60)


func test_a_team_with_no_rounds_says_so_instead_of_firing() -> void:
	for soldier: SimSoldier in view.sim.living(SimSoldier.BattleSide.PLAYER, 1):
		soldier.rounds = 0
	view._process(0.0)
	assert_string_contains(
		view.hud_text(), "Team 1: 5 of 5 fit, 0 pinned, 0 rounds, no rounds left"
	)
	assert_string_contains(view.hud_text(), "Space: pause", "team 2 still has rounds")


func test_when_the_whole_section_is_out_of_rounds_the_strip_says_what_to_do() -> void:
	for soldier: SimSoldier in view.sim.soldiers:
		if soldier.side == SimSoldier.BattleSide.PLAYER:
			soldier.rounds = 0
	view._process(0.0)
	assert_string_contains(view.hud_text(), "G gathers")
	assert_string_contains(view.hud_text(), "B falls back")

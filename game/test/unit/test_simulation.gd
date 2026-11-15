extends GutTest
## The rules that exist so far: orders, walking, and the placeholder enemy fire.

const SEED: int = 1944


## Rules with round numbers so the arithmetic in these tests is obvious.
func _rules() -> SimRules:
	var rules: SimRules = SimRules.new()
	rules.ticks_per_second = 10
	rules.move_ticks_orthogonal = 5
	rules.move_ticks_diagonal = 7
	rules.enemy_range_cells = 6
	rules.enemy_fire_interval_ticks = 10
	rules.enemy_hit_chance_percent = 0
	return rules


## An empty 20 by 9 field. Team 1 has two men on the left; soldiers is extra JSON.
func _sim(rules: SimRules, extra_soldiers: String = "", blocked: String = "") -> Simulation:
	var text: String = (
		'{"width": 20, "height": 9, "blocked_rects": [%s], "soldiers": ['
		+ '{"side": "player", "team": 1, "cell": [1, 4]},'
		+ '{"side": "player", "team": 1, "cell": [1, 5]}%s]}'
	)
	var scenario: Scenario = Scenario.from_json_text(text % [blocked, extra_soldiers])
	assert_eq(scenario.errors, [] as Array[String], "test scenario must be valid")
	return Simulation.new(rules, scenario, SEED)


func _run(sim: Simulation, ticks: int) -> void:
	for count: int in ticks:
		sim.step()


func _count_events(sim: Simulation, kind: SimEvent.Kind) -> int:
	var count: int = 0
	for event: SimEvent in sim.events:
		if event.kind == kind:
			count += 1
	return count


func test_nothing_moves_without_an_order() -> void:
	var sim: Simulation = _sim(_rules())
	var before: String = sim.snapshot().replace("tick=0", "")
	_run(sim, 50)
	assert_eq(sim.snapshot().replace("tick=50", ""), before)


func test_an_order_takes_effect_on_the_next_tick_not_before() -> void:
	var sim: Simulation = _sim(_rules())
	assert_true(sim.order_move(1, Vector2i(6, 4)))
	assert_false(sim.soldiers[0].is_moving(), "still waiting: the order is only queued")
	sim.step()
	assert_true(sim.soldiers[0].is_moving())


func test_a_soldier_takes_five_ticks_per_cell_in_a_straight_line() -> void:
	var sim: Simulation = _sim(_rules())
	sim.order_move(1, Vector2i(5, 4))
	_run(sim, 4)
	assert_eq(sim.soldiers[0].cell, Vector2i(1, 4), "not yet arrived in the next cell")
	_run(sim, 1)
	assert_eq(sim.soldiers[0].cell, Vector2i(2, 4), "one cell after five ticks")
	_run(sim, 15)
	assert_eq(sim.soldiers[0].cell, Vector2i(5, 4), "four cells after twenty ticks")
	assert_false(sim.soldiers[0].is_moving())


func test_a_diagonal_step_takes_seven_ticks() -> void:
	var rules: SimRules = _rules()
	var soldier: String = '{"side": "player", "team": 1, "cell": [1, 1]}'
	var text: String = '{"width": 9, "height": 9, "soldiers": [%s]}' % soldier
	var sim: Simulation = Simulation.new(rules, Scenario.from_json_text(text), SEED)
	sim.order_move(1, Vector2i(2, 2))
	_run(sim, 6)
	assert_eq(sim.soldiers[0].cell, Vector2i(1, 1))
	_run(sim, 1)
	assert_eq(sim.soldiers[0].cell, Vector2i(2, 2))


func test_team_members_end_on_different_cells_next_to_the_target() -> void:
	var sim: Simulation = _sim(_rules())
	sim.order_move(1, Vector2i(8, 4))
	_run(sim, 100)
	var first: Vector2i = sim.soldiers[0].cell
	var second: Vector2i = sim.soldiers[1].cell
	assert_ne(first, second, "two men never share a cell")
	assert_eq(first, Vector2i(8, 4), "the first man stands on the target")
	assert_lt(second.distance_squared_to(Vector2i(8, 4)), 3, "the second stands beside it")
	assert_eq(_count_events(sim, SimEvent.Kind.ARRIVED), 2)


func test_a_team_does_not_stand_on_a_cell_another_team_holds() -> void:
	var sim: Simulation = _sim(_rules(), ',{"side": "player", "team": 2, "cell": [8, 4]}')
	sim.order_move(1, Vector2i(8, 4))
	_run(sim, 100)
	assert_ne(sim.soldiers[0].cell, Vector2i(8, 4))
	assert_ne(sim.soldiers[1].cell, Vector2i(8, 4))
	assert_eq(sim.soldiers[2].cell, Vector2i(8, 4), "team 2 has not been pushed off")


func test_an_order_to_a_blocked_cell_or_off_the_map_is_refused() -> void:
	var sim: Simulation = _sim(_rules(), "", "[10, 0, 1, 9]")
	assert_false(sim.order_move(1, Vector2i(10, 4)), "blocked cell")
	assert_false(sim.order_move(1, Vector2i(99, 4)), "off the map")
	_run(sim, 10)
	assert_false(sim.soldiers[0].is_moving())


func test_an_order_for_a_team_with_nobody_left_is_refused() -> void:
	var sim: Simulation = _sim(_rules())
	assert_false(sim.order_move(7, Vector2i(5, 4)), "team 7 does not exist")


func test_a_new_order_replaces_the_old_one() -> void:
	var sim: Simulation = _sim(_rules())
	sim.order_move(1, Vector2i(15, 4))
	_run(sim, 12)
	sim.order_move(1, Vector2i(1, 1))
	_run(sim, 200)
	assert_eq(sim.soldiers[0].cell, Vector2i(1, 1))


func test_walking_goes_round_a_wall() -> void:
	# A wall across column 10 with one gap at the top row.
	var sim: Simulation = _sim(_rules(), "", "[10, 1, 1, 8]")
	sim.order_move(1, Vector2i(15, 4))
	_run(sim, 400)
	assert_eq(sim.soldiers[0].cell, Vector2i(15, 4))


func test_an_enemy_out_of_range_never_fires() -> void:
	var rules: SimRules = _rules()
	rules.enemy_hit_chance_percent = 100
	var sim: Simulation = _sim(rules, ',{"side": "enemy", "team": 1, "cell": [18, 4]}')
	_run(sim, 200)
	assert_eq(_count_events(sim, SimEvent.Kind.SHOT_HIT), 0)
	assert_eq(sim.living(SimSoldier.BattleSide.PLAYER, 1).size(), 2)


func test_an_enemy_in_range_with_a_certain_hit_causes_a_casualty_at_once() -> void:
	var rules: SimRules = _rules()
	rules.enemy_hit_chance_percent = 100
	var sim: Simulation = _sim(rules, ',{"side": "enemy", "team": 1, "cell": [5, 4]}')
	sim.step()
	assert_eq(sim.living(SimSoldier.BattleSide.PLAYER, 1).size(), 1)
	assert_false(sim.soldiers[0].alive, "the nearer man is the one hit")
	assert_true(sim.soldiers[1].alive)


func test_an_enemy_waits_the_fire_interval_between_shots() -> void:
	var rules: SimRules = _rules()
	rules.enemy_hit_chance_percent = 100
	var sim: Simulation = _sim(rules, ',{"side": "enemy", "team": 1, "cell": [5, 4]}')
	_run(sim, 10)
	assert_eq(_count_events(sim, SimEvent.Kind.SHOT_HIT), 1, "one shot in the first ten ticks")
	_run(sim, 1)
	assert_eq(_count_events(sim, SimEvent.Kind.SHOT_HIT), 2, "second shot on tick eleven")


func test_an_enemy_with_no_chance_to_hit_fires_and_always_misses() -> void:
	var sim: Simulation = _sim(_rules(), ',{"side": "enemy", "team": 1, "cell": [5, 4]}')
	_run(sim, 100)
	assert_gt(_count_events(sim, SimEvent.Kind.SHOT_MISSED), 5)
	assert_eq(_count_events(sim, SimEvent.Kind.SHOT_HIT), 0)


func test_a_wall_between_them_stops_the_enemy_firing() -> void:
	var rules: SimRules = _rules()
	rules.enemy_hit_chance_percent = 100
	var sim: Simulation = _sim(
		rules, ',{"side": "enemy", "team": 1, "cell": [5, 4]}', "[3, 0, 1, 9]"
	)
	_run(sim, 100)
	assert_eq(sim.living(SimSoldier.BattleSide.PLAYER, 1).size(), 2)
	assert_eq(_count_events(sim, SimEvent.Kind.SHOT_MISSED), 0)


func test_a_casualty_stops_moving_and_cannot_be_ordered_about() -> void:
	var rules: SimRules = _rules()
	rules.enemy_hit_chance_percent = 100
	var sim: Simulation = _sim(rules, ',{"side": "enemy", "team": 1, "cell": [5, 4]}')
	_run(sim, 30)
	assert_eq(sim.living(SimSoldier.BattleSide.PLAYER, 1).size(), 0)
	assert_false(sim.order_move(1, Vector2i(2, 2)), "nobody left to take the order")
	assert_eq(sim.strength(SimSoldier.BattleSide.PLAYER, 1), 2, "starting strength is remembered")

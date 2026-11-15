extends GutTest
## Orders and walking. Shooting is tested in test_fire.gd.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER


## A 20 by 9 field with team 1 (two men) on the left, plus any extras.
func _sim(extra: Array[String] = [], blocked: String = "") -> Simulation:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("player", 1, 1, 5),
	]
	soldiers.append_array(extra)
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers, blocked)
	assert_eq(scenario.errors, [] as Array[String], "test scenario must be valid")
	return Simulation.new(SimFixture.rules(), scenario, SimFixture.weapons(0, 0), SimFixture.SEED)


func test_nothing_moves_without_an_order() -> void:
	var sim: Simulation = _sim()
	var before: String = sim.snapshot().replace("tick=0", "")
	SimFixture.run(sim, 50)
	assert_eq(sim.snapshot().replace("tick=50", ""), before)


func test_an_order_takes_effect_on_the_next_tick_not_before() -> void:
	var sim: Simulation = _sim()
	assert_true(sim.order_move(1, Vector2i(6, 4)))
	assert_false(sim.soldiers[0].is_moving(), "still waiting: the order is only queued")
	sim.step()
	assert_true(sim.soldiers[0].is_moving())


func test_a_soldier_takes_five_ticks_per_cell_in_a_straight_line() -> void:
	var sim: Simulation = _sim()
	sim.order_move(1, Vector2i(5, 4))
	SimFixture.run(sim, 4)
	assert_eq(sim.soldiers[0].cell, Vector2i(1, 4), "not yet arrived in the next cell")
	SimFixture.run(sim, 1)
	assert_eq(sim.soldiers[0].cell, Vector2i(2, 4), "one cell after five ticks")
	SimFixture.run(sim, 15)
	assert_eq(sim.soldiers[0].cell, Vector2i(5, 4), "four cells after twenty ticks")
	assert_false(sim.soldiers[0].is_moving())


func test_a_diagonal_step_takes_seven_ticks() -> void:
	var only: Array[String] = [SimFixture.soldier("player", 1, 1, 1)]
	var sim: Simulation = Simulation.new(
		SimFixture.rules(),
		SimFixture.scenario(9, 9, only),
		SimFixture.weapons(0, 0),
		SimFixture.SEED
	)
	sim.order_move(1, Vector2i(2, 2))
	SimFixture.run(sim, 6)
	assert_eq(sim.soldiers[0].cell, Vector2i(1, 1))
	SimFixture.run(sim, 1)
	assert_eq(sim.soldiers[0].cell, Vector2i(2, 2))


func test_team_members_end_on_different_cells_next_to_the_target() -> void:
	var sim: Simulation = _sim()
	sim.order_move(1, Vector2i(8, 4))
	SimFixture.run(sim, 100)
	var first: Vector2i = sim.soldiers[0].cell
	var second: Vector2i = sim.soldiers[1].cell
	assert_ne(first, second, "two men never share a cell")
	assert_eq(first, Vector2i(8, 4), "the first man stands on the target")
	assert_lt(second.distance_squared_to(Vector2i(8, 4)), 3, "the second stands beside it")
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.ARRIVED), 2)


func test_a_team_does_not_stand_on_a_cell_another_team_holds() -> void:
	var sim: Simulation = _sim([SimFixture.soldier("player", 2, 8, 4)])
	sim.order_move(1, Vector2i(8, 4))
	SimFixture.run(sim, 100)
	assert_ne(sim.soldiers[0].cell, Vector2i(8, 4))
	assert_ne(sim.soldiers[1].cell, Vector2i(8, 4))
	assert_eq(sim.soldiers[2].cell, Vector2i(8, 4), "team 2 has not been pushed off")


func test_an_order_to_an_obstacle_or_off_the_map_is_refused() -> void:
	var sim: Simulation = _sim([], "[10, 0, 1, 9]")
	assert_false(sim.order_move(1, Vector2i(10, 4)), "blocked cell")
	assert_false(sim.order_move(1, Vector2i(99, 4)), "off the map")
	SimFixture.run(sim, 10)
	assert_false(sim.soldiers[0].is_moving())


func test_an_order_for_a_team_with_nobody_in_it_is_refused() -> void:
	var sim: Simulation = _sim()
	assert_false(sim.order_move(7, Vector2i(5, 4)), "team 7 does not exist")
	assert_false(sim.order_fire(7, false))


func test_a_new_order_replaces_the_old_one() -> void:
	var sim: Simulation = _sim()
	sim.order_move(1, Vector2i(15, 4))
	SimFixture.run(sim, 12)
	sim.order_move(1, Vector2i(1, 1))
	SimFixture.run(sim, 200)
	assert_eq(sim.soldiers[0].cell, Vector2i(1, 1))


func test_walking_goes_round_a_wall() -> void:
	# A wall down column 10 with one gap in the top row.
	var sim: Simulation = _sim([], "[10, 1, 1, 8]")
	sim.order_move(1, Vector2i(15, 4))
	SimFixture.run(sim, 400)
	assert_eq(sim.soldiers[0].cell, Vector2i(15, 4))


func test_team_strength_remembers_the_starting_number() -> void:
	var sim: Simulation = _sim()
	sim.soldiers[0].alive = false
	assert_eq(sim.living(PLAYER, 1).size(), 1)
	assert_eq(sim.strength(PLAYER, 1), 2)

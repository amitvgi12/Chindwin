extends GutTest
## The player's fall-back order: a team returns to where it started, moving
## even when pinned, and does not fire on the way.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER


## Team 1 (two men) starts at (1, 4) and (1, 5). An unarmed enemy stands in range.
func _sim() -> Simulation:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("player", 1, 1, 5),
		SimFixture.soldier("enemy", 1, 12, 4, 0),
	]
	return Simulation.new(
		SimFixture.rules_with_suppression(),
		SimFixture.scenario(20, 9, soldiers),
		SimFixture.weapons(0, 0),
		SimFixture.SEED
	)


func _advance_then_fall_back(sim: Simulation) -> void:
	sim.order_move(1, Vector2i(7, 4))
	SimFixture.run(sim, 100)
	assert_eq(sim.soldiers[0].cell, Vector2i(7, 4), "the team went forward first")
	assert_true(sim.order_fall_back(1))


func test_a_team_falls_back_to_where_each_man_started() -> void:
	var sim: Simulation = _sim()
	_advance_then_fall_back(sim)
	SimFixture.run(sim, 100)
	assert_eq(sim.soldiers[0].cell, Vector2i(1, 4))
	assert_eq(sim.soldiers[1].cell, Vector2i(1, 5))
	assert_false(sim.soldiers[0].falling_back, "he has arrived")
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.ORDER_FALL_BACK), 1)


func test_men_falling_back_walk_even_when_pinned() -> void:
	var sim: Simulation = _sim()
	_advance_then_fall_back(sim)
	sim.step()
	sim.soldiers[0].suppression = 100
	SimFixture.run(sim, 20)
	assert_ne(sim.soldiers[0].cell, Vector2i(7, 4), "pinned, but going back all the same")


func test_men_falling_back_do_not_fire_until_they_arrive() -> void:
	var sim: Simulation = _sim()
	_advance_then_fall_back(sim)
	var shots_before: int = SimFixture.shots_by(sim, PLAYER)
	SimFixture.run(sim, 20)
	assert_true(sim.soldiers[0].falling_back)
	assert_eq(SimFixture.shots_by(sim, PLAYER), shots_before)


func test_men_who_have_fallen_back_stay_in_the_fight() -> void:
	var sim: Simulation = _sim()
	_advance_then_fall_back(sim)
	SimFixture.run(sim, 100)
	assert_eq(sim.in_fight_count(PLAYER), 2, "they are not counted as withdrawn")
	assert_true(sim.order_move(1, Vector2i(3, 4)), "and they take orders again")


func test_a_move_order_cancels_falling_back() -> void:
	var sim: Simulation = _sim()
	_advance_then_fall_back(sim)
	SimFixture.run(sim, 10)
	sim.order_move(1, Vector2i(7, 6))
	sim.step()
	assert_false(sim.soldiers[0].falling_back)
	sim.soldiers[0].suppression = 100
	var cell_when_pinned: Vector2i = sim.soldiers[0].cell
	SimFixture.run(sim, 10)
	assert_eq(sim.soldiers[0].cell, cell_when_pinned, "an ordinary move stops when pinned")


func test_a_team_already_at_its_start_does_nothing() -> void:
	var sim: Simulation = _sim()
	sim.order_fall_back(1)
	SimFixture.run(sim, 5)
	assert_false(sim.soldiers[0].falling_back)
	assert_eq(sim.soldiers[0].cell, Vector2i(1, 4))


func test_only_a_team_with_someone_left_can_be_told_to_fall_back() -> void:
	var sim: Simulation = _sim()
	assert_false(sim.order_fall_back(9))

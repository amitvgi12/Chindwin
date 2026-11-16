extends GutTest
## How a mission ends: objective taken, section broken, or withdrew.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
const ENEMY: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY


## Two teams of two on the left and one unarmed enemy far away. The section
## is broken when fewer than two of the four men are fit.
func _sim() -> Simulation:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 2, 5),
		SimFixture.soldier("player", 1, 1, 3, 5),
		SimFixture.soldier("player", 2, 1, 5, 5),
		SimFixture.soldier("player", 2, 1, 6, 5),
		SimFixture.soldier("enemy", 1, 18, 4, 0),
	]
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers)
	scenario.section_broken_below = 2
	return Simulation.new(SimFixture.rules(), scenario, SimFixture.weapons(0, 0), SimFixture.SEED)


func test_a_mission_starts_in_progress() -> void:
	var sim: Simulation = _sim()
	SimFixture.run(sim, 20)
	assert_eq(sim.outcome(), Simulation.Outcome.IN_PROGRESS)


func test_the_objective_is_taken_when_the_enemy_has_nobody_left() -> void:
	var sim: Simulation = _sim()
	sim.soldiers[4].alive = false
	sim.step()
	assert_eq(sim.outcome(), Simulation.Outcome.OBJECTIVE_TAKEN)


func test_an_enemy_who_withdraws_also_gives_up_the_objective() -> void:
	var sim: Simulation = _sim()
	sim.withdraw(sim.soldiers[4])
	sim.step()
	assert_eq(sim.outcome(), Simulation.Outcome.OBJECTIVE_TAKEN)


func test_the_section_is_broken_when_too_few_men_are_fit() -> void:
	var sim: Simulation = _sim()
	sim.soldiers[0].alive = false
	sim.soldiers[1].alive = false
	sim.step()
	assert_eq(sim.outcome(), Simulation.Outcome.IN_PROGRESS, "two of four left: still going")
	sim.soldiers[2].alive = false
	sim.step()
	assert_eq(sim.outcome(), Simulation.Outcome.SECTION_BROKEN, "one left: broken")


func test_taking_the_objective_counts_even_if_it_cost_the_section() -> void:
	var sim: Simulation = _sim()
	for index: int in 3:
		sim.soldiers[index].alive = false
	sim.soldiers[4].alive = false
	sim.step()
	assert_eq(sim.outcome(), Simulation.Outcome.OBJECTIVE_TAKEN)


func test_withdrawing_needs_every_team_to_fall_back_and_arrive() -> void:
	var sim: Simulation = _sim()
	sim.order_move(1, Vector2i(6, 2))
	sim.order_move(2, Vector2i(6, 6))
	SimFixture.run(sim, 100)
	sim.order_fall_back(1)
	SimFixture.run(sim, 100)
	assert_eq(sim.outcome(), Simulation.Outcome.IN_PROGRESS, "team 2 has not been told to go")
	sim.order_fall_back(2)
	SimFixture.run(sim, 10)
	assert_eq(sim.outcome(), Simulation.Outcome.IN_PROGRESS, "team 2 is still on its way")
	SimFixture.run(sim, 100)
	assert_eq(sim.outcome(), Simulation.Outcome.WITHDREW)


func test_a_new_move_order_cancels_the_withdrawal() -> void:
	var sim: Simulation = _sim()
	sim.order_move(1, Vector2i(6, 2))
	SimFixture.run(sim, 100)
	sim.order_fall_back(1)
	sim.order_fall_back(2)
	SimFixture.run(sim, 5)
	sim.order_move(1, Vector2i(6, 2))
	SimFixture.run(sim, 200)
	assert_eq(sim.outcome(), Simulation.Outcome.IN_PROGRESS)


func test_a_team_with_nobody_left_does_not_hold_up_a_withdrawal() -> void:
	var sim: Simulation = _sim()
	sim.soldiers[2].alive = false
	sim.soldiers[3].alive = false
	sim.order_fall_back(1)
	SimFixture.run(sim, 5)
	assert_eq(sim.outcome(), Simulation.Outcome.WITHDREW)


func test_nothing_more_happens_once_the_mission_has_ended() -> void:
	var sim: Simulation = _sim()
	sim.soldiers[4].alive = false
	sim.step()
	var ended_at: int = sim.tick
	SimFixture.run(sim, 50)
	assert_eq(sim.tick, ended_at)
	assert_eq(sim.outcome(), Simulation.Outcome.OBJECTIVE_TAKEN)


func test_rounds_are_counted_from_the_start() -> void:
	var sim: Simulation = _sim()
	assert_eq(sim.rounds_at_start(PLAYER), 20)
	assert_eq(sim.rounds_left(PLAYER), 20)
	sim.soldiers[0].rounds = 1
	sim.soldiers[1].alive = false
	assert_eq(sim.rounds_left(PLAYER), 11, "a casualty's rounds are lost with him")
	assert_eq(sim.rounds_at_start(ENEMY), 0)


func test_the_test_range_breaks_the_section_below_four_men() -> void:
	var scenario: Scenario = Scenario.load_file("res://data/scenarios/test_range.json")
	assert_eq(scenario.section_broken_below, 4)

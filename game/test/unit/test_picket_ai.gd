extends GutTest
## Breaking, and the enemy picket's three reasons to give up its position.
## Uses SimFixture.rules_with_suppression(): pinned at 30, broken at 60, and
## the enemy reconsiders every tick.
##
## Layout used by most tests, on a 20 by 9 field:
##   enemy picket (team 1) at (10, 3) and (10, 5), behind a bank down column 9
##   fallback cell at (18, 4)

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
const ENEMY: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY
const BANK: String = "[9, 2, 1, 5]"
const FALLBACK: String = "[18, 4]"


## The two-man picket plus whatever attackers a test adds. Nobody can hit.
func _sim(attackers: Array[String], fallback: String = FALLBACK) -> Simulation:
	var soldiers: Array[String] = [
		SimFixture.soldier("enemy", 1, 10, 3, 0),
		SimFixture.soldier("enemy", 1, 10, 5, 0),
	]
	soldiers.append_array(attackers)
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers, "", BANK, fallback)
	assert_eq(scenario.errors, [] as Array[String], "test scenario must be valid")
	return Simulation.new(
		SimFixture.rules_with_suppression(), scenario, SimFixture.weapons(0, 0), SimFixture.SEED
	)


func _attacker_in_front() -> String:
	return SimFixture.soldier("player", 1, 5, 4, 0)


func _attacker_on_the_flank() -> String:
	return SimFixture.soldier("player", 2, 10, 0, 0)


func _log_mentions(sim: Simulation, words: String) -> bool:
	for line: String in sim.ai_log:
		if line.contains(words):
			return true
	return false


func test_a_man_breaks_at_the_broken_level() -> void:
	var sim: Simulation = _sim([_attacker_in_front()], "")
	sim.soldiers[2].suppression = 59
	sim.step()
	assert_false(sim.soldiers[2].broken)
	sim.soldiers[2].suppression = 60
	sim.step()
	assert_true(sim.soldiers[2].broken)


func test_a_broken_man_stays_broken_until_the_pressure_is_below_the_pinned_level() -> void:
	var sim: Simulation = _sim([_attacker_in_front()], "")
	sim.soldiers[2].suppression = 60
	sim.step()
	sim.soldiers[2].suppression = 45
	sim.step()
	assert_true(sim.soldiers[2].broken, "between pinned and broken: still broken")
	sim.soldiers[2].suppression = 29
	sim.step()
	assert_false(sim.soldiers[2].broken, "below pinned: recovered")


func test_a_broken_man_does_not_fire() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("enemy", 1, 5, 4, 0),
	]
	var sim: Simulation = Simulation.new(
		SimFixture.rules_with_suppression(),
		SimFixture.scenario(20, 9, soldiers),
		SimFixture.weapons(0, 0),
		SimFixture.SEED
	)
	sim.soldiers[0].suppression = 100
	SimFixture.run(sim, 30)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0)
	sim.soldiers[0].suppression = 0
	SimFixture.run(sim, 3)
	assert_gt(SimFixture.shots_by(sim, PLAYER), 0, "recovered: fires again")


func test_a_picket_under_no_pressure_holds() -> void:
	var sim: Simulation = _sim([_attacker_in_front(), _attacker_on_the_flank()])
	SimFixture.run(sim, 50)
	assert_false(sim.picket_is_falling_back(1))
	assert_eq(sim.in_fight_count(ENEMY), 2)
	assert_eq(sim.ai_log.size(), 0, "nothing decided, nothing logged")


func test_a_pinned_picket_that_is_not_flanked_holds() -> void:
	var sim: Simulation = _sim([_attacker_in_front()])
	sim.soldiers[0].suppression = 40
	sim.soldiers[1].suppression = 40
	sim.step()
	assert_false(sim.picket_is_falling_back(1), "fire over the bank alone does not move it")


func test_a_flanked_picket_that_is_not_pinned_holds() -> void:
	var sim: Simulation = _sim([_attacker_on_the_flank()])
	sim.step()
	assert_false(sim.picket_is_falling_back(1))


func test_a_picket_that_is_flanked_and_half_pinned_falls_back() -> void:
	var sim: Simulation = _sim([_attacker_in_front(), _attacker_on_the_flank()])
	sim.soldiers[0].suppression = 40
	sim.step()
	assert_true(sim.picket_is_falling_back(1))
	assert_true(_log_mentions(sim, "flanked and pinned (1 of 2 pinned)"), str(sim.ai_log))
	assert_true(sim.soldiers[0].falling_back)
	assert_true(sim.soldiers[1].falling_back, "the whole picket goes, not just the pinned man")


func test_a_picket_that_has_lost_half_its_men_falls_back() -> void:
	var sim: Simulation = _sim([_attacker_in_front()])
	sim.soldiers[1].alive = false
	sim.step()
	assert_true(sim.picket_is_falling_back(1))
	assert_true(_log_mentions(sim, "lost half its men (1 of 2 left)"), str(sim.ai_log))


func test_a_single_broken_man_goes_back_alone() -> void:
	var sim: Simulation = _sim([_attacker_in_front()])
	sim.soldiers[0].suppression = 100
	sim.step()
	assert_true(sim.soldiers[0].falling_back)
	assert_false(sim.soldiers[1].falling_back, "his comrade stays")
	assert_false(sim.picket_is_falling_back(1), "the picket as a whole has not given up yet")
	assert_true(_log_mentions(sim, "breaks and goes back"), str(sim.ai_log))


func test_men_falling_back_walk_even_while_pinned_and_do_not_fire() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("enemy", 1, 10, 3),
		SimFixture.soldier("enemy", 1, 10, 5),
		_attacker_in_front(),
		_attacker_on_the_flank(),
	]
	var sim: Simulation = Simulation.new(
		SimFixture.rules_with_suppression(),
		SimFixture.scenario(20, 9, soldiers, "", BANK, FALLBACK),
		SimFixture.weapons(0, 0),
		SimFixture.SEED
	)
	sim.soldiers[0].suppression = 50
	sim.soldiers[1].suppression = 50
	sim.step()
	var shots_when_ordered_back: int = SimFixture.shots_by(sim, ENEMY)
	SimFixture.run(sim, 20)
	assert_ne(sim.soldiers[0].cell, Vector2i(10, 3), "he has left his position")
	assert_eq(SimFixture.shots_by(sim, ENEMY), shots_when_ordered_back, "no firing on the way")


func test_men_who_reach_the_fallback_cell_leave_the_fight_unhurt() -> void:
	var sim: Simulation = _sim([_attacker_in_front(), _attacker_on_the_flank()])
	sim.soldiers[0].suppression = 40
	SimFixture.run(sim, 200)
	assert_eq(sim.in_fight_count(ENEMY), 0)
	assert_eq(sim.withdrawn_count(ENEMY), 2)
	assert_eq(sim.casualty_count(ENEMY), 0, "withdrawn men are not casualties")
	assert_true(sim.soldiers[0].alive)
	assert_eq(sim.living(ENEMY, 1).size(), 0)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.WITHDREW), 2)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.PICKET_FALLS_BACK), 1)


func test_a_withdrawn_man_is_not_shot_at() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("enemy", 1, 5, 4, 0),
		SimFixture.soldier("player", 1, 1, 4),
	]
	var sim: Simulation = Simulation.new(
		SimFixture.rules_with_suppression(),
		SimFixture.scenario(20, 9, soldiers),
		SimFixture.weapons(100, 0),
		SimFixture.SEED
	)
	sim.withdraw(sim.soldiers[0])
	SimFixture.run(sim, 30)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0)
	assert_true(sim.soldiers[0].alive)


func test_with_no_fallback_cell_the_picket_only_ever_holds() -> void:
	var sim: Simulation = _sim([_attacker_in_front(), _attacker_on_the_flank()], "")
	sim.soldiers[0].suppression = 100
	sim.soldiers[1].alive = false
	SimFixture.run(sim, 20)
	assert_false(sim.picket_is_falling_back(1))
	assert_eq(sim.soldiers[0].cell, Vector2i(10, 3))
	assert_eq(sim.ai_log.size(), 0)


func test_every_decision_is_logged_with_its_tick() -> void:
	var sim: Simulation = _sim([_attacker_in_front(), _attacker_on_the_flank()])
	SimFixture.run(sim, 7)
	sim.soldiers[0].suppression = 40
	sim.step()
	assert_eq(sim.ai_log.size(), 1)
	assert_true(sim.ai_log[0].begins_with("tick 8: picket 1 falls back"), sim.ai_log[0])


func test_a_fallback_cell_on_an_obstacle_is_refused() -> void:
	var scenario: Scenario = SimFixture.scenario(20, 9, [], "[18, 4, 1, 1]", "", FALLBACK)
	assert_false(scenario.is_valid())

extends GutTest
## Walking away: a hungry man of the player's who breaks may leave for good
## (pillar 4). SimFixture.rules_with_suppression() breaks a man at 60.
## These tests set walk_away_hunger 40 and walk_away_max_percent 100, so a
## starving man always goes and the chance is easy to work out.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
const ENEMY: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY


func _rules(max_percent: int = 100) -> SimRules:
	var rules: SimRules = SimFixture.rules_with_suppression()
	rules.walk_away_hunger = 40
	rules.walk_away_max_percent = max_percent
	return rules


## Two of the player's men in team 1 standing at x = 8, having started at x = 1.
func _sim(hunger: int, rules: SimRules = null, extra: Array[String] = []) -> Simulation:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 3), SimFixture.soldier("player", 1, 1, 5)
	]
	soldiers.append_array(extra)
	var text: String = (
		'{"width": 20, "height": 9, "condition": {"player": {"hunger": %d}}, "soldiers": [%s]}'
		% [hunger, ", ".join(soldiers)]
	)
	var scenario: Scenario = Scenario.from_json_text(text)
	assert_eq(scenario.errors, [] as Array[String], "test scenario must be valid")
	var sim: Simulation = Simulation.new(
		rules if rules != null else _rules(), scenario, SimFixture.weapons(0, 0), SimFixture.SEED
	)
	sim.soldiers[0].cell = Vector2i(8, 3)
	sim.soldiers[1].cell = Vector2i(8, 5)
	return sim


func _break(sim: Simulation, soldier: SimSoldier) -> void:
	soldier.suppression = 100
	sim.step()


func test_the_chance_rises_with_hunger_above_the_threshold() -> void:
	var sim: Simulation = _sim(0, _rules(30))
	var man: SimSoldier = sim.soldiers[0]
	for pair: Array in [[0, 0], [40, 0], [60, 10], [80, 20], [100, 30]]:
		man.hunger = pair[0]
		assert_eq(sim.walk_away_chance_percent(man), pair[1], "hunger %d" % pair[0])


func test_a_starving_man_who_breaks_walks_back_the_way_he_came() -> void:
	var sim: Simulation = _sim(100)
	_break(sim, sim.soldiers[0])
	var man: SimSoldier = sim.soldiers[0]
	assert_true(man.walking_away)
	assert_true(man.is_moving())
	assert_eq(man.destination(), Vector2i(1, 3), "to where he started")
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.WALKED_AWAY), 1)
	assert_false(sim.soldiers[1].walking_away, "only the man who broke")


func test_when_he_gets_there_he_is_gone() -> void:
	var sim: Simulation = _sim(100)
	_break(sim, sim.soldiers[0])
	SimFixture.run(sim, 60)
	var man: SimSoldier = sim.soldiers[0]
	assert_true(man.withdrawn)
	assert_false(man.in_fight())
	assert_eq(sim.walked_away_count(PLAYER), 1)
	assert_eq(sim.withdrawn_count(PLAYER), 0, "walking away is not counted as getting away")
	assert_eq(sim.in_fight_count(PLAYER), 1)


func test_a_man_below_the_threshold_never_walks_away() -> void:
	var sim: Simulation = _sim(40)
	_break(sim, sim.soldiers[0])
	assert_true(sim.soldiers[0].broken)
	assert_false(sim.soldiers[0].walking_away)


func test_nobody_walks_away_when_it_is_turned_off() -> void:
	var sim: Simulation = _sim(100, _rules(0))
	_break(sim, sim.soldiers[0])
	assert_false(sim.soldiers[0].walking_away)


func test_the_roll_is_made_once_as_he_breaks_not_every_tick() -> void:
	# At hunger 70 the chance is 50%. Over many breakings some men go and some
	# stay; one man kept broken for a long time is rolled for only once.
	var sim: Simulation = _sim(70)
	var man: SimSoldier = sim.soldiers[0]
	man.suppression = 100
	SimFixture.run(sim, 1)
	var went: bool = man.walking_away
	for count: int in 50:
		man.suppression = 100
		sim.step()
		assert_eq(man.walking_away, went, "still broken: no new roll")
		if went:
			return


func test_a_man_walking_away_takes_no_orders() -> void:
	var sim: Simulation = _sim(100)
	_break(sim, sim.soldiers[0])
	assert_true(sim.order_move(1, Vector2i(12, 4)))
	sim.step()
	assert_eq(sim.soldiers[0].destination(), Vector2i(1, 3), "he keeps going")
	assert_eq(sim.soldiers[1].destination().x, 12, "his comrade obeys")


func test_a_man_walking_away_does_not_fire() -> void:
	var sim: Simulation = _sim(100, _rules(), [SimFixture.soldier("enemy", 1, 12, 3)])
	sim.soldiers[1].fire_allowed = false
	_break(sim, sim.soldiers[0])
	SimFixture.run(sim, 30)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0)


func test_the_enemy_never_walks_away() -> void:
	var sim: Simulation = _sim(100, _rules(), [SimFixture.soldier("enemy", 1, 12, 3)])
	var enemy: SimSoldier = sim.soldiers[2]
	enemy.hunger = 100
	_break(sim, enemy)
	assert_false(enemy.walking_away)


func test_with_nothing_rolled_a_fed_section_gives_the_same_battle() -> void:
	# Walking away must not use the dice unless someone is hungry enough.
	var first: Simulation = _sim(0, _rules(), [SimFixture.soldier("enemy", 1, 12, 3)])
	var second: Simulation = _sim(0, _rules(0), [SimFixture.soldier("enemy", 1, 12, 3)])
	for sim: Simulation in [first, second]:
		_break(sim, sim.soldiers[0])
		SimFixture.run(sim, 200)
	assert_eq(first.snapshot(), second.snapshot())

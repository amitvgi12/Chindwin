extends GutTest
## Food: rations carried and on the ground, the eat order, and gathering food.
## SimFixture.rules(): a meal takes 10 ticks and takes 40 hunger away; a man
## carries three rations at most; one item is gathered every 5 ticks.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
const ENEMY: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY


func _man(x: int, y: int, rounds: int = 99, rations: int = 0) -> String:
	return (
		'{"side": "player", "team": 1, "cell": [%d, %d], "weapon": "player_rifle", ' % [x, y]
		+ '"rounds": %d, "rations": %d}' % [rounds, rations]
	)


func _scenario(soldiers: Array[String], hunger: int, caches: String = "") -> Scenario:
	var text: String = (
		'{"width": 20, "height": 9, "condition": {"player": {"hunger": %d}}, ' % hunger
		+ '"caches": [%s], "soldiers": [%s]}' % [caches, ", ".join(soldiers)]
	)
	return Scenario.from_json_text(text)


func _sim(
	soldiers: Array[String], hunger: int = 60, caches: String = "", rules: SimRules = null
) -> Simulation:
	var scenario: Scenario = _scenario(soldiers, hunger, caches)
	assert_eq(scenario.errors, [] as Array[String], "test scenario must be valid")
	return Simulation.new(
		rules if rules != null else SimFixture.rules(),
		scenario,
		SimFixture.weapons(0, 0),
		SimFixture.SEED
	)


func test_rations_are_read_for_soldiers_and_boxes() -> void:
	var sim: Simulation = _sim(
		[_man(2, 4, 10, 2)], 60, '{"cell": [5, 4], "rations": 4}, {"cell": [6, 4], "rounds": 9}'
	)
	assert_eq(sim.soldiers[0].rations, 2)
	assert_eq(sim.rations_on_the_ground(), 4)
	assert_eq(sim.rounds_on_the_ground(), 9)
	assert_eq(sim.team_rations(PLAYER, 1), 2)


func test_a_soldier_without_rations_listed_carries_none() -> void:
	var scenario: Scenario = SimFixture.scenario(20, 9, [SimFixture.soldier("player", 1, 2, 4)])
	assert_eq(scenario.soldiers[0].rations, 0)


func test_bad_food_entries_are_reported() -> void:
	assert_false(_scenario([_man(2, 4, 10, -1)], 0).is_valid(), "negative rations")
	assert_false(_scenario([_man(2, 4)], 0, '{"cell": [5, 4]}').is_valid(), "empty box")
	assert_false(_scenario([_man(2, 4)], 0, '{"cell": [5, 4], "rations": -2}').is_valid())


func test_a_man_eats_one_ration_in_ten_ticks_and_stops() -> void:
	var sim: Simulation = _sim([_man(2, 4, 99, 2)], 60)
	assert_true(sim.order_eat(1))
	SimFixture.run(sim, 9)
	assert_eq(sim.soldiers[0].hunger, 60, "not yet")
	assert_eq(sim.eating_count(PLAYER, 1), 1)
	SimFixture.run(sim, 1)
	assert_eq(sim.soldiers[0].hunger, 20)
	assert_eq(sim.soldiers[0].rations, 1)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.ATE), 1)
	SimFixture.run(sim, 30)
	assert_eq(sim.soldiers[0].rations, 1, "one ration per order")
	assert_eq(sim.eating_count(PLAYER, 1), 0)


func test_hunger_does_not_go_below_zero() -> void:
	var sim: Simulation = _sim([_man(2, 4, 99, 1)], 15)
	sim.order_eat(1)
	SimFixture.run(sim, 10)
	assert_eq(sim.soldiers[0].hunger, 0)


func test_nobody_can_be_told_to_eat_without_food_or_hunger() -> void:
	assert_false(_sim([_man(2, 4, 99, 0)], 60).order_eat(1), "no rations")
	assert_false(_sim([_man(2, 4, 99, 3)], 0).order_eat(1), "not hungry")


func test_only_the_men_with_food_eat() -> void:
	var sim: Simulation = _sim([_man(2, 4, 99, 1), _man(2, 5, 99, 0)], 60)
	sim.order_eat(1)
	SimFixture.run(sim, 10)
	assert_eq(sim.soldiers[0].hunger, 20)
	assert_eq(sim.soldiers[1].hunger, 60)


func test_a_man_eating_does_not_fire() -> void:
	var soldiers: Array[String] = [_man(2, 4, 99, 1), SimFixture.soldier("enemy", 1, 6, 4)]
	var sim: Simulation = _sim(soldiers, 60)
	sim.order_eat(1)
	SimFixture.run(sim, 10)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0, "he ate instead")
	SimFixture.run(sim, 1)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 1, "and fires once he has eaten")


func test_a_pinned_man_waits_to_eat() -> void:
	var rules: SimRules = SimFixture.rules_with_suppression()
	var sim: Simulation = _sim([_man(2, 4, 99, 1)], 60, "", rules)
	sim.soldiers[0].suppression = 100
	sim.order_eat(1)
	SimFixture.run(sim, 20)
	assert_eq(sim.soldiers[0].rations, 1, "pinned for all of it")
	SimFixture.run(sim, 400)
	assert_eq(sim.soldiers[0].rations, 0, "ate once the pressure had faded")


func test_a_move_order_puts_the_food_away_uneaten() -> void:
	var sim: Simulation = _sim([_man(2, 4, 99, 1)], 60)
	sim.order_eat(1)
	SimFixture.run(sim, 5)
	sim.order_move(1, Vector2i(6, 4))
	SimFixture.run(sim, 60)
	assert_eq(sim.soldiers[0].rations, 1)
	assert_eq(sim.soldiers[0].hunger, 60)


func test_a_fallen_man_leaves_his_rations_with_his_rounds() -> void:
	var soldiers: Array[String] = [_man(2, 4, 7, 2), SimFixture.soldier("enemy", 1, 6, 4)]
	var scenario: Scenario = _scenario(soldiers, 0)
	var sim: Simulation = Simulation.new(
		SimFixture.rules(), scenario, SimFixture.weapons(0, 100), SimFixture.SEED
	)
	SimFixture.run(sim, 1)
	assert_false(sim.soldiers[0].alive)
	var left: AmmoCache = sim.cache_within_reach(Vector2i(2, 4))
	assert_eq(left.rations, 2)
	assert_eq(left.rounds, 6, "one round fired before he fell")


func test_gathering_takes_rounds_first_then_rations() -> void:
	var sim: Simulation = _sim(
		[_man(4, 4, 10, 0)], 0, '{"cell": [5, 4], "rounds": 1, "rations": 5}'
	)
	sim.order_gather(1, true)
	SimFixture.run(sim, 5)
	assert_eq(sim.soldiers[0].rounds, 11)
	assert_eq(sim.soldiers[0].rations, 0)
	SimFixture.run(sim, 100)
	assert_eq(sim.soldiers[0].rations, 3, "three at most")
	assert_eq(sim.rations_on_the_ground(), 2)
	assert_eq(sim.gathering_count(PLAYER, 1), 0)


func test_a_man_full_of_rounds_still_gathers_food() -> void:
	var sim: Simulation = _sim(
		[_man(4, 4, 12, 0)], 0, '{"cell": [5, 4], "rounds": 9, "rations": 1}'
	)
	sim.order_gather(1, true)
	SimFixture.run(sim, 5)
	assert_eq(sim.soldiers[0].rations, 1)
	assert_eq(sim.rounds_on_the_ground(), 9)

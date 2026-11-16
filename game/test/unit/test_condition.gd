extends GutTest
## Condition: hunger and fatigue, the slow half of a man's will to fight.
## They set a floor that his suppression cannot fade below (GDD section 4).
## SimFixture.rules() has condition off; these tests turn it on.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
const ENEMY: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY
const RULES: String = "res://data/rules/prototype_rules.tres"


## Hunger +1 every 10 ticks, fatigue +1 every 5 ticks walked and -1 every 10
## ticks still. Floor: 30% of hunger plus 20% of fatigue, at most 40.
func _rules() -> SimRules:
	var rules: SimRules = SimFixture.rules_with_suppression()
	rules.hunger_rise_ticks = 10
	rules.fatigue_walk_ticks = 5
	rules.fatigue_rest_ticks = 10
	return rules


func _scenario(condition: String, soldiers: Array[String]) -> Scenario:
	var text: String = (
		'{"width": 20, "height": 9, "condition": %s, "soldiers": [%s]}'
		% [condition, ", ".join(soldiers)]
	)
	return Scenario.from_json_text(text)


func _sim(condition: String, soldiers: Array[String], rules: SimRules = null) -> Simulation:
	var scenario: Scenario = _scenario(condition, soldiers)
	assert_eq(scenario.errors, [] as Array[String], "test scenario must be valid")
	return Simulation.new(
		rules if rules != null else _rules(), scenario, SimFixture.weapons(0, 0), SimFixture.SEED
	)


func _one_man() -> Array[String]:
	return [SimFixture.soldier("player", 1, 2, 4)]


func test_each_side_starts_as_the_scenario_says() -> void:
	var sim: Simulation = _sim(
		'{"player": {"hunger": 60, "fatigue": 10}, "enemy": {"fatigue": 5}}',
		[SimFixture.soldier("player", 1, 2, 4), SimFixture.soldier("enemy", 1, 18, 4)]
	)
	assert_eq(sim.soldiers[0].hunger, 60)
	assert_eq(sim.soldiers[0].fatigue, 10)
	assert_eq(sim.soldiers[1].hunger, 0, "not given, so fed")
	assert_eq(sim.soldiers[1].fatigue, 5)


func test_a_scenario_without_condition_starts_everyone_fed_and_rested() -> void:
	var scenario: Scenario = SimFixture.scenario(20, 9, _one_man())
	var sim: Simulation = Simulation.new(
		_rules(), scenario, SimFixture.weapons(0, 0), SimFixture.SEED
	)
	assert_eq(sim.soldiers[0].hunger, 0)
	assert_eq(sim.soldiers[0].fatigue, 0)
	assert_eq(sim.soldiers[0].suppression, 0)


func test_bad_condition_entries_are_reported() -> void:
	assert_false(_scenario('{"player": {"hunger": 120}}', _one_man()).is_valid())
	assert_false(_scenario('{"player": {"hunger": -1}}', _one_man()).is_valid())
	assert_false(_scenario('{"allies": {"hunger": 10}}', _one_man()).is_valid())
	assert_false(_scenario('{"player": 10}', _one_man()).is_valid())
	assert_false(_scenario("[1]", _one_man()).is_valid())


func test_hunger_rises_with_time_for_everyone_in_the_fight() -> void:
	var sim: Simulation = _sim('{"player": {"hunger": 20}}', _one_man())
	SimFixture.run(sim, 9)
	assert_eq(sim.soldiers[0].hunger, 20)
	SimFixture.run(sim, 1)
	assert_eq(sim.soldiers[0].hunger, 21)
	SimFixture.run(sim, 100)
	assert_eq(sim.soldiers[0].hunger, 31)


func test_hunger_stops_at_100() -> void:
	var sim: Simulation = _sim('{"player": {"hunger": 99}}', _one_man())
	SimFixture.run(sim, 50)
	assert_eq(sim.soldiers[0].hunger, 100)


func test_a_hungry_mans_suppression_never_fades_below_his_floor() -> void:
	# Hunger 60 holds suppression at 18 (30% of 60).
	var rules: SimRules = _rules()
	rules.hunger_rise_ticks = 0
	var sim: Simulation = _sim('{"player": {"hunger": 60}}', _one_man(), rules)
	assert_eq(sim.condition_floor(sim.soldiers[0]), 18)
	assert_eq(sim.soldiers[0].suppression, 18, "the meter starts at the floor")
	sim.soldiers[0].suppression = 25
	SimFixture.run(sim, 200)
	assert_eq(sim.soldiers[0].suppression, 18, "fades back to the floor, no lower")


func test_the_floor_adds_hunger_and_fatigue_and_is_capped() -> void:
	var sim: Simulation = _sim('{"player": {"hunger": 50, "fatigue": 50}}', _one_man())
	assert_eq(sim.condition_floor(sim.soldiers[0]), 25, "15 from hunger and 10 from fatigue")
	sim.soldiers[0].hunger = 100
	sim.soldiers[0].fatigue = 100
	assert_eq(sim.condition_floor(sim.soldiers[0]), 40, "capped at condition_floor_max")


func test_walking_tires_a_man_and_resting_restores_him() -> void:
	var rules: SimRules = _rules()
	rules.hunger_rise_ticks = 0
	var sim: Simulation = _sim("{}", _one_man(), rules)
	sim.order_move(1, Vector2i(14, 4))
	# Twelve cells at 5 ticks each: 60 ticks walking, +1 every 5.
	SimFixture.run(sim, 60)
	assert_eq(sim.soldiers[0].cell, Vector2i(14, 4))
	var tired: int = sim.soldiers[0].fatigue
	assert_between(tired, 11, 12, "about one point for every five ticks walked")
	SimFixture.run(sim, 50)
	assert_eq(sim.soldiers[0].fatigue, tired - 5, "one point back every ten ticks still")


func test_a_hungry_man_is_pinned_by_less_fire() -> void:
	# Pinned at 30; each shot adds 10. An enemy five cells off misses every
	# shot, firing at ticks 1 and 11. Fed, two shots leave a man short of
	# pinned. Hungry (60, floor 18), the same two shots pin him.
	var rules: SimRules = _rules()
	rules.hunger_rise_ticks = 0
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 2, 4), SimFixture.soldier("enemy", 1, 7, 4)
	]
	var fed: Simulation = _sim("{}", soldiers, rules)
	var hungry: Simulation = _sim('{"player": {"hunger": 60}}', soldiers, rules)
	SimFixture.run(fed, 11)
	SimFixture.run(hungry, 11)
	assert_eq(SimFixture.shots_by(fed, ENEMY), 2)
	assert_false(fed.is_pinned(fed.soldiers[0]), "fed: %d" % fed.soldiers[0].suppression)
	assert_true(hungry.is_pinned(hungry.soldiers[0]), "hungry: %d" % hungry.soldiers[0].suppression)


func test_the_shipped_floor_never_pins_a_man_on_its_own() -> void:
	var rules: SimRules = load(RULES) as SimRules
	assert_lt(rules.condition_floor_max, rules.pinned_threshold)


func test_casualties_and_withdrawn_men_stop_getting_hungrier() -> void:
	var sim: Simulation = _sim('{"player": {"hunger": 20}}', _one_man())
	sim.withdraw(sim.soldiers[0])
	SimFixture.run(sim, 50)
	assert_eq(sim.soldiers[0].hunger, 20)

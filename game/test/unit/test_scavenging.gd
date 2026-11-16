extends GutTest
## Scavenging: rounds on the ground, and the gather order that picks them up.
## SimFixture.rules(): one round every 5 ticks, a man carries 12 at most.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
const ENEMY: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY


## A 20 by 9 field with a box of `box_rounds` at (5, 4), plus the soldiers given.
func _sim(soldiers: Array[String], box_rounds: int = 30, enemy_hit: int = 0) -> Simulation:
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers)
	assert_eq(scenario.errors, [] as Array[String], "test scenario must be valid")
	var box: Scenario.CacheSpec = Scenario.CacheSpec.new()
	box.cell = Vector2i(5, 4)
	box.rounds = box_rounds
	scenario.caches.append(box)
	return Simulation.new(
		SimFixture.rules(), scenario, SimFixture.weapons(0, enemy_hit), SimFixture.SEED
	)


## One man with 2 rounds standing right beside the box.
func _man_beside_the_box() -> Array[String]:
	return [SimFixture.soldier("player", 1, 4, 4, 2)]


func test_a_scenario_box_is_on_the_ground_from_the_start() -> void:
	var sim: Simulation = _sim(_man_beside_the_box())
	assert_eq(sim.rounds_on_the_ground(), 30)
	assert_eq(sim.cache_within_reach(Vector2i(4, 4)).cell, Vector2i(5, 4))
	assert_null(sim.cache_within_reach(Vector2i(2, 4)), "three cells away is out of reach")


func test_nobody_gathers_without_being_told() -> void:
	var sim: Simulation = _sim(_man_beside_the_box())
	SimFixture.run(sim, 50)
	assert_eq(sim.soldiers[0].rounds, 2)
	assert_eq(sim.rounds_on_the_ground(), 30)


func test_a_man_told_to_gather_picks_up_one_round_every_five_ticks() -> void:
	var sim: Simulation = _sim(_man_beside_the_box())
	assert_true(sim.order_gather(1, true))
	SimFixture.run(sim, 4)
	assert_eq(sim.soldiers[0].rounds, 2, "not yet")
	SimFixture.run(sim, 1)
	assert_eq(sim.soldiers[0].rounds, 3)
	assert_eq(sim.rounds_on_the_ground(), 29)
	SimFixture.run(sim, 10)
	assert_eq(sim.soldiers[0].rounds, 5)
	assert_eq(sim.gathering_count(PLAYER, 1), 1)


func test_a_man_stops_when_he_is_carrying_all_he_can() -> void:
	var sim: Simulation = _sim(_man_beside_the_box())
	sim.order_gather(1, true)
	SimFixture.run(sim, 300)
	assert_eq(sim.soldiers[0].rounds, 12)
	assert_eq(sim.rounds_on_the_ground(), 20)
	assert_eq(sim.gathering_count(PLAYER, 1), 0)


func test_gathering_stops_when_the_box_is_empty() -> void:
	var sim: Simulation = _sim(_man_beside_the_box(), 3)
	sim.order_gather(1, true)
	SimFixture.run(sim, 100)
	assert_eq(sim.soldiers[0].rounds, 5)
	assert_eq(sim.rounds_on_the_ground(), 0)
	assert_null(sim.cache_within_reach(Vector2i(4, 4)), "an empty box is not worth reaching for")


func test_a_man_too_far_from_the_box_gathers_nothing() -> void:
	var sim: Simulation = _sim([SimFixture.soldier("player", 1, 2, 4, 2)])
	sim.order_gather(1, true)
	SimFixture.run(sim, 50)
	assert_eq(sim.soldiers[0].rounds, 2)


func test_a_man_gathers_once_he_has_walked_to_the_box() -> void:
	var sim: Simulation = _sim([SimFixture.soldier("player", 1, 1, 4, 2)])
	sim.order_gather(1, true)
	sim.order_move(1, Vector2i(4, 4))
	SimFixture.run(sim, 14)
	assert_eq(sim.soldiers[0].rounds, 2, "still walking: nothing picked up")
	SimFixture.run(sim, 20)
	assert_gt(sim.soldiers[0].rounds, 2)


func test_a_man_who_is_gathering_does_not_fire() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 4, 4, 2),
		SimFixture.soldier("enemy", 1, 8, 4, 0),
	]
	var sim: Simulation = _sim(soldiers)
	sim.order_gather(1, true)
	SimFixture.run(sim, 40)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0)
	assert_gt(sim.soldiers[0].rounds, 2)


func test_he_fires_again_once_told_to_stop_gathering() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 4, 4, 2),
		SimFixture.soldier("enemy", 1, 8, 4, 0),
	]
	var sim: Simulation = _sim(soldiers)
	sim.order_gather(1, true)
	SimFixture.run(sim, 20)
	sim.order_gather(1, false)
	SimFixture.run(sim, 15)
	assert_gt(SimFixture.shots_by(sim, PLAYER), 0)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.ORDER_GATHER), 1)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.ORDER_STOP_GATHERING), 1)


func test_a_pinned_man_does_not_gather() -> void:
	var scenario: Scenario = SimFixture.scenario(20, 9, _man_beside_the_box())
	var box: Scenario.CacheSpec = Scenario.CacheSpec.new()
	box.cell = Vector2i(5, 4)
	box.rounds = 30
	scenario.caches.append(box)
	var sim: Simulation = Simulation.new(
		SimFixture.rules_with_suppression(), scenario, SimFixture.weapons(0, 0), SimFixture.SEED
	)
	sim.order_gather(1, true)
	sim.soldiers[0].suppression = 100
	SimFixture.run(sim, 20)
	assert_eq(sim.soldiers[0].rounds, 2)


func test_a_man_who_falls_leaves_his_rounds_where_he_fell() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 10, 2, 7),
		SimFixture.soldier("enemy", 1, 13, 2, 5),
	]
	var sim: Simulation = _sim(soldiers, 30, 100)
	sim.order_fire(1, false)
	sim.step()
	assert_false(sim.soldiers[0].alive)
	assert_eq(sim.soldiers[0].rounds, 0)
	assert_eq(sim.rounds_on_the_ground(), 37, "the box and the seven he carried")
	assert_eq(sim.cache_within_reach(Vector2i(10, 3)).rounds, 7)


func test_a_comrade_can_gather_what_the_fallen_man_carried() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 10, 2, 7),
		SimFixture.soldier("player", 2, 10, 3, 0),
		SimFixture.soldier("enemy", 1, 13, 2, 1),
	]
	var sim: Simulation = _sim(soldiers, 30, 100)
	sim.order_fire(1, false)
	# Held so that he does not spend what he picks up on the enemy still in range.
	sim.order_fire(2, false)
	sim.order_gather(2, true)
	SimFixture.run(sim, 60)
	assert_false(sim.soldiers[0].alive)
	assert_eq(sim.soldiers[1].rounds, 7)


func test_an_enemy_who_withdraws_takes_his_rounds_with_him() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4, 2),
		SimFixture.soldier("enemy", 1, 15, 4, 9),
	]
	var sim: Simulation = _sim(soldiers)
	sim.withdraw(sim.soldiers[1])
	assert_eq(sim.rounds_on_the_ground(), 30)


func test_caches_are_read_from_json_and_bad_ones_reported() -> void:
	var good: Scenario = Scenario.from_json_text(
		'{"width": 9, "height": 9, "soldiers": [], "caches": [{"cell": [3, 3], "rounds": 40}]}'
	)
	assert_eq(good.errors, [] as Array[String])
	assert_eq(good.caches[0].cell, Vector2i(3, 3))
	assert_eq(good.caches[0].rounds, 40)
	var empty: Scenario = Scenario.from_json_text(
		'{"width": 9, "height": 9, "soldiers": [], "caches": [{"cell": [3, 3], "rounds": 0}]}'
	)
	assert_false(empty.is_valid())
	var off_map: Scenario = Scenario.from_json_text(
		'{"width": 9, "height": 9, "soldiers": [], "caches": [{"cell": [30, 3], "rounds": 5}]}'
	)
	assert_false(off_map.is_valid())


func test_only_a_team_with_someone_left_can_be_told_to_gather() -> void:
	var sim: Simulation = _sim(_man_beside_the_box())
	assert_false(sim.order_gather(9, true))

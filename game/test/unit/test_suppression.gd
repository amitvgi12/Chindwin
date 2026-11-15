extends GutTest
## Suppression: pressure from incoming fire, how it fades, and what being
## pinned does to a man. Uses SimFixture.rules_with_suppression():
## 10 per shot, 4 to a neighbour, halved by cover, one point lost every
## 5 ticks, pinned at 30, a pinned man fires half as often and half as well.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
const ENEMY: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY


func _sim(
	soldiers: Array[String], player_hit: int, enemy_hit: int, cover: String = ""
) -> Simulation:
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers, "", cover)
	assert_eq(scenario.errors, [] as Array[String], "test scenario must be valid")
	return Simulation.new(
		SimFixture.rules_with_suppression(),
		scenario,
		SimFixture.weapons(player_hit, enemy_hit),
		SimFixture.SEED
	)


## One player at (1, 4) and one enemy four cells to his right.
func _duel(player_rounds: int, enemy_rounds: int, player_hit: int = 0) -> Simulation:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4, player_rounds),
		SimFixture.soldier("enemy", 1, 5, 4, enemy_rounds),
	]
	return _sim(soldiers, player_hit, 0)


func test_a_shot_that_misses_still_puts_pressure_on_the_target() -> void:
	var sim: Simulation = _duel(99, 99)
	sim.step()
	assert_eq(sim.soldiers[0].suppression, 10)
	assert_eq(sim.soldiers[1].suppression, 10)


func test_pressure_fades_one_point_every_five_ticks_down_to_zero() -> void:
	var sim: Simulation = _duel(0, 1)
	sim.step()
	assert_eq(sim.soldiers[0].suppression, 10, "the enemy's only round was fired at him")
	SimFixture.run(sim, 4)
	assert_eq(sim.soldiers[0].suppression, 9, "one point gone at tick five")
	SimFixture.run(sim, 45)
	assert_eq(sim.soldiers[0].suppression, 0)
	SimFixture.run(sim, 50)
	assert_eq(sim.soldiers[0].suppression, 0, "never below zero")


func test_cover_halves_the_pressure_on_the_man_behind_it() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("enemy", 1, 5, 4),
	]
	var sim: Simulation = _sim(soldiers, 0, 0, "[4, 4, 1, 1]")
	sim.step()
	assert_eq(sim.soldiers[1].suppression, 5, "the enemy is behind the bank")
	assert_eq(sim.soldiers[0].suppression, 10, "the player is in the open")


func test_men_standing_next_to_the_target_feel_some_of_it() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4, 0),
		SimFixture.soldier("player", 1, 1, 5, 0),
		SimFixture.soldier("player", 1, 1, 7, 0),
		SimFixture.soldier("enemy", 1, 5, 4, 1),
	]
	var sim: Simulation = _sim(soldiers, 0, 0)
	sim.step()
	assert_eq(sim.soldiers[0].suppression, 10, "the man shot at")
	assert_eq(sim.soldiers[1].suppression, 4, "the man beside him")
	assert_eq(sim.soldiers[2].suppression, 0, "the man three cells away")
	assert_eq(sim.soldiers[3].suppression, 0, "the shooter's own side feels nothing")


func test_pressure_never_goes_above_one_hundred() -> void:
	var sim: Simulation = _duel(0, 99)
	sim.soldiers[0].suppression = 98
	sim.step()
	assert_eq(sim.soldiers[0].suppression, 100)


func test_a_man_is_pinned_from_the_threshold_upwards() -> void:
	var sim: Simulation = _duel(0, 0)
	sim.soldiers[0].suppression = 29
	assert_false(sim.is_pinned(sim.soldiers[0]))
	assert_eq(sim.pinned_count(PLAYER, 1), 0)
	sim.soldiers[0].suppression = 30
	assert_true(sim.is_pinned(sim.soldiers[0]))
	assert_eq(sim.pinned_count(PLAYER, 1), 1)


func test_a_pinned_man_stops_walking_and_goes_on_when_the_pressure_fades() -> void:
	var sim: Simulation = _sim([SimFixture.soldier("player", 1, 1, 4)], 0, 0)
	sim.order_move(1, Vector2i(6, 4))
	sim.step()
	sim.soldiers[0].suppression = 32
	SimFixture.run(sim, 9)
	assert_eq(sim.soldiers[0].cell, Vector2i(1, 4), "pinned where he was")
	assert_true(sim.soldiers[0].is_moving(), "he has not forgotten his order")
	SimFixture.run(sim, 100)
	assert_eq(sim.soldiers[0].cell, Vector2i(6, 4), "he carried on once it faded")


func test_a_pinned_man_fires_half_as_often() -> void:
	var sim: Simulation = _duel(99, 0)
	sim.soldiers[0].suppression = 40
	SimFixture.run(sim, 40)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 2, "ticks 1 and 21; unpinned it would be four")


func test_a_pinned_man_hits_half_as_often() -> void:
	var sim: Simulation = _duel(99, 0, 80)
	assert_eq(sim.hit_chance_percent(sim.soldiers[0], sim.soldiers[1]), 80)
	sim.soldiers[0].suppression = 30
	assert_eq(sim.hit_chance_percent(sim.soldiers[0], sim.soldiers[1]), 40)


func test_a_man_pinned_on_the_move_can_still_fire() -> void:
	var sim: Simulation = _duel(99, 0)
	sim.order_move(1, Vector2i(1, 8))
	sim.step()
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0, "walking: no shot")
	sim.soldiers[0].suppression = 40
	SimFixture.run(sim, 3)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 1, "pinned and stopped: he shoots back")


func test_fire_goes_to_the_opponent_under_least_pressure() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("enemy", 1, 4, 4, 0),
		SimFixture.soldier("enemy", 1, 6, 4, 0),
	]
	var sim: Simulation = _sim(soldiers, 0, 0)
	sim.step()
	assert_eq(sim.soldiers[1].suppression, 10, "first shot at the nearer man")
	SimFixture.run(sim, 10)
	assert_eq(sim.soldiers[2].suppression, 10, "second shot at the man with his head still up")
	assert_eq(sim.soldiers[1].suppression, 8, "the first man's pressure has begun to fade")


func test_a_casualty_carries_no_pressure() -> void:
	var sim: Simulation = _duel(99, 0, 100)
	sim.soldiers[1].suppression = 60
	sim.step()
	assert_false(sim.soldiers[1].alive)
	assert_eq(sim.soldiers[1].suppression, 0)
	assert_eq(sim.pinned_count(ENEMY, 1), 0)


func test_with_suppression_switched_off_nothing_builds_up() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("enemy", 1, 5, 4),
	]
	var sim: Simulation = Simulation.new(
		SimFixture.rules(),
		SimFixture.scenario(20, 9, soldiers),
		SimFixture.weapons(0, 0),
		SimFixture.SEED
	)
	SimFixture.run(sim, 50)
	assert_eq(sim.soldiers[0].suppression, 0)
	assert_eq(sim.soldiers[1].suppression, 0)

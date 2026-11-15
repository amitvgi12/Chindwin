extends GutTest
## Shooting: who fires, at whom, how often, with what, and what cover does.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
const ENEMY: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY


## A 20 by 9 field. `soldiers` come from SimFixture.soldier().
func _sim(
	soldiers: Array[String],
	player_hit_percent: int,
	enemy_hit_percent: int,
	blocked: String = "",
	cover: String = ""
) -> Simulation:
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers, blocked, cover)
	assert_eq(scenario.errors, [] as Array[String], "test scenario must be valid")
	return Simulation.new(
		SimFixture.rules(),
		scenario,
		SimFixture.weapons(player_hit_percent, enemy_hit_percent),
		SimFixture.SEED
	)


## One player at (1, 4) facing one enemy `distance` cells to his right.
func _duel(distance: int, player_hit: int, enemy_hit: int, rounds: int = 99) -> Simulation:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4, rounds),
		SimFixture.soldier("enemy", 1, 1 + distance, 4, rounds),
	]
	return _sim(soldiers, player_hit, enemy_hit)


func test_nobody_fires_at_an_opponent_out_of_range() -> void:
	var sim: Simulation = _duel(7, 100, 100)
	SimFixture.run(sim, 200)
	assert_eq(SimFixture.shots_by(sim, PLAYER) + SimFixture.shots_by(sim, ENEMY), 0)


func test_a_man_standing_still_fires_at_an_opponent_in_range() -> void:
	var sim: Simulation = _duel(6, 0, 0)
	sim.step()
	assert_eq(SimFixture.shots_by(sim, PLAYER), 1)
	assert_eq(SimFixture.shots_by(sim, ENEMY), 1)


func test_a_certain_hit_causes_a_casualty() -> void:
	var sim: Simulation = _duel(4, 100, 0)
	sim.step()
	assert_eq(sim.living(ENEMY, 1).size(), 0)
	assert_eq(sim.living(PLAYER, 1).size(), 1)


func test_a_weapon_that_cannot_hit_never_causes_a_casualty() -> void:
	var sim: Simulation = _duel(4, 0, 0)
	SimFixture.run(sim, 300)
	assert_gt(SimFixture.shots_by(sim, PLAYER), 5)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.SHOT_HIT), 0)


func test_two_men_can_hit_each_other_in_the_same_tick() -> void:
	var sim: Simulation = _duel(4, 100, 100)
	sim.step()
	assert_eq(sim.living(PLAYER, 1).size(), 0)
	assert_eq(sim.living(ENEMY, 1).size(), 0, "being hit this tick did not stop his shot")


func test_a_man_waits_the_weapon_interval_between_shots() -> void:
	var sim: Simulation = _duel(4, 0, 0)
	SimFixture.run(sim, 10)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 1, "one shot in the first ten ticks")
	SimFixture.run(sim, 1)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 2, "second shot on tick eleven")


func test_each_shot_uses_one_round_and_firing_stops_when_they_run_out() -> void:
	var sim: Simulation = _duel(4, 0, 0, 3)
	SimFixture.run(sim, 11)
	assert_eq(sim.soldiers[0].rounds, 1, "two shots fired from three rounds")
	SimFixture.run(sim, 500)
	assert_eq(sim.soldiers[0].rounds, 0)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 3, "no more shots than rounds")
	assert_eq(sim.team_rounds(PLAYER, 1), 0)


func test_a_man_with_no_weapon_never_fires() -> void:
	var sim: Simulation = _duel(4, 100, 0)
	sim.soldiers[0].weapon = null
	SimFixture.run(sim, 100)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0)
	assert_eq(sim.hit_chance_percent(sim.soldiers[0], sim.soldiers[1]), 0)


func test_a_walking_man_does_not_fire_and_starts_once_he_stops() -> void:
	var sim: Simulation = _duel(4, 0, 0)
	sim.order_move(1, Vector2i(1, 6))
	sim.step()
	var shots_before_walking: int = SimFixture.shots_by(sim, PLAYER)
	# Two cells take ten ticks. After nine he is still on his way.
	SimFixture.run(sim, 8)
	assert_true(sim.soldiers[0].is_moving())
	assert_eq(SimFixture.shots_by(sim, PLAYER), shots_before_walking, "no shots while walking")
	SimFixture.run(sim, 20)
	assert_false(sim.soldiers[0].is_moving())
	assert_gt(SimFixture.shots_by(sim, PLAYER), shots_before_walking, "fires again once still")


func test_a_team_told_to_hold_fire_stops_and_resumes_on_fire_at_will() -> void:
	var sim: Simulation = _duel(4, 0, 0)
	assert_true(sim.order_fire(1, false))
	SimFixture.run(sim, 100)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0, "holding fire from the first tick")
	assert_false(sim.team_may_fire(PLAYER, 1))
	assert_gt(SimFixture.shots_by(sim, ENEMY), 0, "the enemy is not affected")
	sim.order_fire(1, true)
	SimFixture.run(sim, 20)
	assert_gt(SimFixture.shots_by(sim, PLAYER), 0)
	assert_true(sim.team_may_fire(PLAYER, 1))


func test_holding_fire_saves_ammunition() -> void:
	var sim: Simulation = _duel(4, 0, 0, 10)
	sim.order_fire(1, false)
	SimFixture.run(sim, 300)
	assert_eq(sim.team_rounds(PLAYER, 1), 10)


func test_a_man_fires_at_the_nearest_opponent() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("enemy", 1, 6, 4),
		SimFixture.soldier("enemy", 1, 3, 4),
	]
	var sim: Simulation = _sim(soldiers, 100, 0)
	sim.step()
	assert_true(sim.soldiers[1].alive, "the far man is left alone")
	assert_false(sim.soldiers[2].alive, "the near man is the one hit")


func test_thick_jungle_between_two_men_stops_them_firing() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("enemy", 1, 5, 4),
	]
	var sim: Simulation = _sim(soldiers, 100, 100, "[3, 0, 1, 9]")
	SimFixture.run(sim, 100)
	assert_eq(SimFixture.shots_by(sim, PLAYER) + SimFixture.shots_by(sim, ENEMY), 0)


func test_cover_does_not_stop_men_seeing_and_firing() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("enemy", 1, 5, 4),
	]
	var sim: Simulation = _sim(soldiers, 0, 0, "", "[4, 4, 1, 1]")
	sim.step()
	assert_eq(SimFixture.shots_by(sim, PLAYER), 1)
	assert_eq(SimFixture.shots_by(sim, ENEMY), 1)


func test_cover_cuts_the_hit_chance_only_for_the_man_behind_it() -> void:
	# Player at (1, 4). Cover at (4, 4). Enemy right behind it at (5, 4).
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("enemy", 1, 5, 4),
	]
	var sim: Simulation = _sim(soldiers, 80, 80, "", "[4, 4, 1, 1]")
	var player: SimSoldier = sim.soldiers[0]
	var enemy: SimSoldier = sim.soldiers[1]
	assert_eq(sim.hit_chance_percent(player, enemy), 40, "80 cut to half by cover")
	assert_eq(sim.hit_chance_percent(enemy, player), 80, "the man in the open gets no help")


func test_cover_does_not_protect_against_fire_from_the_side() -> void:
	# Enemy at (5, 4) behind cover at (4, 4). One player in front, one to the north.
	var soldiers: Array[String] = [
		SimFixture.soldier("enemy", 1, 5, 4),
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("player", 2, 5, 1),
	]
	var sim: Simulation = _sim(soldiers, 80, 0, "", "[4, 4, 1, 1]")
	var enemy: SimSoldier = sim.soldiers[0]
	assert_eq(sim.hit_chance_percent(sim.soldiers[1], enemy), 40, "from the front: covered")
	assert_eq(sim.hit_chance_percent(sim.soldiers[2], enemy), 80, "from the flank: not covered")


func test_perfect_cover_makes_a_man_safe_from_the_front_but_not_the_flank() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("enemy", 1, 5, 4),
		SimFixture.soldier("player", 1, 1, 4),
	]
	var rules: SimRules = SimFixture.rules()
	rules.cover_hit_percent = 0
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers, "", "[4, 4, 1, 1]")
	var sim: Simulation = Simulation.new(
		rules, scenario, SimFixture.weapons(100, 0), SimFixture.SEED
	)
	SimFixture.run(sim, 100)
	assert_true(sim.soldiers[0].alive, "a certain hit becomes impossible behind perfect cover")
	sim.order_move(1, Vector2i(5, 1))
	SimFixture.run(sim, 200)
	assert_false(sim.soldiers[0].alive, "from the flank the same shot lands")

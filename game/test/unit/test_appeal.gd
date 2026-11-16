extends GutTest
## Calling on Indian soldiers opposite to come over. Usually it fails; it is
## likelier against men who are pinned or have lost comrades.
## SimFixture.rules(): heard 8 cells off, answered after 10 ticks, chance 0
## unless a test raises it.

const PLAYER: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
const ENEMY: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY


## Team 1 (two men) at (1, 4) and (1, 5). Enemy team 1 (two men) `distance`
## cells to the right. Nobody can hit. `appealable` lists enemy teams of
## Indian soldiers.
func _sim(
	distance: int = 6, appealable: Array[int] = [1], rules: SimRules = SimFixture.rules()
) -> Simulation:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4, 20),
		SimFixture.soldier("player", 1, 1, 5, 20),
		SimFixture.soldier("enemy", 1, 1 + distance, 4, 20),
		SimFixture.soldier("enemy", 1, 1 + distance, 5, 20),
	]
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers)
	scenario.appealable_enemy_teams = appealable
	return Simulation.new(rules, scenario, SimFixture.weapons(0, 0), SimFixture.SEED)


func _certain(chance: int) -> SimRules:
	var rules: SimRules = SimFixture.rules()
	rules.appeal_base_percent = chance
	return rules


func test_a_group_within_earshot_can_be_called_to() -> void:
	var sim: Simulation = _sim(6)
	assert_eq(sim.appeal_target_for(1), 1)
	assert_true(sim.order_appeal(1))


func test_a_group_out_of_earshot_cannot() -> void:
	var sim: Simulation = _sim(10)
	assert_eq(sim.appeal_target_for(1), -1)
	assert_false(sim.order_appeal(1))


func test_a_group_that_is_not_indian_troops_cannot_be_called_to() -> void:
	var sim: Simulation = _sim(6, [])
	assert_eq(sim.appeal_target_for(1), -1)


func test_callers_do_not_fire_and_the_answer_comes_after_the_appeal_time() -> void:
	var sim: Simulation = _sim(6)
	sim.order_appeal(1)
	SimFixture.run(sim, 9)
	assert_true(sim.appeal_in_progress())
	assert_true(sim.soldiers[0].calling_out)
	assert_eq(SimFixture.shots_by(sim, PLAYER), 0, "calling, not shooting")
	assert_gt(SimFixture.shots_by(sim, ENEMY), 0, "the enemy did not wait")
	SimFixture.run(sim, 1)
	assert_false(sim.appeal_in_progress(), "answered on the tenth tick")
	assert_false(sim.soldiers[0].calling_out)
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.APPEAL_STARTED), 1)


func test_a_group_that_comes_over_leaves_the_fight_and_lays_down_its_rounds() -> void:
	var sim: Simulation = _sim(6, [1], _certain(100))
	sim.order_fire(1, false)
	sim.order_appeal(1)
	SimFixture.run(sim, 10)
	assert_eq(sim.in_fight_count(ENEMY), 0)
	assert_eq(sim.came_over_count(ENEMY), 2)
	assert_eq(sim.withdrawn_count(ENEMY), 0, "coming over is not getting away")
	assert_eq(sim.casualty_count(ENEMY), 0)
	assert_eq(sim.outcome(), Simulation.Outcome.OBJECTIVE_TAKEN)
	assert_gt(sim.rounds_on_the_ground(), 0, "their rounds are left where they stood")
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.APPEAL_ACCEPTED), 1)


func test_a_refusal_puts_heart_back_into_them_and_they_open_fire_at_once() -> void:
	var sim: Simulation = _sim(6, [1], SimFixture.rules_with_suppression())
	sim.order_fire(1, false)
	sim.order_appeal(1)
	SimFixture.run(sim, 9)
	sim.soldiers[2].suppression = 50
	sim.soldiers[2].fire_cooldown_ticks = 8
	var enemy_shots_before: int = SimFixture.shots_by(sim, ENEMY)
	sim.step()
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.APPEAL_REFUSED), 1)
	assert_lte(sim.soldiers[2].suppression, 20, "50 less 30, and no more pressure on him")
	assert_gt(SimFixture.shots_by(sim, ENEMY), enemy_shots_before, "fired on the same tick")
	assert_eq(sim.in_fight_count(ENEMY), 2)
	assert_string_contains(sim.ai_log[sim.ai_log.size() - 1], "refuses the appeal")


func test_each_group_gets_one_appeal() -> void:
	var sim: Simulation = _sim(6)
	sim.order_appeal(1)
	SimFixture.run(sim, 10)
	assert_eq(sim.appeal_target_for(1), -1)
	assert_false(sim.order_appeal(1))


func test_only_one_appeal_at_a_time() -> void:
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("player", 2, 1, 6),
		SimFixture.soldier("enemy", 1, 6, 4),
		SimFixture.soldier("enemy", 2, 6, 6),
	]
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers)
	scenario.appealable_enemy_teams = [1, 2]
	var sim: Simulation = Simulation.new(
		SimFixture.rules(), scenario, SimFixture.weapons(0, 0), SimFixture.SEED
	)
	sim.order_appeal(1)
	sim.step()
	assert_eq(sim.appeal_target_for(2), -1, "team 2 must wait for team 1's answer")
	SimFixture.run(sim, 10)
	assert_ne(sim.appeal_target_for(2), -1)


func test_moving_the_callers_ends_the_appeal_without_using_up_the_try() -> void:
	var sim: Simulation = _sim(6)
	sim.order_appeal(1)
	SimFixture.run(sim, 5)
	sim.order_move(1, Vector2i(1, 1))
	sim.step()
	assert_false(sim.appeal_in_progress())
	assert_eq(SimFixture.count_events(sim, SimEvent.Kind.APPEAL_REFUSED), 0)
	SimFixture.run(sim, 40)
	assert_eq(sim.appeal_target_for(1), 1, "the group can still be called to")


func test_the_chance_rises_with_men_pinned_and_men_lost_and_has_a_ceiling() -> void:
	var rules: SimRules = SimFixture.rules_with_suppression()
	rules.appeal_base_percent = 2
	rules.appeal_pinned_percent = 20
	rules.appeal_losses_percent = 20
	rules.appeal_max_percent = 40
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("enemy", 1, 6, 2),
		SimFixture.soldier("enemy", 1, 6, 3),
		SimFixture.soldier("enemy", 1, 6, 4),
		SimFixture.soldier("enemy", 1, 6, 5),
	]
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers)
	scenario.appealable_enemy_teams = [1]
	var sim: Simulation = Simulation.new(rules, scenario, SimFixture.weapons(0, 0), 1)
	assert_eq(sim.appeal_chance_percent(1), 2, "nobody pinned, nobody lost")
	sim.soldiers[1].suppression = 40
	sim.soldiers[2].suppression = 40
	assert_eq(sim.appeal_chance_percent(1), 12, "half of four pinned: 2 + 10")
	sim.soldiers[4].alive = false
	assert_eq(sim.appeal_chance_percent(1), 20, "two of three pinned, one of four lost: 2 + 13 + 5")
	rules.appeal_base_percent = 90
	assert_eq(sim.appeal_chance_percent(1), 40, "never above the ceiling")


func test_rain_drowns_an_appeal_that_would_carry_in_dry_weather() -> void:
	var downpour: WeatherDef = WeatherDef.new()
	downpour.sight_range_cells = 99
	downpour.voice_range_cells = 3
	var change: Scenario.WeatherChange = Scenario.WeatherChange.new()
	change.at_tick = 0
	change.weather_id = "downpour"
	var soldiers: Array[String] = [
		SimFixture.soldier("player", 1, 1, 4),
		SimFixture.soldier("enemy", 1, 7, 4),
	]
	var scenario: Scenario = SimFixture.scenario(20, 9, soldiers)
	scenario.appealable_enemy_teams = [1]
	scenario.weather_schedule = [change]
	var sim: Simulation = Simulation.new(
		SimFixture.rules(), scenario, SimFixture.weapons(0, 0), 1, {"downpour": downpour}
	)
	assert_eq(sim.appeal_range_cells(), 3)
	assert_eq(sim.appeal_target_for(1), -1)


func test_the_test_range_picket_is_made_up_of_indian_soldiers() -> void:
	var scenario: Scenario = Scenario.load_file("res://data/scenarios/test_range.json")
	assert_eq(scenario.appealable_enemy_teams, [1] as Array[int])

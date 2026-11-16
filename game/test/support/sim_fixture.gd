class_name SimFixture
extends RefCounted
## Builds small scenarios and simulations for tests, with round numbers so the
## arithmetic in a test is obvious.
##
## Player soldiers carry "player_rifle" and enemy soldiers "enemy_rifle", so a
## test can make one side deadly and the other harmless.

const SEED: int = 1944


static func rules() -> SimRules:
	var result: SimRules = SimRules.new()
	result.ticks_per_second = 10
	result.move_ticks_orthogonal = 5
	result.move_ticks_diagonal = 7
	result.cover_hit_percent = 50
	result.cover_suppression_cap = 100
	# Suppression is off unless a test turns it on, so that other rules can
	# be tested one at a time.
	result.suppression_per_shot = 0
	result.suppression_splash = 0
	# Condition is off unless a test turns it on.
	result.hunger_rise_ticks = 0
	result.fatigue_walk_ticks = 0
	result.fatigue_rest_ticks = 0
	result.hunger_floor_percent = 30
	result.fatigue_floor_percent = 20
	result.condition_floor_max = 40
	result.gather_ticks_per_round = 5
	result.max_rounds_carried = 12
	# Appeals: heard 8 cells off, answered after 10 ticks, never work unless a
	# test raises the chance.
	result.appeal_range_cells = 8
	result.appeal_ticks = 10
	result.appeal_base_percent = 0
	result.appeal_pinned_percent = 0
	result.appeal_losses_percent = 0
	result.appeal_max_percent = 100
	result.appeal_refusal_relief = 30
	return result


## The same rules with suppression on, in round numbers: 10 per shot, 4 to a
## neighbour, halved by cover, one point lost every 5 ticks, pinned at 30,
## broken at 60. The enemy reconsiders every tick.
static func rules_with_suppression() -> SimRules:
	var result: SimRules = rules()
	result.suppression_per_shot = 10
	result.suppression_splash = 4
	result.cover_suppression_percent = 50
	result.suppression_decay_ticks = 5
	result.pinned_threshold = 30
	result.pinned_fire_interval_percent = 200
	result.pinned_hit_percent = 50
	result.broken_threshold = 60
	result.ai_think_ticks = 1
	return result


## A rifle with a range of 6 cells that fires every 10 ticks.
static func rifle(hit_chance_percent: int) -> WeaponDef:
	var weapon: WeaponDef = WeaponDef.new()
	weapon.range_cells = 6
	weapon.fire_interval_ticks = 10
	weapon.hit_chance_percent = hit_chance_percent
	return weapon


static func weapons(
	player_hit_percent: int, enemy_hit_percent: int
) -> Dictionary[String, WeaponDef]:
	return {
		"player_rifle": rifle(player_hit_percent),
		"enemy_rifle": rifle(enemy_hit_percent),
	}


## One soldier as JSON. `side` is "player" or "enemy".
static func soldier(side: String, team: int, x: int, y: int, rounds: int = 99) -> String:
	return (
		'{"side": "%s", "team": %d, "cell": [%d, %d], "weapon": "%s_rifle", "rounds": %d}'
		% [side, team, x, y, side, rounds]
	)


## A scenario from soldiers and optional obstacle rectangles written as JSON,
## for example blocked = "[3, 0, 1, 9]".
static func scenario(
	width: int,
	height: int,
	soldiers: Array[String],
	blocked: String = "",
	cover: String = "",
	enemy_fallback: String = ""
) -> Scenario:
	var fallback: String = ""
	if not enemy_fallback.is_empty():
		fallback = '"enemy_fallback": %s, ' % enemy_fallback
	var text: String = (
		'{"width": %d, "height": %d, %s"blocked_rects": [%s], "cover_rects": [%s], "soldiers": [%s]}'
		% [width, height, fallback, blocked, cover, ", ".join(soldiers)]
	)
	return Scenario.from_json_text(text)


static func count_events(sim: Simulation, kind: SimEvent.Kind) -> int:
	var count: int = 0
	for event: SimEvent in sim.events:
		if event.kind == kind:
			count += 1
	return count


## Shots fired by one side, hits and misses together.
static func shots_by(sim: Simulation, side: SimSoldier.BattleSide) -> int:
	var count: int = 0
	for event: SimEvent in sim.events:
		var is_shot: bool = (
			event.kind == SimEvent.Kind.SHOT_HIT or event.kind == SimEvent.Kind.SHOT_MISSED
		)
		if is_shot and sim.soldiers[event.actor_id].side == side:
			count += 1
	return count


static func run(sim: Simulation, ticks: int) -> void:
	for count: int in ticks:
		sim.step()

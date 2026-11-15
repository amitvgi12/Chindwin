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
	width: int, height: int, soldiers: Array[String], blocked: String = "", cover: String = ""
) -> Scenario:
	var text: String = (
		'{"width": %d, "height": %d, "blocked_rects": [%s], "cover_rects": [%s], "soldiers": [%s]}'
		% [width, height, blocked, cover, ", ".join(soldiers)]
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

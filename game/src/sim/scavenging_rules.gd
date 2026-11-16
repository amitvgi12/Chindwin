class_name ScavengingRules
extends RefCounted
## Scavenging: picking rounds and rations up off the ground. Called by
## Simulation once a tick; holds no state of its own.


## Men told to gather pick rounds, then rations, up from a cache beside
## them, one item every few ticks. A man must be standing still and not
## pinned. It is slow, and he cannot fire while he does it: that is the risk.
static func gather(sim: Simulation) -> void:
	for soldier: SimSoldier in sim.soldiers:
		soldier.gathering_now = false
		if not soldier.in_fight() or not soldier.told_to_gather:
			continue
		if soldier.is_moving() or sim.is_pinned(soldier):
			continue
		var cache: AmmoCache = sim.cache_within_reach(soldier.cell)
		if cache == null:
			continue
		# Rounds first, then food.
		var wants_rounds: bool = cache.rounds > 0 and soldier.rounds < sim.rules.max_rounds_carried
		var wants_food: bool = cache.rations > 0 and soldier.rations < sim.rules.max_rations_carried
		if not wants_rounds and not wants_food:
			continue
		soldier.gathering_now = true
		soldier.gather_progress_ticks += 1
		if soldier.gather_progress_ticks < sim.rules.gather_ticks_per_round:
			continue
		soldier.gather_progress_ticks = 0
		if wants_rounds:
			cache.rounds -= 1
			soldier.rounds += 1
		else:
			cache.rations -= 1
			soldier.rations += 1

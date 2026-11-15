class_name PicketAi
extends RefCounted
## How an enemy picket behaves. It holds its position and fires. It gives the
## position up in three cases, each written to the simulation's AI log:
##
##   1. a man breaks under fire and goes back on his own
##   2. the picket has lost half its men
##   3. the picket is flanked and at least half of those left are pinned
##
## Men who fall back walk to the scenario's fallback cell and leave the fight.
## A scenario with no fallback cell gets a picket that only ever holds.
## Uses no random numbers.

## Enemy teams that have been told to fall back.
var _falling_back: Dictionary[int, bool] = {}


func think(sim: Simulation) -> void:
	if not sim.has_fallback_cell():
		return
	for team_id: int in sim.team_ids(SimSoldier.BattleSide.ENEMY):
		var fit: Array[SimSoldier] = sim.living(SimSoldier.BattleSide.ENEMY, team_id)
		if fit.is_empty():
			continue
		if not _falling_back.has(team_id):
			var reason: String = _reason_to_fall_back(sim, team_id, fit)
			if not reason.is_empty():
				_falling_back[team_id] = true
				sim.note_ai("picket %d falls back: %s" % [team_id, reason])
				sim.log_event(SimEvent.Kind.PICKET_FALLS_BACK, team_id, -1, sim.fallback_cell)
		for soldier: SimSoldier in fit:
			if soldier.falling_back:
				continue
			if _falling_back.has(team_id):
				_send_back(sim, soldier)
			elif soldier.broken:
				sim.note_ai(
					(
						"man %d of picket %d breaks and goes back (suppression %d)"
						% [soldier.id, team_id, soldier.suppression]
					)
				)
				_send_back(sim, soldier)


func is_falling_back(team_id: int) -> bool:
	return _falling_back.has(team_id)


## Why the picket should give up its position now, or "" if it should hold.
func _reason_to_fall_back(sim: Simulation, team_id: int, fit: Array[SimSoldier]) -> String:
	var started_with: int = sim.strength(SimSoldier.BattleSide.ENEMY, team_id)
	if fit.size() * 2 <= started_with:
		return "lost half its men (%d of %d left)" % [fit.size(), started_with]
	var pinned: int = sim.pinned_count(SimSoldier.BattleSide.ENEMY, team_id)
	if pinned * 2 >= fit.size() and _is_flanked(sim, fit):
		return "flanked and pinned (%d of %d pinned)" % [pinned, fit.size()]
	return ""


## True when some attacker in range can see a man of the picket and has a
## shot at him that no cover reduces.
func _is_flanked(sim: Simulation, fit: Array[SimSoldier]) -> bool:
	for attacker: SimSoldier in sim.soldiers:
		if not attacker.in_fight() or attacker.side != SimSoldier.BattleSide.PLAYER:
			continue
		if attacker.weapon == null:
			continue
		var range_squared: int = attacker.weapon.range_cells * attacker.weapon.range_cells
		for member: SimSoldier in fit:
			if attacker.cell.distance_squared_to(member.cell) > range_squared:
				continue
			if not sim.grid.has_line_of_sight(attacker.cell, member.cell):
				continue
			if not sim.grid.gives_cover(attacker.cell, member.cell):
				return true
	return false


func _send_back(sim: Simulation, soldier: SimSoldier) -> void:
	var taken: Dictionary[Vector2i, bool] = {}
	for other: SimSoldier in sim.soldiers:
		if other.in_fight() and other != soldier:
			taken[other.destination()] = true
	var places: Array[Vector2i] = sim.grid.free_cells_near(sim.fallback_cell, 1, taken)
	soldier.falling_back = true
	soldier.step_ticks_left = 0
	soldier.step_ticks_total = 0
	soldier.path.clear()
	if not places.is_empty():
		soldier.path = sim.grid.find_path(soldier.cell, places[0])
	if soldier.path.is_empty():
		sim.withdraw(soldier)

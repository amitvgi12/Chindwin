class_name Simulation
extends RefCounted
## The rules of the game, advanced one tick at a time by step().
##
## No nodes, no rendering, no clock: the same seed and the same orders at the
## same ticks always give the same result. The view only reads this state and
## calls the order_ functions and step().


class Order:
	extends RefCounted
	enum Kind { MOVE, FIRE_CONTROL, FALL_BACK, GATHER, APPEAL }
	var kind: Kind
	var team_id: int
	## Where to walk to, for MOVE.
	var target: Vector2i
	## For MOVE: true adds a leg after the current route, false replaces it.
	var append: bool
	## Whether the team may shoot, for FIRE_CONTROL.
	var fire_allowed: bool
	## Whether the team should gather rounds, for GATHER.
	var gather: bool


## How a mission can end. IN_PROGRESS means it has not.
enum Outcome { IN_PROGRESS, OBJECTIVE_TAKEN, WITHDREW, SECTION_BROKEN }


## One shot decided this tick, applied after everyone has fired.
class Shot:
	extends RefCounted
	var shooter: SimSoldier
	var target: SimSoldier
	var hit: bool


var tick: int = 0
var rules: SimRules
var grid: BattleGrid
var soldiers: Array[SimSoldier] = []
## Everything that has happened so far, oldest first.
var events: Array[SimEvent] = []
## Where the enemy goes when it gives up its position. See has_fallback_cell().
var fallback_cell: Vector2i = Vector2i.ZERO
## What the enemy decided and why, one line per decision, for reading afterwards.
var ai_log: Array[String] = []
## Rounds lying on the ground. A cache stays in the list when it is empty.
var caches: Array[AmmoCache] = []
## The weather now, or null when the scenario has none.
var weather: WeatherDef
## Id of the weather now, or "" when the scenario has none.
var weather_id: String = ""

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pending_orders: Array[Order] = []
var _section_broken_below: int = 1
var _outcome: Outcome = Outcome.IN_PROGRESS
## Player teams whose last order was to fall back.
var _teams_withdrawing: Dictionary[int, bool] = {}
## Enemy teams of Indian soldiers, who can be called on to come over.
var _appealable: Dictionary[int, bool] = {}
## Enemy teams that have already been called to. Each gets one appeal.
var _appealed: Dictionary[int, bool] = {}
## The appeal under way: who is calling, to whom, and for how much longer.
var _appeal_caller_team: int = -1
var _appeal_target_team: int = -1
var _appeal_ticks_left: int = 0
var _rounds_at_start: Dictionary[SimSoldier.BattleSide, int] = {}
var _weathers: Dictionary[String, WeatherDef] = {}
var _weather_schedule: Array[Scenario.WeatherChange] = []
var _has_fallback_cell: bool = false
var _picket_ai: PicketAi = PicketAi.new()


func _init(
	p_rules: SimRules,
	scenario: Scenario,
	weapons: Dictionary[String, WeaponDef],
	seed_value: int,
	weathers: Dictionary[String, WeatherDef] = {}
) -> void:
	rules = p_rules
	grid = BattleGrid.new(
		scenario.width, scenario.height, scenario.blocked, scenario.cover, scenario.slopes
	)
	_weathers = weathers
	_weather_schedule = scenario.weather_schedule
	_rng.seed = seed_value
	fallback_cell = scenario.enemy_fallback
	_has_fallback_cell = scenario.has_enemy_fallback
	_section_broken_below = scenario.section_broken_below
	for team_id: int in scenario.appealable_enemy_teams:
		_appealable[team_id] = true
	for spec: Scenario.SoldierSpec in scenario.soldiers:
		var soldier: SimSoldier = SimSoldier.new()
		soldier.id = soldiers.size()
		soldier.side = spec.side
		soldier.team_id = spec.team_id
		soldier.cell = spec.cell
		soldier.start_cell = spec.cell
		soldier.weapon = weapons.get(spec.weapon_id)
		soldier.rounds = spec.rounds
		soldiers.append(soldier)
		_rounds_at_start[spec.side] = _rounds_at_start.get(spec.side, 0) + spec.rounds
	for cache_spec: Scenario.CacheSpec in scenario.caches:
		caches.append(AmmoCache.new(cache_spec.cell, cache_spec.rounds))
	if not _weather_schedule.is_empty() and _weather_schedule[0].at_tick == 0:
		set_weather(_weather_schedule[0].weather_id)


## Ask a player team to walk to a cell. Returns false when the order makes no
## sense (blocked cell, or nobody left in the team). The order takes effect at
## the start of the next tick, so orders given while paused are safe.
## With `append`, the team finishes its current route first and then goes on
## to the new cell: that is how a route round a flank is laid out.
func order_move(team_id: int, target: Vector2i, append: bool = false) -> bool:
	if grid.is_blocked(target):
		return false
	if living(SimSoldier.BattleSide.PLAYER, team_id).is_empty():
		return false
	var order: Order = Order.new()
	order.kind = Order.Kind.MOVE
	order.team_id = team_id
	order.target = target
	order.append = append
	_pending_orders.append(order)
	return true


## Tell a player team to hold fire (false) or to fire at will (true).
## Returns false when nobody is left in the team.
func order_fire(team_id: int, fire_allowed: bool) -> bool:
	if living(SimSoldier.BattleSide.PLAYER, team_id).is_empty():
		return false
	var order: Order = Order.new()
	order.kind = Order.Kind.FIRE_CONTROL
	order.team_id = team_id
	order.fire_allowed = fire_allowed
	_pending_orders.append(order)
	return true


## Tell a player team to fall back to where it started. Men falling back walk
## even when pinned and do not fire. Any later move order cancels it.
## Returns false when nobody is left in the team.
func order_fall_back(team_id: int) -> bool:
	if living(SimSoldier.BattleSide.PLAYER, team_id).is_empty():
		return false
	var order: Order = Order.new()
	order.kind = Order.Kind.FALL_BACK
	order.team_id = team_id
	_pending_orders.append(order)
	return true


## Tell a player team to gather rounds from the ground (true) or to stop
## (false). A man gathers when he is standing still, not pinned, beside a
## cache that has rounds in it, and not already carrying all he can. While he
## is gathering he does not fire. Returns false when nobody is left in the team.
func order_gather(team_id: int, gather: bool) -> bool:
	if living(SimSoldier.BattleSide.PLAYER, team_id).is_empty():
		return false
	var order: Order = Order.new()
	order.kind = Order.Kind.GATHER
	order.team_id = team_id
	order.gather = gather
	_pending_orders.append(order)
	return true


## Tell a player team to call out to the nearest enemy group within earshot,
## asking its men to come over. Returns false when no group can be called to
## right now (see appeal_target_for()). The answer comes after appeal_ticks.
func order_appeal(team_id: int) -> bool:
	if appeal_target_for(team_id) == -1:
		return false
	var order: Order = Order.new()
	order.kind = Order.Kind.APPEAL
	order.team_id = team_id
	_pending_orders.append(order)
	return true


## The enemy team a player team could call to now, or -1. It must be made up
## of Indian soldiers, not yet called to, and within earshot of a man of the
## team who is standing still and not pinned. Nearest first.
func appeal_target_for(team_id: int) -> int:
	if _appeal_caller_team != -1:
		return -1
	var reach: int = appeal_range_cells()
	var best_team: int = -1
	var best_distance: int = reach * reach + 1
	for caller: SimSoldier in living(SimSoldier.BattleSide.PLAYER, team_id):
		if caller.is_moving() or is_pinned(caller):
			continue
		for enemy: SimSoldier in soldiers:
			if not enemy.in_fight() or enemy.side != SimSoldier.BattleSide.ENEMY:
				continue
			if not _appealable.has(enemy.team_id) or _appealed.has(enemy.team_id):
				continue
			var distance: int = caller.cell.distance_squared_to(enemy.cell)
			if distance < best_distance:
				best_team = enemy.team_id
				best_distance = distance
	return best_team


## How far a shouted appeal carries right now, in cells.
func appeal_range_cells() -> int:
	if weather == null:
		return rules.appeal_range_cells
	return mini(rules.appeal_range_cells, weather.voice_range_cells)


## Chance from 0 to 100 that an enemy team would come over if called to now.
## It rises with the share of its men pinned or broken and the share it has
## lost, and never passes appeal_max_percent.
func appeal_chance_percent(enemy_team: int) -> int:
	var fit: Array[SimSoldier] = living(SimSoldier.BattleSide.ENEMY, enemy_team)
	if fit.is_empty():
		return 0
	var started_with: int = strength(SimSoldier.BattleSide.ENEMY, enemy_team)
	var pressed: int = 0
	for soldier: SimSoldier in fit:
		if soldier.broken or is_pinned(soldier):
			pressed += 1
	var lost: int = started_with - fit.size()
	var chance: int = rules.appeal_base_percent
	chance += rules.appeal_pinned_percent * pressed / fit.size()
	chance += rules.appeal_losses_percent * lost / started_with
	return clampi(chance, 0, rules.appeal_max_percent)


## True while a player team is calling out.
func appeal_in_progress() -> bool:
	return _appeal_caller_team != -1


## The team calling out, or -1.
func appeal_caller_team() -> int:
	return _appeal_caller_team


## Advance the simulation by one tick. Does nothing once the mission has ended.
func step() -> void:
	if _outcome != Outcome.IN_PROGRESS:
		return
	tick += 1
	_follow_weather_schedule()
	_apply_pending_orders()
	_fade_suppression()
	_update_broken()
	if rules.ai_think_ticks > 0 and tick % rules.ai_think_ticks == 0:
		_picket_ai.think(self)
	for soldier: SimSoldier in soldiers:
		# A pinned man will not walk forward, but a man going back still goes.
		if soldier.is_moving() and (soldier.falling_back or not is_pinned(soldier)):
			_advance_movement(soldier)
	_gather_rounds()
	_advance_appeal()
	_resolve_fire()
	_outcome = _work_out_outcome()


## Change the weather now. Returns false when no such weather was loaded.
## The schedule calls this; so can a debug key.
func set_weather(id: String) -> bool:
	if not _weathers.has(id):
		return false
	weather_id = id
	weather = _weathers[id]
	grid.set_slope_cost_percent(weather.slope_move_percent)
	log_event(SimEvent.Kind.WEATHER_CHANGED, -1, -1, Vector2i.ZERO)
	return true


## Ids of every weather state this simulation can switch to, in name order.
func weather_ids() -> Array[String]:
	var ids: Array[String] = _weathers.keys()
	ids.sort()
	return ids


## How far a man can shoot right now: his weapon's range, cut down to how far
## anyone can see in this weather.
func effective_range_cells(shooter: SimSoldier) -> int:
	if shooter.weapon == null:
		return 0
	if weather == null:
		return shooter.weapon.range_cells
	return mini(shooter.weapon.range_cells, weather.sight_range_cells)


## True when a man could fire at another right now: in range for this
## weather, and nothing tall in the way.
func can_engage(shooter: SimSoldier, target: SimSoldier) -> bool:
	var reach: int = effective_range_cells(shooter)
	if shooter.cell.distance_squared_to(target.cell) > reach * reach:
		return false
	return grid.has_line_of_sight(shooter.cell, target.cell)


## How the mission ended, or IN_PROGRESS.
##   OBJECTIVE_TAKEN   the enemy has nobody left in the fight
##   SECTION_BROKEN    too few of the player's men are fit to go on
##   WITHDREW          every team was told to fall back and all are back
func outcome() -> Outcome:
	return _outcome


## Rounds one side carried when the scenario began.
func rounds_at_start(side: SimSoldier.BattleSide) -> int:
	return _rounds_at_start.get(side, 0)


## Rounds one side still holds, counting only men still in the fight.
func rounds_left(side: SimSoldier.BattleSide) -> int:
	var total: int = 0
	for soldier: SimSoldier in soldiers:
		if soldier.side == side and soldier.in_fight():
			total += soldier.rounds
	return total


## Soldiers of one team who are still in the fight, in id order.
func living(side: SimSoldier.BattleSide, team_id: int) -> Array[SimSoldier]:
	var found: Array[SimSoldier] = []
	for soldier: SimSoldier in soldiers:
		if soldier.in_fight() and soldier.side == side and soldier.team_id == team_id:
			found.append(soldier)
	return found


## The team numbers one side has, lowest first, whether or not anyone is left.
func team_ids(side: SimSoldier.BattleSide) -> Array[int]:
	var ids: Array[int] = []
	for soldier: SimSoldier in soldiers:
		if soldier.side == side and not ids.has(soldier.team_id):
			ids.append(soldier.team_id)
	ids.sort()
	return ids


## How many men one side still has in the fight, across all its teams.
func in_fight_count(side: SimSoldier.BattleSide) -> int:
	var count: int = 0
	for soldier: SimSoldier in soldiers:
		if soldier.side == side and soldier.in_fight():
			count += 1
	return count


## How many men of one side have left the fight unhurt.
func withdrawn_count(side: SimSoldier.BattleSide) -> int:
	var count: int = 0
	for soldier: SimSoldier in soldiers:
		if soldier.side == side and soldier.withdrawn and not soldier.came_over:
			count += 1
	return count


## How many men of one side came over in answer to an appeal.
func came_over_count(side: SimSoldier.BattleSide) -> int:
	var count: int = 0
	for soldier: SimSoldier in soldiers:
		if soldier.side == side and soldier.came_over:
			count += 1
	return count


## How many men of one side have become casualties.
func casualty_count(side: SimSoldier.BattleSide) -> int:
	var count: int = 0
	for soldier: SimSoldier in soldiers:
		if soldier.side == side and not soldier.alive:
			count += 1
	return count


func has_fallback_cell() -> bool:
	return _has_fallback_cell


## True when an enemy team has been told to give up its position.
func picket_is_falling_back(team_id: int) -> bool:
	return _picket_ai.is_falling_back(team_id)


## Take a man out of the fight unhurt.
func withdraw(soldier: SimSoldier) -> void:
	soldier.withdrawn = true
	soldier.path.clear()
	soldier.suppression = 0
	log_event(SimEvent.Kind.WITHDREW, soldier.id, -1, soldier.cell)


## Record an enemy decision with its reason. Read ai_log to see why the enemy
## did what it did.
func note_ai(text: String) -> void:
	ai_log.append("tick %d: %s" % [tick, text])


func log_event(kind: SimEvent.Kind, actor_id: int, target_id: int, cell: Vector2i) -> void:
	events.append(SimEvent.new(tick, kind, actor_id, target_id, cell))


## How many soldiers a team started with.
func strength(side: SimSoldier.BattleSide, team_id: int) -> int:
	var count: int = 0
	for soldier: SimSoldier in soldiers:
		if soldier.side == side and soldier.team_id == team_id:
			count += 1
	return count


## True when incoming fire has pinned a man: he will not walk, and he fires
## slower and less accurately until the pressure fades.
func is_pinned(soldier: SimSoldier) -> bool:
	return soldier.in_fight() and soldier.suppression >= rules.pinned_threshold


## How many living members of a team are pinned.
func pinned_count(side: SimSoldier.BattleSide, team_id: int) -> int:
	var count: int = 0
	for soldier: SimSoldier in living(side, team_id):
		if is_pinned(soldier):
			count += 1
	return count


## Rounds held by the living members of a team.
func team_rounds(side: SimSoldier.BattleSide, team_id: int) -> int:
	var total: int = 0
	for soldier: SimSoldier in living(side, team_id):
		total += soldier.rounds
	return total


## Rounds lying on the ground across the whole map.
func rounds_on_the_ground() -> int:
	var total: int = 0
	for cache: AmmoCache in caches:
		total += cache.rounds
	return total


## The cache with rounds in it on or next to a cell, nearest first, or null.
func cache_within_reach(cell: Vector2i) -> AmmoCache:
	var best: AmmoCache = null
	var best_distance: int = 3
	for cache: AmmoCache in caches:
		if cache.rounds <= 0:
			continue
		var apart: Vector2i = (cache.cell - cell).abs()
		var distance: int = maxi(apart.x, apart.y)
		if distance < best_distance and distance <= 1:
			best = cache
			best_distance = distance
	return best


## How many men of a team are picking rounds up this tick.
func gathering_count(side: SimSoldier.BattleSide, team_id: int) -> int:
	var count: int = 0
	for soldier: SimSoldier in living(side, team_id):
		if soldier.gathering_now:
			count += 1
	return count


## Whether a team is currently allowed to shoot. False when nobody is left.
func team_may_fire(side: SimSoldier.BattleSide, team_id: int) -> bool:
	for soldier: SimSoldier in living(side, team_id):
		if soldier.fire_allowed:
			return true
	return false


## The living soldier standing on a cell, or null.
func soldier_at(cell: Vector2i) -> SimSoldier:
	for soldier: SimSoldier in soldiers:
		if soldier.in_fight() and soldier.cell == cell:
			return soldier
	return null


## Chance from 0 to 100 that a shot by one man at another causes a casualty.
## Cover in front of the target cuts it down, and so does the shooter being pinned.
func hit_chance_percent(shooter: SimSoldier, target: SimSoldier) -> int:
	if shooter.weapon == null:
		return 0
	var chance: int = shooter.weapon.hit_chance_percent
	if grid.gives_cover(shooter.cell, target.cell):
		chance = chance * rules.cover_hit_percent / 100
	if is_pinned(shooter):
		chance = chance * rules.pinned_hit_percent / 100
	return chance


## The whole state as one line of text. Two runs are identical exactly when
## their snapshots are equal, which is how the tests check determinism.
func snapshot() -> String:
	var parts: PackedStringArray = PackedStringArray(["tick=%d" % tick])
	if not weather_id.is_empty():
		parts.append("weather=%s" % weather_id)
	for soldier: SimSoldier in soldiers:
		var fields: Array[int] = [
			soldier.cell.x,
			soldier.cell.y,
			1 if soldier.alive else 0,
			soldier.path.size(),
			soldier.rounds,
			soldier.suppression,
			1 if soldier.broken else 0,
			1 if soldier.withdrawn else 0,
		]
		parts.append("%d:%s" % [soldier.id, ",".join(fields.map(str))])
	parts.append("ground=%d" % rounds_on_the_ground())
	return " ".join(parts)


func _apply_pending_orders() -> void:
	for order: Order in _pending_orders:
		var team: Array[SimSoldier] = living(SimSoldier.BattleSide.PLAYER, order.team_id)
		if team.is_empty():
			continue
		if order.kind == Order.Kind.GATHER:
			_set_gathering(team, order)
		elif order.kind == Order.Kind.MOVE:
			_start_move(team, order)
		elif order.kind == Order.Kind.APPEAL:
			_start_appeal(order.team_id)
		elif order.kind == Order.Kind.FALL_BACK:
			_start_fall_back(team, order)
		else:
			_set_fire_control(team, order)
	_pending_orders.clear()


func _follow_weather_schedule() -> void:
	for change: Scenario.WeatherChange in _weather_schedule:
		if change.at_tick == tick:
			set_weather(change.weather_id)


## Checked once a tick, in this order: taking the objective counts even if it
## cost the section; a broken section cannot be said to have withdrawn.
func _work_out_outcome() -> Outcome:
	var player: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
	var enemy: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY
	# A side that was never on the map cannot be beaten: a scenario with no
	# enemy, or with no player, simply runs on.
	if not team_ids(enemy).is_empty() and in_fight_count(enemy) == 0:
		return Outcome.OBJECTIVE_TAKEN
	if team_ids(player).is_empty():
		return Outcome.IN_PROGRESS
	if in_fight_count(player) < _section_broken_below:
		return Outcome.SECTION_BROKEN
	if _teams_withdrawing.is_empty():
		return Outcome.IN_PROGRESS
	for team_id: int in team_ids(player):
		for soldier: SimSoldier in living(player, team_id):
			if not _teams_withdrawing.has(team_id) or soldier.is_moving():
				return Outcome.IN_PROGRESS
	return Outcome.WITHDREW


func _start_appeal(team_id: int) -> void:
	var target: int = appeal_target_for(team_id)
	if target == -1:
		return
	_appeal_caller_team = team_id
	_appeal_target_team = target
	_appeal_ticks_left = rules.appeal_ticks
	for soldier: SimSoldier in living(SimSoldier.BattleSide.PLAYER, team_id):
		soldier.calling_out = true
	log_event(SimEvent.Kind.APPEAL_STARTED, team_id, target, Vector2i.ZERO)


## Moving the callers, or losing them all to fire, ends the appeal before an
## answer comes. That does not use up the one try at that group.
func _cancel_appeal() -> void:
	for soldier: SimSoldier in soldiers:
		soldier.calling_out = false
	_appeal_caller_team = -1
	_appeal_target_team = -1
	_appeal_ticks_left = 0


func _advance_appeal() -> void:
	if _appeal_caller_team == -1:
		return
	var callers: Array[SimSoldier] = living(SimSoldier.BattleSide.PLAYER, _appeal_caller_team)
	var still_calling: bool = false
	for caller: SimSoldier in callers:
		if not caller.is_moving() and not is_pinned(caller):
			still_calling = true
	if not still_calling or living(SimSoldier.BattleSide.ENEMY, _appeal_target_team).is_empty():
		_cancel_appeal()
		return
	_appeal_ticks_left -= 1
	if _appeal_ticks_left > 0:
		return
	var target: int = _appeal_target_team
	var caller_team: int = _appeal_caller_team
	var chance: int = appeal_chance_percent(target)
	_cancel_appeal()
	_appealed[target] = true
	# The only dice of the appeal. Rolled once, when the answer comes.
	if _rng.randi_range(1, 100) <= chance:
		for enemy: SimSoldier in living(SimSoldier.BattleSide.ENEMY, target):
			_drop_rounds(enemy)
			enemy.came_over = true
			withdraw(enemy)
		note_ai("picket %d comes over in answer to the appeal (chance %d%%)" % [target, chance])
		log_event(SimEvent.Kind.APPEAL_ACCEPTED, caller_team, target, Vector2i.ZERO)
	else:
		for enemy: SimSoldier in living(SimSoldier.BattleSide.ENEMY, target):
			enemy.suppression = maxi(0, enemy.suppression - rules.appeal_refusal_relief)
			enemy.broken = false
			enemy.fire_cooldown_ticks = 0
		note_ai("picket %d refuses the appeal and opens fire (chance %d%%)" % [target, chance])
		log_event(SimEvent.Kind.APPEAL_REFUSED, caller_team, target, Vector2i.ZERO)


func _start_move(team: Array[SimSoldier], order: Order) -> void:
	if order.team_id == _appeal_caller_team:
		_cancel_appeal()
	_teams_withdrawing.erase(order.team_id)
	# Cells other soldiers stand on, or are walking to, are not available.
	var taken: Dictionary[Vector2i, bool] = {}
	for other: SimSoldier in soldiers:
		if other.in_fight() and not team.has(other):
			taken[other.destination()] = true
	var places: Array[Vector2i] = grid.free_cells_near(order.target, team.size(), taken)
	for index: int in team.size():
		if index >= places.size():
			break
		var soldier: SimSoldier = team[index]
		soldier.falling_back = false
		if order.append and soldier.is_moving():
			soldier.path.append_array(grid.find_path(soldier.destination(), places[index]))
		else:
			soldier.path = grid.find_path(soldier.cell, places[index])
			soldier.step_ticks_left = 0
			soldier.step_ticks_total = 0
	_log(SimEvent.Kind.ORDER_MOVE, order.team_id, -1, order.target)


func _start_fall_back(team: Array[SimSoldier], order: Order) -> void:
	if order.team_id == _appeal_caller_team:
		_cancel_appeal()
	_teams_withdrawing[order.team_id] = true
	for soldier: SimSoldier in team:
		# His own starting cell, or the nearest free one if somebody is on it.
		var taken: Dictionary[Vector2i, bool] = {}
		for other: SimSoldier in soldiers:
			if other.in_fight() and other != soldier:
				taken[other.destination()] = true
		var places: Array[Vector2i] = grid.free_cells_near(soldier.start_cell, 1, taken)
		soldier.step_ticks_left = 0
		soldier.step_ticks_total = 0
		soldier.path.clear()
		if not places.is_empty():
			soldier.path = grid.find_path(soldier.cell, places[0])
		soldier.falling_back = not soldier.path.is_empty()
	_log(SimEvent.Kind.ORDER_FALL_BACK, order.team_id, -1, Vector2i.ZERO)


func _set_gathering(team: Array[SimSoldier], order: Order) -> void:
	for soldier: SimSoldier in team:
		soldier.told_to_gather = order.gather
		soldier.gather_progress_ticks = 0
	var kind: SimEvent.Kind = (
		SimEvent.Kind.ORDER_GATHER if order.gather else SimEvent.Kind.ORDER_STOP_GATHERING
	)
	_log(kind, order.team_id, -1, Vector2i.ZERO)


func _set_fire_control(team: Array[SimSoldier], order: Order) -> void:
	for soldier: SimSoldier in team:
		soldier.fire_allowed = order.fire_allowed
	var kind: SimEvent.Kind = (
		SimEvent.Kind.ORDER_FIRE_AT_WILL if order.fire_allowed else SimEvent.Kind.ORDER_HOLD_FIRE
	)
	_log(kind, order.team_id, -1, Vector2i.ZERO)


func _advance_movement(soldier: SimSoldier) -> void:
	var next_cell: Vector2i = soldier.path[0]
	if soldier.step_ticks_left == 0:
		var diagonal: bool = next_cell.x != soldier.cell.x and next_cell.y != soldier.cell.y
		var cost: int = rules.move_ticks_diagonal if diagonal else rules.move_ticks_orthogonal
		if weather != null and grid.is_slope(next_cell):
			cost = cost * weather.slope_move_percent / 100
		soldier.step_ticks_total = cost
		soldier.step_ticks_left = cost
	soldier.step_ticks_left -= 1
	if soldier.step_ticks_left > 0:
		return
	soldier.cell = next_cell
	soldier.path.remove_at(0)
	soldier.step_ticks_total = 0
	if soldier.path.is_empty():
		# An enemy who has gone back is out of the fight. One of the player's
		# men who has gone back is simply back where he started.
		if soldier.falling_back and soldier.side == SimSoldier.BattleSide.ENEMY:
			withdraw(soldier)
		else:
			soldier.falling_back = false
			_log(SimEvent.Kind.ARRIVED, soldier.id, -1, soldier.cell)


## Men told to gather pick rounds up from a cache beside them, one round
## every few ticks. A man must be standing still and not pinned. It is slow,
## and he cannot fire while he does it: that is the risk.
func _gather_rounds() -> void:
	for soldier: SimSoldier in soldiers:
		soldier.gathering_now = false
		if not soldier.in_fight() or not soldier.told_to_gather:
			continue
		if soldier.is_moving() or is_pinned(soldier):
			continue
		if soldier.rounds >= rules.max_rounds_carried:
			continue
		var cache: AmmoCache = cache_within_reach(soldier.cell)
		if cache == null:
			continue
		soldier.gathering_now = true
		soldier.gather_progress_ticks += 1
		if soldier.gather_progress_ticks >= rules.gather_ticks_per_round:
			soldier.gather_progress_ticks = 0
			cache.rounds -= 1
			soldier.rounds += 1


## Every man who is not walking, is allowed to fire, has rounds left and can
## see an opponent in range fires one shot. A man who is walking does not
## fire: that is the choice between fire and movement. A pinned man has
## stopped walking, so he does fire, but slower and less accurately.
##
## All shots of a tick are decided first and applied afterwards, so two men
## can hit each other in the same tick and nobody gains from a lower id.
func _resolve_fire() -> void:
	var shots: Array[Shot] = []
	for shooter: SimSoldier in soldiers:
		if not shooter.in_fight() or shooter.weapon == null or shooter.broken:
			continue
		if shooter.fire_cooldown_ticks > 0:
			shooter.fire_cooldown_ticks -= 1
			if shooter.fire_cooldown_ticks > 0:
				continue
		if shooter.gathering_now or shooter.calling_out:
			continue
		var pinned: bool = is_pinned(shooter)
		var walking: bool = shooter.is_moving() and (shooter.falling_back or not pinned)
		if walking or not shooter.fire_allowed or shooter.rounds <= 0:
			continue
		var target: SimSoldier = _choose_target(shooter)
		if target == null:
			continue
		if _weapon_stops(shooter):
			continue
		shooter.rounds -= 1
		var interval: int = shooter.weapon.fire_interval_ticks
		if pinned:
			interval = interval * rules.pinned_fire_interval_percent / 100
		shooter.fire_cooldown_ticks = interval
		var shot: Shot = Shot.new()
		shot.shooter = shooter
		shot.target = target
		shot.hit = _rng.randi_range(1, 100) <= hit_chance_percent(shooter, target)
		shots.append(shot)
	for shot: Shot in shots:
		_suppress_around(shot)
		if shot.hit:
			_make_casualty(shot.target)
			_log(SimEvent.Kind.SHOT_HIT, shot.shooter.id, shot.target.id, shot.target.cell)
		else:
			_log(SimEvent.Kind.SHOT_MISSED, shot.shooter.id, shot.target.id, shot.target.cell)


## In wet weather a shot may not go off. The round is not spent, and the man
## needs a moment to clear the weapon. No dice are rolled when the chance is
## zero, so dry weather leaves the sequence of random numbers untouched.
func _weapon_stops(shooter: SimSoldier) -> bool:
	if weather == null or weather.stoppage_chance_percent <= 0:
		return false
	if _rng.randi_range(1, 100) > weather.stoppage_chance_percent:
		return false
	shooter.fire_cooldown_ticks = weather.stoppage_clear_ticks
	_log(SimEvent.Kind.STOPPAGE, shooter.id, -1, shooter.cell)
	return true


func _make_casualty(soldier: SimSoldier) -> void:
	_drop_rounds(soldier)
	soldier.alive = false
	soldier.gathering_now = false
	soldier.path.clear()
	soldier.step_ticks_left = 0
	soldier.step_ticks_total = 0
	soldier.suppression = 0
	soldier.broken = false


## What a man was carrying stays on the ground where he fell.
func _drop_rounds(soldier: SimSoldier) -> void:
	if soldier.rounds <= 0:
		return
	for cache: AmmoCache in caches:
		if cache.cell == soldier.cell:
			cache.rounds += soldier.rounds
			soldier.rounds = 0
			return
	caches.append(AmmoCache.new(soldier.cell, soldier.rounds))
	soldier.rounds = 0


## A shot, hit or miss, puts pressure on the man shot at and a little on each
## comrade standing next to him. Cover in front of a man reduces it and
## limits how high it can go.
func _suppress_around(shot: Shot) -> void:
	if rules.suppression_per_shot <= 0:
		return
	for soldier: SimSoldier in soldiers:
		if not soldier.in_fight() or soldier.side != shot.target.side:
			continue
		var amount: int = 0
		if soldier == shot.target:
			amount = rules.suppression_per_shot
		elif _are_neighbours(soldier.cell, shot.target.cell):
			amount = rules.suppression_splash
		if amount == 0:
			continue
		var limit: int = 100
		if grid.gives_cover(shot.shooter.cell, soldier.cell):
			amount = amount * rules.cover_suppression_percent / 100
			limit = rules.cover_suppression_cap
		# Never lowers pressure that fire from another direction already put on him.
		soldier.suppression = maxi(soldier.suppression, mini(limit, soldier.suppression + amount))


func _are_neighbours(a: Vector2i, b: Vector2i) -> bool:
	return a != b and absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1


## Pressure wears off: one point every few ticks, for everyone.
func _fade_suppression() -> void:
	if rules.suppression_decay_ticks <= 0 or tick % rules.suppression_decay_ticks != 0:
		return
	for soldier: SimSoldier in soldiers:
		if soldier.suppression > 0:
			soldier.suppression -= 1


## A man breaks at the broken level and stays broken until the pressure has
## fallen below the pinned level, so he does not flicker in and out.
func _update_broken() -> void:
	for soldier: SimSoldier in soldiers:
		if not soldier.in_fight():
			continue
		if soldier.suppression >= rules.broken_threshold:
			soldier.broken = true
		elif soldier.suppression < rules.pinned_threshold:
			soldier.broken = false


## Whom a man shoots at: of the opponents he can see within range, the one
## under the least suppression, then the nearest, then the lowest id. Aiming
## at whoever still has his head up spreads a team's fire across the enemy.
func _choose_target(shooter: SimSoldier) -> SimSoldier:
	var best: SimSoldier = null
	var best_distance: int = 0
	for candidate: SimSoldier in soldiers:
		if not candidate.in_fight() or candidate.side == shooter.side:
			continue
		var distance: int = shooter.cell.distance_squared_to(candidate.cell)
		var better: bool = (
			best == null
			or candidate.suppression < best.suppression
			or (candidate.suppression == best.suppression and distance < best_distance)
		)
		if better and can_engage(shooter, candidate):
			best = candidate
			best_distance = distance
	return best


func _log(kind: SimEvent.Kind, actor_id: int, target_id: int, cell: Vector2i) -> void:
	events.append(SimEvent.new(tick, kind, actor_id, target_id, cell))

class_name Simulation
extends RefCounted
## The rules of the game, advanced one tick at a time by step().
##
## No nodes, no rendering, no clock: the same seed and the same orders at the
## same ticks always give the same result. The view only reads this state and
## calls the order_ functions and step().


class Order:
	extends RefCounted
	enum Kind { MOVE, FIRE_CONTROL, FALL_BACK }
	var kind: Kind
	var team_id: int
	## Where to walk to, for MOVE.
	var target: Vector2i
	## For MOVE: true adds a leg after the current route, false replaces it.
	var append: bool
	## Whether the team may shoot, for FIRE_CONTROL.
	var fire_allowed: bool


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

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pending_orders: Array[Order] = []
var _has_fallback_cell: bool = false
var _picket_ai: PicketAi = PicketAi.new()


func _init(
	p_rules: SimRules, scenario: Scenario, weapons: Dictionary[String, WeaponDef], seed_value: int
) -> void:
	rules = p_rules
	grid = BattleGrid.new(scenario.width, scenario.height, scenario.blocked, scenario.cover)
	_rng.seed = seed_value
	fallback_cell = scenario.enemy_fallback
	_has_fallback_cell = scenario.has_enemy_fallback
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


## Advance the simulation by one tick.
func step() -> void:
	tick += 1
	_apply_pending_orders()
	_fade_suppression()
	_update_broken()
	if rules.ai_think_ticks > 0 and tick % rules.ai_think_ticks == 0:
		_picket_ai.think(self)
	for soldier: SimSoldier in soldiers:
		# A pinned man will not walk forward, but a man going back still goes.
		if soldier.is_moving() and (soldier.falling_back or not is_pinned(soldier)):
			_advance_movement(soldier)
	_resolve_fire()


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
		if soldier.side == side and soldier.withdrawn:
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
	return " ".join(parts)


func _apply_pending_orders() -> void:
	for order: Order in _pending_orders:
		var team: Array[SimSoldier] = living(SimSoldier.BattleSide.PLAYER, order.team_id)
		if team.is_empty():
			continue
		if order.kind == Order.Kind.MOVE:
			_start_move(team, order)
		elif order.kind == Order.Kind.FALL_BACK:
			_start_fall_back(team, order)
		else:
			_set_fire_control(team, order)
	_pending_orders.clear()


func _start_move(team: Array[SimSoldier], order: Order) -> void:
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
		soldier.step_ticks_total = (
			rules.move_ticks_diagonal if diagonal else rules.move_ticks_orthogonal
		)
		soldier.step_ticks_left = soldier.step_ticks_total
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
		var pinned: bool = is_pinned(shooter)
		var walking: bool = shooter.is_moving() and (shooter.falling_back or not pinned)
		if walking or not shooter.fire_allowed or shooter.rounds <= 0:
			continue
		var target: SimSoldier = _choose_target(shooter)
		if target == null:
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


func _make_casualty(soldier: SimSoldier) -> void:
	soldier.alive = false
	soldier.path.clear()
	soldier.step_ticks_left = 0
	soldier.step_ticks_total = 0
	soldier.suppression = 0
	soldier.broken = false


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
	var range_squared: int = shooter.weapon.range_cells * shooter.weapon.range_cells
	var best: SimSoldier = null
	var best_distance: int = 0
	for candidate: SimSoldier in soldiers:
		if not candidate.in_fight() or candidate.side == shooter.side:
			continue
		var distance: int = shooter.cell.distance_squared_to(candidate.cell)
		if distance > range_squared:
			continue
		var better: bool = (
			best == null
			or candidate.suppression < best.suppression
			or (candidate.suppression == best.suppression and distance < best_distance)
		)
		if better and grid.has_line_of_sight(shooter.cell, candidate.cell):
			best = candidate
			best_distance = distance
	return best


func _log(kind: SimEvent.Kind, actor_id: int, target_id: int, cell: Vector2i) -> void:
	events.append(SimEvent.new(tick, kind, actor_id, target_id, cell))

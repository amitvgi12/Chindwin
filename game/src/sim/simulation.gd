class_name Simulation
extends RefCounted
## The rules of the game, advanced one tick at a time by step().
##
## No nodes, no rendering, no clock: the same seed and the same orders at the
## same ticks always give the same result. The view only reads this state and
## calls the order_ functions and step().


class Order:
	extends RefCounted
	enum Kind { MOVE, FIRE_CONTROL }
	var kind: Kind
	var team_id: int
	## Where to walk to, for MOVE.
	var target: Vector2i
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

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pending_orders: Array[Order] = []


func _init(
	p_rules: SimRules, scenario: Scenario, weapons: Dictionary[String, WeaponDef], seed_value: int
) -> void:
	rules = p_rules
	grid = BattleGrid.new(scenario.width, scenario.height, scenario.blocked, scenario.cover)
	_rng.seed = seed_value
	for spec: Scenario.SoldierSpec in scenario.soldiers:
		var soldier: SimSoldier = SimSoldier.new()
		soldier.id = soldiers.size()
		soldier.side = spec.side
		soldier.team_id = spec.team_id
		soldier.cell = spec.cell
		soldier.weapon = weapons.get(spec.weapon_id)
		soldier.rounds = spec.rounds
		soldiers.append(soldier)


## Ask a player team to walk to a cell. Returns false when the order makes no
## sense (blocked cell, or nobody left in the team). The order takes effect at
## the start of the next tick, so orders given while paused are safe.
func order_move(team_id: int, target: Vector2i) -> bool:
	if grid.is_blocked(target):
		return false
	if living(SimSoldier.BattleSide.PLAYER, team_id).is_empty():
		return false
	var order: Order = Order.new()
	order.kind = Order.Kind.MOVE
	order.team_id = team_id
	order.target = target
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


## Advance the simulation by one tick.
func step() -> void:
	tick += 1
	_apply_pending_orders()
	for soldier: SimSoldier in soldiers:
		if soldier.is_moving():
			_advance_movement(soldier)
	_resolve_fire()


## Living soldiers of one team, in id order.
func living(side: SimSoldier.BattleSide, team_id: int) -> Array[SimSoldier]:
	var found: Array[SimSoldier] = []
	for soldier: SimSoldier in soldiers:
		if soldier.alive and soldier.side == side and soldier.team_id == team_id:
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


## How many soldiers a team started with.
func strength(side: SimSoldier.BattleSide, team_id: int) -> int:
	var count: int = 0
	for soldier: SimSoldier in soldiers:
		if soldier.side == side and soldier.team_id == team_id:
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
		if soldier.alive and soldier.cell == cell:
			return soldier
	return null


## Chance from 0 to 100 that a shot by one man at another causes a casualty.
## Cover between them cuts the weapon's chance down.
func hit_chance_percent(shooter: SimSoldier, target: SimSoldier) -> int:
	if shooter.weapon == null:
		return 0
	var chance: int = shooter.weapon.hit_chance_percent
	if grid.gives_cover(shooter.cell, target.cell):
		chance = chance * rules.cover_hit_percent / 100
	return chance


## The whole state as one line of text. Two runs are identical exactly when
## their snapshots are equal, which is how the tests check determinism.
func snapshot() -> String:
	var parts: PackedStringArray = PackedStringArray(["tick=%d" % tick])
	for soldier: SimSoldier in soldiers:
		parts.append(
			(
				"%d:%d,%d,%s,%d,%d"
				% [
					soldier.id,
					soldier.cell.x,
					soldier.cell.y,
					"up" if soldier.alive else "down",
					soldier.path.size(),
					soldier.rounds,
				]
			)
		)
	return " ".join(parts)


func _apply_pending_orders() -> void:
	for order: Order in _pending_orders:
		var team: Array[SimSoldier] = living(SimSoldier.BattleSide.PLAYER, order.team_id)
		if team.is_empty():
			continue
		if order.kind == Order.Kind.MOVE:
			_start_move(team, order)
		else:
			_set_fire_control(team, order)
	_pending_orders.clear()


func _start_move(team: Array[SimSoldier], order: Order) -> void:
	# Cells other soldiers stand on, or are walking to, are not available.
	var taken: Dictionary[Vector2i, bool] = {}
	for other: SimSoldier in soldiers:
		if other.alive and not team.has(other):
			taken[other.destination()] = true
	var places: Array[Vector2i] = grid.free_cells_near(order.target, team.size(), taken)
	for index: int in team.size():
		if index >= places.size():
			break
		var soldier: SimSoldier = team[index]
		soldier.path = grid.find_path(soldier.cell, places[index])
		soldier.step_ticks_left = 0
		soldier.step_ticks_total = 0
	_log(SimEvent.Kind.ORDER_MOVE, order.team_id, -1, order.target)


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
		_log(SimEvent.Kind.ARRIVED, soldier.id, -1, soldier.cell)


## Every man who is standing still, allowed to fire, has rounds left and can
## see an opponent in range fires one shot at the nearest. A man who is
## walking does not fire: that is the choice between fire and movement.
##
## All shots of a tick are decided first and applied afterwards, so two men
## can hit each other in the same tick and nobody gains from a lower id.
func _resolve_fire() -> void:
	var shots: Array[Shot] = []
	for shooter: SimSoldier in soldiers:
		if not shooter.alive or shooter.weapon == null:
			continue
		if shooter.fire_cooldown_ticks > 0:
			shooter.fire_cooldown_ticks -= 1
			if shooter.fire_cooldown_ticks > 0:
				continue
		if shooter.is_moving() or not shooter.fire_allowed or shooter.rounds <= 0:
			continue
		var target: SimSoldier = _nearest_visible_opponent(shooter)
		if target == null:
			continue
		shooter.rounds -= 1
		shooter.fire_cooldown_ticks = shooter.weapon.fire_interval_ticks
		var shot: Shot = Shot.new()
		shot.shooter = shooter
		shot.target = target
		shot.hit = _rng.randi_range(1, 100) <= hit_chance_percent(shooter, target)
		shots.append(shot)
	for shot: Shot in shots:
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


func _nearest_visible_opponent(shooter: SimSoldier) -> SimSoldier:
	var range_cells: int = shooter.weapon.range_cells
	var best: SimSoldier = null
	var best_distance: int = range_cells * range_cells + 1
	for candidate: SimSoldier in soldiers:
		if not candidate.alive or candidate.side == shooter.side:
			continue
		var distance: int = shooter.cell.distance_squared_to(candidate.cell)
		# Strictly closer wins, so ties go to the lower id. Never random.
		if distance < best_distance and grid.has_line_of_sight(shooter.cell, candidate.cell):
			best = candidate
			best_distance = distance
	return best


func _log(kind: SimEvent.Kind, actor_id: int, target_id: int, cell: Vector2i) -> void:
	events.append(SimEvent.new(tick, kind, actor_id, target_id, cell))

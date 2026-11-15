class_name Simulation
extends RefCounted
## The rules of the game, advanced one tick at a time by step().
##
## No nodes, no rendering, no clock: the same seed and the same orders at the
## same ticks always give the same result. The view only reads this state and
## calls order_move() and step().


class MoveOrder:
	extends RefCounted
	var team_id: int
	var target: Vector2i


var tick: int = 0
var rules: SimRules
var grid: BattleGrid
var soldiers: Array[SimSoldier] = []
## Everything that has happened so far, oldest first.
var events: Array[SimEvent] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pending_orders: Array[MoveOrder] = []


func _init(p_rules: SimRules, scenario: Scenario, seed_value: int) -> void:
	rules = p_rules
	grid = BattleGrid.new(scenario.width, scenario.height, scenario.blocked)
	_rng.seed = seed_value
	for spec: Scenario.SoldierSpec in scenario.soldiers:
		var soldier: SimSoldier = SimSoldier.new()
		soldier.id = soldiers.size()
		soldier.side = spec.side
		soldier.team_id = spec.team_id
		soldier.cell = spec.cell
		soldiers.append(soldier)


## Ask a player team to walk to a cell. Returns false when the order makes no
## sense (blocked cell, or nobody left in the team). The order takes effect at
## the start of the next tick, so orders given while paused are safe.
func order_move(team_id: int, target: Vector2i) -> bool:
	if grid.is_blocked(target):
		return false
	if living(SimSoldier.BattleSide.PLAYER, team_id).is_empty():
		return false
	var order: MoveOrder = MoveOrder.new()
	order.team_id = team_id
	order.target = target
	_pending_orders.append(order)
	return true


## Advance the simulation by one tick.
func step() -> void:
	tick += 1
	_apply_pending_orders()
	for soldier: SimSoldier in soldiers:
		if soldier.is_moving():
			_advance_movement(soldier)
	_enemy_fire()


## Living soldiers of one team, in id order.
func living(side: SimSoldier.BattleSide, team_id: int) -> Array[SimSoldier]:
	var found: Array[SimSoldier] = []
	for soldier: SimSoldier in soldiers:
		if soldier.alive and soldier.side == side and soldier.team_id == team_id:
			found.append(soldier)
	return found


## How many soldiers a team started with.
func strength(side: SimSoldier.BattleSide, team_id: int) -> int:
	var count: int = 0
	for soldier: SimSoldier in soldiers:
		if soldier.side == side and soldier.team_id == team_id:
			count += 1
	return count


## The living soldier standing on a cell, or null.
func soldier_at(cell: Vector2i) -> SimSoldier:
	for soldier: SimSoldier in soldiers:
		if soldier.alive and soldier.cell == cell:
			return soldier
	return null


## The whole state as one line of text. Two runs are identical exactly when
## their snapshots are equal, which is how the tests check determinism.
func snapshot() -> String:
	var parts: PackedStringArray = PackedStringArray(["tick=%d" % tick])
	for soldier: SimSoldier in soldiers:
		(
			parts
			. append(
				(
					"%d:%d,%d,%s,%d"
					% [
						soldier.id,
						soldier.cell.x,
						soldier.cell.y,
						"up" if soldier.alive else "down",
						soldier.path.size(),
					]
				)
			)
		)
	return " ".join(parts)


func _apply_pending_orders() -> void:
	for order: MoveOrder in _pending_orders:
		var team: Array[SimSoldier] = living(SimSoldier.BattleSide.PLAYER, order.team_id)
		if team.is_empty():
			continue
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
	_pending_orders.clear()


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


## Placeholder enemy: each man fires at the nearest player soldier he can see
## within range. Replaced by real behaviour later in Phase 1.
func _enemy_fire() -> void:
	for shooter: SimSoldier in soldiers:
		if not shooter.alive or shooter.side != SimSoldier.BattleSide.ENEMY:
			continue
		if shooter.fire_cooldown_ticks > 0:
			shooter.fire_cooldown_ticks -= 1
			if shooter.fire_cooldown_ticks > 0:
				continue
		var target: SimSoldier = _nearest_visible_player(shooter)
		if target == null:
			continue
		shooter.fire_cooldown_ticks = rules.enemy_fire_interval_ticks
		if _rng.randi_range(1, 100) <= rules.enemy_hit_chance_percent:
			target.alive = false
			target.path.clear()
			target.step_ticks_left = 0
			target.step_ticks_total = 0
			_log(SimEvent.Kind.SHOT_HIT, shooter.id, target.id, target.cell)
		else:
			_log(SimEvent.Kind.SHOT_MISSED, shooter.id, target.id, target.cell)


func _nearest_visible_player(shooter: SimSoldier) -> SimSoldier:
	var range_squared: int = rules.enemy_range_cells * rules.enemy_range_cells
	var best: SimSoldier = null
	var best_distance: int = range_squared + 1
	for candidate: SimSoldier in soldiers:
		if not candidate.alive or candidate.side != SimSoldier.BattleSide.PLAYER:
			continue
		var distance: int = shooter.cell.distance_squared_to(candidate.cell)
		# Strictly closer wins, so ties go to the lower id. Never random.
		if distance < best_distance and grid.has_line_of_sight(shooter.cell, candidate.cell):
			best = candidate
			best_distance = distance
	return best


func _log(kind: SimEvent.Kind, actor_id: int, target_id: int, cell: Vector2i) -> void:
	events.append(SimEvent.new(tick, kind, actor_id, target_id, cell))

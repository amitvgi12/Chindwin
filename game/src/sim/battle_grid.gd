class_name BattleGrid
extends RefCounted
## The map as a grid of cells. Answers four questions: can a soldier stand
## here, how does he walk from A to B, can A see B, and is B behind cover
## from A. Pure logic: no nodes, no physics.
##
## Two kinds of obstacle:
##   tall  (thick jungle)  stops movement and sight
##   low   (a bank, logs)  stops movement, not sight, and gives cover
## One kind of ground:
##   slope                 open, but slower to cross; how much depends on the weather

## Fixed order in which neighbouring cells are visited, so results never vary.
const NEIGHBOURS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, 1),
	Vector2i(-1, 1),
	Vector2i(-1, -1),
	Vector2i(1, -1),
]

## How many cells behind a bank a man can stand and still be covered by it.
const COVER_DEPTH: int = 2

var width: int
var height: int

var _tall: Dictionary[Vector2i, bool] = {}
var _low: Dictionary[Vector2i, bool] = {}
var _slope: Dictionary[Vector2i, bool] = {}
var _astar: AStarGrid2D = AStarGrid2D.new()


func _init(
	p_width: int,
	p_height: int,
	tall: Array[Vector2i],
	low: Array[Vector2i] = [],
	slopes: Array[Vector2i] = []
) -> void:
	width = p_width
	height = p_height
	_astar.region = Rect2i(0, 0, width, height)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for cell: Vector2i in tall:
		if in_bounds(cell):
			_tall[cell] = true
			_astar.set_point_solid(cell, true)
	for cell: Vector2i in low:
		if in_bounds(cell) and not _tall.has(cell):
			_low[cell] = true
			_astar.set_point_solid(cell, true)
	for cell: Vector2i in slopes:
		if in_bounds(cell) and not is_blocked(cell):
			_slope[cell] = true


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


## True when nobody can stand on the cell. Off-map cells count as blocked.
func is_blocked(cell: Vector2i) -> bool:
	return not in_bounds(cell) or _tall.has(cell) or _low.has(cell)


## True when the cell hides whatever is behind it.
func blocks_sight(cell: Vector2i) -> bool:
	return not in_bounds(cell) or _tall.has(cell)


func is_low_cover(cell: Vector2i) -> bool:
	return _low.has(cell)


func is_slope(cell: Vector2i) -> bool:
	return _slope.has(cell)


func slope_cells() -> Array[Vector2i]:
	return _slope.keys()


## Tell the route-finder how slow slopes are right now, as a percentage of
## normal, so that routes go round them when that is quicker.
func set_slope_cost_percent(percent: int) -> void:
	for cell: Vector2i in _slope:
		_astar.set_point_weight_scale(cell, maxf(1.0, percent / 100.0))


func tall_cells() -> Array[Vector2i]:
	return _tall.keys()


func low_cells() -> Array[Vector2i]:
	return _low.keys()


## Cells to walk through to get from one cell to another, not including the
## starting cell. Empty when there is no route or the two cells are the same.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var steps: Array[Vector2i] = []
	if is_blocked(from) or is_blocked(to) or from == to:
		return steps
	var full_path: Array[Vector2i] = _astar.get_id_path(from, to)
	for index: int in range(1, full_path.size()):
		steps.append(full_path[index])
	return steps


## Every cell on the straight line between two cells, both ends included.
func line_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var dx: int = absi(to.x - from.x)
	var dy: int = -absi(to.y - from.y)
	var step_x: int = 1 if from.x < to.x else -1
	var step_y: int = 1 if from.y < to.y else -1
	var error: int = dx + dy
	var x: int = from.x
	var y: int = from.y
	while true:
		cells.append(Vector2i(x, y))
		if x == to.x and y == to.y:
			break
		var doubled: int = 2 * error
		if doubled >= dy:
			error += dy
			x += step_x
		if doubled <= dx:
			error += dx
			y += step_y
	return cells


## True when nothing tall lies strictly between the two cells.
func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	for cell: Vector2i in line_cells(from, to):
		if cell != from and cell != to and blocks_sight(cell):
			return false
	return true


## True when a man at `target` is behind cover from a shot fired at `shooter`.
##
## He is covered when the shot crosses low cover within COVER_DEPTH cells of
## him, unless that cover is right next to the shooter: a man standing at a
## bank fires over it freely, and two men either side of the same bank at
## arm's length have no cover from each other.
##
## So cover only protects against fire that comes over it from a distance.
## A shot from the side or from behind does not cross it, which is what makes
## going round the flank pay.
func gives_cover(shooter: Vector2i, target: Vector2i) -> bool:
	var cells: Array[Vector2i] = line_cells(shooter, target)
	var last: int = cells.size() - 1
	for back: int in range(1, COVER_DEPTH + 1):
		var index: int = last - back
		if index >= 2 and is_low_cover(cells[index]):
			return true
	return false


## Up to `count` free cells as close as possible to `target`, nearest first.
## Used to give each soldier of a team his own place to stand. Cells in
## `taken` are skipped. Empty when `target` itself is blocked.
func free_cells_near(
	target: Vector2i, count: int, taken: Dictionary[Vector2i, bool]
) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	if is_blocked(target):
		return found
	var visited: Dictionary[Vector2i, bool] = {target: true}
	var queue: Array[Vector2i] = [target]
	var head: int = 0
	while head < queue.size() and found.size() < count:
		var cell: Vector2i = queue[head]
		head += 1
		if not taken.has(cell):
			found.append(cell)
		for offset: Vector2i in NEIGHBOURS:
			var next: Vector2i = cell + offset
			if not visited.has(next) and not is_blocked(next):
				visited[next] = true
				queue.append(next)
	return found

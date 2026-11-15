extends GutTest
## Rules of the map: where a soldier can stand, walk and see.


func _grid_with_wall() -> BattleGrid:
	# 7 wide, 5 high, with a wall down column 3 that leaves a gap in the bottom row.
	#   . . . # . . .
	#   . . . # . . .
	#   . . . # . . .
	#   . . . # . . .
	#   . . . . . . .
	var wall: Array[Vector2i] = [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3)]
	return BattleGrid.new(7, 5, wall)


func test_cells_off_the_map_count_as_blocked() -> void:
	var grid: BattleGrid = _grid_with_wall()
	assert_true(grid.is_blocked(Vector2i(-1, 0)))
	assert_true(grid.is_blocked(Vector2i(7, 0)))
	assert_true(grid.is_blocked(Vector2i(0, 5)))
	assert_false(grid.is_blocked(Vector2i(0, 0)))


func test_wall_cells_are_blocked() -> void:
	var grid: BattleGrid = _grid_with_wall()
	assert_true(grid.is_blocked(Vector2i(3, 2)))
	assert_false(grid.is_blocked(Vector2i(3, 4)), "the gap in the wall is open")


func test_path_goes_round_the_wall_through_the_gap() -> void:
	var grid: BattleGrid = _grid_with_wall()
	var path: Array[Vector2i] = grid.find_path(Vector2i(1, 0), Vector2i(5, 0))
	assert_false(path.is_empty(), "a route exists")
	assert_has(path, Vector2i(3, 4), "the only way through is the gap")
	assert_eq(path[path.size() - 1], Vector2i(5, 0), "the path ends at the target")
	for cell: Vector2i in path:
		assert_false(grid.is_blocked(cell), "path never crosses a blocked cell: %s" % cell)


func test_path_leaves_out_the_starting_cell() -> void:
	var grid: BattleGrid = _grid_with_wall()
	var path: Array[Vector2i] = grid.find_path(Vector2i(0, 0), Vector2i(2, 0))
	assert_eq(path, [Vector2i(1, 0), Vector2i(2, 0)] as Array[Vector2i])


func test_no_path_to_a_blocked_cell_or_to_itself() -> void:
	var grid: BattleGrid = _grid_with_wall()
	assert_true(grid.find_path(Vector2i(0, 0), Vector2i(3, 1)).is_empty())
	assert_true(grid.find_path(Vector2i(0, 0), Vector2i(0, 0)).is_empty())


func test_no_path_when_the_target_is_walled_off() -> void:
	var full_wall: Array[Vector2i] = []
	for y: int in 5:
		full_wall.append(Vector2i(3, y))
	var grid: BattleGrid = BattleGrid.new(7, 5, full_wall)
	assert_true(grid.find_path(Vector2i(1, 2), Vector2i(5, 2)).is_empty())


func test_the_same_path_is_found_every_time() -> void:
	var grid: BattleGrid = _grid_with_wall()
	var first: Array[Vector2i] = grid.find_path(Vector2i(0, 0), Vector2i(6, 0))
	for attempt: int in 5:
		assert_eq(grid.find_path(Vector2i(0, 0), Vector2i(6, 0)), first)


func test_line_includes_both_ends() -> void:
	var grid: BattleGrid = _grid_with_wall()
	var cells: Array[Vector2i] = grid.line_cells(Vector2i(0, 0), Vector2i(5, 2))
	assert_eq(cells[0], Vector2i(0, 0))
	assert_eq(cells[cells.size() - 1], Vector2i(5, 2))


func test_a_wall_blocks_line_of_sight() -> void:
	var grid: BattleGrid = _grid_with_wall()
	assert_false(grid.has_line_of_sight(Vector2i(1, 1), Vector2i(5, 1)), "wall in between")
	assert_true(grid.has_line_of_sight(Vector2i(1, 4), Vector2i(5, 4)), "clear along the gap row")


func test_line_of_sight_is_the_same_in_both_directions_along_a_row() -> void:
	var grid: BattleGrid = _grid_with_wall()
	assert_eq(
		grid.has_line_of_sight(Vector2i(1, 1), Vector2i(5, 1)),
		grid.has_line_of_sight(Vector2i(5, 1), Vector2i(1, 1))
	)


func test_free_cells_near_starts_with_the_target_and_skips_taken_cells() -> void:
	var grid: BattleGrid = _grid_with_wall()
	var nobody: Dictionary[Vector2i, bool] = {}
	var open: Array[Vector2i] = grid.free_cells_near(Vector2i(1, 1), 3, nobody)
	assert_eq(open.size(), 3)
	assert_eq(open[0], Vector2i(1, 1), "the target itself comes first")

	var taken: Dictionary[Vector2i, bool] = {Vector2i(1, 1): true}
	var around: Array[Vector2i] = grid.free_cells_near(Vector2i(1, 1), 3, taken)
	assert_does_not_have(around, Vector2i(1, 1), "a taken cell is never handed out")
	assert_eq(around.size(), 3)


func test_free_cells_near_never_returns_blocked_cells_or_duplicates() -> void:
	var grid: BattleGrid = _grid_with_wall()
	var nobody: Dictionary[Vector2i, bool] = {}
	var cells: Array[Vector2i] = grid.free_cells_near(Vector2i(2, 2), 10, nobody)
	var seen: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in cells:
		assert_false(grid.is_blocked(cell))
		assert_false(seen.has(cell), "no cell twice")
		seen[cell] = true
	assert_eq(cells.size(), 10)


func test_free_cells_near_a_blocked_target_is_empty() -> void:
	var grid: BattleGrid = _grid_with_wall()
	var nobody: Dictionary[Vector2i, bool] = {}
	assert_true(grid.free_cells_near(Vector2i(3, 1), 3, nobody).is_empty())


func _grid_with_bank() -> BattleGrid:
	# 7 wide, 5 high, with one low bank (cover) at (3, 2).
	var nothing_tall: Array[Vector2i] = []
	var bank: Array[Vector2i] = [Vector2i(3, 2)]
	return BattleGrid.new(7, 5, nothing_tall, bank)


func test_low_cover_stops_walking_but_not_sight() -> void:
	var grid: BattleGrid = _grid_with_bank()
	assert_true(grid.is_blocked(Vector2i(3, 2)), "nobody stands on the bank")
	assert_false(grid.blocks_sight(Vector2i(3, 2)), "but you can see over it")
	assert_true(grid.has_line_of_sight(Vector2i(1, 2), Vector2i(5, 2)))
	assert_does_not_have(grid.find_path(Vector2i(1, 2), Vector2i(5, 2)), Vector2i(3, 2))


func test_thick_jungle_stops_both_walking_and_sight() -> void:
	var grid: BattleGrid = _grid_with_wall()
	assert_true(grid.is_blocked(Vector2i(3, 2)))
	assert_true(grid.blocks_sight(Vector2i(3, 2)))
	assert_false(grid.is_low_cover(Vector2i(3, 2)))


func test_a_man_right_behind_a_bank_is_covered_from_the_front() -> void:
	var grid: BattleGrid = _grid_with_bank()
	assert_true(grid.gives_cover(Vector2i(0, 2), Vector2i(4, 2)), "shot crosses the bank last")


func test_a_man_behind_a_bank_is_not_covered_from_the_side_or_rear() -> void:
	var grid: BattleGrid = _grid_with_bank()
	assert_false(grid.gives_cover(Vector2i(4, 0), Vector2i(4, 2)), "from the side")
	assert_false(grid.gives_cover(Vector2i(6, 2), Vector2i(4, 2)), "from behind")


func test_a_bank_does_not_cover_a_man_standing_away_from_it() -> void:
	var grid: BattleGrid = _grid_with_bank()
	assert_false(grid.gives_cover(Vector2i(0, 2), Vector2i(6, 2)), "two cells back: no cover")


func test_the_man_shooting_over_a_bank_gets_no_cover_from_it_at_long_range() -> void:
	var grid: BattleGrid = _grid_with_bank()
	assert_false(grid.gives_cover(Vector2i(4, 2), Vector2i(0, 2)))


func test_adjacent_men_never_have_cover_between_them() -> void:
	var grid: BattleGrid = _grid_with_bank()
	assert_false(grid.gives_cover(Vector2i(4, 2), Vector2i(5, 2)))

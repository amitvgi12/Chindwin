class_name BattleView
extends Node2D
## Draws the simulation and turns mouse and keyboard input into orders.
## Holds no rules: everything shown here is read from Simulation.


## A line drawn for a moment from a shooter to his target.
class Tracer:
	extends RefCounted
	var from: Vector2
	var to: Vector2
	var hit: bool
	var seconds_left: float


const SCENARIO_PATH: String = "res://data/scenarios/test_range.json"
const RULES_PATH: String = "res://data/rules/prototype_rules.tres"
const DEFAULT_SEED: int = 1944

## Size of one grid cell on screen, in pixels.
const CELL_PX: int = 32
## Most simulation ticks run in one drawn frame, so a slow frame cannot snowball.
const MAX_STEPS_PER_FRAME: int = 5
const TRACER_SECONDS: float = 0.25

# Colours are from a palette chosen to stay distinct for colour-blind players.
# Shape also differs: player soldiers are circles, enemy soldiers are diamonds.
const COLOUR_GROUND: Color = Color("2f3b2f")
const COLOUR_GRID_LINE: Color = Color(1.0, 1.0, 1.0, 0.05)
const COLOUR_BLOCKED: Color = Color("6b6257")
const COLOUR_TEAM_1: Color = Color("4477aa")
const COLOUR_TEAM_2: Color = Color("66ccee")
const COLOUR_ENEMY: Color = Color("ee6677")
const COLOUR_CASUALTY: Color = Color("bbbbbb")
const COLOUR_SELECTED: Color = Color("ffffff")
const COLOUR_SHOT_MISSED: Color = Color("ccbb44")
const COLOUR_SHOT_HIT: Color = Color("ee6677")

var sim: Simulation
var paused: bool = true
var selected_team: int = 1

var _scenario_name_key: String = ""
var _tick_accumulator: float = 0.0
var _events_drawn: int = 0
var _tracers: Array[Tracer] = []

@onready var _hud_text: Label = $Hud/Panel/Text


func _ready() -> void:
	InputActions.ensure_defaults()
	restart()


func _process(delta: float) -> void:
	advance(delta)
	_refresh_hud()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	handle_input(event)


func _draw() -> void:
	_draw_ground()
	_draw_destinations()
	for soldier: SimSoldier in sim.soldiers:
		if not soldier.alive:
			_draw_casualty(soldier)
	for soldier: SimSoldier in sim.soldiers:
		if soldier.alive:
			_draw_soldier(soldier)
	_draw_tracers()


## Start the scenario again from the beginning, paused.
func restart() -> void:
	var rules: SimRules = load(RULES_PATH) as SimRules
	var scenario: Scenario = Scenario.load_file(SCENARIO_PATH)
	for problem: String in scenario.errors:
		push_error("%s: %s" % [SCENARIO_PATH, problem])
	sim = Simulation.new(rules, scenario, DEFAULT_SEED)
	_scenario_name_key = scenario.name_key
	paused = true
	selected_team = 1
	_tick_accumulator = 0.0
	_events_drawn = 0
	_tracers.clear()
	_refresh_hud()
	queue_redraw()


## Run the simulation forward by `delta` seconds of real time, unless paused.
func advance(delta: float) -> void:
	if paused:
		return
	_age_tracers(delta)
	var tick_seconds: float = 1.0 / sim.rules.ticks_per_second
	_tick_accumulator += delta
	var steps: int = 0
	# The tiny allowance stops rounding error from delaying a tick by a frame.
	while _tick_accumulator + 0.000001 >= tick_seconds and steps < MAX_STEPS_PER_FRAME:
		sim.step()
		_tick_accumulator -= tick_seconds
		steps += 1
	if steps == MAX_STEPS_PER_FRAME:
		_tick_accumulator = 0.0
	_collect_new_tracers()


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.PAUSE):
		toggle_pause()
	elif event.is_action_pressed(InputActions.SELECT_TEAM_1):
		select_team(1)
	elif event.is_action_pressed(InputActions.SELECT_TEAM_2):
		select_team(2)
	elif event.is_action_pressed(InputActions.RESTART):
		restart()
	elif event is InputEventMouseButton:
		var click: InputEventMouseButton = event as InputEventMouseButton
		if not click.pressed:
			return
		if click.button_index == MOUSE_BUTTON_RIGHT:
			order_selected_team_to(cell_at(click.position))
		elif click.button_index == MOUSE_BUTTON_LEFT:
			select_team_at(cell_at(click.position))


func toggle_pause() -> void:
	paused = not paused


## Select a player team by number. Ignored if the team does not exist.
func select_team(team_id: int) -> void:
	if sim.team_ids(SimSoldier.BattleSide.PLAYER).has(team_id):
		selected_team = team_id


## Select the team of the player soldier standing on a cell, if there is one.
func select_team_at(cell: Vector2i) -> void:
	var soldier: SimSoldier = sim.soldier_at(cell)
	if soldier != null and soldier.side == SimSoldier.BattleSide.PLAYER:
		select_team(soldier.team_id)


## Order the selected team to walk to a cell. Works while paused.
func order_selected_team_to(cell: Vector2i) -> bool:
	return sim.order_move(selected_team, cell)


## The grid cell under a point on screen.
func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / CELL_PX), floori(point.y / CELL_PX))


## The middle of a grid cell on screen.
func cell_centre(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * CELL_PX, (cell.y + 0.5) * CELL_PX)


## The text currently shown in the corner panel.
func hud_text() -> String:
	return _hud_text.text


func _refresh_hud() -> void:
	var state: String = tr("HUD_PAUSED") if paused else tr("HUD_RUNNING")
	var status: String = tr("HUD_STATUS").format(
		{"state": state, "time": _clock_text(), "team": selected_team}
	)
	var strengths: PackedStringArray = PackedStringArray()
	for team_id: int in sim.team_ids(SimSoldier.BattleSide.PLAYER):
		(
			strengths
			. append(
				(
					tr("HUD_TEAM")
					. format(
						{
							"team": team_id,
							"fit": sim.living(SimSoldier.BattleSide.PLAYER, team_id).size(),
							"total": sim.strength(SimSoldier.BattleSide.PLAYER, team_id),
						}
					)
				)
			)
		)
	var enemy_fit: int = 0
	var enemy_total: int = 0
	for team_id: int in sim.team_ids(SimSoldier.BattleSide.ENEMY):
		enemy_fit += sim.living(SimSoldier.BattleSide.ENEMY, team_id).size()
		enemy_total += sim.strength(SimSoldier.BattleSide.ENEMY, team_id)
	strengths.append(tr("HUD_ENEMY").format({"fit": enemy_fit, "total": enemy_total}))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s: %s      %s" % [tr("GAME_TITLE"), tr(_scenario_name_key), status])
	lines.append("      ".join(strengths))
	lines.append(tr("HUD_CONTROLS"))
	_hud_text.text = "\n".join(lines)


func _clock_text() -> String:
	var seconds: int = sim.tick / sim.rules.ticks_per_second
	return "%d:%02d" % [seconds / 60, seconds % 60]


func _collect_new_tracers() -> void:
	while _events_drawn < sim.events.size():
		var event: SimEvent = sim.events[_events_drawn]
		_events_drawn += 1
		var hit: bool = event.kind == SimEvent.Kind.SHOT_HIT
		if not hit and event.kind != SimEvent.Kind.SHOT_MISSED:
			continue
		var tracer: Tracer = Tracer.new()
		tracer.from = cell_centre(sim.soldiers[event.actor_id].cell)
		tracer.to = cell_centre(event.cell)
		tracer.hit = hit
		tracer.seconds_left = TRACER_SECONDS
		_tracers.append(tracer)


func _age_tracers(delta: float) -> void:
	var still_showing: Array[Tracer] = []
	for tracer: Tracer in _tracers:
		tracer.seconds_left -= delta
		if tracer.seconds_left > 0.0:
			still_showing.append(tracer)
	_tracers = still_showing


## Where to draw a soldier: part-way to the next cell while he is walking.
func _soldier_position(soldier: SimSoldier) -> Vector2:
	var here: Vector2 = cell_centre(soldier.cell)
	if not soldier.is_moving() or soldier.step_ticks_total == 0:
		return here
	var tick_seconds: float = 1.0 / sim.rules.ticks_per_second
	var ticks_done: float = soldier.step_ticks_total - soldier.step_ticks_left
	if not paused:
		ticks_done += _tick_accumulator / tick_seconds
	var progress: float = clampf(ticks_done / soldier.step_ticks_total, 0.0, 1.0)
	return here.lerp(cell_centre(soldier.path[0]), progress)


func _team_colour(soldier: SimSoldier) -> Color:
	if soldier.side == SimSoldier.BattleSide.ENEMY:
		return COLOUR_ENEMY
	return COLOUR_TEAM_1 if soldier.team_id == 1 else COLOUR_TEAM_2


func _draw_ground() -> void:
	var size: Vector2 = Vector2(sim.grid.width * CELL_PX, sim.grid.height * CELL_PX)
	draw_rect(Rect2(Vector2.ZERO, size), COLOUR_GROUND)
	for x: int in range(sim.grid.width + 1):
		draw_line(Vector2(x * CELL_PX, 0), Vector2(x * CELL_PX, size.y), COLOUR_GRID_LINE)
	for y: int in range(sim.grid.height + 1):
		draw_line(Vector2(0, y * CELL_PX), Vector2(size.x, y * CELL_PX), COLOUR_GRID_LINE)
	for cell: Vector2i in sim.grid.blocked_cells():
		var corner: Vector2 = Vector2(cell.x * CELL_PX, cell.y * CELL_PX)
		draw_rect(Rect2(corner, Vector2(CELL_PX, CELL_PX)), COLOUR_BLOCKED)


## A small hollow square where each walking player soldier is heading.
func _draw_destinations() -> void:
	for soldier: SimSoldier in sim.soldiers:
		if soldier.side != SimSoldier.BattleSide.PLAYER or not soldier.is_moving():
			continue
		var centre: Vector2 = cell_centre(soldier.destination())
		var box: Rect2 = Rect2(centre - Vector2(6, 6), Vector2(12, 12))
		draw_rect(box, _team_colour(soldier), false, 2.0)


func _draw_soldier(soldier: SimSoldier) -> void:
	var centre: Vector2 = _soldier_position(soldier)
	if soldier.side == SimSoldier.BattleSide.ENEMY:
		draw_colored_polygon(_diamond(centre, 12.0), COLOUR_ENEMY)
		return
	draw_circle(centre, 11.0, _team_colour(soldier))
	if soldier.team_id == selected_team:
		draw_arc(centre, 13.0, 0.0, TAU, 32, COLOUR_SELECTED, 2.0)
	draw_string(
		ThemeDB.fallback_font,
		centre + Vector2(-4, 5),
		str(soldier.team_id),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color.BLACK
	)


## A casualty is a grey cross inside the outline of what he was.
func _draw_casualty(soldier: SimSoldier) -> void:
	var centre: Vector2 = cell_centre(soldier.cell)
	if soldier.side == SimSoldier.BattleSide.ENEMY:
		draw_polyline(_diamond(centre, 12.0, true), COLOUR_CASUALTY, 1.5)
	else:
		draw_arc(centre, 11.0, 0.0, TAU, 32, COLOUR_CASUALTY, 1.5)
	draw_line(centre + Vector2(-6, -6), centre + Vector2(6, 6), COLOUR_CASUALTY, 2.0)
	draw_line(centre + Vector2(-6, 6), centre + Vector2(6, -6), COLOUR_CASUALTY, 2.0)


func _draw_tracers() -> void:
	for tracer: Tracer in _tracers:
		var colour: Color = COLOUR_SHOT_HIT if tracer.hit else COLOUR_SHOT_MISSED
		colour.a = clampf(tracer.seconds_left / TRACER_SECONDS, 0.0, 1.0)
		draw_line(tracer.from, tracer.to, colour, 3.0 if tracer.hit else 1.5)


func _diamond(centre: Vector2, radius: float, closed: bool = false) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array(
		[
			centre + Vector2(0, -radius),
			centre + Vector2(radius, 0),
			centre + Vector2(0, radius),
			centre + Vector2(-radius, 0),
		]
	)
	if closed:
		points.append(points[0])
	return points

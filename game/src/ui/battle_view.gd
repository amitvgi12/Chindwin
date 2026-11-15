class_name BattleView
extends Node2D
## Draws the simulation and turns mouse and keyboard input into orders.
## Holds no rules: everything shown here is read from Simulation.
##
## The look is a trial of one art direction, "a military map in the rain".
## It is drawn entirely in code, uses no art files, and is a placeholder
## until the art decision in Phase 3.


## A line drawn for a moment from a shooter to his target.
class Tracer:
	extends RefCounted
	var from: Vector2
	var to: Vector2
	var hit: bool
	var by_player: bool
	var seconds_left: float


const SCENARIO_PATH: String = "res://data/scenarios/test_range.json"
const RULES_PATH: String = "res://data/rules/prototype_rules.tres"
const DEFAULT_SEED: int = 1944

## Size of one grid cell on screen, in pixels.
const CELL_PX: int = 32
## Most simulation ticks run in one drawn frame, so a slow frame cannot snowball.
const MAX_STEPS_PER_FRAME: int = 5
const TRACER_SECONDS: float = 0.35
const RAIN_STREAKS: int = 170

# Ground and terrain.
const COLOUR_GROUND_LIGHT: Color = Color("5c5a40")
const COLOUR_GROUND_DARK: Color = Color("4c4d36")
const COLOUR_TRACK: Color = Color("7d6747")
const COLOUR_JUNGLE: Array[Color] = [Color("1f3320"), Color("294228"), Color("17281a")]
const COLOUR_BANK: Color = Color("8f7a52")
const COLOUR_BANK_EDGE: Color = Color("3a3122")
const COLOUR_RAIN: Color = Color(0.86, 0.9, 0.95, 0.2)
const COLOUR_RAIN_HAZE: Color = Color(0.45, 0.55, 0.65, 0.1)

# Soldiers. The palette stays distinct for colour-blind players, and shape
# differs too: player soldiers are circles, enemy soldiers are diamonds.
const COLOUR_TEAM_1: Color = Color("4477aa")
const COLOUR_TEAM_2: Color = Color("66ccee")
const COLOUR_ENEMY: Color = Color("ee6677")
const COLOUR_OUTLINE: Color = Color("141414")
const COLOUR_CASUALTY: Color = Color("c9c9c9")
const COLOUR_SELECTED: Color = Color("ffffff")
const COLOUR_SHOT_MISSED: Color = Color("e8d44d")
const COLOUR_SHOT_HIT: Color = Color("ff3b30")
const COLOUR_METER_BACK: Color = Color(0.0, 0.0, 0.0, 0.6)
const COLOUR_METER_RISING: Color = Color("e8d44d")
const COLOUR_METER_PINNED: Color = Color("ff7a1a")
const COLOUR_METER_BROKEN: Color = Color("ff2d2d")
const COLOUR_DEBUG_THREAT: Color = Color(1.0, 0.25, 0.2, 0.55)
const COLOUR_DEBUG_COVERED: Color = Color(0.8, 0.8, 0.8, 0.3)
const COLOUR_DEBUG_CLEAR_SHOT: Color = Color(0.3, 1.0, 0.4, 0.6)
const COLOUR_DEBUG_RANGE: Color = Color(1.0, 1.0, 1.0, 0.12)
## How many of the enemy's latest decisions the debug overlay lists.
const DEBUG_LOG_LINES: int = 6

var sim: Simulation
var paused: bool = true
var selected_team: int = 1
## Shows who can hit whom, suppression numbers and the enemy's decisions.
var debug_overlay: bool = false

var _scenario: Scenario
## What each player team was last told about firing. Kept here because an
## order given while paused has not reached the simulation yet.
var _team_fire: Dictionary[int, bool] = {}
var _tick_accumulator: float = 0.0
var _rain_clock: float = 0.0
var _events_drawn: int = 0
var _tracers: Array[Tracer] = []

@onready var _hud_text: Label = $Hud/Panel/Margin/Text
@onready var _paused_banner: Label = $Hud/Banner
@onready var _debug_text: Label = $Hud/Debug
@onready var _help: ControlsCard = $Hud/Help


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
	_draw_tracks()
	_draw_banks()
	_draw_jungle()
	_draw_routes()
	_draw_destinations()
	for soldier: SimSoldier in sim.soldiers:
		if not soldier.alive:
			_draw_casualty(soldier)
	for soldier: SimSoldier in sim.soldiers:
		if soldier.in_fight():
			_draw_soldier(soldier)
	_draw_tracers()
	_draw_rain()
	if debug_overlay:
		_draw_debug()


## Start the scenario again from the beginning, paused.
func restart() -> void:
	var rules: SimRules = load(RULES_PATH) as SimRules
	_scenario = Scenario.load_file(SCENARIO_PATH)
	for problem: String in _scenario.errors:
		push_error("%s: %s" % [SCENARIO_PATH, problem])
	var weapons: Dictionary[String, WeaponDef] = WeaponLibrary.load_for(_scenario)
	for weapon_id: String in _scenario.missing_weapons(weapons):
		push_error("%s: no weapon file for '%s'" % [SCENARIO_PATH, weapon_id])
	sim = Simulation.new(rules, _scenario, weapons, DEFAULT_SEED)
	paused = true
	selected_team = 1
	_team_fire.clear()
	for team_id: int in sim.team_ids(SimSoldier.BattleSide.PLAYER):
		_team_fire[team_id] = true
	_tick_accumulator = 0.0
	_rain_clock = 0.0
	_events_drawn = 0
	_tracers.clear()
	_refresh_hud()
	queue_redraw()


## Run the simulation forward by `delta` seconds of real time, unless paused.
func advance(delta: float) -> void:
	if paused:
		return
	_rain_clock += delta
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
	elif event.is_action_pressed(InputActions.TOGGLE_FIRE):
		toggle_fire_for_selected_team()
	elif event.is_action_pressed(InputActions.FALL_BACK):
		order_selected_team_to_fall_back()
	elif event.is_action_pressed(InputActions.HELP):
		toggle_help()
	elif event.is_action_pressed(InputActions.TOGGLE_OVERLAY):
		debug_overlay = not debug_overlay
	elif event.is_action_pressed(InputActions.RESTART):
		restart()
	elif event is InputEventMouseButton:
		var click: InputEventMouseButton = event as InputEventMouseButton
		if not click.pressed:
			return
		if click.button_index == MOUSE_BUTTON_RIGHT:
			order_selected_team_to(cell_at(click.position), click.shift_pressed)
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
## With `as_waypoint`, the team finishes its current route first.
func order_selected_team_to(cell: Vector2i, as_waypoint: bool = false) -> bool:
	return sim.order_move(selected_team, cell, as_waypoint)


## Order the selected team back to where it started. Works while paused.
func order_selected_team_to_fall_back() -> bool:
	return sim.order_fall_back(selected_team)


## Show or hide the "how to play" page. Showing it pauses the game.
func toggle_help() -> void:
	_help.visible = not _help.visible
	if _help.visible:
		paused = true


func help_is_showing() -> bool:
	return _help.visible


## The text of the debug panel, or "" when the overlay is off.
func debug_text() -> String:
	return _debug_text.text if _debug_text.visible else ""


## Switch the selected team between holding fire and firing at will.
func toggle_fire_for_selected_team() -> void:
	var may_fire: bool = not team_is_firing(selected_team)
	if sim.order_fire(selected_team, may_fire):
		_team_fire[selected_team] = may_fire


## What a player team was last told: true for fire at will, false for hold fire.
func team_is_firing(team_id: int) -> bool:
	return _team_fire.get(team_id, true)


## The grid cell under a point on screen.
func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / CELL_PX), floori(point.y / CELL_PX))


## The middle of a grid cell on screen.
func cell_centre(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * CELL_PX, (cell.y + 0.5) * CELL_PX)


## The text currently shown in the status strip.
func hud_text() -> String:
	return _hud_text.text


func paused_banner_is_showing() -> bool:
	return _paused_banner.visible


## What the banner across the top says, or "" when it is hidden.
func banner_text() -> String:
	return _paused_banner.text if _paused_banner.visible else ""


func _refresh_hud() -> void:
	_refresh_banner()
	_refresh_debug_text()
	var state: String = tr("HUD_PAUSED") if paused else tr("HUD_RUNNING")
	var status: String = tr("HUD_STATUS").format(
		{"state": state, "time": _clock_text(), "team": selected_team}
	)
	var strengths: PackedStringArray = PackedStringArray()
	for team_id: int in sim.team_ids(SimSoldier.BattleSide.PLAYER):
		strengths.append(_team_line(team_id))
	var enemy_fit: int = 0
	var enemy_total: int = 0
	var enemy_pinned: int = 0
	for team_id: int in sim.team_ids(SimSoldier.BattleSide.ENEMY):
		enemy_fit += sim.living(SimSoldier.BattleSide.ENEMY, team_id).size()
		enemy_total += sim.strength(SimSoldier.BattleSide.ENEMY, team_id)
		enemy_pinned += sim.pinned_count(SimSoldier.BattleSide.ENEMY, team_id)
	var enemy: String = (
		tr("HUD_ENEMY")
		. format(
			{
				"fit": enemy_fit,
				"total": enemy_total,
				"pinned": enemy_pinned,
				"withdrew": sim.withdrawn_count(SimSoldier.BattleSide.ENEMY),
			}
		)
	)
	var title: String = "%s: %s" % [tr("GAME_TITLE"), tr(_scenario.name_key)]
	var lines: PackedStringArray = PackedStringArray()
	lines.append("      ".join(PackedStringArray([title, status, enemy])))
	lines.append("      ".join(strengths))
	lines.append(tr("HUD_CONTROLS"))
	_hud_text.text = "\n".join(lines)


## The banner shows how the fight ended, or that the game is paused.
func _refresh_banner() -> void:
	var player: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
	var enemy: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY
	if sim.in_fight_count(enemy) == 0:
		_paused_banner.text = (
			tr("HUD_OUTCOME_CLEARED")
			. format(
				{
					"fell": sim.casualty_count(enemy),
					"withdrew": sim.withdrawn_count(enemy),
					"fit": sim.in_fight_count(player),
					"total": sim.soldiers.size() - _count_side(enemy),
				}
			)
		)
		_paused_banner.visible = true
	elif sim.in_fight_count(player) == 0:
		_paused_banner.text = tr("HUD_OUTCOME_LOST")
		_paused_banner.visible = true
	else:
		_paused_banner.text = tr("HUD_PAUSED_BANNER")
		_paused_banner.visible = paused


## One team's entry in the status strip.
func _team_line(team_id: int) -> String:
	var player: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
	var fit: int = sim.living(player, team_id).size()
	if fit == 0:
		return tr("HUD_TEAM_GONE").format({"team": team_id})
	var fire_key: String = "HUD_FIRE_ON" if team_is_firing(team_id) else "HUD_FIRE_OFF"
	var values: Dictionary[String, Variant] = {
		"team": team_id,
		"fit": fit,
		"total": sim.strength(player, team_id),
		"pinned": sim.pinned_count(player, team_id),
		"rounds": sim.team_rounds(player, team_id),
		"fire": tr(fire_key),
	}
	return tr("HUD_TEAM").format(values)


func _refresh_debug_text() -> void:
	_debug_text.visible = debug_overlay
	if not debug_overlay:
		return
	var lines: PackedStringArray = PackedStringArray()
	lines.append(tr("DEBUG_TITLE").format({"seed": DEFAULT_SEED, "tick": sim.tick}))
	lines.append(tr("DEBUG_LEGEND"))
	lines.append(tr("DEBUG_LOG_HEADING"))
	if sim.ai_log.is_empty():
		lines.append(tr("DEBUG_LOG_EMPTY"))
	# The enemy's own words. These are developer notes, so they are not translated.
	for index: int in range(maxi(0, sim.ai_log.size() - DEBUG_LOG_LINES), sim.ai_log.size()):
		lines.append(sim.ai_log[index])
	_debug_text.text = "\n".join(lines)


func _count_side(side: SimSoldier.BattleSide) -> int:
	var count: int = 0
	for soldier: SimSoldier in sim.soldiers:
		if soldier.side == side:
			count += 1
	return count


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
		var shooter: SimSoldier = sim.soldiers[event.actor_id]
		var tracer: Tracer = Tracer.new()
		tracer.from = cell_centre(shooter.cell)
		tracer.to = cell_centre(event.cell)
		tracer.hit = hit
		tracer.by_player = shooter.side == SimSoldier.BattleSide.PLAYER
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


## A repeatable number from 0 to 1 for a cell or index, used only to make the
## drawing look less regular. Never used by any rule.
func _speckle(a: int, b: int) -> float:
	return float(absi(hash(Vector2i(a, b))) % 1000) / 1000.0


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell.x * CELL_PX, cell.y * CELL_PX), Vector2(CELL_PX, CELL_PX))


## Wet ground, each cell a slightly different shade so it does not look flat.
func _draw_ground() -> void:
	for y: int in sim.grid.height:
		for x: int in sim.grid.width:
			var shade: float = _speckle(x * 31 + 7, y * 17 + 3)
			var colour: Color = COLOUR_GROUND_LIGHT.lerp(COLOUR_GROUND_DARK, shade * 0.3)
			draw_rect(_cell_rect(Vector2i(x, y)), colour)


## A muddy track. Drawn only: no rule uses tracks yet.
func _draw_tracks() -> void:
	for track: PackedVector2Array in _scenario.tracks:
		var points: PackedVector2Array = PackedVector2Array()
		for cell: Vector2 in track:
			points.append(cell_centre(Vector2i(cell)))
		draw_polyline(points, COLOUR_TRACK.darkened(0.25), 22.0, true)
		draw_polyline(points, COLOUR_TRACK, 16.0, true)


## Low cover: an earth bank a man can shoot over. Neighbouring bank cells are
## joined so a row of them reads as one continuous bank.
func _draw_banks() -> void:
	var cells: Array[Vector2i] = sim.grid.low_cells()
	for pass_index: int in 2:
		var colour: Color = COLOUR_BANK_EDGE if pass_index == 0 else COLOUR_BANK
		var width: float = 18.0 if pass_index == 0 else 12.0
		for cell: Vector2i in cells:
			var centre: Vector2 = cell_centre(cell)
			draw_circle(centre, width * 0.5, colour)
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)] as Array[Vector2i]:
				if sim.grid.is_low_cover(cell + offset):
					draw_line(centre, cell_centre(cell + offset), colour, width)


## Thick jungle: a dark mass of tree crowns that nobody can see or walk through.
func _draw_jungle() -> void:
	var cells: Array[Vector2i] = sim.grid.tall_cells()
	for cell: Vector2i in cells:
		draw_rect(_cell_rect(cell), COLOUR_JUNGLE[2])
	for cell: Vector2i in cells:
		for crown: int in 3:
			var offset: Vector2 = Vector2(
				(_speckle(cell.x * 13 + crown, cell.y * 7) - 0.5) * CELL_PX * 0.8,
				(_speckle(cell.x * 5, cell.y * 11 + crown) - 0.5) * CELL_PX * 0.8
			)
			var radius: float = 11.0 + _speckle(cell.x + crown * 3, cell.y + crown) * 8.0
			draw_circle(cell_centre(cell) + offset, radius, COLOUR_JUNGLE[crown])


## The route still to be walked by each man of the selected team.
func _draw_routes() -> void:
	for soldier: SimSoldier in sim.soldiers:
		var selected: bool = (
			soldier.side == SimSoldier.BattleSide.PLAYER and soldier.team_id == selected_team
		)
		if not selected or not soldier.is_moving():
			continue
		var points: PackedVector2Array = PackedVector2Array([_soldier_position(soldier)])
		for cell: Vector2i in soldier.path:
			points.append(cell_centre(cell))
		var colour: Color = _team_colour(soldier)
		colour.a = 0.45
		draw_polyline(points, colour, 1.5, true)


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
	# A pinned man is drawn smaller: he has his head down.
	var size: float = 0.75 if sim.is_pinned(soldier) else 1.0
	if soldier.side == SimSoldier.BattleSide.ENEMY:
		draw_colored_polygon(_diamond(centre, 14.0 * size), COLOUR_OUTLINE)
		draw_colored_polygon(_diamond(centre, 11.5 * size), COLOUR_ENEMY)
	else:
		draw_circle(centre, 12.5 * size, COLOUR_OUTLINE)
		draw_circle(centre, 10.5 * size, _team_colour(soldier))
		if soldier.team_id == selected_team:
			draw_arc(centre, 14.5, 0.0, TAU, 32, COLOUR_SELECTED, 2.0)
		draw_string(
			ThemeDB.fallback_font,
			centre + Vector2(-4, 5),
			str(soldier.team_id),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			Color.BLACK
		)
	_draw_suppression_meter(soldier, centre)


## A bar over a man's head showing how much fire he is under. It fills from
## the left: yellow while it rises, orange once he is pinned, red once he breaks.
func _draw_suppression_meter(soldier: SimSoldier, centre: Vector2) -> void:
	if soldier.suppression <= 0:
		return
	var corner: Vector2 = centre + Vector2(-12.0, -22.0)
	draw_rect(Rect2(corner - Vector2(1, 1), Vector2(26.0, 6.0)), COLOUR_METER_BACK)
	var colour: Color = COLOUR_METER_RISING
	if soldier.broken:
		colour = COLOUR_METER_BROKEN
	elif sim.is_pinned(soldier):
		colour = COLOUR_METER_PINNED
	draw_rect(Rect2(corner, Vector2(24.0 * soldier.suppression / 100.0, 4.0)), colour)
	# A tick marks the level at which a man becomes pinned.
	var mark_x: float = corner.x + 24.0 * sim.rules.pinned_threshold / 100.0
	draw_line(Vector2(mark_x, corner.y - 1), Vector2(mark_x, corner.y + 5), Color.WHITE, 1.0)


## A casualty is a pale cross inside the outline of what he was.
func _draw_casualty(soldier: SimSoldier) -> void:
	var centre: Vector2 = cell_centre(soldier.cell)
	if soldier.side == SimSoldier.BattleSide.ENEMY:
		draw_polyline(_diamond(centre, 12.0, true), COLOUR_CASUALTY, 1.5)
	else:
		draw_arc(centre, 11.0, 0.0, TAU, 32, COLOUR_CASUALTY, 1.5)
	draw_line(centre + Vector2(-6, -6), centre + Vector2(6, 6), COLOUR_CASUALTY, 2.0)
	draw_line(centre + Vector2(-6, 6), centre + Vector2(6, -6), COLOUR_CASUALTY, 2.0)


## Shots: thin yellow for a miss, thick red for a hit. Your own side's shots
## are drawn solid, the enemy's slightly fainter.
func _draw_tracers() -> void:
	for tracer: Tracer in _tracers:
		var colour: Color = COLOUR_SHOT_HIT if tracer.hit else COLOUR_SHOT_MISSED
		var strength: float = clampf(tracer.seconds_left / TRACER_SECONDS, 0.0, 1.0)
		colour.a = strength if tracer.by_player else strength * 0.75
		draw_line(tracer.from, tracer.to, colour, 3.5 if tracer.hit else 1.5)


## Rain: a faint haze and slanting streaks. It stops moving while paused.
## Decoration only until weather becomes a rule in Phase 2.
func _draw_rain() -> void:
	var size: Vector2 = Vector2(sim.grid.width * CELL_PX, sim.grid.height * CELL_PX)
	draw_rect(Rect2(Vector2.ZERO, size), COLOUR_RAIN_HAZE)
	var fall: Vector2 = Vector2(-7.0, 20.0)
	for streak: int in RAIN_STREAKS:
		var speed: float = 620.0 + _speckle(streak, 5) * 260.0
		var travelled: float = _rain_clock * speed + _speckle(streak, 9) * (size.y + 40.0)
		var start: Vector2 = Vector2(
			_speckle(streak, 1) * (size.x + 120.0), fmod(travelled, size.y + 40.0) - 20.0
		)
		start.x -= (start.y / fall.y) * 7.0
		if start.y + fall.y < size.y:
			draw_line(start, start + fall, COLOUR_RAIN, 1.0)


## Debug overlay: the enemy's range, who he can hit, who is seen but covered,
## which of your men has a clear shot, and each man's suppression and state.
func _draw_debug() -> void:
	for shooter: SimSoldier in sim.soldiers:
		if not shooter.in_fight() or shooter.weapon == null:
			continue
		var from: Vector2 = _soldier_position(shooter)
		var is_enemy: bool = shooter.side == SimSoldier.BattleSide.ENEMY
		if is_enemy:
			var reach: float = shooter.weapon.range_cells * CELL_PX
			draw_arc(from, reach, 0.0, TAU, 64, COLOUR_DEBUG_RANGE, 1.0)
		for target: SimSoldier in sim.soldiers:
			if not target.in_fight() or target.side == shooter.side:
				continue
			var range_cells: int = shooter.weapon.range_cells
			if shooter.cell.distance_squared_to(target.cell) > range_cells * range_cells:
				continue
			if not sim.grid.has_line_of_sight(shooter.cell, target.cell):
				continue
			var covered: bool = sim.grid.gives_cover(shooter.cell, target.cell)
			var to: Vector2 = _soldier_position(target)
			if is_enemy:
				var colour: Color = COLOUR_DEBUG_COVERED if covered else COLOUR_DEBUG_THREAT
				draw_line(from, to, colour, 1.0)
			elif not covered:
				draw_line(from, to, COLOUR_DEBUG_CLEAR_SHOT, 1.0)
	for soldier: SimSoldier in sim.soldiers:
		if soldier.in_fight():
			_draw_debug_label(soldier)


func _draw_debug_label(soldier: SimSoldier) -> void:
	var label: String = str(soldier.suppression)
	if soldier.falling_back:
		label += " F"
	elif soldier.broken:
		label += " B"
	elif sim.is_pinned(soldier):
		label += " P"
	var where: Vector2 = _soldier_position(soldier) + Vector2(14, -14)
	draw_string(ThemeDB.fallback_font, where, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


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

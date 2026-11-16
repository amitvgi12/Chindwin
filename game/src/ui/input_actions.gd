class_name InputActions
extends RefCounted
## Names of the game's input actions and their default keys.
## Actions are registered in code so the bindings are readable here and can be
## changed by an options menu later (Phase 3).

const PAUSE: StringName = &"game_pause"
const SELECT_TEAM_1: StringName = &"game_select_team_1"
const SELECT_TEAM_2: StringName = &"game_select_team_2"
const TOGGLE_FIRE: StringName = &"game_toggle_fire"
const FALL_BACK: StringName = &"game_fall_back"
const RESTART: StringName = &"game_restart"
const HELP: StringName = &"game_help"
const TOGGLE_OVERLAY: StringName = &"game_toggle_overlay"
const DEBUG_NEXT_WEATHER: StringName = &"game_debug_next_weather"


## Register any action that does not exist yet. Safe to call more than once.
static func ensure_defaults() -> void:
	_add_key(PAUSE, KEY_SPACE)
	_add_key(SELECT_TEAM_1, KEY_1)
	_add_key(SELECT_TEAM_2, KEY_2)
	_add_key(TOGGLE_FIRE, KEY_F)
	_add_key(FALL_BACK, KEY_B)
	_add_key(RESTART, KEY_R)
	_add_key(HELP, KEY_H)
	_add_key(TOGGLE_OVERLAY, KEY_O)
	_add_key(DEBUG_NEXT_WEATHER, KEY_W)


static func _add_key(action: StringName, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

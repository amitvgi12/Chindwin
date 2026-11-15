extends SceneTree
## Dev tool, not part of the game. Opens a scene in a window, saves a picture
## of the screen and quits. Claude uses it to look at the game; it is also a
## quick visual smoke test.
##
##   make screenshot                                     the test range, mid-battle
##   make screenshot OVERLAY=1                           the same, debug overlay on
##   make screenshot SCENE=res://scenes/briefing.tscn    any other scene
##
## Both write build/screenshot.png.

const DEFAULT_SCENE: String = "res://scenes/test_range.tscn"
## For the test range: game time to play before the picture, in ticks.
const TICKS_BEFORE_PICTURE: int = 200
## For any other scene: frames to wait so it has drawn.
const FRAMES_BEFORE_PICTURE: int = 30
## Give up after this many frames so the tool can never hang.
const FRAME_LIMIT: int = 300000

var _scene: Node
var _frames: int = 0
var _scene_path: String = DEFAULT_SCENE
var _output_path: String = "user://screenshot.png"
var _overlay: bool = false


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_output_path = argument.trim_prefix("--out=")
		elif argument == "--overlay":
			_overlay = true
		elif argument.begins_with("--scene=") and argument.length() > 8:
			_scene_path = argument.trim_prefix("--scene=")
	var packed: PackedScene = load(_scene_path) as PackedScene
	_scene = packed.instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	_frames += 1
	var view: BattleView = _scene as BattleView
	if view == null:
		if _frames < FRAMES_BEFORE_PICTURE:
			return false
	else:
		if _frames == 2:
			_start_scripted_battle(view)
		if view.sim.tick < TICKS_BEFORE_PICTURE and _frames < FRAME_LIMIT:
			return false
	var picture: Image = root.get_texture().get_image()
	var result: Error = picture.save_png(_output_path)
	print("screenshot: %s (%s)" % [_output_path, error_string(result)])
	return true


## Team 1 goes to the bank facing the picket; team 2 goes round the north
## behind the jungle.
func _start_scripted_battle(view: BattleView) -> void:
	view.select_team(1)
	view.order_selected_team_to(Vector2i(22, 9))
	view.select_team(2)
	view.order_selected_team_to(Vector2i(20, 1))
	view.order_selected_team_to(Vector2i(33, 1), true)
	view.order_selected_team_to(Vector2i(35, 4), true)
	view.debug_overlay = _overlay
	view.toggle_pause()

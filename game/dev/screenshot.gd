extends SceneTree
## Dev tool, not part of the game. Opens the test range in a window, plays a
## short scripted battle, saves a picture of the screen and quits.
## Claude uses it to look at the game; it is also a quick visual smoke test.
##
## Run with: make screenshot     (writes build/screenshot.png)

const SCENE_PATH: String = "res://scenes/test_range.tscn"
## Game time to play before taking the picture, in simulation ticks.
const TICKS_BEFORE_PICTURE: int = 170
## Give up after this many frames so the tool can never hang.
const FRAME_LIMIT: int = 20000

var _view: BattleView
var _frames: int = 0
var _output_path: String = "user://screenshot.png"


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_output_path = argument.trim_prefix("--out=")
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	_view = packed.instantiate() as BattleView
	root.add_child(_view)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		# Team 1 walks forward; team 2 goes round by the south.
		_view.select_team(1)
		_view.order_selected_team_to(Vector2i(14, 10))
		_view.select_team(2)
		_view.order_selected_team_to(Vector2i(24, 15))
		_view.toggle_pause()
	if _view.sim.tick < TICKS_BEFORE_PICTURE and _frames < FRAME_LIMIT:
		return false
	var picture: Image = root.get_texture().get_image()
	var result: Error = picture.save_png(_output_path)
	print("screenshot: %s (%s)" % [_output_path, error_string(result)])
	return true

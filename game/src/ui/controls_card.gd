class_name ControlsCard
extends Control
## The "how to play" page: the keys, and what the marks on the map mean.
##
## Used twice. As a screen of its own after the briefing, where Space goes on
## to `next_scene`. And inside the map, where H shows and hides it and
## `next_scene` is left empty.

const KEY_LINES: Array[String] = [
	"CONTROLS_KEY_1",
	"CONTROLS_KEY_2",
	"CONTROLS_KEY_3",
	"CONTROLS_KEY_4",
	"CONTROLS_KEY_5",
	"CONTROLS_KEY_6",
	"CONTROLS_KEY_7",
	"CONTROLS_KEY_8",
	"CONTROLS_KEY_9",
]
const MARK_LINES: Array[String] = [
	"CONTROLS_MARK_1",
	"CONTROLS_MARK_2",
	"CONTROLS_MARK_3",
	"CONTROLS_MARK_4",
	"CONTROLS_MARK_5",
	"CONTROLS_MARK_6",
	"CONTROLS_MARK_7",
	"CONTROLS_MARK_8",
	"CONTROLS_MARK_9",
	"CONTROLS_MARK_10",
]

## Scene to open when the player continues. Empty when shown inside the map.
@export var next_scene: String = ""

@onready var _keys: Label = $Margin/Lines/Keys
@onready var _marks: Label = $Margin/Lines/Marks
@onready var _footer: Label = $Margin/Lines/Footer


func _ready() -> void:
	InputActions.ensure_defaults()
	_keys.text = keys_text()
	_marks.text = marks_text()
	_footer.text = tr("CONTROLS_CONTINUE") if is_a_screen_of_its_own() else tr("CONTROLS_CLOSE")


func _unhandled_input(event: InputEvent) -> void:
	if is_a_screen_of_its_own() and wants_to_continue(event):
		get_tree().change_scene_to_file(next_scene)


func is_a_screen_of_its_own() -> bool:
	return not next_scene.is_empty()


func keys_text() -> String:
	return _joined(KEY_LINES)


func marks_text() -> String:
	return _joined(MARK_LINES)


## True for the inputs that leave the page: Space, Enter or a mouse click.
func wants_to_continue(event: InputEvent) -> bool:
	if event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed(&"ui_accept"):
		return true
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	return false


func _joined(keys: Array[String]) -> String:
	var lines: PackedStringArray = PackedStringArray()
	for key: String in keys:
		lines.append(tr(key))
	return "\n".join(lines)

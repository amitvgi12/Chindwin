class_name Briefing
extends Control
## The opening screen: where and when, in a few plain sentences, then the map.
##
## Every sentence shown here has a row in docs/history/mission-01.md with its
## source. Do not add or change a BRIEFING_ string without changing that file.

const NEXT_SCENE: String = "res://scenes/controls.tscn"
## Keys of the briefing sentences, in order. The first is shown as the heading.
const SENTENCE_KEYS: Array[String] = [
	"BRIEFING_1",
	"BRIEFING_2",
	"BRIEFING_3",
	"BRIEFING_4",
	"BRIEFING_5",
	"BRIEFING_6",
	"BRIEFING_7",
	"BRIEFING_8",
]

@onready var _heading: Label = $Margin/Lines/Heading
@onready var _body: Label = $Margin/Lines/Body


func _ready() -> void:
	InputActions.ensure_defaults()
	_heading.text = tr(SENTENCE_KEYS[0])
	_body.text = body_text()


func _unhandled_input(event: InputEvent) -> void:
	if wants_to_begin(event):
		get_tree().change_scene_to_file(NEXT_SCENE)


## The sentences after the heading, one per line, with the last set apart.
func body_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for index: int in range(1, SENTENCE_KEYS.size() - 1):
		lines.append(tr(SENTENCE_KEYS[index]))
	lines.append("")
	lines.append(tr(SENTENCE_KEYS[SENTENCE_KEYS.size() - 1]))
	return "\n".join(lines)


## True for the inputs that leave the briefing: Space, Enter or a mouse click.
func wants_to_begin(event: InputEvent) -> bool:
	if event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed(&"ui_accept"):
		return true
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	return false

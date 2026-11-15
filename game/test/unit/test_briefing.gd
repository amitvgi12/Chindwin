extends GutTest
## The opening briefing. Its sentences are history, so the tests also guard
## the link between the game text and docs/history/mission-01.md.

const SCENE: String = "res://scenes/briefing.tscn"

var briefing: Briefing


func before_each() -> void:
	TranslationServer.set_locale("en")
	var packed: PackedScene = load(SCENE) as PackedScene
	briefing = packed.instantiate() as Briefing
	add_child_autofree(briefing)


func _key(key: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	# Godot's built-in actions match on keycode, ours on physical_keycode.
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	return event


func test_every_briefing_sentence_has_english_text() -> void:
	for key: String in Briefing.SENTENCE_KEYS:
		assert_ne(tr(key), key, "%s needs an English string" % key)


func test_the_screen_shows_the_heading_and_every_sentence() -> void:
	var heading: Label = briefing.get_node("Margin/Lines/Heading") as Label
	assert_eq(heading.text, tr("BRIEFING_1"))
	for index: int in range(1, Briefing.SENTENCE_KEYS.size()):
		assert_string_contains(briefing.body_text(), tr(Briefing.SENTENCE_KEYS[index]))


func test_no_text_key_is_shown_raw() -> void:
	assert_false(briefing.body_text().contains("BRIEFING_"))


func test_the_screen_names_its_source_and_says_the_map_is_a_test_range() -> void:
	assert_string_contains(tr("BRIEFING_SOURCE"), "Sundaram")
	assert_string_contains(tr("BRIEFING_SOURCE"), "pp. 48-49")
	assert_string_contains(tr("BRIEFING_NOTE"), "test range")
	assert_string_contains(tr("BRIEFING_NOTE"), "fiction")


func test_every_sentence_in_the_game_is_word_for_word_in_the_history_file() -> void:
	var path: String = ProjectSettings.globalize_path("res://").path_join(
		"../docs/history/mission-01.md"
	)
	if not FileAccess.file_exists(path):
		pass_test("history file is not shipped with exported builds")
		return
	var history: String = FileAccess.get_file_as_string(path)
	assert_string_contains(history, "- [x] I have read", "the history check must be ticked")
	for key: String in Briefing.SENTENCE_KEYS:
		assert_string_contains(history, "| %s |" % tr(key), "%s is not in the history file" % key)


func test_space_enter_or_a_click_begins() -> void:
	assert_true(briefing.wants_to_begin(_key(KEY_SPACE)))
	assert_true(briefing.wants_to_begin(_key(KEY_ENTER)))
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	assert_true(briefing.wants_to_begin(click))


func test_other_keys_and_mouse_movement_do_not_begin() -> void:
	assert_false(briefing.wants_to_begin(_key(KEY_A)))
	assert_false(briefing.wants_to_begin(InputEventMouseMotion.new()))

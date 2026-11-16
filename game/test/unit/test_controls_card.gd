extends GutTest
## The "how to play" page, as a screen of its own and inside the map.

const SCENE: String = "res://scenes/controls.tscn"

var card: ControlsCard


func before_each() -> void:
	TranslationServer.set_locale("en")
	var packed: PackedScene = load(SCENE) as PackedScene
	card = packed.instantiate() as ControlsCard
	add_child_autofree(card)


func test_every_line_has_english_text() -> void:
	for key: String in ControlsCard.KEY_LINES + ControlsCard.MARK_LINES:
		assert_ne(tr(key), key, "%s needs an English string" % key)
	assert_false(card.keys_text().contains("CONTROLS_"))
	assert_false(card.marks_text().contains("CONTROLS_"))


func test_the_page_names_every_key_the_game_uses() -> void:
	var text: String = card.keys_text()
	for word: String in [
		"Space", "1 and 2", "Right-click", "Shift", "F ", "B ", "G ", "R ", "H ", "O "
	]:
		assert_string_contains(text, word)


func test_as_a_screen_of_its_own_it_goes_on_to_the_test_range() -> void:
	assert_true(card.is_a_screen_of_its_own())
	assert_eq(card.next_scene, "res://scenes/test_range.tscn")
	assert_string_contains((card.get_node("Margin/Lines/Footer") as Label).text, "Space")


func test_the_briefing_leads_to_this_page() -> void:
	assert_eq(Briefing.NEXT_SCENE, SCENE)


func test_inside_the_map_it_does_not_change_scene_and_says_how_to_close() -> void:
	var packed: PackedScene = load("res://scenes/test_range.tscn") as PackedScene
	var view: BattleView = packed.instantiate() as BattleView
	add_child_autofree(view)
	var help: ControlsCard = view.get_node("Hud/Help") as ControlsCard
	assert_false(help.is_a_screen_of_its_own())
	assert_string_contains((help.get_node("Margin/Lines/Footer") as Label).text, "H")

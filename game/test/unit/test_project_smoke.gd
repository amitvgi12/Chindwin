extends GutTest
## Smoke tests for the scaffolding: the project starts on the right scene,
## its text pipeline works, and typed code stays enforced.

const MAIN_SCENE: String = "res://scenes/test_range.tscn"


func test_main_scene_is_the_test_range() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(main_scene, MAIN_SCENE)


func test_main_scene_instantiates() -> void:
	var packed: PackedScene = load(MAIN_SCENE) as PackedScene
	assert_not_null(packed, "main scene should load")
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	assert_true(scene is BattleView)


func test_text_keys_resolve_to_english() -> void:
	TranslationServer.set_locale("en")
	assert_eq(tr("GAME_TITLE"), "Beyond the Chindwin")
	assert_eq(tr("GAME_SUBTITLE"), "The Forgotten Front")


func test_untyped_code_is_a_compile_error() -> void:
	var level: int = ProjectSettings.get_setting("debug/gdscript/warnings/untyped_declaration")
	assert_eq(level, 2, "untyped declarations must stay an error (2), see CLAUDE.md")

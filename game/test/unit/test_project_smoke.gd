extends GutTest
## Phase 0 smoke tests: the project boots and its text pipeline works.
## These guard the scaffolding. Game rules get their own tests from Phase 1.

const BOOT_SCENE: String = "res://scenes/boot.tscn"


func test_main_scene_is_the_boot_scene() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(main_scene, BOOT_SCENE)


func test_boot_scene_instantiates() -> void:
	var packed: PackedScene = load(BOOT_SCENE) as PackedScene
	assert_not_null(packed, "boot scene should load")
	var boot: Node = packed.instantiate()
	add_child_autofree(boot)
	assert_not_null(boot.get_node_or_null("Lines/Title"), "boot scene should have a title label")


func test_text_keys_resolve_to_english() -> void:
	TranslationServer.set_locale("en")
	assert_eq(tr("GAME_TITLE"), "Beyond the Chindwin")
	assert_eq(tr("GAME_SUBTITLE"), "The Forgotten Front")
	assert_ne(tr("BOOT_NOTE"), "BOOT_NOTE", "BOOT_NOTE should have an English string")


func test_untyped_code_is_a_compile_error() -> void:
	var level: int = ProjectSettings.get_setting("debug/gdscript/warnings/untyped_declaration")
	assert_eq(level, 2, "untyped declarations must stay an error (2), see CLAUDE.md")

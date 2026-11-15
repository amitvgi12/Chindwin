extends GutTest
## The same seed and the same orders must always give the same battle.
## Replays, saved games and every other test depend on this.

const TEST_RANGE: String = "res://data/scenarios/test_range.json"
const RULES: String = "res://data/rules/prototype_rules.tres"

## State of the shipped test range after the scripted battle below, seed 1944.
## Recorded on macOS (Apple silicon). CI repeats it on Linux: if this test
## fails only there, the simulation is not portable and that must be fixed
## before anything else. If you change rules or the test range on purpose,
## run the tests, copy the new value from the failure message, and say why
## in the commit.
const GOLDEN_SNAPSHOT: String = (
	"tick=300 0:14,10,up,0 1:15,10,up,0 2:14,11,up,0 3:13,10,up,0 "
	+ "4:14,9,up,0 5:24,16,down,0 6:25,16,down,0 7:24,17,down,0 "
	+ "8:23,16,down,0 9:24,15,up,0 10:34,9,up,0 11:34,11,up,0 12:35,10,up,0 "
	+ "13:35,12,up,0"
)


func _scripted_battle(seed_value: int) -> Simulation:
	var rules: SimRules = load(RULES) as SimRules
	var sim: Simulation = Simulation.new(rules, Scenario.load_file(TEST_RANGE), seed_value)
	sim.order_move(1, Vector2i(14, 10))
	for count: int in 60:
		sim.step()
	sim.order_move(2, Vector2i(24, 16))
	for count: int in 240:
		sim.step()
	return sim


func test_two_runs_with_the_same_seed_are_identical() -> void:
	var first: Simulation = _scripted_battle(1944)
	var second: Simulation = _scripted_battle(1944)
	assert_eq(first.snapshot(), second.snapshot())
	assert_eq(first.events.size(), second.events.size())


func test_a_different_seed_gives_a_different_battle() -> void:
	var first: Simulation = _scripted_battle(1944)
	var second: Simulation = _scripted_battle(7)
	assert_ne(first.snapshot(), second.snapshot())


func test_the_scripted_battle_matches_the_recorded_result() -> void:
	assert_eq(_scripted_battle(1944).snapshot(), GOLDEN_SNAPSHOT)


func test_the_scripted_battle_actually_involves_shooting() -> void:
	var sim: Simulation = _scripted_battle(1944)
	var shots: int = 0
	for event: SimEvent in sim.events:
		if event.kind == SimEvent.Kind.SHOT_HIT or event.kind == SimEvent.Kind.SHOT_MISSED:
			shots += 1
	assert_gt(shots, 10, "otherwise this test proves nothing about the random numbers")

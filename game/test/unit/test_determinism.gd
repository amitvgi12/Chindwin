extends GutTest
## The same seed and the same orders must always give the same battle.
## Replays, saved games and every other test depend on this.

const TEST_RANGE: String = "res://data/scenarios/test_range.json"
const RULES: String = "res://data/rules/prototype_rules.tres"

## State of the shipped test range after the scripted battle below, seed 1944.
## Each soldier reads id:x,y,up-or-down,cells-left-to-walk,rounds-left.
## Recorded on macOS (Apple silicon). CI repeats it on Linux: if this test
## fails only there, the simulation is not portable and that must be fixed
## before anything else. If you change rules or the test range on purpose,
## run the tests, copy the new value from the failure message, and say why
## in the commit.
const GOLDEN_SNAPSHOT: String = (
	"tick=460 0:22,9,up,0,4 1:22,10,down,0,16 2:21,9,up,0,4 3:22,8,up,0,4 "
	+ "4:21,10,up,0,4 5:33,4,up,0,15 6:34,4,up,0,16 7:33,5,down,0,17 "
	+ "8:32,4,up,0,15 9:33,3,up,0,15 10:34,8,down,0,25 11:34,9,down,0,25 "
	+ "12:34,10,down,0,24 13:34,11,down,0,24"
)


## Team 1 goes to the cover facing the picket; team 2 flanks round the north.
func _scripted_battle(seed_value: int) -> Simulation:
	var rules: SimRules = load(RULES) as SimRules
	var scenario: Scenario = Scenario.load_file(TEST_RANGE)
	var weapons: Dictionary[String, WeaponDef] = WeaponLibrary.load_for(scenario)
	var sim: Simulation = Simulation.new(rules, scenario, weapons, seed_value)
	sim.order_move(1, Vector2i(22, 9))
	for count: int in 60:
		sim.step()
	sim.order_move(2, Vector2i(33, 4))
	for count: int in 400:
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

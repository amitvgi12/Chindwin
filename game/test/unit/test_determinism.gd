extends GutTest
## The same seed and the same orders must always give the same battle.
## Replays, saved games and every other test depend on this.

const TEST_RANGE: String = "res://data/scenarios/test_range.json"
const RULES: String = "res://data/rules/prototype_rules.tres"

## State of the shipped test range after the scripted battle below, seed 1944.
## Each soldier reads
## id:x,y,alive,cells-left-to-walk,rounds-left,suppression,broken,withdrawn,
## and the line ends with the rounds lying on the ground.
## Recorded on macOS (Apple silicon). CI repeats it on Linux: if this test
## fails only there, the simulation is not portable and that must be fixed
## before anything else. If you change rules or the test range on purpose,
## run the tests, copy the new value from the failure message, and say why
## in the commit.
const GOLDEN_SNAPSHOT: String = (
	"tick=434 weather=rain 0:22,9,1,0,4,40,0,0 1:22,10,1,0,5,40,0,0 "
	+ "2:21,9,1,0,5,40,0,0 3:20,8,0,0,0,0,0,0 4:21,10,1,0,4,40,0,0 "
	+ "5:33,2,1,2,18,59,0,0 6:33,1,1,4,18,55,0,0 7:33,2,1,3,18,63,0,0 "
	+ "8:33,3,1,1,18,51,0,0 9:33,1,0,0,0,0,0,0 10:38,9,1,0,13,0,1,1 "
	+ "11:39,9,1,0,15,0,1,1 12:38,10,1,0,13,0,1,1 13:34,11,0,0,0,0,0,0 "
	+ "ground=113"
)


## Team 1 goes to the cover facing the picket; team 2 flanks round the north.
func _scripted_battle(seed_value: int) -> Simulation:
	var rules: SimRules = load(RULES) as SimRules
	var scenario: Scenario = Scenario.load_file(TEST_RANGE)
	var weapons: Dictionary[String, WeaponDef] = WeaponLibrary.load_for(scenario)
	var weathers: Dictionary[String, WeatherDef] = WeatherLibrary.load_for(scenario)
	var sim: Simulation = Simulation.new(rules, scenario, weapons, seed_value, weathers)
	sim.order_move(1, Vector2i(22, 9))
	for count: int in 200:
		sim.step()
	# Round the north behind the jungle, then in from the side.
	sim.order_move(2, Vector2i(20, 1))
	sim.step()
	sim.order_move(2, Vector2i(33, 1), true)
	sim.order_move(2, Vector2i(35, 4), true)
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

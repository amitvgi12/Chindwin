class_name Gate1Plans
extends RefCounted
## The two attacks that Gate 1's first pass criterion compares, played on the
## shipped test range with the shipped rules:
##
##   FRONTAL          both teams walk straight at the picket at once and
##                    stop a few cells in front of it
##   PIN_THEN_FLANK   team 1 goes to the bank and fires; twenty seconds later
##                    team 2 goes round the north and comes in from the side
##
## A third plan is the strongest frontal attack. It is held to the same
## standard as FRONTAL:
##
##   RUSH_THE_BANK    both teams walk straight up to the picket's own bank
##
## Two more plans are reported, never asserted as part of the criterion:
## the same flank with team 1 holding its fire, to show whether the pinning
## is doing any work.
##
##   FLANK_WITHOUT_FIRE   as PIN_THEN_FLANK, but team 1 holds fire throughout
##
## An attack SUCCEEDS when, within the time limit, the picket has nobody left
## in the fight and at least six of the ten attackers are still fit.

enum Plan { FRONTAL, PIN_THEN_FLANK, RUSH_THE_BANK, FLANK_WITHOUT_FIRE }

const TEST_RANGE: String = "res://data/scenarios/test_range.json"
const RULES: String = "res://data/rules/prototype_rules.tres"
## Two minutes of game time at ten ticks a second.
const TIME_LIMIT_TICKS: int = 1200
const ATTACKERS_NEEDED_FIT: int = 6
## Ticks team 2 waits before setting off in the PIN_THEN_FLANK plan.
const FLANK_DELAY_TICKS: int = 200


class Result:
	extends RefCounted
	var succeeded: bool
	var ticks: int
	var attackers_fit: int
	var picket_fell: int
	var picket_withdrew: int
	var rounds_left: int
	var ai_log: Array[String]

	func summary() -> String:
		return (
			"%s  time %3ds  attackers fit %2d  picket fell %d withdrew %d  rounds left %3d"
			% [
				"SUCCESS" if succeeded else "failure",
				ticks / 10,
				attackers_fit,
				picket_fell,
				picket_withdrew,
				rounds_left,
			]
		)


static func play(plan: Plan, seed_value: int) -> Result:
	var rules: SimRules = load(RULES) as SimRules
	var scenario: Scenario = Scenario.load_file(TEST_RANGE)
	var weapons: Dictionary[String, WeaponDef] = WeaponLibrary.load_for(scenario)
	var weathers: Dictionary[String, WeatherDef] = WeatherLibrary.load_for(scenario)
	var sim: Simulation = Simulation.new(rules, scenario, weapons, seed_value, weathers)
	var player: SimSoldier.BattleSide = SimSoldier.BattleSide.PLAYER
	var enemy: SimSoldier.BattleSide = SimSoldier.BattleSide.ENEMY

	if plan == Plan.FRONTAL:
		sim.order_move(1, Vector2i(30, 8))
		sim.order_move(2, Vector2i(30, 11))
	elif plan == Plan.RUSH_THE_BANK:
		sim.order_move(1, Vector2i(32, 8))
		sim.order_move(2, Vector2i(32, 11))
	else:
		sim.order_move(1, Vector2i(22, 9))
		if plan == Plan.FLANK_WITHOUT_FIRE:
			sim.order_fire(1, false)

	var flanking: bool = plan == Plan.PIN_THEN_FLANK or plan == Plan.FLANK_WITHOUT_FIRE
	while sim.tick < TIME_LIMIT_TICKS:
		if flanking and sim.tick == FLANK_DELAY_TICKS:
			sim.order_move(2, Vector2i(20, 1))
			sim.step()
			sim.order_move(2, Vector2i(33, 1), true)
			sim.order_move(2, Vector2i(35, 4), true)
		sim.step()
		if sim.outcome() != Simulation.Outcome.IN_PROGRESS:
			break

	var result: Result = Result.new()
	result.ticks = sim.tick
	result.attackers_fit = sim.in_fight_count(player)
	result.picket_fell = sim.casualty_count(enemy)
	result.picket_withdrew = sim.withdrawn_count(enemy)
	result.rounds_left = 0
	for team_id: int in sim.team_ids(player):
		result.rounds_left += sim.team_rounds(player, team_id)
	result.ai_log = sim.ai_log
	result.succeeded = (
		sim.in_fight_count(enemy) == 0 and result.attackers_fit >= ATTACKERS_NEEDED_FIT
	)
	return result


## How many of the seeds 1 to `runs` end in success for a plan.
static func successes(plan: Plan, runs: int) -> int:
	var count: int = 0
	for seed_value: int in range(1, runs + 1):
		if play(plan, seed_value).succeeded:
			count += 1
	return count

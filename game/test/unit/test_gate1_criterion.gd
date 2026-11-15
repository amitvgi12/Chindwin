extends GutTest
## Gate 1, pass criterion 1 (docs/SCOPE.md): "The rules do what pillar 1
## says. Over ten seeded simulation runs, a frontal assault with no
## suppression fails at least eight times, and suppress-then-flank succeeds
## at least seven times."
##
## Played on the shipped test range with the shipped rules, seeds 1 to 10.
## What counts as success is defined in test/support/gate1_plans.gd.
## Run `make gate1` to see every battle and the enemy's decisions.
##
## If this fails after a change to data/, the change broke the game's central
## claim. Tune the data until it passes again; do not loosen the numbers here.

const RUNS: int = 10


func test_a_frontal_attack_that_stops_in_front_of_the_picket_fails() -> void:
	var wins: int = Gate1Plans.successes(Gate1Plans.Plan.FRONTAL, RUNS)
	assert_lte(wins, 2, "frontal attack succeeded %d times in %d" % [wins, RUNS])


func test_a_frontal_rush_right_up_to_the_pickets_bank_fails() -> void:
	var wins: int = Gate1Plans.successes(Gate1Plans.Plan.RUSH_THE_BANK, RUNS)
	assert_lte(wins, 2, "frontal rush succeeded %d times in %d" % [wins, RUNS])


func test_pinning_the_picket_and_then_flanking_it_succeeds() -> void:
	var wins: int = Gate1Plans.successes(Gate1Plans.Plan.PIN_THEN_FLANK, RUNS)
	assert_gte(wins, 7, "pin-then-flank succeeded only %d times in %d" % [wins, RUNS])


func test_covering_fire_makes_the_flank_no_worse() -> void:
	var with_fire: int = Gate1Plans.successes(Gate1Plans.Plan.PIN_THEN_FLANK, RUNS)
	var without: int = Gate1Plans.successes(Gate1Plans.Plan.FLANK_WITHOUT_FIRE, RUNS)
	assert_gte(with_fire, without, "covering fire: %d, without: %d" % [with_fire, without])

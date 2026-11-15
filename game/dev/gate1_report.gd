extends SceneTree
## Dev tool, not part of the game. Plays the two Gate 1 attacks ten times each
## and prints what happened, so the numbers in data/ can be tuned with evidence.
##
## Run with: make gate1            ten battles per plan, every one listed
##           make gate1 RUNS=100   a larger sample, totals only

const DEFAULT_RUNS: int = 10


func _initialize() -> void:
	var runs: int = DEFAULT_RUNS
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--runs=") and argument.length() > 7:
			runs = int(argument.trim_prefix("--runs="))
	var list_each: bool = runs <= DEFAULT_RUNS
	var names: Dictionary[Gate1Plans.Plan, String] = {
		Gate1Plans.Plan.FRONTAL: "FRONTAL",
		Gate1Plans.Plan.PIN_THEN_FLANK: "PIN THEN FLANK",
		Gate1Plans.Plan.RUSH_THE_BANK: "RUSH THE BANK",
		Gate1Plans.Plan.FLANK_WITHOUT_FIRE: "FLANK WITHOUT COVERING FIRE (for comparison)",
	}
	for plan: Gate1Plans.Plan in names:
		var name: String = names[plan]
		print("")
		print("== %s ==" % name)
		var wins: int = 0
		var fit_total: int = 0
		for seed_value: int in range(1, runs + 1):
			var result: Gate1Plans.Result = Gate1Plans.play(plan, seed_value)
			if result.succeeded:
				wins += 1
			fit_total += result.attackers_fit
			if not list_each:
				continue
			print("seed %2d  %s" % [seed_value, result.summary()])
			for line: String in result.ai_log:
				print("           %s" % line)
		var average_fit: float = float(fit_total) / runs
		print(
			(
				"%s: %d of %d succeeded, %.1f of 10 attackers fit on average"
				% [name, wins, runs, average_fit]
			)
		)
	quit(0)

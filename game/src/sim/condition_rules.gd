class_name ConditionRules
extends RefCounted
## Condition: the slow half of a man's will to fight (GDD section 4).
##
## Hunger creeps up through a mission. Walking tires a man and standing
## still rests him. Together they set a floor under his suppression, so a
## hungry, tired man is pinned and broken by less fire. Food takes hunger
## away. Called by Simulation once a tick; holds no state of its own.


## The least suppression a man can have, given how hungry and tired he is.
static func floor_for(rules: SimRules, soldier: SimSoldier) -> int:
	var floor_value: int = (
		soldier.hunger * rules.hunger_floor_percent / 100
		+ soldier.fatigue * rules.fatigue_floor_percent / 100
	)
	return clampi(floor_value, 0, rules.condition_floor_max)


## True when a man has a ration and is at all hungry.
static func can_eat(soldier: SimSoldier) -> bool:
	return soldier.in_fight() and soldier.rations > 0 and soldier.hunger > 0


## Hunger creeps up for everyone. Walking tires a man; standing still rests
## him. Then nobody's suppression is left below what his condition allows.
## Counted on the shared tick, so no man carries a private clock.
static func wear(sim: Simulation) -> void:
	var rules: SimRules = sim.rules
	var hungrier: bool = rules.hunger_rise_ticks > 0 and sim.tick % rules.hunger_rise_ticks == 0
	var tiring: bool = rules.fatigue_walk_ticks > 0 and sim.tick % rules.fatigue_walk_ticks == 0
	var resting: bool = rules.fatigue_rest_ticks > 0 and sim.tick % rules.fatigue_rest_ticks == 0
	for soldier: SimSoldier in sim.soldiers:
		if not soldier.in_fight():
			continue
		if hungrier:
			soldier.hunger = mini(100, soldier.hunger + 1)
		var walking: bool = (
			soldier.is_moving() and (soldier.falling_back or not sim.is_pinned(soldier))
		)
		if walking and tiring:
			soldier.fatigue = mini(100, soldier.fatigue + 1)
		elif not soldier.is_moving() and resting:
			soldier.fatigue = maxi(0, soldier.fatigue - 1)
		soldier.suppression = maxi(soldier.suppression, floor_for(rules, soldier))


## Each man of a team who can eat is told to eat one ration.
static func start_eating(team: Array[SimSoldier]) -> void:
	for soldier: SimSoldier in team:
		soldier.told_to_eat = can_eat(soldier)
		soldier.eat_progress_ticks = 0


## Food is put away uneaten when a team is told to move or go back.
static func stop_eating(team: Array[SimSoldier]) -> void:
	for soldier: SimSoldier in team:
		soldier.told_to_eat = false
		soldier.eating_now = false
		soldier.eat_progress_ticks = 0


## Chance from 0 to 100 that a man walks away when he breaks: nothing up to
## walk_away_hunger, then rising in proportion to walk_away_max_percent at 100.
static func walk_away_chance_percent(rules: SimRules, soldier: SimSoldier) -> int:
	if rules.walk_away_max_percent <= 0 or rules.walk_away_hunger >= 100:
		return 0
	if soldier.hunger <= rules.walk_away_hunger:
		return 0
	var over: int = soldier.hunger - rules.walk_away_hunger
	return rules.walk_away_max_percent * over / (100 - rules.walk_away_hunger)


## He gets up and goes back to where he started, leaving whatever he was
## doing. He walks even when pinned, does not fire, and takes no orders.
## When he gets there he is out of the fight.
static func start_walking_away(sim: Simulation, soldier: SimSoldier) -> void:
	soldier.walking_away = true
	soldier.told_to_gather = false
	soldier.told_to_eat = false
	soldier.eating_now = false
	soldier.calling_out = false
	sim.log_event(SimEvent.Kind.WALKED_AWAY, soldier.id, -1, soldier.cell)
	var taken: Dictionary[Vector2i, bool] = {}
	for other: SimSoldier in sim.soldiers:
		if other.in_fight() and other != soldier:
			taken[other.destination()] = true
	var places: Array[Vector2i] = sim.grid.free_cells_near(soldier.start_cell, 1, taken)
	soldier.step_ticks_left = 0
	soldier.step_ticks_total = 0
	soldier.path.clear()
	if not places.is_empty():
		soldier.path = sim.grid.find_path(soldier.cell, places[0])
	if soldier.path.is_empty():
		sim.withdraw(soldier)
	else:
		soldier.falling_back = true


## Men told to eat do so when standing still and not pinned. A meal takes
## eat_ticks, and a man eating does not fire. Then he stops.
static func eat(sim: Simulation) -> void:
	for soldier: SimSoldier in sim.soldiers:
		soldier.eating_now = false
		if not soldier.in_fight() or not soldier.told_to_eat:
			continue
		if not can_eat(soldier):
			soldier.told_to_eat = false
			continue
		if soldier.is_moving() or sim.is_pinned(soldier):
			continue
		soldier.eating_now = true
		soldier.eat_progress_ticks += 1
		if soldier.eat_progress_ticks < sim.rules.eat_ticks:
			continue
		soldier.rations -= 1
		soldier.hunger = maxi(0, soldier.hunger - sim.rules.ration_hunger_relief)
		soldier.told_to_eat = false
		soldier.eat_progress_ticks = 0
		sim.log_event(SimEvent.Kind.ATE, soldier.id, -1, soldier.cell)

class_name SimSoldier
extends RefCounted
## One man in the simulation. Data only; the rules live in Simulation.

## Named BattleSide because Godot already has a built-in enum called Side.
enum BattleSide { PLAYER, ENEMY }

var id: int
var side: BattleSide
var team_id: int
var cell: Vector2i
## Where he stood when the scenario began. A team falling back returns here.
var start_cell: Vector2i
## False once he is a casualty. A casualty takes no further part.
var alive: bool = true

## Cells still to walk through, next one first.
var path: Array[Vector2i] = []
## Ticks left before he reaches path[0]. Zero when the step has not started.
var step_ticks_left: int = 0
## Length in ticks of the step in progress. Used by the view to draw him between cells.
var step_ticks_total: int = 0
## What he shoots with. Null means he cannot fire.
var weapon: WeaponDef
## Rounds he has left.
var rounds: int = 0
## False when his team has been told to hold fire.
var fire_allowed: bool = true
## Ticks until he may fire again.
var fire_cooldown_ticks: int = 0
## True when his team has been told to gather rounds from the ground.
var told_to_gather: bool = false
## True on a tick in which he is actually picking rounds up. He does not fire.
var gathering_now: bool = false
## Ticks spent on the round he is picking up.
var gather_progress_ticks: int = 0
## Pressure from incoming fire, 0 to 100. Fades when the firing stops.
var suppression: int = 0
## True from the moment he breaks until the pressure has faded. He does not fire.
var broken: bool = false
## True while he is going back: an enemy to the rear and out of the fight, one
## of the player's men to where he started. He walks even when pinned and
## does not fire.
var falling_back: bool = false
## True once he has left the fight unhurt. He takes no further part.
var withdrawn: bool = false
## True when he left the fight by coming over in answer to an appeal.
var came_over: bool = false
## True while his team is calling out to the enemy. He does not fire.
var calling_out: bool = false


## Still taking part: neither a casualty nor withdrawn.
func in_fight() -> bool:
	return alive and not withdrawn


func is_moving() -> bool:
	return in_fight() and not path.is_empty()


## Where he will end up once his current path is walked.
func destination() -> Vector2i:
	return cell if path.is_empty() else path[path.size() - 1]

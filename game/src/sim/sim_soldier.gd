class_name SimSoldier
extends RefCounted
## One man in the simulation. Data only; the rules live in Simulation.

## Named BattleSide because Godot already has a built-in enum called Side.
enum BattleSide { PLAYER, ENEMY }

var id: int
var side: BattleSide
var team_id: int
var cell: Vector2i
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
## Pressure from incoming fire, 0 to 100. Fades when the firing stops.
var suppression: int = 0


func is_moving() -> bool:
	return alive and not path.is_empty()


## Where he will end up once his current path is walked.
func destination() -> Vector2i:
	return cell if path.is_empty() else path[path.size() - 1]

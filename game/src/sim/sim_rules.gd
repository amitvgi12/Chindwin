class_name SimRules
extends Resource
## Tunable numbers for the simulation.
## Change the values in data/rules/*.tres, not the defaults in this script.

@export_group("Time")
## Simulation steps per second of game time.
@export var ticks_per_second: int = 10

@export_group("Movement")
## Ticks a soldier needs to walk one cell sideways or up/down.
@export var move_ticks_orthogonal: int = 5
## Ticks a soldier needs to walk one cell diagonally.
@export var move_ticks_diagonal: int = 7

@export_group("Cover")
## Share of the normal hit chance that is left when the target is behind
## cover, from 0 (cover is perfect) to 100 (cover does nothing).
@export var cover_hit_percent: int = 35

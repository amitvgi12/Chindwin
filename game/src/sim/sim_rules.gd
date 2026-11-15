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

@export_group("Enemy fire (placeholder until weapons are data)")
## How far an enemy soldier can shoot, in cells.
@export var enemy_range_cells: int = 14
## Ticks between two shots by the same enemy soldier.
@export var enemy_fire_interval_ticks: int = 12
## Chance from 0 to 100 that one shot causes a casualty.
@export var enemy_hit_chance_percent: int = 12

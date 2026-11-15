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

@export_group("Suppression")
## Pressure added to a man each time he is shot at, hit or miss. 0 turns
## suppression off. A man's suppression runs from 0 to 100.
@export var suppression_per_shot: int = 12
## Pressure added to each comrade standing next to the man shot at.
@export var suppression_splash: int = 4
## Share of that pressure that still reaches a man behind cover, 0 to 100.
@export var cover_suppression_percent: int = 60
## A man loses one point of suppression every this many ticks.
@export var suppression_decay_ticks: int = 2
## At this much suppression a man is pinned: he will not walk, and he fires
## slower and less accurately.
@export var pinned_threshold: int = 50
## A pinned man's time between shots, as a percentage of normal. 200 is twice as long.
@export var pinned_fire_interval_percent: int = 200
## A pinned man's hit chance, as a percentage of normal.
@export var pinned_hit_percent: int = 50

@export_group("Breaking and enemy behaviour")
## At this much suppression a man breaks: he stops firing, and an enemy
## soldier leaves his position. He recovers once his suppression has fallen
## back below the pinned level.
@export var broken_threshold: int = 85
## The enemy picket reconsiders what to do every this many ticks.
@export var ai_think_ticks: int = 10

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
## cover, from 0 (fire across cover never hits, it only suppresses) to 100
## (cover does nothing).
@export var cover_hit_percent: int = 35

@export_group("Suppression")
## Pressure added to a man each time he is shot at, hit or miss. 0 turns
## suppression off. A man's suppression runs from 0 to 100.
@export var suppression_per_shot: int = 12
## Pressure added to each comrade standing next to the man shot at.
@export var suppression_splash: int = 4
## Share of that pressure that still reaches a man behind cover, 0 to 100.
@export var cover_suppression_percent: int = 60
## Fire that has to cross a man's cover cannot push his suppression above
## this. Keep it below broken_threshold: then fire from the front can pin a
## man in cover but never break him, and only fire from a side his cover
## does not protect can. 100 removes the limit.
@export var cover_suppression_cap: int = 70
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

@export_group("Scavenging")
## Ticks a man needs to pick up one round from the ground beside him.
@export var gather_ticks_per_round: int = 5
## The most rounds one man can carry.
@export var max_rounds_carried: int = 40

@export_group("Appeals")
## How far a shouted appeal carries in still air, in cells. Weather can cut it.
@export var appeal_range_cells: int = 8
## How long a team spends calling out before the answer comes, in ticks.
@export var appeal_ticks: int = 50
## Chance from 0 to 100 that an appeal works on men who are neither pinned nor
## have lost anyone. Keep it low: appeals were "largely unsuccessful" (S1 p. 43).
@export var appeal_base_percent: int = 2
## Added in proportion to the share of the group that is pinned or broken.
@export var appeal_pinned_percent: int = 20
## Added in proportion to the share of the group lost (fallen or gone).
@export var appeal_losses_percent: int = 20
## The chance never goes above this.
@export var appeal_max_percent: int = 40
## Suppression each man of the group sheds when he refuses: he takes heart.
@export var appeal_refusal_relief: int = 30

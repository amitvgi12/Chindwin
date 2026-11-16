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

@export_group("Condition")
## Every man in the fight grows one point hungrier every this many ticks.
## 0 turns hunger off.
@export var hunger_rise_ticks: int = 600
## A man who is walking grows one point more tired every this many ticks.
## Slopes and rain slow him, so they tire him more. 0 turns fatigue off.
@export var fatigue_walk_ticks: int = 30
## A man standing still loses one point of fatigue every this many ticks.
@export var fatigue_rest_ticks: int = 50
## Share of a man's hunger, 0 to 100, that his suppression can never fade below.
@export var hunger_floor_percent: int = 30
## Share of a man's fatigue, 0 to 100, that his suppression can never fade below.
@export var fatigue_floor_percent: int = 20
## The most that hunger and fatigue together can hold suppression up. Keep it
## below pinned_threshold: a starving man pins sooner, but is never pinned by
## hunger alone.
@export var condition_floor_max: int = 40

@export_group("Walking away")
## Below this hunger none of the player's men walks away, however hard pressed.
@export var walk_away_hunger: int = 40
## Chance from 0 to 100 that a starving man (hunger 100) walks away when he
## breaks. Between walk_away_hunger and 100 the chance rises in proportion.
## 0 turns walking away off.
@export var walk_away_max_percent: int = 30

@export_group("Food")
## Ticks a man needs to eat a ration. He does not fire meanwhile.
@export var eat_ticks: int = 30
## Hunger one ration takes away.
@export var ration_hunger_relief: int = 40
## The most rations one man can carry.
@export var max_rations_carried: int = 3

@export_group("Scavenging")
## Ticks a man needs to pick up one round, or one ration, from the ground
## beside him.
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

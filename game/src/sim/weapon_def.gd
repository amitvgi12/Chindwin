class_name WeaponDef
extends Resource
## One kind of weapon. Edit the files in data/weapons/, not this script.
## Names and numbers are placeholders until the history is sourced.

## Translation key for the weapon's display name.
@export var name_key: String = ""
## How far it can shoot, in cells.
@export var range_cells: int = 14
## Ticks between two shots by the same man.
@export var fire_interval_ticks: int = 12
## Chance from 0 to 100 that one shot at a man in the open causes a casualty.
@export var hit_chance_percent: int = 8

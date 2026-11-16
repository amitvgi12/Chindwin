class_name WeatherDef
extends Resource
## One state of the weather and what it does. Edit the files in
## data/weather/, not this script. The numbers are game values, not history.

## Translation key for the weather's display name.
@export var name_key: String = ""

@export_group("Rules")
## Nobody can see or shoot further than this, whatever his weapon's range.
@export var sight_range_cells: int = 99
## Time to walk onto a slope cell, as a percentage of normal. 150 is half as slow again.
@export var slope_move_percent: int = 100
## Chance from 0 to 100 that a shot does not go off because the weapon has stopped.
@export var stoppage_chance_percent: int = 0
## Ticks a man needs to clear a stoppage before he can try again.
@export var stoppage_clear_ticks: int = 30
## A shouted appeal carries no further than this. Rain drowns voices.
@export var voice_range_cells: int = 99

@export_group("Look (used by the view only)")
## Number of rain streaks drawn. 0 for none.
@export var rain_streaks: int = 0
## How strongly the scene is hazed over, 0 to 100.
@export var haze_percent: int = 0

class_name AmmoCache
extends RefCounted
## Rounds and rations lying on the ground at one cell: a supply box placed by
## the scenario, or what a man was carrying when he fell.

var cell: Vector2i
var rounds: int
var rations: int


func _init(p_cell: Vector2i, p_rounds: int, p_rations: int = 0) -> void:
	cell = p_cell
	rounds = p_rounds
	rations = p_rations


## True while there is anything left in it.
func has_anything() -> bool:
	return rounds > 0 or rations > 0

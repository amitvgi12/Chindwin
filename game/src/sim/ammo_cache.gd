class_name AmmoCache
extends RefCounted
## Rounds lying on the ground at one cell: an ammunition box placed by the
## scenario, or what a man was carrying when he fell.

var cell: Vector2i
var rounds: int


func _init(p_cell: Vector2i, p_rounds: int) -> void:
	cell = p_cell
	rounds = p_rounds

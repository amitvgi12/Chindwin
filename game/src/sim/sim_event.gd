class_name SimEvent
extends RefCounted
## Something that happened in the simulation, kept in a log.
## Tests read the log to check rules. The view reads it to draw shots.

enum Kind {
	ORDER_MOVE,
	ORDER_HOLD_FIRE,
	ORDER_FIRE_AT_WILL,
	ORDER_FALL_BACK,
	ARRIVED,
	SHOT_MISSED,
	SHOT_HIT,
	PICKET_FALLS_BACK,
	WITHDREW,
}

var tick: int
var kind: Kind
## Soldier who acted, or the team id for the ORDER kinds and PICKET_FALLS_BACK.
var actor_id: int
## Soldier acted upon, or -1 when there is none.
var target_id: int
## Cell the event refers to: an order's target or where a man arrived.
var cell: Vector2i


func _init(p_tick: int, p_kind: Kind, p_actor_id: int, p_target_id: int, p_cell: Vector2i) -> void:
	tick = p_tick
	kind = p_kind
	actor_id = p_actor_id
	target_id = p_target_id
	cell = p_cell

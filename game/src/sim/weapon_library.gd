class_name WeaponLibrary
extends RefCounted
## Loads the weapon files a scenario asks for.

const WEAPON_PATH: String = "res://data/weapons/%s.tres"


## The weapons named by a scenario's soldiers, by id. Ids with no matching
## file are left out; Scenario.missing_weapons() reports them.
static func load_for(scenario: Scenario) -> Dictionary[String, WeaponDef]:
	var weapons: Dictionary[String, WeaponDef] = {}
	for spec: Scenario.SoldierSpec in scenario.soldiers:
		if weapons.has(spec.weapon_id):
			continue
		var path: String = WEAPON_PATH % spec.weapon_id
		if ResourceLoader.exists(path):
			var weapon: WeaponDef = load(path) as WeaponDef
			if weapon != null:
				weapons[spec.weapon_id] = weapon
	return weapons

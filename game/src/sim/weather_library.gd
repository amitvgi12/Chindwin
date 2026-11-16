class_name WeatherLibrary
extends RefCounted
## Loads the weather files a scenario asks for.

const WEATHER_PATH: String = "res://data/weather/%s.tres"


## The weather states named in a scenario's schedule, by id. Ids with no
## matching file are left out; Scenario.missing_weather() reports them.
static func load_for(scenario: Scenario) -> Dictionary[String, WeatherDef]:
	var found: Dictionary[String, WeatherDef] = {}
	for change: Scenario.WeatherChange in scenario.weather_schedule:
		if found.has(change.weather_id):
			continue
		var path: String = WEATHER_PATH % change.weather_id
		if ResourceLoader.exists(path):
			var weather: WeatherDef = load(path) as WeatherDef
			if weather != null:
				found[change.weather_id] = weather
	return found

extends Object

class_name Terrain

enum TerrainType { GRASS, FOREST, WATER }

var terrain: TerrainType

func _init():
	terrain = randi() % TerrainType.size()

func set_to(terrain_type):
	terrain = terrain_type
	
func get_type():
	return terrain
	
func get_colour():
	match terrain:
		TerrainType.GRASS:
			return Color8(96,108,56)
		TerrainType.FOREST:
			return Color8(40,54,24)
		TerrainType.WATER:
			return Color8(38,70,83)
			
static func tally_terrains(arr: Array[TerrainType]) -> Dictionary:
	var tally = {}
	for terrain in arr:
		if not tally.has(terrain):
			tally[terrain] = 0
		tally[terrain] += 1
	return tally
	
static func pick_highest_tally(arr: Array[TerrainType]) -> TerrainType:
	var tally = tally_terrains(arr)
	var highest_key = 0
	var highest_value = 0
	for key in tally:
		if tally[key] >= highest_value:
			highest_key = key
			highest_value = tally[key]
	return highest_key

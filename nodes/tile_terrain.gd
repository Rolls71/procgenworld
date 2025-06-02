extends Resource

class_name TileTerrain

const SEA = 0
const BEACH = 1
const GRASS = 2
const TREES = 3

var value
var colour
var colour_dict = {
	SEA: Color8(38,70,83),
	BEACH: Color8(233,196,106),
	GRASS: Color8(96,108,56),
	TREES: Color8(40,54,24),
}

func _init(type:int):
	value = type
	colour = colour_dict[value]

static func domain():
	var arr:Array[int] = [SEA, BEACH, GRASS, TREES]
	return arr
	
static func get_valid_adjacent_terrains(test_terrain):
	var valid_terrains = []
	for potential_terrain in domain():
		if can_be_adjacent(test_terrain, potential_terrain):
			valid_terrains.append(potential_terrain)
	return valid_terrains

static func can_be_adjacent(a:int, b:int):
	if a == b:
		return true
	if a+1 == b:
		return true
	if a == b+1:
		return true
	return false

class_name Tile extends Node2D



@export var id:int
@export var domain:Array[int] = TileTerrain.domain()
@export var neighbours:Array[Tile] = []

func construct(_id, pos):
	id = _id
	position = pos
	
func test_adjacency(pos:Vector2):
	for neighbour in neighbours:
		if neighbour.position == pos:
			return true
	return false
	

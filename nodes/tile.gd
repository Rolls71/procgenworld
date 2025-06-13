class_name Tile extends Node2D

var id:int
var neighbours:Array[Tile] = []
var domain:Array[int] = TileTerrain.domain()
var site:Delaunay.VoronoiSite
var terrain_type:TileTerrain
var propagation_count = 0

func construct(_id, pos):
	id = _id
	position = pos
	
func test_adjacency(pos:Vector2):
	for neighbour in neighbours:
		if neighbour.position == pos:
			return true
	return false
	
func entropy():
	if domain.size() <= 0:
		print("Tile at ",position," has 0 entropy")
		push_error("Tile at ",position," has 0 entropy")
	return domain.size()

func collapse():
	if domain.size() > 1:
		terrain_type = TileTerrain.new(domain.pick_random())
	elif domain.size() == 1:
		terrain_type = TileTerrain.new(domain[0])
	else:
		print("Error: domain size of 0 at ", position)
		terrain_type = TileTerrain.domain().pick_random()
	domain = [terrain_type.value]
	return self
	
func collapse_to(terrain):
	if terrain.value not in domain:
		collapse()
	terrain_type = terrain
	domain = [terrain_type.value]
	return self
	

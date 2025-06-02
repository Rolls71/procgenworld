class_name Tile extends Node2D

var id:int
var neighbours:Array[Tile] = []
var domain:Array[int] = TileTerrain.domain()
var site:Delaunay.VoronoiSite
var terrain_type:TileTerrain 
var is_collapsed:bool = false
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

func observe():
	print("observe collapse at ",position)
	collapse()
	var collapsed:Array = propagate(true)
	collapsed.append(self)
	return collapsed
	
func propagate(is_start_point):
	#print("propagate at ",position)
	#print("  count: ",propagation_count)
	#print("  neighbours: ")
	var collapse_list = []
	if is_start_point:
		propagation_count += 1
	for neighbour in neighbours:
		#print("    ",neighbour.domain)
		if neighbour.propagation_count >= propagation_count:
			continue
		neighbour.propagation_count += 1
		if not neighbour.is_collapsed:
			collapse_list.append(neighbour.update_with(domain))
		collapse_list.append_array(neighbour.propagate(false))
		
	return collapse_list

func update_with(other_domain):
	var valid_terrains = []
	var invalid_terrains = []
	for terrain in other_domain:
		var terrain_list = TileTerrain.get_valid_adjacent_terrains(terrain)
		for valid_terrain in terrain_list:
			if valid_terrain not in valid_terrains:
				valid_terrains.append(valid_terrain)
	
	for terrain in TileTerrain.domain():
		if terrain not in valid_terrains:
			invalid_terrains.append(terrain)
	for terrain in invalid_terrains:
		var i = domain.find(terrain)
		if i != -1:
			domain.remove_at(i)
	
	if entropy() == 0:
		push_error("No valid terrain choices at ",position)
	
	is_collapsed = (entropy() == 1)
	if is_collapsed:
		collapse()
		print("wave collapse at ",position)
		return self

func collapse():
	if domain.size() > 1:
		terrain_type = TileTerrain.new(domain.pick_random())
	else:
		terrain_type = TileTerrain.new(domain[0])
	domain = [terrain_type.value]
	is_collapsed = true
	return self

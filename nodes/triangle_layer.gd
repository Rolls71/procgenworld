extends Node2D
var web: Web
var k = 0

func _init():
	web = Web.new()
	
func _draw():
	var triangles_shuffled = web.chunks[0].triangles.values().duplicate()
	triangles_shuffled.shuffle()
	for triangle in triangles_shuffled:
		var options: Array[Terrain.TerrainType] = []
		for neighbour in triangle.get_vertex_neighbours():
			if neighbour.terrain:
				options.append(neighbour.terrain.get_type())
		var terrain = Terrain.new()
		if options.size() > 0:
			terrain.set_to(Terrain.pick_highest_tally(options))
		triangle.terrain = terrain
		draw_colored_polygon(triangle.get_packed_vec_array(), terrain.get_colour())
	for edge in web.chunks[0].edges.values():
		draw_line(edge.a.pos, edge.b.pos, Color.BLACK)
	for vertex in web.chunks[0].vertices.values():
		draw_circle(vertex.pos, 5, Color.RED)

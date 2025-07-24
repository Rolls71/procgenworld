extends Node2D
var web: Web
var k = 0

func _init():
	web = Web.new()
	
func _draw():
	for key in web.chunks:
		var triangles_shuffled = web.chunks[key].triangles.values().duplicate()
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
	for key in web.chunks:
		var borders = web.chunks[key].get_border_edges()
		for edge in web.chunks[key].edges.values():
			if edge in borders:
				draw_line(edge.a.pos, edge.b.pos, Color.YELLOW)
			else:
				draw_line(edge.a.pos, edge.b.pos, Color.BLACK)
					
	var color = Color(randf(), randf(), randf())
	for key in web.chunks:
		for point in web.chunks[key].points:
			draw_circle(point, 5, color)
		color = Color(randf(), randf(), randf())
			

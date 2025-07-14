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
		var down_borders = web.chunks[key].get_specific_border_edges(Vector2.DOWN)
		var right_borders = web.chunks[key].get_specific_border_edges(Vector2.RIGHT)
		var up_borders = web.chunks[key].get_specific_border_edges(Vector2.UP)
		var left_borders = web.chunks[key].get_specific_border_edges(Vector2.LEFT)
		for edge in web.chunks[key].edges.values():
			if edge in down_borders:
				draw_line(edge.a.pos, edge.b.pos, Color.RED)
			elif edge in right_borders:
				draw_line(edge.a.pos, edge.b.pos, Color.GREEN)
			elif edge in up_borders:
				draw_line(edge.a.pos, edge.b.pos, Color.YELLOW)
			elif edge in left_borders:
				draw_line(edge.a.pos, edge.b.pos, Color.CYAN)
			else:
				draw_line(edge.a.pos, edge.b.pos, Color.BLACK)
					
		for vertex in web.chunks[key].vertices.values():
			draw_circle(vertex.pos, 5, Color.RED)
	
	draw_colored_polygon(web.get_bordering_points(Vector2i(1,1)), Color.PURPLE)

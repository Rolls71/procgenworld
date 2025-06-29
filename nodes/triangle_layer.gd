extends Node2D
var web: Web
var k = 0

func _init():
	web = Web.new()
	
func _draw():
	for triangle in web.chunks[0].triangles.values():
		draw_colored_polygon(triangle.get_packed_vec_array(), Color(randf(), randf(), randf()))
	for edge in web.chunks[0].edges.values():
		draw_line(edge.a.pos, edge.b.pos, Color.BLACK)
	for vertex in web.chunks[0].vertices.values():
		draw_circle(vertex.pos, 5, Color.RED)

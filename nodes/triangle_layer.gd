extends Node2D
var web: Web
var k = 0

func _init():
	web = Web.new()
	
func _draw():
	for vertex in web.chunks[0].vertices:
		draw_circle(vertex.pos, 5, Color.RED)

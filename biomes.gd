extends Node2D

const width = 1152
const height = 648
const count = 10

var points: Array

func _draw():
	draw_rect(Rect2(0,0,width,height), Color.WHITE)
	
	points = []
	var n1 = Node2D.new()
	n1.position = Vector2(0,0)
	var n2 = Node2D.new()
	n2.position = Vector2(width,0)
	var n3 = Node2D.new()
	n3.position = Vector2(0,height)
	var n4 = Node2D.new()
	n4.position = Vector2(width, height)
	points.append_array([n1, n2, n3, n4])
	for i in count:
		if i <= 3:
			continue
		var node: Node2D = Node2D.new()
		node.position = Vector2(randi_range(0,width), randi_range(0,height))
		points.append(node)
		draw_circle(node.position, 3, Color.RED)
		
	for i in count:
		for j in count:
			if j <= i:
				continue
			draw_line(points[i].position, points[j].position, Color.BLACK)
		
		
		
		
		
		
		
#func qpoint_to_vector(p):
		#var x = p%width
		#var y = p/width
		#return Vector2(x,y)
	#
#func vector_to_qpoint(v):
	#return v.y*width + v.x
	#
#func get_point_neighborhood(v, radius):
	#pass
	
#func find_free_point(radius):
	#var a = randi_range(0,width)
	#var b = randi_range(0,height)
	#var v = Vector2(a, b)
	#
	#for p in biome_points:
		#if p.distance_to(v) <= radius:
			#return find_free_point(radius)
		#else:
			#return v
#
#
#func grid_has_unclaimed_points():
	#for x in width:
		#for y in height:
			#if grid[x][y] == 0:
				#return true
			#else:
				#continue
	#return false

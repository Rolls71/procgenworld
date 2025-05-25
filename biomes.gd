extends Node2D

const width = 1152
const height = 648
const count = 8

var points: Array[int]
var pointq: Array[int]
var nodes: Array[Node2D]
var biome_colours = {
	0:Color.LIGHT_SEA_GREEN,
	1:Color.SANDY_BROWN,
	2:Color.LIME_GREEN,
	3:Color.DARK_GREEN,
	4:Color.DIM_GRAY,
	5:Color.PALE_TURQUOISE,
	6:Color.DARK_ORANGE,
	7:Color.NAVY_BLUE,
}

func _draw():
	draw_rect(Rect2(0,0,width,height), Color.WHITE)
	points = []
	points.resize(width*height)
	points.fill(0)
	pointq = points.duplicate()
	nodes = []
	#var n1 = Node2D.new()
	#n1.position = Vector2(0,0)
	#var n2 = Node2D.new()
	#n2.position = Vector2(width,0)
	#var n3 = Node2D.new()
	#n3.position = Vector2(0,height)
	#var n4 = Node2D.new()
	#n4.position = Vector2(width, height)
	#nodes.append_array([n1, n2, n3, n4])
	for i in count:
		var border
		var node: Node2D = Node2D.new()
		var x = randi()%width
		var y = randi()%height
		
		if i % 2 == 1:
			node.position = Vector2(x, y)
		else:
			var r = randi()%4
			if r == 0:
				node.position = Vector2(x,0)
			elif r == 1:
				node.position = Vector2(width,y)
			elif r == 2:
				node.position = Vector2(x,height)
			elif r == 3:
				node.position = Vector2(0,y)
		nodes.append(node)

	for i in count:
		var shortest = 9223372036854775807
		var sj = i
		for j in count:
			if j == i:
				continue
			var dist = nodes[i].position.distance_to(nodes[j].position)
			if dist < shortest:
				shortest = dist
				sj = j
		draw_circle(nodes[i].position, shortest/2, biome_colours[i%biome_colours.size()])
		#get_all_points_in_radius(nodes[i].position, shortest/2)
		
		
			
			
			
		
		
		
		
		
		
		
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
	#for p in biome_nodes:
		#if p.distance_to(v) <= radius:
			#return find_free_point(radius)
		#else:
			#return v
#
#
#func grid_has_unclaimed_nodes():
	#for x in width:
		#for y in height:
			#if grid[x][y] == 0:
				#return true
			#else:
				#continue
	#return false

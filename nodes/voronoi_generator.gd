extends Node

## Originally created by arcanewright
## https://github.com/arcanewright/godot-chunked-voronoi-generator

@export var random_seed:int
@export var width_per_chunk:int = 5
@export var height_per_chunk:int = 5
@export var dist_between_points:float = 30
@export var dist_between_points_variation:float = .3
@export var voronoi_tolerance:float = .3

var view

func random_num_on_coords(coords:Vector2, initial_seed:int):
	var result = initial_seed
	var rand_gen = RandomNumberGenerator.new()
	rand_gen.seed = coords.x
	result += rand_gen.randi()
	var newy = rand_gen.randi() + coords.y
	rand_gen.seed = newy
	result += rand_gen.randi()
	rand_gen.seed = result
	result = rand_gen.randi()
	return result

func generate_chunk_points(
		coords:Vector2, 
		width_range:Vector2 = Vector2(0, width_per_chunk), 
		height_range:Vector2 = Vector2(0, height_per_chunk)
	):
	var local_rand_seed = random_num_on_coords(coords, random_seed)
	var init_points: Array[Vector2] = []
	for w in range(width_range.x, width_range.y):
		for h in range(height_range.x, height_range.y):
			var rand_gen = RandomNumberGenerator.new()
			var point_rand_seed = random_num_on_coords(Vector2(w,h), local_rand_seed)
			rand_gen.seed = point_rand_seed
			var new_point = Vector2(w*dist_between_points + rand_gen.randf_range(-dist_between_points_variation, dist_between_points_variation)*dist_between_points, h*dist_between_points + rand_gen.randf_range(-dist_between_points_variation, dist_between_points_variation)*dist_between_points)
			init_points.append(new_point)
	return init_points

func generate_chunk_voronoi(coords:Vector2):
	var init_points = generate_chunk_points(coords)
	var surrounding_points: Array[Vector2] = []
	for i in range(-1, 2):
		for j in range(-1, 2):
			if (!(i == 0 && j == 0)):
				var xmin = 0
				var xmax = 1
				var ymin = 0
				var ymax = 1
				if (i == -1):
					xmin = 1 - voronoi_tolerance
				if (i == +1):
					xmax = voronoi_tolerance
				if (j== -1):
					ymin = 1 - voronoi_tolerance
				if (j== 1):
					ymax = voronoi_tolerance
				var temp_points = generate_chunk_points(Vector2(coords.x+i, coords.y+j), Vector2(xmin*width_per_chunk, xmax*width_per_chunk), Vector2(ymin*height_per_chunk, ymax*height_per_chunk))
				var result_points: Array[Vector2] = []
				for point in temp_points:
					var temp_point = point + Vector2(i * width_per_chunk * dist_between_points, j * height_per_chunk * dist_between_points)
					result_points.append(temp_point)
				surrounding_points.append_array(result_points)
	var all_points = init_points+surrounding_points
	var all_delauney = Geometry2D.triangulate_delaunay(all_points)
	var triangle_array = []
	@warning_ignore("integer_division")
	for triple in range(0, all_delauney.size()/3):
		triangle_array.append([all_delauney[triple*3], all_delauney[triple*3+1], all_delauney[triple*3+2]])
	var circumcenters: Array[Vector2] = []
	for triple in triangle_array:
		circumcenters.append(get_circumcentre(all_points[triple[0]], all_points[triple[1]], all_points[triple[2]]))
	var vCtrIdxWithVerts = []
	for point in range(init_points.size()):
		var temp_verts: Array[Vector2] = []
		for triangle in range(triangle_array.size()):
			if (point == triangle_array[triangle][0] || point == triangle_array[triangle][1] || point == triangle_array[triangle][2]):
				temp_verts.append(circumcenters[triangle])
		temp_verts = clockwise_points(init_points[point], temp_verts)
		vCtrIdxWithVerts.append([init_points[point], temp_verts])
	
	return vCtrIdxWithVerts

func clockwise_points(center:Vector2, sorrounding:Array[Vector2]):
	var result: Array[Vector2] = []
	var angles: Array = []
	var sorted_indices: Array[int] = []
	for point in sorrounding:
		angles.append(center.angle_to_point(point))
	var remaining_indices: Array[int] = [] 
	for angle in range(angles.size()):
		remaining_indices.append(angle)
	for angle in range(angles.size()):
		var currentMin = PI
		var current_test_index = 0
		for test in range(remaining_indices.size()):
			if (angles[remaining_indices[test]] < currentMin):
				current_test_index = test
				currentMin = angles[remaining_indices[test]]
		sorted_indices.append(remaining_indices[current_test_index])
		remaining_indices.pop_at(current_test_index)
	for index in sorted_indices:
		result.append(sorrounding[index])
	return result

func get_circumcentre(a:Vector2, b:Vector2, c:Vector2):
	var result = Vector2(0,0)
	var midpoint_ab = Vector2((a.x+b.x)/2,(a.y+b.y)/2)
	var slope_perp_ab = -((b.x-a.x)/(b.y-a.y))
	var midpoint_ac = Vector2((a.x+c.x)/2,(a.y+c.y)/2)
	var slope_perp_ac = -((c.x-a.x)/(c.y-a.y))
	var b_of_perp_ab = midpoint_ab.y - (midpoint_ab.x * slope_perp_ab)
	var b_of_perp_ac = midpoint_ac.y - (midpoint_ac.x * slope_perp_ac)
	result.x = (b_of_perp_ab - b_of_perp_ac)/(slope_perp_ac - slope_perp_ab)
	result.y = slope_perp_ab*result.x + b_of_perp_ab
	return result

func display_voronoi_from_chunk(chunk_location:Vector2):
	view = get_child(0)
	view.random_seed = random_num_on_coords(chunk_location, random_seed)
	var voronoi = generate_chunk_voronoi(chunk_location)
	for each in voronoi:
		view.display_polygon(Vector2(chunk_location.x*width_per_chunk*dist_between_points,chunk_location.y*height_per_chunk*dist_between_points), each[1])
	view.display_points(Vector2(chunk_location.x*width_per_chunk*dist_between_points,chunk_location.y*height_per_chunk*dist_between_points), generate_chunk_points(chunk_location))
	pass

func _ready():
	for w in 10:
		for h in 10:
			if not (w == 5 && h == 5):
				display_voronoi_from_chunk(Vector2(w, h))
	pass

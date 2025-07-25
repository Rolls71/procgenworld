extends Resource
class_name Web

# ==== CONSTANTS ====
const EDGE_MIN: float = 40
const EDGE_MAX: float = 100
const POISSON_SAMPLE_ATTEMPTS: int = 15
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const CHUNK_BORDER_WIDTH: int = 400

# ==== CLASSES ====

class Vertex:
	var pos: Vector2
	var edges: Array[Edge]
	var triangles: Array[Triangle]
	
	func _init(position:Vector2):
		self.pos = position
		
	func equals(vertex:Vertex) -> bool:
		return (self.pos == vertex.pos)

class Edge:
	var a: Vertex
	var b: Vertex
	var triangles: Array[Triangle]
	
	func _init(_a: Vertex, _b: Vertex):
		self.a = _a
		self.b = _b
		
	func equals(edge: Edge) -> bool:
		return ((a.pos == edge.a.pos && b.pos == edge.b.pos) || 
				(a.pos == edge.b.pos && b.pos == edge.a.pos))
	
	func length() -> float:
		return a.pos.distance_to(b.pos)
	
	func center() -> Vector2:
		return (a.pos + b.pos) * 0.5
	
	func points() -> PackedVector2Array:
		return PackedVector2Array([a, b])
	

class Triangle:
	var a: Vertex
	var b: Vertex
	var c: Vertex
	
	var ab: Edge
	var bc: Edge
	var ac: Edge
	
	var center: Vector2
	var radius_sqr: float
	var terrain: Terrain
	
	func _init(_a: Vertex, _b: Vertex, _c: Vertex, _ab: Edge, _bc: Edge, _ac: Edge):
		self.a = _a
		self.b = _b
		self.c = _c
		ab = _ab
		bc = _bc
		ac = _ac
		recalculate_circumcircle()
	
	func recalculate_circumcircle() -> void:
		var _ab := a.pos.length_squared()
		var _cd := b.pos.length_squared()
		var _ef := c.pos.length_squared()
		
		var cmb := c.pos - b.pos
		var amc := a.pos - c.pos
		var bma := b.pos - a.pos
	
		var circum := Vector2(
			(_ab * cmb.y + _cd * amc.y + _ef * bma.y) / (a.pos.x * cmb.y + b.pos.x * amc.y + c.pos.x * bma.y),
			(_ab * cmb.x + _cd * amc.x + _ef * bma.x) / (a.pos.y * cmb.x + b.pos.y * amc.x + c.pos.y * bma.x)
		)
	
		center = circum * 0.5
		radius_sqr = a.pos.distance_squared_to(center)
	
	func is_point_inside_circumcircle(point: Vector2) -> bool:
		return center.distance_squared_to(point) < radius_sqr
	
	func is_corner(point: Vector2) -> bool:
		return point == a.pos || point == b.pos || point == c.pos
	
	func get_edge_opposite_corner(corner: Vertex) -> Edge:
		if corner.pos == a.pos:
			return bc
		elif corner.pos == b.pos:
			return ac
		elif corner.pos == c.pos:
			return ab
		else:
			return null
			
	func get_edge_neighbours():
		var neighbours = []
		for triangle in ab.triangles:
			if triangle != self and triangle not in neighbours:
				neighbours.append(triangle)
		for triangle in bc.triangles:
			if triangle != self and triangle not in neighbours:
				neighbours.append(triangle)
		for triangle in ac.triangles:
			if triangle != self and triangle not in neighbours:
				neighbours.append(triangle)
		return neighbours

	func get_vertex_neighbours():
		var neighbours = []
		for triangle in a.triangles:
			if triangle != self and triangle not in neighbours:
				neighbours.append(triangle)
		for triangle in b.triangles:
			if triangle != self and triangle not in neighbours:
				neighbours.append(triangle)
		for triangle in c.triangles:
			if triangle != self and triangle not in neighbours:
				neighbours.append(triangle)
		return neighbours
			
	func link_components():
		_link_component(a)
		_link_component(b)
		_link_component(c)
		_link_component(ab)
		_link_component(bc)
		_link_component(ac)
			
	func _link_component(component): 
		if not component.triangles.has(self): 
			component.triangles.append(self)
			
	func get_packed_vec_array():
		var arr = [a.pos, b.pos, c.pos]
		return PackedVector2Array(arr)
		
class Chunk:
	var vertices: Dictionary[Vector2, Vertex] = {}
	var edges: Dictionary[Vector2, Edge] = {}
	var triangles: Dictionary[Vector2, Triangle] = {}
	var borders: PackedVector2Array
	var pos: Vector2i
	
	func _init(_pos: Vector2i, chunk_borders: PackedVector2Array):
		pos = _pos
		borders = chunk_borders
		
		var points = PoissonDiscSampling.generate_points_for_polygon(
			borders, 
			EDGE_MIN, 
			POISSON_SAMPLE_ATTEMPTS
		)
		var delaunay = Delaunay.new(Rect2())
		for point in points:
			vertices[point] = Vertex.new(point)
			delaunay.add_point(point)
			
		var triangulation: Array[Delaunay.Triangle] = delaunay.triangulate()
		delaunay.remove_border_triangles(triangulation)
		for delaunay_triangle in triangulation:
			var a = delaunay_triangle.a
			var b = delaunay_triangle.b
			var c = delaunay_triangle.c
			
			# if edge is already chosen, link triangle isntead of new edge
			var link_edges = []
			var ab
			var bc
			var ac
			if (Vector2(a.x, a.y)+Vector2(b.x, b.y))*0.5 in edges.keys():
				link_edges.append((Vector2(a.x, a.y)+Vector2(b.x, b.y))*0.5)
				ab = edges[(Vector2(a.x, a.y)+Vector2(b.x, b.y))*0.5]
			else:
				ab = Edge.new(vertices[a], vertices[b])
			if ab.length() > EDGE_MAX or ab.length() < EDGE_MIN:
				continue
				
			if (Vector2(b.x, b.y)+Vector2(c.x, c.y))*0.5 in edges.keys():
				link_edges.append((Vector2(b.x, b.y)+Vector2(c.x, c.y))*0.5)
				bc = edges[(Vector2(b.x, b.y)+Vector2(c.x, c.y))*0.5]
			else:
				bc = Edge.new(vertices[b], vertices[c])
			if bc.length() > EDGE_MAX or bc.length() < EDGE_MIN:
				continue
				
			if (Vector2(a.x, a.y)+Vector2(c.x, c.y))*0.5 in edges.keys():
				link_edges.append((Vector2(a.x, a.y)+Vector2(c.x, c.y))*0.5)
				ac = edges[(Vector2(a.x, a.y)+Vector2(c.x, c.y))*0.5]
			else:
				ac = Edge.new(vertices[a], vertices[c])
			if ac.length() > EDGE_MAX or ac.length() < EDGE_MIN:
				continue

			edges[(Vector2(a.x, a.y)+Vector2(b.x, b.y))*0.5] = ab
			edges[(Vector2(b.x, b.y)+Vector2(c.x, c.y))*0.5] = bc
			edges[(Vector2(a.x, a.y)+Vector2(c.x, c.y))*0.5] = ac
			
			var triangle = Triangle.new(
				vertices[a], 
				vertices[b], 
				vertices[c],
				ab,
				bc,
				ac,
			)
			
			if triangle.center not in triangles.keys():
				triangles[triangle.center] = triangle
		for key in triangles:
			triangles[key].link_components()
		
	func get_border_edges() -> Array[Edge] :
		var border_edges: Array[Edge] = []
		for key in edges:
			if edges[key].triangles.size() == 1:
				border_edges.append(edges[key])
		return border_edges
	
	func get_specific_border_edges(dir: Vector2):
		var border_edges = get_border_edges()
		var specific_edges = []
		for edge in border_edges:
			var avg_point = Vector2.ZERO
			for point in borders:
				avg_point += point
			avg_point /= borders.size()
			var angle = avg_point.angle_to_point(edge.center())
			if abs(angle_difference(dir.angle(), angle)) < PI/4:
				specific_edges.append(edge)
				
		return specific_edges

# ==== PUBLIC VARIABLES =====
var vertices: Array[Vertex]
var edges: Array[Edge]
var triangles: Array[Triangle]
var chunks: Dictionary[Vector2i, Chunk]
var display_polygons: Array[Polygon2D]

# ==== CONSTRUCTOR =====
func _init():
	chunks = {}
	for x in 3:
		for y in 2:
			var pos = Vector2i(x, y)
			chunks[pos] = Chunk.new(pos,get_bordering_points(pos))
			#print("RIGHT ", chunks[Vector2i(x, y)].get_specific_border_edges(Vector2i.RIGHT))
			#print("DOWN ", chunks[Vector2i(x, y)].get_specific_border_edges(Vector2i.DOWN))
			#chunks[Vector2i(x, y)].get_specific_border_edges(Vector2i.LEFT)
			#chunks[Vector2i(x, y)].get_specific_border_edges(Vector2i.UP)
			
# ==== PUBLIC FUNCTIONS ====
func get_neighbouring_chunks(pos: Vector2i) -> Array[Chunk]:
	var x = pos.x
	var y = pos.y
	var neighbours: Array[Chunk] = []
	for i in range(-1,2):
		for j in range(-1,2):
			if i == 0 and j == 0:
				continue
			if Vector2i(x+i, y+j) in chunks:
				neighbours.append(chunks[Vector2i(x+i, y+j)])
	return neighbours
	
func get_bordering_points(pos: Vector2i) -> PackedVector2Array:
	var points: Array[Vector2] = []
	for dir in DIRECTIONS:
		if chunks.has(pos+dir):
			var border_edges = chunks[pos+dir].get_specific_border_edges(-dir)
			for edge in border_edges:
				if edge.a.pos not in points:
					points.append(edge.a.pos)
				if edge.b.pos not in points:
					points.append(edge.b.pos)
		else:
			match dir:
				Vector2i.RIGHT:
					points.append(Vector2(pos)*CHUNK_BORDER_WIDTH+Vector2.RIGHT*CHUNK_BORDER_WIDTH)
				Vector2i.DOWN:
					points.append(Vector2(pos)*CHUNK_BORDER_WIDTH+Vector2.ONE*CHUNK_BORDER_WIDTH)
				Vector2i.LEFT:
					points.append(Vector2(pos)*CHUNK_BORDER_WIDTH+Vector2.DOWN*CHUNK_BORDER_WIDTH)
				Vector2i.UP:
					points.append(Vector2(pos)*CHUNK_BORDER_WIDTH+Vector2.ZERO*CHUNK_BORDER_WIDTH)

	var ordered_pts = PackedVector2Array(clockwise_points(get_avg_point(points), points))
	ordered_pts.append(ordered_pts[0])
	print(ordered_pts)
	return PackedVector2Array(ordered_pts)

func get_avg_point(points):
	var avg_point = Vector2.ZERO
	for point in points:
		avg_point += point
	avg_point /= points.size()
	return avg_point


func sort_ascending(a, b):
	if a[1] < b[1]:
		return true
	return false
func clockwise_points(center:Vector2, surrounding:Array[Vector2]):
	var arr: Array = []
	for point in surrounding:
		arr.append([point, center.angle_to_point(point)])
	arr.sort_custom(sort_ascending)
	var result: Array[Vector2] = []
	for i in arr.size():
		result.append(arr[i][0])
	
	return result
	


	

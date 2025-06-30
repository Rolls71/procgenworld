extends Resource
class_name Web

# ==== CONSTANTS ====
const EDGE_MIN: float = 40
const EDGE_MAX: float = 100
const POISSON_SAMPLE_ATTEMPTS: int = 15

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
		_link_components()
	
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
			
	func _link_components():
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
	var edges: Dictionary[Vector4, Edge] = {}
	var triangles: Dictionary[Vector2, Triangle] = {}
	var borders: Rect2
	var x: int
	var y: int
	
	func _init(chunk_x, chunk_y, chunk_borders):
		x = chunk_x
		y = chunk_y
		borders = chunk_borders
		
		var corners = [
			borders.position, 
			borders.position+Vector2(borders.size[0], 0),
			borders.position+Vector2(borders.size[0], borders.size[1]),
			borders.position+Vector2(0, borders.size[1]),
		]
		var points = PoissonDiscSampling.generate_points_for_polygon(
			PackedVector2Array(corners), 
			EDGE_MIN, 
			POISSON_SAMPLE_ATTEMPTS
		)
		var delaunay = Delaunay.new(borders)
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
			if Vector4(a.x, a.y, b.x, b.y) in edges.keys():
				link_edges.append(Vector4(a.x, a.y, b.x, b.y))
				ab = edges[Vector4(a.x, a.y, b.x, b.y)]
			else:
				ab = Edge.new(vertices[a], vertices[b])
				
			if Vector4(b.x, b.y, c.x, c.y) in edges.keys():
				link_edges.append(Vector4(b.x, b.y, c.x, c.y))
				bc = edges[Vector4(b.x, b.y, c.x, c.y)]
			else:
				bc = Edge.new(vertices[b], vertices[c])
				
			if Vector4(a.x, a.y, c.x, c.y) in edges.keys():
				link_edges.append(Vector4(a.x, a.y, c.x, c.y))
				ac = edges[Vector4(a.x, a.y, c.x, c.y)]
			else:
				ac = Edge.new(vertices[a], vertices[c])
			edges[Vector4(a.x, a.y, b.x, b.y)] = ab
			edges[Vector4(b.x, b.y, c.x, c.y)] = bc
			edges[Vector4(a.x, a.y, c.x, c.y)] = ac
			
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

# ==== PUBLIC VARIABLES =====
var vertices: Array[Vertex]
var edges: Array[Edge]
var triangles: Array[Triangle]
var chunks: Array[Chunk]
var display_polygons: Array[Polygon2D]

# ==== CONSTRUCTOR =====
func _init():
	chunks = [Chunk.new(0,0,Rect2(0,0,1920,1080))]
			
	

	
	


# ==== PUBLIC FUNCTIONS ====

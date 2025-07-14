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
	var pos: Vector2i
	
	func _init(_pos: Vector2i, chunk_borders: Rect2):
		pos = _pos
		borders = chunk_borders
		borders.position = Vector2(pos.x*borders.size[0], pos.y*borders.size[1])
		
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
			if ab.length() > EDGE_MAX or ab.length() < EDGE_MIN:
				continue
				
			if Vector4(b.x, b.y, c.x, c.y) in edges.keys():
				link_edges.append(Vector4(b.x, b.y, c.x, c.y))
				bc = edges[Vector4(b.x, b.y, c.x, c.y)]
			else:
				bc = Edge.new(vertices[b], vertices[c])
			if bc.length() > EDGE_MAX or bc.length() < EDGE_MIN:
				continue
				
			if Vector4(a.x, a.y, c.x, c.y) in edges.keys():
				link_edges.append(Vector4(a.x, a.y, c.x, c.y))
				ac = edges[Vector4(a.x, a.y, c.x, c.y)]
			else:
				ac = Edge.new(vertices[a], vertices[c])
			if ac.length() > EDGE_MAX or ac.length() < EDGE_MIN:
				continue

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
		
	func get_border_edges() -> Array[Edge] :
		var border_edges: Array[Edge] = []
		for key in edges:
			print(key)
			if edges[key].triangles.size() == 1:
				border_edges.append(edges[key])
		return border_edges

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
			chunks[Vector2i(x, y)] = Chunk.new(Vector2i(x, y),Rect2(0,0,400,400))
			print(chunks[Vector2i(x, y)].get_border_edges())
			
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

	


	

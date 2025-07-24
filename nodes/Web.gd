extends Resource
class_name Web

# ==== CONSTANTS ====
const EDGE_MIN: float = 40
const EDGE_MAX: float = 100
const POISSON_SAMPLE_ATTEMPTS: int = 15
const CHUNK_WIDTH: float = 200
const CORNERS: Array[Vector2] = [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]

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
	
	var _center: Vector2
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
	
	func get_center():
		recalculate_circumcircle()
		return _center
	
	func recalculate_circumcircle() -> void:
		var _ab := a.pos.length_squared()
		var _cd := b.pos.length_squared()
		var _ef := c.pos.length_squared()
		
		var cmb := c.pos - b.pos
		var amc := a.pos - c.pos
		var bma := b.pos - a.pos
	
		var circum := Vector2(
			(_ab * cmb.y + _cd * amc.y + _ef * bma.y) / 
				(a.pos.x * cmb.y + b.pos.x * amc.y + c.pos.x * bma.y),
			(_ab * cmb.x + _cd * amc.x + _ef * bma.x) / 
				(a.pos.y * cmb.x + b.pos.y * amc.x + c.pos.y * bma.x)
		)
	
		_center = circum * 0.5
		radius_sqr = a.pos.distance_squared_to(_center)
	
	func is_point_inside_circumcircle(point: Vector2) -> bool:
		return _center.distance_squared_to(point) < radius_sqr
	
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
	var borders: Rect2
	var pos: Vector2i
	var neighbours: Array[Chunk]
	var points: PackedVector2Array = []
	
	func _init(_pos: Vector2i, _neighbours: Array[Chunk]):
		pos = _pos
		borders = Rect2(pos*CHUNK_WIDTH, Vector2.ONE*CHUNK_WIDTH)
		neighbours = _neighbours
		
		var neighbourhood_borders = borders.grow(CHUNK_WIDTH)
		var border_corners = []
		for direction in CORNERS:
			border_corners.append(
				borders.position+borders.size*direction)
		var start_points = []
		for neighbour in neighbours:
			for key in neighbour.vertices:
				start_points.append(neighbour.vertices[key].pos)
		
		points = PoissonDiscSampling.generate_points_for_polygon(
			PackedVector2Array(border_corners), 
			EDGE_MIN, 
			POISSON_SAMPLE_ATTEMPTS,
			Vector2.INF,
			PackedVector2Array(start_points)
		)
		
		for neighbour in neighbours:
			for key in neighbour.vertices:
				var vertex:Vertex = neighbour.vertices[key]
				if borders.grow(EDGE_MAX).has_point(vertex.pos):
					vertices[vertex.pos] = neighbour.vertices[vertex.pos]
					for edge in vertex.edges:
						edges[edge.center()] = edge
					for triangle in vertex.triangles:
						triangles[triangle._center] = triangle
		
		var delaunay = Delaunay.new(borders)
		for point in points:
			delaunay.add_point(point)
			
		var triangulation: Array[Delaunay.Triangle] = delaunay.triangulate()
		delaunay.remove_border_triangles(triangulation)
		for delaunay_triangle in triangulation:
			
			var a = delaunay_triangle.a
			var b = delaunay_triangle.b
			var c = delaunay_triangle.c
			if not (borders.has_point(a) or borders.has_point(b) or borders.has_point(c)):
				continue
			for i in [a, b, c]:
				if i not in vertices:
						vertices[i] = Vertex.new(i)
			
			var ab
			var bc
			var ac
			if (Vector2(a.x, a.y)+Vector2(b.x, b.y))*0.5 in edges.keys():
				ab = edges[(Vector2(a.x, a.y)+Vector2(b.x, b.y))*0.5]
			else:
				ab = Edge.new(vertices[a], vertices[b])
			if ab.length() > EDGE_MAX or ab.length() < EDGE_MIN:
				continue
				
			if (Vector2(b.x, b.y)+Vector2(c.x, c.y))*0.5 in edges.keys():
				bc = edges[(Vector2(b.x, b.y)+Vector2(c.x, c.y))*0.5]
			else:
				bc = Edge.new(vertices[b], vertices[c])
			if bc.length() > EDGE_MAX or bc.length() < EDGE_MIN:
				continue
				
			if (Vector2(a.x, a.y)+Vector2(c.x, c.y))*0.5 in edges.keys():
				ac = edges[(Vector2(a.x, a.y)+Vector2(c.x, c.y))*0.5]
			else:
				ac = Edge.new(vertices[a], vertices[c])
			if ac.length() > EDGE_MAX or ac.length() < EDGE_MIN:
				continue

			edges[(Vector2(a.x, a.y)+Vector2(b.x, b.y))*0.5] = ab
			edges[(Vector2(b.x, b.y)+Vector2(c.x, c.y))*0.5] = bc
			edges[(Vector2(a.x, a.y)+Vector2(c.x, c.y))*0.5] = ac
			
			var triangle:Triangle = Triangle.new(
				vertices[a], 
				vertices[b], 
				vertices[c],
				ab,
				bc,
				ac,
			)
			
			if triangle._center not in triangles.keys():
				triangles[triangle._center] = triangle
		for key in triangles:
			triangles[key].link_components()
		
	func get_border_edges() -> Array[Edge] :
		var border_edges: Array[Edge] = []
		for key in edges:
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
			chunks[Vector2i(x, y)] = Chunk.new(Vector2i(x, y), get_neighbouring_chunks(Vector2i(x, y)))
			
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

	


	

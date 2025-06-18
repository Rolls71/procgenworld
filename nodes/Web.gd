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
	
	func _init(_a: Vector2, _b: Vector2, _c: Vector2):
		self.a = Vertex.new(_a)
		self.b = Vertex.new(_b)
		self.c = Vertex.new(_c)
		ab = Edge.new(self.a,self.b)
		bc = Edge.new(self.b,self.c)
		ac = Edge.new(self.c,self.a)
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

class Chunk:
	var vertices: Array[Vertex] = []
	var edges: Array[Edge] = []
	var triangles: Array[Triangle] = []
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
			vertices.append(Vertex.new(point))
			delaunay.add_point(point)
			
		var triangulation: Array[Delaunay.Triangle] = delaunay.triangulate()
		for delaunay_triangle in triangulation:
			triangles.append(
				Triangle.new(delaunay_triangle.a, delaunay_triangle.b, delaunay_triangle.c)
			)
		for triangle in triangles:
			edges.append(triangle.ab)
			edges.append(triangle.bc)
			edges.append(triangle.ac)
		for i in range(edges.size()-2, -1, -1):
			for j in range(edges.size()-1, i, -1):
				if edges[i].equals(edges[j]):
					edges.remove_at(j)

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

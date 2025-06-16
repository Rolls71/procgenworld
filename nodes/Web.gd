extends Resource
class_name Web

# ==== CONSTANTS ====
const EDGE_MIN: float
const EDGE_MAX: float

# ==== CLASSES ====

class Vertex:
	var pos: Vector2
	var edges: Array[Edge]
	var triangles: Array[Triangle]
	
	func _init(a:Vector2):
		self.pos = pos
		
	func equals(vertex:Vertex) -> bool:
		return (self.pos == vertex.pos)

class Edge:
	var a: Vertex
	var b: Vertex
	
	func _init(a: Vertex, b: Vertex):
		self.a = a
		self.b = b
		
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
	var ca: Edge
	
	var center: Vector2
	var radius_sqr: float
	
	func _init(a: Vector2, b: Vector2, c: Vector2):
		self.a = Vertex.new(a)
		self.b = Vertex.new(b)
		self.c = Vertex.new(c)
		ab = Edge.new(self.a,self.b)
		bc = Edge.new(self.b,self.c)
		ca = Edge.new(self.c,self.a)
		recalculate_circumcircle()
	
	
	func recalculate_circumcircle() -> void:
		var ab := a.pos.length_squared()
		var cd := b.pos.length_squared()
		var ef := c.pos.length_squared()
		
		var cmb := c.pos - b.pos
		var amc := a.pos - c.pos
		var bma := b.pos - a.pos
	
		var circum := Vector2(
			(ab * cmb.y + cd * amc.y + ef * bma.y) / (a.x * cmb.y + b.x * amc.y + c.x * bma.y),
			(ab * cmb.x + cd * amc.x + ef * bma.x) / (a.y * cmb.x + b.y * amc.x + c.y * bma.x)
		)
	
		center = circum * 0.5
		radius_sqr = a.distance_squared_to(center)
	
	func is_point_inside_circumcircle(point: Vector2) -> bool:
		return center.distance_squared_to(point) < radius_sqr
	
	func is_corner(point: Vector2) -> bool:
		return point == a.pos || point == b.pos || point == c.pos
	
	func get_edge_opposite_corner(corner: Vertex) -> Edge:
		if corner.pos == a.pos:
			return bc
		elif corner.pos == b.pos:
			return ca
		elif corner.pos == c.pos:
			return ab
		else:
			return null

class Chunk:
	var vertices: Array[Vertex]
	var edges: Array[Edge]
	var triangles: Array[Triangle]
	var borders: Rect2
	var x: int
	var y: int
	
	func _init(chunk_x, chunk_y, chunk_borders):
		self.x = chunk_x
		self.y = chunk_y
		self.borders = chunk_borders
		# TODO: generate web chunk

# ==== PUBLIC VARIABLES =====
var vertices: Array[Vertex]
var edges: Array[Edge]
var triangles: Array[Triangle]
var chunks: Array[Chunk]

# ==== CONSTRUCTOR =====
func _init():
	pass

# ==== PUBLIC FUNCTIONS ====

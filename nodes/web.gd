extends Node2D

const CHUNK_WIDTH = 64
const CHUNK_HEIGHT = 64

@export var noise_scale = 0.1
@export var point_variation = 0.4
@export var view_scale = 10

var noise: FastNoiseLite
var rng: RandomNumberGenerator
var web: Array
var points:Array[Vector2]
var point_resource: Resource = preload("res://nodes/point.tscn")
var seed:int = 0

func _init():
	noise = FastNoiseLite.new()
	rng = RandomNumberGenerator.new()
	
	web = []
	for i in CHUNK_WIDTH*CHUNK_HEIGHT:
		var p = point_resource.instantiate()
		p.id = i
		@warning_ignore("integer_division")
		p.position = Vector2(i%CHUNK_WIDTH, i/CHUNK_HEIGHT)
		p.position += Vector2(rng.randf()*point_variation, rng.randf()*point_variation)
		web.append(p)
		points.append(p.position)
	

func _draw():
	var triangle_indices = Geometry2D.triangulate_delaunay(points)
	#print(triangle_indices)
	var queue:Array[Vector2] = []
	for i in triangle_indices.size():
		queue.append(points[triangle_indices[i]]*view_scale)
		if i%3 != 2:
			continue
		var triangle = PackedVector2Array(queue.duplicate())
		queue = []
		draw_colored_polygon(triangle, Color(randf(), randf(), randf()))
	for point:Node2D in web:
		draw_circle(point.position*view_scale, 2, Color.RED)

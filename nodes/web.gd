extends Node2D

const WIDTH = 1152
const HEIGHT = 648

@export var noise_scale = 0.1
@export var point_variation = 0.4

var x_axis_points = 23
var y_axis_points = 12
var units_per_x = (WIDTH/x_axis_points)
var units_per_y = (HEIGHT/y_axis_points)
@warning_ignore("integer_division")
var count = x_axis_points*y_axis_points

var noise: FastNoiseLite
var rng: RandomNumberGenerator
var web: Array
var point_resource: Resource = preload("res://nodes/point.tscn")
var seed:int = 0

func _init():
	noise = FastNoiseLite.new()
	rng = RandomNumberGenerator.new()
	#noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	
	web = []
	for i in count:
		var p = point_resource.instantiate()
		p.id = i
		@warning_ignore("integer_division")
		p.position = Vector2((i%x_axis_points)*units_per_x, (i/x_axis_points)*units_per_y)
		web.append(p)

func _draw():
	for point:Node2D in web:
		@warning_ignore("integer_division")
		rng.randf()
		var pos = point.position
		pos += Vector2(rng.randf()*point_variation*units_per_x, rng.randf()*point_variation*units_per_y)
		var value = noise.get_noise_2dv(pos*noise_scale)
		draw_circle(pos, 40, Color(value,0,1-value))
		# Compare to neighbours and only draw if greatest of neighbours
		print(value)

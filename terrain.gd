extends Node2D

const WIDTH = 1152
const HEIGHT = 648

var world_width = 1152
var world_height = 648
var scalar = 4
var count = (world_width*world_height)/scalar

var noise: FastNoiseLite
var web: Array
var point_resource: Resource = preload("res://point.tscn")

func _init():
	noise = FastNoiseLite.new()
	web = []
	for i in count:
		var p = point_resource.instantiate()
		p.id = i
		@warning_ignore("integer_division")
		p.position = Vector2((i*scalar)%world_width, (i*scalar)/world_width)
		web.append(p)

func _draw():
	draw_rect(Rect2(0,0,WIDTH,HEIGHT), Color.WHITE)
	
	for point:Node2D in web:
		draw_circle(point.position, 2, Color(noise.get_noise_2dv(point.position)*3,0,0))

extends Node2D

const WIDTH = 1152
const HEIGHT = 648

@export var noise_scale = 0.1

var web_width = 115
var web_height = 64
@warning_ignore("integer_division")
var count = web_width*web_height

var noise: FastNoiseLite
var web: Array
var point_resource: Resource = preload("res://point.tscn")

func _init():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	web = []
	for i in count:
		var p = point_resource.instantiate()
		p.id = i
		@warning_ignore("integer_division")
		p.position = Vector2((i%web_width)*(WIDTH/web_width), (i/web_width)*(HEIGHT/web_height))
		web.append(p)

func _draw():
	$"../Polygon2D".texture = ImageTexture.create_from_image(noise.get_image(WIDTH, HEIGHT))
	for point:Node2D in web:
		@warning_ignore("integer_division")
		draw_circle(point.position, 2, Color(1,0,0))

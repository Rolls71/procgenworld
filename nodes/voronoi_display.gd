extends Node2D

@export var random_seed:int

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func display_points(offset:Vector2, points:Array[Vector2], color:Color = Color(1,1,1,1)):
	for point in points:
		var point_polygon = Polygon2D.new()
		point_polygon.position = point + offset
		point_polygon.polygon = Array([Vector2(-2,-2), Vector2(-2,2), Vector2(2,2), Vector2(2,-2)])
		point_polygon.color = color
		add_child(point_polygon)
	pass

func display_polygon(offset:Vector2, polygon:Array[Vector2]):
	var new_polygon = Polygon2D.new()
	var polygon_points: Array[Vector2] = []
	for point in polygon:
		polygon_points.append(point + offset)
	new_polygon.polygon = polygon_points
	var rand_gen = RandomNumberGenerator.new()
	rand_gen.seed = random_seed
	new_polygon.color = Color(rand_gen.randf(), rand_gen.randf(), rand_gen.randf(), 1)
	random_seed = rand_gen.randi()
	add_child(new_polygon)
	pass
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

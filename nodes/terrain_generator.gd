extends Node2D

const CHUNK_WIDTH = 8
const CHUNK_HEIGHT = 8
const STEP_TIME = 0.01
const STEP_TIMER = false

@export var point_variance = 0.4
@export var view_scale = 80

signal terrain_generation_complete

var tileNode = preload("res://nodes/tile.tscn")
var structure_layer = preload("res://nodes/terrain_generator.tscn")

@onready var rng:RandomNumberGenerator = RandomNumberGenerator.new()
@onready var delaunay:Delaunay = Delaunay.new(Rect2(0,0,CHUNK_WIDTH,CHUNK_HEIGHT))
var tiles:Array[Tile]
var triangulation:Array[Delaunay.Triangle]
var posDict = {}
var start_time
var last_time

func _ready():	
	start_time = Time.get_ticks_msec()
	last_time = start_time
	
	print("Start generating terrain")
	for x in CHUNK_WIDTH:
		for y in CHUNK_HEIGHT:
			var t:Tile = tileNode.instantiate()
			var pos = Vector2(
				x+rng.randf()*point_variance,
				y+rng.randf()*point_variance)
			@warning_ignore("integer_division")
			t.construct(x%CHUNK_WIDTH+y/CHUNK_HEIGHT, pos)
			delaunay.add_point(pos)
			tiles.append(t)
			posDict[pos] = [t]
			
	time_check("Instantiated tiles")
	
	triangulation = delaunay.triangulate()
	time_check("Calculated Delaunay triangulation")
	
	var sites:Array[Delaunay.VoronoiSite] = delaunay.make_voronoi(triangulation)
	
	time_check("Generated Voronoi sites")
	
	## Link voronoi sites and tiles
	for site in sites:
		if posDict.has(site.center):
			posDict[site.center].append(site)
			posDict[site.center][0].site = site
	for key in posDict:
		var tile:Tile = posDict[key][0]
		var edges:Array[Delaunay.VoronoiEdge] = posDict[key][1].neighbours
		for edge in edges:
			var site:Delaunay.VoronoiSite = edge.other
			if not tile.test_adjacency(site.center):
				tile.neighbours.append(posDict[site.center][0])
	time_check("Linked tiles")
	
	## Set tiles
	var remaining = tiles.duplicate()
	while remaining.size() > 0:
		var tile = remaining.pop_at(randi()%remaining.size())
		var set_tiles = []
		for neighbour in tile.neighbours:
			if neighbour.terrain_type:
				set_tiles.append(neighbour)
		if set_tiles.size() > 0:
			show_site(tile.collapse_to(set_tiles.pick_random().terrain_type))
		else:
			show_site(tile.collapse())
			
		if STEP_TIMER:
			await get_tree().create_timer(STEP_TIME).timeout
	time_check("Displayed sites")
	
	print("Finished generating terrain in ", (last_time-start_time)/1000.0, " secs")
	emit_signal("terrain_generation_complete")
	
		
func show_site(tile:Tile):
	var site = tile.site
	var triangles:Array[Delaunay.Triangle] = site.source_triangles
	for triangle in triangles:
		if delaunay.is_border_triangle(triangle):
			continue
		var polygon = Polygon2D.new()
		var arr = []
		arr.append(triangle.a)
		arr.append(triangle.b)
		arr.append(triangle.c)
		arr.append(triangle.a)
		var packed = PackedVector2Array(arr)
		
		var temp = []
		for each in packed:
			temp.append(each*view_scale)
		polygon.polygon = temp
		polygon.color = tile.terrain_type.colour
		polygon.z_index = -1
		add_child(polygon)

func time_check(msg):
	var t = Time.get_ticks_msec()
	print(msg," in ", (t-last_time)/1000.0, " secs")
	last_time = t

extends Node2D

const CHUNK_WIDTH = 16
const CHUNK_HEIGHT = 16
const STEP_TIME = 0.5
const STEP_TIMER = false

@export var point_variance = 0.4
@export var view_scale = 30

signal terrain_generation_complete

var tileNode = preload("res://nodes/tile.tscn")
var structure_layer = preload("res://nodes/terrain_generator.tscn")

@onready var rng:RandomNumberGenerator = RandomNumberGenerator.new()
@onready var delaunay:Delaunay = Delaunay.new(Rect2(0,0,CHUNK_WIDTH,CHUNK_HEIGHT))
var tiles:Array[Tile]
var posDict = {}

func _ready():	
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
	var sites:Array[Delaunay.VoronoiSite] = delaunay.make_voronoi(delaunay.triangulate())
	
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
	
	print("Finished generating terrain!")
	emit_signal("terrain_generation_complete")
		
func show_site(tile:Tile):
	var site = tile.site
	var polygon = Polygon2D.new()
	var p = site.polygon
	p.append(p[0])
	var temp = []
	for each in p:
		temp.append(each*view_scale)
	polygon.polygon = temp
	polygon.color = tile.terrain_type.colour
	polygon.z_index = -1
	add_child(polygon)

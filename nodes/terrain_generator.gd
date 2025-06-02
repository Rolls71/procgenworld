extends Node2D

const CHUNK_WIDTH = 16
const CHUNK_HEIGHT = 16

const Delaunay = preload("res://addons/gdDelaunay/Delaunay.gd")

@export var point_variance = 0.4
@export var view_scale = 100

var tile = preload("res://nodes/tile.tscn")

var rng:RandomNumberGenerator
var delaunay:Delaunay
var tiles:Array[Tile]
var posDict = {}

func _ready():
	rng = RandomNumberGenerator.new()
	delaunay = Delaunay.new(Rect2(0,0,CHUNK_WIDTH,CHUNK_HEIGHT))
	
	for x in CHUNK_WIDTH:
		for y in CHUNK_HEIGHT:
			var t:Tile = tile.instantiate()
			var pos = Vector2(
				x+rng.randf()*point_variance,
				y+rng.randf()*point_variance)
			t.construct(x%CHUNK_WIDTH+y/CHUNK_HEIGHT, pos)
			delaunay.add_point(pos)
			tiles.append(t)
			posDict[pos] = [t]
	var sites:Array[Delaunay.VoronoiSite] = delaunay.make_voronoi(delaunay.triangulate())
	
	## Link voronoi sites and tiles
	for i in sites.size():
		var site = sites[i]
		show_site(site)
		if posDict.has(site.center):
			posDict[site.center].append(site)
	for key in posDict:
		var tile:Tile = posDict[key][0]
		var edges:Array[Delaunay.VoronoiEdge] = posDict[key][1].neighbours
		for edge in edges:
			var site:Delaunay.VoronoiSite = edge.other
			if not tile.test_adjacency(site.center):
				tile.neighbours.append(posDict[site.center][0])


func show_site(site: Delaunay.VoronoiSite):
	var polygon = Polygon2D.new()
	var p = site.polygon
	p.append(p[0])
	var temp = []
	for each in p:
		temp.append(each*view_scale)
	polygon.polygon = temp
	polygon.color = Color(randf_range(0,1),randf_range(0,1),randf_range(0,1),0.5)
	polygon.z_index = -1
	add_child(polygon)

extends Node2D

const CHUNK_WIDTH = 16
const CHUNK_HEIGHT = 16

@export var point_variance = 0.4
@export var view_scale = 100

var rng:RandomNumberGenerator
var delaunay:Delaunay

func _ready():
	rng = RandomNumberGenerator.new()
	delaunay = Delaunay.new(Rect2(0,0,CHUNK_WIDTH,CHUNK_HEIGHT))
	
	for x in CHUNK_WIDTH:
		for y in CHUNK_HEIGHT:
			delaunay.add_point(Vector2(
				x+rng.randf()*point_variance,
				y+rng.randf()*point_variance))
	var sites = delaunay.make_voronoi(delaunay.triangulate())
	for site in sites:
		show_site(site)
		
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

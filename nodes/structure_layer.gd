extends Node2D

const TOWER_COUNT = 5

var tower = preload("res://nodes/tower.tscn")
var tileNode = preload("res://nodes/tile.tscn")

@onready var terrain = get_parent()
@onready var tiles:Array[Tile] = terrain.tiles


func _on_terrain_generation_complete():
	for each in TOWER_COUNT:
		var t = tower.instantiate()
		t.position = tiles.pick_random().position*30
		add_child(t)
		print(t.position)

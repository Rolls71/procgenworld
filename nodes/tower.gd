extends Node2D

func _draw():
	draw_circle(Vector2.ZERO, 10, Color.DIM_GRAY)
	draw_rect(Rect2(3, 0, 15.0,4.0),Color(0.1,0.1,0.1))

func _physics_process(delta):
	rotate(delta*PI)
	queue_redraw()

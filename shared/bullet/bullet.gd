extends RigidBody3D

var speed = 1
var time_elapsed: float = 0

func _physics_process(delta):
	time_elapsed += delta
	
	if time_elapsed > 30:
		queue_free()

func _on_Bullet_body_entered(body):
	if body.is_in_group("mobs"):
		body.queue_free()
	queue_free()

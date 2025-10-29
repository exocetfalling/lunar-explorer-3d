extends Spacecraft


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var hp = 500


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if hp <= 0:
		var e = explosion_scene.instantiate()
		owner.add_child(e)
		e.transform = self.global_transform
		queue_free()

func on_hit(damage):
	hp -= damage
	print("HP")
	print(hp)

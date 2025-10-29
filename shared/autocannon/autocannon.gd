class_name Autocannon
extends Node3D

var active: bool = false

var bullet = preload("res://shared/bullet/bullet.tscn")

@export var fire_rate = 5

var time_elapsed: float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if active:
		time_elapsed += delta
		
		if time_elapsed >= 1.0 / fire_rate:
			var b = bullet.instantiate()
			get_parent().get_parent().add_child(b)
			#print_tree_pretty()
			b.transform = self.global_transform
			b.linear_velocity = get_parent().linear_velocity + 200 * b.global_basis
			time_elapsed = 0
	
	active = false

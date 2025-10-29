@tool

class_name Laser
extends Node3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
@onready var raycast = $RayCast3D
var object
var hit_point: Vector3

var active: bool = false
var has_method: bool = false

var beam_material_blue = load("res://shared/laser/laser_blue.tres")
var beam_material_green = load("res://shared/laser/laser_green.tres")
var beam_material_orange = load("res://shared/laser/laser_orange.tres")
var beam_material_purple = load("res://shared/laser/laser_purple.tres")
var beam_material_red = load("res://shared/laser/laser_red.tres")

@export_enum("Blue", "Green", "Orange", "Purple", "Red") var laser_colour: int

# Called when the node enters the scene tree for the first time.
func _ready():
#	DebugOverlay.stats.add_property(self, "object", "")
#	DebugOverlay.stats.add_property(self, "has_method", "")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if laser_colour == 0:
		$Beam.material = beam_material_blue
	if laser_colour == 1:
		$Beam.material = beam_material_green
	if laser_colour == 2:
		$Beam.material = beam_material_orange
	if laser_colour == 3:
		$Beam.material = beam_material_purple
	if laser_colour == 4:
		$Beam.material = beam_material_red
	
	
	if active == true:
		raycast.enabled = true
		$Beam.visible = true
	else:
		raycast.enabled = false
		$Beam.visible = false
	
	raycast.force_raycast_update()
	
	object = raycast.get_collider()
	hit_point = raycast.get_collision_point()
	
	if object != null and active == true:
		$Beam.height = hit_point.distance_to(self.global_transform.origin) * 1
		$ImpactPoint.position.z = -hit_point.distance_to(self.global_transform.origin)
		$ImpactPoint.visible = true
		
		if object.has_method("on_hit"):
			has_method = true
			object.on_hit(50 * delta)
	else:
		$Beam.height = 20000
		$ImpactPoint.visible = false
		$ImpactPoint.position.z = 0
	
	$Beam.position.z = -$Beam.height / 2
	
	active = false
	

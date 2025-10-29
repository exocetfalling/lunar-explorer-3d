extends Node3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var fx_intensity: float = 1
var time_elapsed: float = 0
var has_peaked: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func calc_fx_intensity(vec_rcs_commands):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if fx_intensity > 0:
		$GPUParticles3D.scale = Vector3.ONE * fx_intensity
		$OmniLight3D.light_energy = fx_intensity
	else:
		$GPUParticles3D.scale = Vector3.ONE * 0.000001
		$OmniLight3D.light_energy = 0
	
	time_elapsed += delta
	
	fx_intensity = sin(time_elapsed) * 5
	
	if time_elapsed > PI:
		queue_free()

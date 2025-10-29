extends Node3D

class_name EngineEffect

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var fx_intensity: float = 0
var vec_result: Vector3 = Vector3.ZERO
@export var rcs_rotation_scalars: Vector3 = Vector3.ZERO
@export var rcs_translation_scalars: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func calc_fx_intensity(cmd_rotate, cmd_translate):
	vec_result = cmd_rotate * rcs_rotation_scalars + cmd_translate * rcs_translation_scalars
	#fx_intensity = 2 * clamp((vec_result.x + vec_result.y + vec_result.z), 0, 1)
	fx_intensity = lerp(fx_intensity, 2 * float(clamp((vec_result.x + vec_result.y + vec_result.z), 0, 1)), 0.05)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if fx_intensity > 0.1:
		$GPUParticles3D.visible = true
		$GPUParticles3D.scale = Vector3.ONE * fx_intensity
		$OmniLight3D.light_energy = 2 * fx_intensity
		$SpotLight3D.light_energy = 2 * fx_intensity
	else:
		$GPUParticles3D.visible = false
		$GPUParticles3D.scale = Vector3.ONE
		$OmniLight3D.light_energy = 0
		$SpotLight3D.light_energy = 0

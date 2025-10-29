extends RigidBody3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var control_type: int = 1

var cmd_rotate: Vector3 = Vector3.ZERO
var cmd_translate: Vector3 = Vector3.ZERO

var thruster_max_force: float = 200

#var dbg_color 

func add_force_local(force: Vector3, pos: Vector3):
	var force_local
	var pos_local
	
	pos_local = self.transform.basis * (pos)
	force_local = self.transform.basis * (force)
	self.apply_force(pos_local, force_local)

func add_torque_local(torque: Vector3):
	var torque_local

	torque_local = self.transform.basis * (torque)
	self.apply_torque(torque_local)

# Called when the node enters the scene tree for the first time.
func _ready():
	DebugOverlay.stats.add_property(self, "cmd_rotate", "round")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta): 
#	angular_velocity_local = (angular_velocity)
	if (control_type == 1):
		get_input(delta)
		
		add_torque_local(cmd_rotate * 100)

func get_input(delta):
	# Check if aircraft is under player control
	if (control_type == 1):
		cmd_rotate.x = Input.get_axis("rcs_pitch_down", "rcs_pitch_up")
		cmd_rotate.y = Input.get_axis("rcs_yaw_right", "rcs_yaw_left")
		cmd_rotate.z = Input.get_axis("rcs_roll_right", "rcs_roll_left")
	
#	dbg_color = $EngineEffect/Particles.color

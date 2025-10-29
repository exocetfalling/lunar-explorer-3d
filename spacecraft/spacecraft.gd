class_name Spacecraft
extends RigidBody3D
 
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
@export_enum("None", "Player", "AI") var control_type: int
@export_enum("None", "SAS", "Full") var flight_assist_mode: int
@export_enum("Alpha", "Bravo", "Charlie", "Delta") var team: int

# AI FSM setup
#var ai_state: int
#enum States {IDLE, SEARCH, TRACK, CHASE, ENGAGE}
@export_enum("Idle", "Search", "Chase", "Attack", "Evade") var ai_state: int

# Rotation and translation commands
var cmd_rotate: Vector3 = Vector3.ZERO
var cmd_translate: Vector3 = Vector3.ZERO

var input_rotate: Vector3 = Vector3.ZERO
var input_translate: Vector3 = Vector3.ZERO

@export var rcs_max_torque: Vector3 = Vector3(20000, 20000, 20000)
@export var rcs_max_thrust: Vector3 = Vector3(20000, 20000, 20000)
@export var eng_max_torque: Vector3 = Vector3(0, 0, 0)
@export var fwd_max_thrust: float = 40000
@export var aft_max_thrust: float = 0

var linear_velocity_local: Vector3 = Vector3.ZERO

var angular_velocity_local: Vector3 = Vector3.ZERO
var angular_velocity_local_deg: Vector3 = Vector3.ZERO
var angular_velocity_deg: Vector3 = Vector3.ZERO

var rotation_degrees_local: Vector3 = Vector3.ZERO

var bogey_array: Array = []
var hostile_array: Array = []

var target: RigidBody3D
var target_polar_coords_pred: Vector3 = Vector3.ZERO
var target_polar_coords_curr: Vector3 = Vector3.ZERO
var target_pos_pred: Vector3 = Vector3.ZERO


var attack_timer_curr: float = 0
var attack_timer_max: float = 30

var evasion_vec: Vector3 = Vector3.ZERO
var evasion_timer_curr: float = 0
var evasion_timer_max: float = 0
var evasion_iter_curr: float = 1
var evasion_iter_max: float = 2
var evasion_phase: int = 1

@export var weapon_vel: float = 299792458

@export var speed_limit: float = 1000

@export_enum("None", "Cockpit", "External") var cameras_active: int

var shield_pts: float = 100
var shield_pts_regen: float = 5
var hull_pts: float = 100
var hull_pts_regen: float = 1

var explosion_scene = preload("res://shared/explosion/explosion.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	#DebugOverlay.stats.add_property(self, "cmd_rotate", "round")
	#DebugOverlay.stats.add_property(self, "cmd_translate", "round")
	#DebugOverlay.stats.add_property(self, "input_rotate", "round")
	#DebugOverlay.stats.add_property(self, "input_translate", "round")
	#DebugOverlay.stats.add_property(self, "linear_velocity", "")
	#DebugOverlay.stats.add_property(self, "linear_velocity_local", "")
	#DebugOverlay.stats.add_property(self, "angular_velocity", "")
	#DebugOverlay.stats.add_property(self, "angular_velocity_local", "")
	#DebugOverlay.stats.add_property(self, "target_polar_coords", "round")
	#DebugOverlay.stats.add_property(self, "angular_velocity_local_deg", "round")
	#DebugOverlay.stats.add_property(self, "rotation_degrees_local", "round")
	#DebugOverlay.stats.add_property(self, "ai_state", "round")
	#DebugOverlay.stats.add_property(self, "evasion_time_curr", "round")
	#DebugOverlay.stats.add_property(self, "evasion_time_max", "round")
	#DebugOverlay.stats.add_property(self, "evasion_phase", "round")
	#DebugOverlay.stats.add_property(self, "hull_pts", "round")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# VFX
	for child in get_children():
		if child is RCSEffect or child is EngineEffect:
			child.calc_fx_intensity(cmd_rotate, cmd_translate)
	
	if cameras_active == 0:
		$CameraFPV.current = false
		$CameraExt.current = false
		$HUD.visible = false
	if cameras_active == 1:
		$CameraFPV.current = true
		$CameraExt.current = false
		$HUD.visible = true
	if cameras_active == 2:
		$CameraFPV.current = false
		$CameraExt.current = true
		$HUD.visible = true


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if is_instance_valid(target):
		target_pos_pred = target.global_position + target.linear_velocity \
			* to_local(target.global_position).length() / weapon_vel
		target_polar_coords_curr = find_angles_and_distance_to_target(target.global_position)
		target_polar_coords_pred = find_angles_and_distance_to_target(target_pos_pred)
	else:
		target_pos_pred = Vector3.ZERO
		target_polar_coords_curr = find_angles_and_distance_to_target(Vector3.ZERO)
		target_polar_coords_pred = find_angles_and_distance_to_target(Vector3.ZERO)
		ai_state = 1
	
	linear_velocity_local = linear_velocity * global_basis
	
	angular_velocity_local = angular_velocity * global_basis
	
	angular_velocity_local_deg.x = rad_to_deg(angular_velocity_local.x)
	angular_velocity_local_deg.y = rad_to_deg(angular_velocity_local.y)
	angular_velocity_local_deg.z = rad_to_deg(angular_velocity_local.z)
	
	if (control_type == 1):
		get_input(delta)
	if (control_type == 2):
		# FSM states
		# Idle
		if ai_state == 0:
			cmd_rotate.x = $PIDControllerRX.calc_PID_output(\
			input_rotate.x * 2 * PI, \
			angular_velocity_local.x
			)
			cmd_rotate.y = $PIDControllerRY.calc_PID_output(\
			input_rotate.y * 2 * PI, \
			angular_velocity_local.y
			)
			cmd_rotate.z = $PIDControllerRZ.calc_PID_output(\
			input_rotate.z * 2 * PI, \
			angular_velocity_local.z
			)
			
			cmd_translate.x = $PIDControllerTX.calc_PID_output(\
			input_translate.x * speed_limit, \
			linear_velocity_local.x
			)
			cmd_translate.y = $PIDControllerTY.calc_PID_output(\
			input_translate.y * speed_limit, \
			linear_velocity_local.y
			)
			cmd_translate.z = $PIDControllerTZ.calc_PID_output(\
			input_translate.z * speed_limit, \
			linear_velocity_local.z
			)
		# Search
		if ai_state == 1:
			# Control
			cmd_rotate.x = $PIDControllerRX.calc_PID_output(\
			input_rotate.x * 2 * PI, \
			angular_velocity_local.x
			)
			cmd_rotate.y = $PIDControllerRY.calc_PID_output(\
			input_rotate.y * 2 * PI, \
			angular_velocity_local.y
			)
			cmd_rotate.z = $PIDControllerRZ.calc_PID_output(\
			input_rotate.z * 2 * PI, \
			angular_velocity_local.z
			)
			
			cmd_translate.x = $PIDControllerTX.calc_PID_output(\
			input_translate.x * speed_limit, \
			linear_velocity_local.x
			)
			cmd_translate.y = $PIDControllerTY.calc_PID_output(\
			input_translate.y * speed_limit, \
			linear_velocity_local.y
			)
			cmd_translate.z = $PIDControllerTZ.calc_PID_output(\
			input_translate.z * speed_limit, \
			linear_velocity_local.z
			)
			
			bogey_array.clear()
			hostile_array.clear()
			for body in $ScanArea.get_overlapping_bodies():
				if body is Spacecraft:
					bogey_array.append(body)
					if body.team != self.team:
						hostile_array.append(body)
			#print(hostile_array)
			bogey_array.sort_custom(sort_targets_by_dist)
			hostile_array.sort_custom(sort_targets_by_dist)
			
			if hostile_array.size() > 0:
				target = hostile_array[0]
				ai_state = 3
			else:
				ai_state = 1
		# Chase
		if ai_state == 2:
			pass
		# Attack
		if ai_state == 3:
			#attack_timer_curr += delta
			#
			#if attack_timer_curr > attack_timer_max:
				#attack_timer_curr = 0
				#ai_state = 4
			
			cmd_rotate.x = $PIDControllerAX.calc_PID_output(\
			input_rotate.x * 2 * PI, \
			target_polar_coords_pred.x
			)
			cmd_rotate.y = $PIDControllerAY.calc_PID_output(\
			input_rotate.y * 2 * PI, \
			target_polar_coords_pred.y
			)
			cmd_rotate.z = $PIDControllerAZ.calc_PID_output(\
			0, \
			angular_velocity_local.z
			)
			
			cmd_translate.x = $PIDControllerPX.calc_PID_output(\
			clamp(to_local(target_pos_pred).x, -speed_limit, speed_limit), \
			linear_velocity_local.x
			)
			cmd_translate.y = $PIDControllerPY.calc_PID_output(\
			clamp(to_local(target_pos_pred).y, -speed_limit, speed_limit), \
			linear_velocity_local.y
			)
			cmd_translate.z = $PIDControllerPZ.calc_PID_output(\
			clamp(to_local(target_pos_pred).z, -speed_limit, speed_limit), \
			linear_velocity_local.z
			)
			
			if sqrt(abs(pow(target_polar_coords_pred.x, 2) + pow(target_polar_coords_pred.y, 2))) < 0.2:
				shoot_weapon_pri()
				evasion_iter_curr = 1
				attack_timer_curr = 0
				target.target = self
			
			# Collision prevention
			if is_instance_valid(target):
				if to_local(target.global_position).length() < 20 + (target.linear_velocity - linear_velocity).length():
					cmd_translate = -1 * to_local(target.global_position).normalized()
					pass
		
		# Evade
		if ai_state == 4:
			evasion_timer_curr += delta
			#print(var_to_str(evasion_timer_curr))
			#print(var_to_str(evasion_timer_max))
			
			cmd_rotate.x = $PIDControllerAX.calc_PID_output(\
			evasion_vec.x * 2 * PI, \
			angular_velocity_local.x
			)
			cmd_rotate.y = $PIDControllerAY.calc_PID_output(\
			evasion_vec.y * 2 * PI, \
			angular_velocity_local.y
			)
			cmd_rotate.z = $PIDControllerAZ.calc_PID_output(\
			evasion_vec.z * 0.5 * PI, \
			angular_velocity_local.z
			)
			
			cmd_translate.x = $PIDControllerPX.calc_PID_output(\
			evasion_vec.x * speed_limit, \
			linear_velocity_local.x
			)
			cmd_translate.y = $PIDControllerPY.calc_PID_output(\
			evasion_vec.y * speed_limit, \
			linear_velocity_local.y
			)
			cmd_translate.z = $PIDControllerPZ.calc_PID_output(\
			-speed_limit, \
			linear_velocity_local.z
			)
			
			if evasion_timer_curr >= evasion_timer_max:
				evasion_timer_curr = 0
				evasion_timer_max = randf_range(0.25, 1)
				
				if evasion_phase == 0:
					evasion_iter_curr += 1
					evasion_phase = 1
					evasion_vec = Vector3.ZERO
				elif evasion_phase == 1:
					evasion_phase = 0
					evasion_vec.x = randf_range(-1, 1)
					evasion_vec.y = randf_range(-1, 1)
					evasion_vec.z = randf_range(-1, 1)
				
				ai_state = 3
	
	# Apply forces
	apply_torque_local((rcs_max_torque + eng_max_torque) * cmd_rotate)
	apply_force_local(rcs_max_thrust * cmd_translate, Vector3.ZERO)

#		Engine force
	if cmd_translate.z < 0:
		apply_force_local(fwd_max_thrust * cmd_translate, Vector3.ZERO)
	if cmd_translate.z > 0:
		apply_force_local(aft_max_thrust * cmd_translate, Vector3.ZERO)
	
	# Shield/hull
	if shield_pts < 100:
		shield_pts += shield_pts_regen * delta
	if hull_pts < 100:
		hull_pts += hull_pts_regen * delta
	
	if hull_pts < 0:
		var e = explosion_scene.instantiate()
		owner.add_child(e)
		e.transform = self.global_transform
		queue_free()



func get_input(delta):
	# Check if craft is under player control
	if control_type == 1:
		input_rotate.x = Input.get_axis("rcs_pitch_down", "rcs_pitch_up")
		input_rotate.y = Input.get_axis("rcs_yaw_right", "rcs_yaw_left")
		input_rotate.z = Input.get_axis("rcs_roll_right", "rcs_roll_left")
		
		input_translate.x = Input.get_axis("rcs_trans_left", "rcs_trans_right")
		input_translate.y = Input.get_axis("rcs_trans_down", "rcs_trans_up")
		input_translate.z = Input.get_axis("rcs_trans_fwd", "rcs_trans_aft")
		
		if flight_assist_mode == 0:
			cmd_rotate = input_rotate
			cmd_translate = input_translate
		
		if flight_assist_mode == 1:
			cmd_rotate.x = $PIDControllerRX.calc_PID_output(\
			input_rotate.x * 2 * PI, \
			angular_velocity_local.x
			)
			cmd_rotate.y = $PIDControllerRY.calc_PID_output(\
			input_rotate.y * 2 * PI, \
			angular_velocity_local.y
			)
			cmd_rotate.z = $PIDControllerRZ.calc_PID_output(\
			input_rotate.z * 2 * PI, \
			angular_velocity_local.z
			)
			
			cmd_translate = input_translate
		
		if flight_assist_mode == 2:
			cmd_rotate.x = $PIDControllerRX.calc_PID_output(\
			input_rotate.x * 2 * PI, \
			angular_velocity_local.x
			)
			cmd_rotate.y = $PIDControllerRY.calc_PID_output(\
			input_rotate.y * 2 * PI, \
			angular_velocity_local.y
			)
			cmd_rotate.z = $PIDControllerRZ.calc_PID_output(\
			input_rotate.z * 2 * PI, \
			angular_velocity_local.z
			)
			
			cmd_translate.x = $PIDControllerTX.calc_PID_output(\
			input_translate.x * speed_limit, \
			linear_velocity_local.x
			)
			cmd_translate.y = $PIDControllerTY.calc_PID_output(\
			input_translate.y * speed_limit, \
			linear_velocity_local.y
			)
			cmd_translate.z = $PIDControllerTZ.calc_PID_output(\
			input_translate.z * speed_limit, \
			linear_velocity_local.z
			)
			
		if Input.is_action_pressed("weapon_pri_fire"):
			shoot_weapon_pri()
		
		if Input.is_action_just_pressed("camera_toggle"):
			if get_node_or_null("CameraExt") and get_node_or_null("CameraFPV"):
				if $CameraExt.current == true:
					$CameraFPV.current = true
				else:
					$CameraExt.current = true


func shoot_weapon_pri():
	for child in get_children():
		if child is Laser or child is Autocannon:
			child.active = true


func apply_force_local(force_local: Vector3, pos_local: Vector3):
	var force_global: Vector3
	var pos_global: Vector3
	
	force_global = self.global_basis * (force_local)
	pos_global = self.global_basis * (pos_local)
	
	self.apply_force(force_global, pos_global)


func apply_torque_local(torque: Vector3):
	var torque_local

	torque_local = self.transform.basis * (torque)
	self.apply_torque(torque_local)


func find_angles_and_distance_to_target(vec_pos_target):
	var vec_delta_local = to_local(vec_pos_target)
	var pitch_to = -rad_to_deg(atan2(vec_delta_local.y, -vec_delta_local.z))
	var yaw_to = rad_to_deg(atan2(vec_delta_local.x, -vec_delta_local.z))
	var range_to = vec_delta_local.length()
	
	return Vector3(pitch_to, yaw_to, range_to)

func on_hit(damage):
	# Reduce shield/hull
	if shield_pts > 0:
		shield_pts -= damage
	else:
		shield_pts = 0
		hull_pts -= damage
	
	# AI should evade if hit, if not already evaded
	if control_type == 2 and evasion_iter_curr <= evasion_iter_max:
		ai_state = 4


func sort_targets_by_dist(target_1, target_2):
	if (target_1.global_position - global_position).length() > (target_2.global_position - global_position).length():
		return true
	else:
		return false

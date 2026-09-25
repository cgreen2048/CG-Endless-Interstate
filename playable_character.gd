extends CharacterBody3D

# adds properties to inspector in script
# use to turn car tires
@export var frontLeftWheel: Node3D
@export var frontRightWheel: Node3D

@export var frWheelRay: RayCast3D
@export var flWheelRay: RayCast3D
@export var blWheelRay: RayCast3D
@export var brWheelRay: RayCast3D
@export var carRay: RayCast3D

@export var leftBrakeLight: SpotLight3D
@export var rightBrakeLight: SpotLight3D
@export var leftBrakeLightNode: CSGCylinder3D
@export var rightBrakeLightNode: CSGCylinder3D

@export var leftHeadLight: SpotLight3D
@export var rightHeadLight: SpotLight3D
@export var leftHeadLightNode: CSGCylinder3D
@export var rightHeadLightNode: CSGCylinder3D

@export var cameraPivot: Node3D
@export var camera: Camera3D

const MAX_SPEED = 50.0
const MAX_WHEEL_ANGLE = 3.14159265 / 6
const ACCEL = 4.0
const BRAKE_DECEL = 8.0
const FRICTION = 1.0
const WHEEL_ACCEL = 0.5
const WHEEL_RETURN_RATE = 0.4
const CAR_TURN_RATE = 1
const BACKFLIP_ACCEL = 4
const MIN_GROUND_UP_DOT = 0.5
const LANDING_ALIGNMENT_THRESHOLD = 0.866
const SURFACE_ALIGNMENT_THRESHOLD = 0.9999
const AIR_ROTATION_DELAY = 0.15

var speed : float = 0.0
var wheelAngle : float = 0.0
var flipAngle : float = 0.0
var headlights : bool = false
var movementLocked : bool = false
var wasAirborne : bool = false
var airTime : float = 0.0

func _ready() -> void:
	headlights = false
	
	leftHeadLight.visible = false
	rightHeadLight.visible = false
	(leftHeadLightNode.material as StandardMaterial3D).emission_enabled = false
	(rightHeadLightNode.material as StandardMaterial3D).emission_enabled = false
	
	leftBrakeLight.visible = false
	rightBrakeLight.visible = false
	(leftBrakeLightNode.material as StandardMaterial3D).emission_enabled = false
	(rightBrakeLightNode.material as StandardMaterial3D).emission_enabled = false
	

func _physics_process(delta: float) -> void:
	var floorNormal = get_ground_normal()
	var isAirborne = floorNormal == Vector3.ZERO
	
	if Input.is_action_just_pressed("Toggle Headlights"):
		headlights = not headlights
		leftHeadLight.visible = headlights
		rightHeadLight.visible = headlights
		(leftHeadLightNode.material as StandardMaterial3D).emission_enabled = headlights
		(rightHeadLightNode.material as StandardMaterial3D).emission_enabled = headlights
	
	var leftBrakeLightNodeMaterial = leftBrakeLightNode.material as StandardMaterial3D
	var rightBrakeLightNodeMaterial = rightBrakeLightNode.material as StandardMaterial3D
	
	var braking = Input.is_action_pressed("Brake")
	if braking:
		leftBrakeLight.visible = true
		rightBrakeLight.visible = true
		leftBrakeLight.light_energy = 5.0
		rightBrakeLight.light_energy = 5.0
		
		leftBrakeLightNodeMaterial.emission_enabled = true
		leftBrakeLightNodeMaterial.emission_energy_multiplier = 5.0
		rightBrakeLightNodeMaterial.emission_enabled = true
		rightBrakeLightNodeMaterial.emission_energy_multiplier = 5.0
	elif headlights:
		leftBrakeLight.visible = true
		rightBrakeLight.visible = true
		leftBrakeLight.light_energy = 1
		rightBrakeLight.light_energy = 1
		
		leftBrakeLightNodeMaterial.emission_enabled = true
		leftBrakeLightNodeMaterial.emission_energy_multiplier = 0.5
		rightBrakeLightNodeMaterial.emission_enabled = true
		rightBrakeLightNodeMaterial.emission_energy_multiplier = 0.5
	else:
		leftBrakeLight.visible = false
		rightBrakeLight.visible = false
		leftBrakeLightNodeMaterial.emission_enabled = false
		rightBrakeLightNodeMaterial.emission_enabled = false


	# Handle movement
	if isAirborne:
		velocity += get_gravity() * delta
		
		if not movementLocked:
			var flipAngleDelta = delta * BACKFLIP_ACCEL
			flipAngle += flipAngleDelta
			
			if Input.is_action_pressed("Move Forward"):
				rotate(basis.x.normalized(), -flipAngleDelta)
			elif Input.is_action_pressed("Move Backward"):
				rotate(basis.x.normalized(), flipAngleDelta)
			elif Input.is_action_pressed("Turn Left"):
				rotate_z(flipAngleDelta)
			elif Input.is_action_pressed("Turn Right"):
				rotate_z(-flipAngleDelta)
		
	else:
		# if on the ground but no wheels on ground, increase airTime
		# else, we should have at least one wheel on the ground
		var turningLeft = Input.is_action_pressed("Turn Left") and not movementLocked
		var turningRight = Input.is_action_pressed("Turn Right") and not movementLocked
		var movingForward = Input.is_action_pressed("Move Forward") and not movementLocked
		var movingBackward = Input.is_action_pressed("Move Backward") and not movementLocked
		

		
		var requestedDeltaAngle = 0.0
		if turningLeft:
			requestedDeltaAngle += delta * WHEEL_ACCEL
			
		if turningRight:
			requestedDeltaAngle -= delta * WHEEL_ACCEL
			
		if movingForward:
			if speed >= 0.0:
				speed += delta * ACCEL
			
		if movingBackward:
			if speed <= 0.0:
				speed -= delta * ACCEL
		
		
		var newWheelAngle = clamp(
			wheelAngle + requestedDeltaAngle,
			-MAX_WHEEL_ANGLE,
			MAX_WHEEL_ANGLE
		)
		
		var actualDeltaAngle = 0.0
		if (newWheelAngle > 0.0 and wheelAngle < 0.0) or (newWheelAngle < 0.0 and wheelAngle > 0.0):
			actualDeltaAngle = -wheelAngle
			wheelAngle = 0.0
		else:
			actualDeltaAngle = newWheelAngle - wheelAngle
			wheelAngle = newWheelAngle

		frontLeftWheel.rotate(frontLeftWheel.basis.y.normalized(), actualDeltaAngle)
		frontRightWheel.rotate(frontRightWheel.basis.y.normalized(), actualDeltaAngle)

		if speed != 0:
			var carRotation = wheelAngle * CAR_TURN_RATE * delta
			if speed > 0.0:
				rotate(basis.y.normalized(), carRotation)
			else:
				rotate(basis.y.normalized(), -carRotation)
				
			if not turningLeft and not turningRight:
				if wheelAngle > 0.0:
					actualDeltaAngle = -WHEEL_RETURN_RATE * delta
					if wheelAngle + actualDeltaAngle < 0:
						actualDeltaAngle = -wheelAngle
				else:
					actualDeltaAngle = WHEEL_RETURN_RATE * delta
					if wheelAngle + actualDeltaAngle > 0:
						actualDeltaAngle = -wheelAngle
				
				wheelAngle += actualDeltaAngle
				
				frontLeftWheel.rotate(frontLeftWheel.basis.y.normalized(), actualDeltaAngle)
				frontRightWheel.rotate(frontRightWheel.basis.y.normalized(), actualDeltaAngle)
					 
		
		if braking:
			if speed > 0.0:
				speed -= delta * BRAKE_DECEL
				if speed < 0.0:
					speed = 0.0
			elif speed < 0.0:
				speed += delta * BRAKE_DECEL
				if speed > 0.0:
					speed = 0.0
		
		if speed > 0.0:
			speed -= delta * FRICTION
			if speed < 0.0:
				speed = 0.0
		elif speed < 0.0:
			speed += delta * FRICTION
			if speed > 0.0:
				speed = 0.0
		
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		if speed < -MAX_SPEED:
			speed = -MAX_SPEED
		
		var direction := -basis.z
		direction *= speed
		direction.y = velocity.y
		velocity = direction

	move_and_slide()

	carRay.global_position = global_position

	floorNormal = get_ground_normal()

	if floorNormal == Vector3.ZERO:
		wasAirborne = true
	else:
		handle_surface_contact(floorNormal)
		wasAirborne = false
	
	cameraPivot.global_position = global_position
	if not wasAirborne:
		cameraPivot.rotation = Vector3(0.0, global_rotation.y, 0.0)

func get_ground_normal() -> Vector3:
	if not carRay.is_colliding():
		return Vector3.ZERO
	
	var normal = carRay.get_collision_normal().normalized()
	
	if normal.dot(Vector3.UP) < MIN_GROUND_UP_DOT:
		return Vector3.ZERO
		
	return normal
	

func handle_surface_contact(groundNormal: Vector3) -> void:
	if movementLocked:
		return
		
	var carUp = global_transform.basis.y.normalized()
	
	var alignment = carUp.dot(groundNormal)
	
	if wasAirborne:
		if alignment >= LANDING_ALIGNMENT_THRESHOLD:
			handle_good_landing(groundNormal)
		else:
			handle_bad_landing()
	else:
		if alignment < SURFACE_ALIGNMENT_THRESHOLD:
			align_car_to_surface(groundNormal)


func handle_good_landing(groundNormal: Vector3) -> void:
	var oldHorizontalVelo = Vector3(velocity.x, 0.0, velocity.z)
	var oldSpeed = oldHorizontalVelo.length()
	
	align_car_to_surface(groundNormal)
	
	if oldSpeed > 0.001:
		var surfaceForward = -global_transform.basis.z.normalized()
		
		velocity = surfaceForward * oldSpeed
		speed = oldSpeed


func align_car_to_surface(groundNormal: Vector3):
	var forward = -global_transform.basis.z
	
	forward = forward.slide(groundNormal).normalized()
	
	var right = forward.cross(groundNormal).normalized()
	
	global_transform.basis = Basis(
		right,
		groundNormal,
		-forward
	).orthonormalized()


func handle_bad_landing() -> void:
	if movementLocked: 
		return
		
	movementLocked = true
	
	velocity = Vector3.ZERO
	speed = 0.0
	
	await get_tree().create_timer(0.5).timeout
	
	reset_car()

func reset_car() -> void:
	var cameraForward = -camera.global_transform.basis.z
	cameraForward.y = 0.0
	
	if cameraForward.length_squared() > 0.001:
		cameraForward = cameraForward.normalized()
		look_at(global_position + cameraForward, Vector3.UP)

	velocity = Vector3.ZERO
	speed = 0.0
	
	movementLocked = false
	
func is_at_least_one_wheel_on_ground() -> bool:
	return (
		flWheelRay.is_colliding()
		or frWheelRay.is_colliding()
		or blWheelRay.is_colliding()
		or brWheelRay.is_colliding()
	)

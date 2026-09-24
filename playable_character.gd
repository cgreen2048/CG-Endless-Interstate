extends CharacterBody3D

# adds properties to inspector in script
# use to turn car tires
@export var frontLeftWheel: Node3D
@export var frontRightWheel: Node3D

@export var frWheelRay: RayCast3D
@export var flWheelRay: RayCast3D
@export var blWheelRay: RayCast3D
@export var brWheelRay: RayCast3D

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

var speed : float = 0.0
var wheelAngle : float = 0.0
var flipAngle : float = 0.0
var airTime : float = 0.0
var headlights : bool = false
var movementLocked : bool = false
var hadWheelOnGroundLastFrame : bool = false

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
	var allWheelsOnGround = are_all_wheels_on_ground()
	var atLeastOneWheelOnGround = is_at_least_one_wheel_on_ground()
	var justLanded = atLeastOneWheelOnGround and not hadWheelOnGroundLastFrame
	
	if not atLeastOneWheelOnGround:
		airTime += delta
	else:
		if justLanded and airTime > 0.2:
			reset_moving_car()
		
		airTime = 0.0

	# Add the gravity.
	if not is_on_floor():
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
		if is_touching_ground():
			if not atLeastOneWheelOnGround:
				airTime += delta
			else: 
				airTime = 0.0
		else:
			airTime = 0.0
			
		if is_touching_ground() and airTime >= 1.0 and not movementLocked:
			reset_car()
			
		var braking = Input.is_action_pressed("Brake")
		var turningLeft = Input.is_action_pressed("Turn Left")
		var turningRight = Input.is_action_pressed("Turn Right")
		var movingForward = Input.is_action_pressed("Move Forward")
		var movingBackward = Input.is_action_pressed("Move Backward")
		
		
		if Input.is_action_just_pressed("Toggle Headlights"):
			headlights = not headlights
			leftHeadLight.visible = headlights
			rightHeadLight.visible = headlights
			(leftHeadLightNode.material as StandardMaterial3D).emission_enabled = headlights
			(rightHeadLightNode.material as StandardMaterial3D).emission_enabled = headlights
		
		var leftBrakeLightNodeMaterial = leftBrakeLightNode.material as StandardMaterial3D
		var rightBrakeLightNodeMaterial = rightBrakeLightNode.material as StandardMaterial3D
		
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

		
		var requestedDeltaAngle = 0.0
		
		if allWheelsOnGround:
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
		

	
	# negative z is the default forward vector
	var direction := -basis.z
	direction *= speed
	direction.y = velocity.y
	velocity = direction
	hadWheelOnGroundLastFrame = atLeastOneWheelOnGround

	move_and_slide()
	
	cameraPivot.global_position = global_position
	cameraPivot.rotation = Vector3(0.0, global_rotation.y, 0.0)

func reset_car() -> void:
	movementLocked = true
	
	var cameraForward = -camera.global_transform.basis.z
	cameraForward.y = 0.0
	
	if cameraForward.length_squared() > 0.001:
		cameraForward = cameraForward.normalized()
		look_at(global_position + cameraForward, Vector3.UP)

	velocity = Vector3.ZERO
	speed = 0.0
	airTime = 0.0

	while true:
		var grounded = are_all_wheels_on_ground()
		var stopped = velocity.length() < 0.1

		if grounded and stopped:
			break

		await get_tree().physics_frame
	movementLocked = false
	
func reset_moving_car() -> void:
	var cameraForward = -camera.global_transform.basis.z
	cameraForward.y = 0.0
	
	if cameraForward.length_squared() > 0.001:
		cameraForward = cameraForward.normalized()
		look_at(global_position + cameraForward, Vector3.UP)

	airTime = 0.0

	while true:
		var grounded = are_all_wheels_on_ground()
		var stopped = velocity.length() < 0.1

		if grounded and stopped:
			break

		await get_tree().physics_frame
	
func is_touching_ground() -> bool:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider != null and collider.is_in_group("ground"):
			return true

	return false

func is_at_least_one_wheel_on_ground() -> bool:
	return (
		flWheelRay.is_colliding()
		or frWheelRay.is_colliding()
		or blWheelRay.is_colliding()
		or brWheelRay.is_colliding()
	)

func are_all_wheels_on_ground() -> bool:
	return (
		flWheelRay.is_colliding()
		and frWheelRay.is_colliding()
		and blWheelRay.is_colliding()
		and brWheelRay.is_colliding()
	)

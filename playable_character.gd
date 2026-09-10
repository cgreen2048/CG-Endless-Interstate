extends CharacterBody3D

# adds properties to inspector in script
# use to turn car tires
@export var frontLeftWheel : CSGBox3D
@export var frontRightWheel: CSGBox3D

@export var leftBrakeLight: SpotLight3D
@export var rightBrakeLight: SpotLight3D
@export var leftBrakeLightNode: CSGCylinder3D
@export var rightBrakeLightNode: CSGCylinder3D

@export var leftHeadLight: SpotLight3D
@export var rightHeadLight: SpotLight3D
@export var leftHeadLightNode: CSGCylinder3D
@export var rightHeadLightNode: CSGCylinder3D

const MAX_SPEED = 25.0
const MAX_WHEEL_ANGLE = 3.14159 / 6
const ACCEL = 2.0
const BRAKE_DECEL = 4.0
const FRICTION = 1.0
const ANGLE_ACCEL = 0.8
const WHEEL_ACCEL = 0.4
const CAR_TURN_RATE = 1.0

var speed : float = 0.0
var wheelAngle : float = 0.0
var headlights : bool = false

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
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_just_pressed("Toggle Headlights"):
		headlights = not headlights
		leftHeadLight.visible = headlights
		rightHeadLight.visible = headlights
		(leftHeadLightNode.material as StandardMaterial3D).emission_enabled = headlights
		(rightHeadLightNode.material as StandardMaterial3D).emission_enabled = headlights
		
	var braking = Input.is_action_pressed("Brake")
	
	leftBrakeLight.visible = braking
	rightBrakeLight.visible = braking
	(leftBrakeLightNode.material as StandardMaterial3D).emission_enabled = braking
	(rightBrakeLightNode.material as StandardMaterial3D).emission_enabled = braking
	
	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var angle = 0.0
	var deltaAngle = 0.0
	var requestedDeltaAngle = 0.0
	
	if Input.is_action_pressed("Turn Left"):
		angle += delta * ANGLE_ACCEL
		requestedDeltaAngle += delta * WHEEL_ACCEL
		
	if Input.is_action_pressed("Turn Right"):
		angle -= delta * ANGLE_ACCEL
		requestedDeltaAngle -= delta * WHEEL_ACCEL
		
	var newWheelAngle = clamp(
		wheelAngle + requestedDeltaAngle,
		-MAX_WHEEL_ANGLE,
		MAX_WHEEL_ANGLE
	)

	var actualDeltaAngle = newWheelAngle - wheelAngle
	wheelAngle = newWheelAngle
		
	frontLeftWheel.rotate(frontLeftWheel.basis.y.normalized(), actualDeltaAngle)
	frontRightWheel.rotate(frontLeftWheel.basis.y.normalized(), actualDeltaAngle)

	
	# negative z is the default forward vector
	var direction := -basis.z
	
	if speed != 0:
		var carRotation = wheelAngle * CAR_TURN_RATE * delta
		if speed > 0.0:
			rotate(basis.y.normalized(), carRotation)
		else:
			rotate(basis.y.normalized(), -carRotation)
	
	# is_action_pressed accounts for holding down button
	# is_action_just_pressed is for one time event
	if Input.is_action_pressed("Move Forward"):
		speed += delta * ACCEL
		
	if Input.is_action_pressed("Move Backward"):
		if speed <= 0.0:
			speed -= delta * ACCEL
			
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
	
	direction *= speed
	direction.y = velocity.y
	velocity = direction
	
	
	# transform.basis stores the original x,y,z directions for this playable character object
	# hence we want to transform the movement vector in this direction
	# allows for left, right, forward, and backward directions to be rotated if character rotates
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
		## movement in x and z directions have velocity 5 in the correct direction
		##velocity.x = direction.x * SPEED
		##velocity.z = direction.z * SPEED
		#
		## DONT MODIFY Y BECUASE IT"S HANDLED BY GRAVITY ABOVE
	#else:
		# decelerate from current velocity to 0
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)

	# integrate velocity of character and update states like is_on_floor
	move_and_slide()

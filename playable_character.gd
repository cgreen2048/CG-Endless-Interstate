extends CharacterBody3D

# adds properties to inspector in script
# use to turn car tires
@export var leftShoulder : CSGSphere3D

const MAX_SPEED = 25.0
const ACCEL = 2.0
const FRICTION = 1.0
const ANGLE_ACCEL = 0.8
const JUMP_VELOCITY = 4.5

var speed : float = 0.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var angle = 0.0
	if Input.is_action_pressed("Turn Left"):
		angle += delta * ANGLE_ACCEL
	if Input.is_action_pressed("Turn Right"):
		angle -= delta * ANGLE_ACCEL
		
	# function rotations around first arg axis by second arg angle
	rotate(basis.y, angle)
	
	# negative z is the default forward vector
	var direction := -basis.z
	
	
	# is_action_pressed accounts for holding down button
	# is_action_just_pressed is for one time event
	if Input.is_action_pressed("Move Forward"):
		speed += delta * ACCEL
		
	if Input.is_action_pressed("Move Backward"):
		speed -= delta * ACCEL
		
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

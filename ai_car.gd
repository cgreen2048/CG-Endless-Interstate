extends CharacterBody3D

@export var mileMarkers: Array[Area3D]

@export var leftBrakeLight: SpotLight3D
@export var rightBrakeLight: SpotLight3D
@export var leftBrakeLightNode: CSGCylinder3D
@export var rightBrakeLightNode: CSGCylinder3D

@export var leftHeadLight: SpotLight3D
@export var rightHeadLight: SpotLight3D
@export var leftHeadLightNode: CSGCylinder3D
@export var rightHeadLightNode: CSGCylinder3D

@export var carDetectionArea: Area3D

const MAX_SPEED = 20
const ACCEL = 4.0
const BRAKE_DECEL = 8.0
const FRICTION = 1.0
const WHEEL_ACCEL = 0.5
const WHEEL_RETURN_RATE = 0.4
const CAR_TURN_RATE = 1


enum State {
	DRIVING, 
	REALIGNING,
	BRAKING
}

enum SegmentType {
	STRAIGHT,
	CURVE_LONG,
	CURVE_SHORT
}

var speed = 0.0
var currentMarker = 0
var state: State = State.DRIVING
var segmentTypeSequence: Array[SegmentType] = [
	SegmentType.STRAIGHT,
	SegmentType.CURVE_LONG,
	SegmentType.STRAIGHT,
	SegmentType.CURVE_SHORT,
	SegmentType.STRAIGHT,
	SegmentType.STRAIGHT,
	SegmentType.CURVE_LONG,
	SegmentType.STRAIGHT,
	SegmentType.CURVE_SHORT,
	SegmentType.STRAIGHT
]
var t : float = 0.0

func _ready() -> void:
	for marker in mileMarkers:
		marker.body_entered.connect(_on_mile_marker_entered.bind(marker))
		
	leftHeadLight.visible = false
	rightHeadLight.visible = false
	(leftHeadLightNode.material as StandardMaterial3D).emission_enabled = false
	(rightHeadLightNode.material as StandardMaterial3D).emission_enabled = false
	
	leftBrakeLight.visible = false
	rightBrakeLight.visible = false
	(leftBrakeLightNode.material as StandardMaterial3D).emission_enabled = false
	(rightBrakeLightNode.material as StandardMaterial3D).emission_enabled = false

func _physics_process(delta: float) -> void:
	var target = mileMarkers[currentMarker]
	var segmentType = segmentTypeSequence[currentMarker]
	var startPosition = mileMarkers[(currentMarker - 1) % mileMarkers.size()].global_position
	var endPosition = target.global_position
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		match state:
			State.DRIVING:
				if speed < MAX_SPEED:
					speed = min(MAX_SPEED, speed + delta * ACCEL)
				
				var desiredPosition = Vector3.ZERO
				t = min(t + delta, 1.0)
				if segmentType == SegmentType.STRAIGHT:
					desiredPosition = startPosition.lerp(endPosition, t)
				else:
					var curveCentroid = Vector3.ZERO
					if segmentType == SegmentType.CURVE_LONG:
						curveCentroid = Vector3(endPosition.x, 0.0, startPosition.z)
					else:
						curveCentroid = Vector3(startPosition.x, 0.0, endPosition.z)
						
					var startVector = startPosition - curveCentroid
					var endVector = endPosition - curveCentroid
					var radius = startVector.length()
					
					var direction = startVector.lerp(endVector, t).normalized()
					desiredPosition = curveCentroid + direction * radius
						
				var desiredDirection = (desiredPosition - global_position).normalized()
				desiredDirection *= speed
				desiredDirection.y = velocity.y
				velocity = desiredDirection
			State.BRAKING:
				leftBrakeLight.visible = true
				rightBrakeLight.visible = true
				leftBrakeLight.light_energy = 5.0
				rightBrakeLight.light_energy = 5.0
				
				var leftBrakeLightNodeMaterial = leftBrakeLightNode.material as StandardMaterial3D
				var rightBrakeLightNodeMaterial = rightBrakeLightNode.material as StandardMaterial3D
				leftBrakeLightNodeMaterial.emission_enabled = true
				leftBrakeLightNodeMaterial.emission_energy_multiplier = 5.0
				rightBrakeLightNodeMaterial.emission_enabled = true
				rightBrakeLightNodeMaterial.emission_energy_multiplier = 5.0
				
				speed = max(0.0, speed - delta * BRAKE_DECEL)

				var horizontalDirection = Vector3(velocity.x, 0, velocity.z).normalized()

				velocity.x = horizontalDirection.x * speed
				velocity.z = horizontalDirection.z * speed

	move_and_slide()

	if is_car_nearby():
		state = State.BRAKING
	else:
		state = State.DRIVING

func _on_mile_marker_entered(body: Node3D, marker: Area3D) -> void:
	if body == self and marker == mileMarkers[currentMarker]:
		print("Entered: ", marker.name,
		  " | body: ", body.name,
		  " | target: ", mileMarkers[currentMarker].name)
		currentMarker = (currentMarker + 1) % mileMarkers.size()
		t = 0.0
		
func is_car_nearby() -> bool:
	for body in carDetectionArea.get_overlapping_bodies():
		if body is CharacterBody3D and body != self:
			return true

	return false

extends Area3D

signal mile_passed

@export var nextMileMarker : Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node3D):
	if body is not CharacterBody3D:
		return
		
	var bodyDirection = body.velocity.normalized()
	var markerForward = -global_transform.basis.z.normalized()
	
	if markerForward.dot(bodyDirection) > 0.5:
		mile_passed.emit()
		print("player crossed marker")
		
		set_deferred("monitoring", false)
		
		if nextMileMarker:
			nextMileMarker.set_deferred("monitoring", true)

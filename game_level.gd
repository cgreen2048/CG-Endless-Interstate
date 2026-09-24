extends Node3D

var current_mile := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$UI/MileLabel.text = "Mile %d" % current_mile


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_mile_passed() -> void:
	current_mile += 1
	$UI/MileLabel.text = "Mile %d" % current_mile

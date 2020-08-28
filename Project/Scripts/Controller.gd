extends Node
class_name Controller

var turnDirection := 0.0
var accelerating := false
var braking := false
var useItem := false

func _ready() -> void:
	pass

func resetValues() -> void:
	turnDirection = 0.0
	accelerating = false
	braking = false
	useItem = false

extends KinematicBody
class_name Kart

export (float) var topSpeed := 10.0

var velocity: Vector3 = Vector3.ZERO
var intendedTurnDirection := 0.0
var intendedAccelerating := false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	intendedTurnDirection = 0.0
	intendedAccelerating = false
	
	var controller := getController()
	if controller != null:
		intendedTurnDirection = controller.turnDirection
		intendedAccelerating = controller.accelerating

func _physics_process(delta: float) -> void:
	if intendedAccelerating:
		var direction: Vector3 = -transform.basis.z
		
		if intendedTurnDirection != 0.0:
			#direction = direction.rotated(Vector3.UP, deg2rad(-intendedTurnDirection))
			rotate(Vector3.UP, deg2rad(-intendedTurnDirection))
		
		velocity = direction * topSpeed
		velocity.y = 0.0
		
		velocity = move_and_slide(velocity, Vector3(0.0, -1.0, 0.0))

func getController() -> Controller:
	if has_node("Controller"):
		return $Controller as Controller
	
	return null

extends KinematicBody
class_name Kart

const nominalVelocityLength := 0.4
const wheelBase := 0.5 # TODO: Needs to be based on scene.
const steeringAngle := 1.0

export (float) var enginePower := 25.0
export (float) var friction := -1.9
export (float) var drag := -0.00001

var acceleration := Vector3.ZERO
var velocity := Vector3.ZERO
var steerDirection := 0.0

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
	
	steerDirection = deg2rad(-intendedTurnDirection * steeringAngle)

func _physics_process(delta: float) -> void:
	acceleration = Vector3.ZERO
	
	if intendedAccelerating:
		acceleration = -transform.basis.z * enginePower
	
	applyFriction()
	
	calculateSteering(delta)
	
	velocity += acceleration * delta
	velocity.y = 0.0
	velocity = move_and_slide(velocity, Vector3.UP)

func getController() -> Controller:
	if has_node("Controller"):
		return $Controller as Controller
	
	return null

func applyFriction() -> void:
	if velocity.length() < nominalVelocityLength:
		velocity = Vector3.ZERO
	
	var frictionForce := velocity * friction
	var dragForce = velocity * velocity.length() * drag
	
	acceleration += dragForce + frictionForce

func calculateSteering(delta: float) -> void:
	var rearWheel = transform.origin + transform.basis.z * wheelBase / 2.0
	var frontWheel = transform.origin - transform.basis.z * wheelBase / 2.0
	
	rearWheel += velocity * delta
	frontWheel += velocity.rotated(Vector3.UP, steerDirection) * delta
	
	var newHeading = (frontWheel - rearWheel).normalized()
	velocity = newHeading * velocity.length()
	
	# TODO: This part is question.
	#rotation = newHeading
	#rotation_degrees = newHeading
	#transform.looking_at(Vector3(0, 0, 1), Vector3.UP)
	rotate(Vector3.UP, steerDirection)

extends KinematicBody
class_name Kart

const nominalVelocityLength := 0.1
const wheelBase := 0.5 # TODO: Needs to be based on scene.
const steeringAngle := 1.0
const reverseSpeedRatio := 0.975

export (float) var enginePower := 25.0
export (float) var brakingPower := -15.0
export (float) var slipSpeed := 12.0
export (float) var tractionFast := 0.1
export (float) var tractionSlow := 0.7

export (float) var friction := -1.9
export (float) var drag := -0.00001

var acceleration := Vector3.ZERO
var velocity := Vector3.ZERO
var steerDirection := 0.0

var positionLocked := true

var intendedTurnDirection := 0.0
var intendedAccelerating := false
var intendedBraking := false

func _ready() -> void:
	$AudioPlayers/Engine.stream.loop_offset = randf()

func _process(delta: float) -> void:
	intendedTurnDirection = 0.0
	intendedAccelerating = false
	intendedBraking = false
	
	var controller := getController()
	if controller != null:
		intendedTurnDirection = controller.turnDirection
		intendedAccelerating = controller.accelerating
		intendedBraking = controller.braking
	
	steerDirection = deg2rad(-intendedTurnDirection * steeringAngle)
	
	$AudioPlayers/Engine.pitch_scale = 1.0 + (velocity.length() / 4.0)

func _physics_process(delta: float) -> void:
	if positionLocked:
		return
	
	acceleration = Vector3.ZERO
	
	if intendedAccelerating:
		acceleration = -transform.basis.z * enginePower
	
	if intendedBraking:
		acceleration = -transform.basis.z * brakingPower
	
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
	var rearWheel := transform.origin + transform.basis.z * wheelBase / 2.0
	var frontWheel := transform.origin - transform.basis.z * wheelBase / 2.0
	
	rearWheel += velocity * delta
	frontWheel += velocity.rotated(Vector3.UP, steerDirection) * delta
	
	var newHeading := (frontWheel - rearWheel).normalized()
	
	var traction := tractionSlow
	if velocity.length() > slipSpeed:
		traction = tractionFast
	
	var dotProduct := newHeading.dot(velocity.normalized())
	if dotProduct > 0.0:
		velocity = velocity.linear_interpolate(newHeading * velocity.length(), traction)
		
		# NOTE: It's questionable to do rotation like this.
		# TODO: Should try to use newHeading.
		rotate(Vector3.UP, steerDirection)
	elif dotProduct < 0.0:
		velocity = -newHeading * velocity.length() * reverseSpeedRatio
		rotate(Vector3.UP, -steerDirection)

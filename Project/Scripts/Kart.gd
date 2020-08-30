extends KinematicBody
class_name Kart

signal loadedItem(kart, itemType)
signal usedItem(kart)

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
var intendedUseItem := false

var roughZoneCounter := 0

var coinCount := 0
var loadingItem: int = Global.ItemType.NONE
var ownedItem: int = Global.ItemType.NONE

var coinsAhead := []
var questionBlocksAhead := []

var positionWaypoint: Waypoint = null
#var previousWaypoint: Waypoint = null
#var nextWaypoint: Waypoint = null

func _ready() -> void:
	$AudioPlayers/Engine.stream.loop_offset = randf()
	
	resetValues()

func _process(delta: float) -> void:
	intendedTurnDirection = 0.0
	intendedAccelerating = false
	intendedBraking = false
	intendedUseItem = false
	
	var controller := getController()
	if controller != null:
		intendedTurnDirection = controller.turnDirection
		intendedAccelerating = controller.accelerating
		intendedBraking = controller.braking
		intendedUseItem = controller.useItem
	
	steerDirection = deg2rad(intendedTurnDirection * steeringAngle)
	
	if Global.debug:
		$TurnSignals.visible = true
		
		if steerDirection == 0.0:
			$TurnSignals.frame = 1
		else:
			if steerDirection < 0.0:
				$TurnSignals.frame = 0
			else:
				$TurnSignals.frame = 2
	
	if intendedUseItem:
		useItem()
	
	updateDebugDisplay()
	
	$AudioPlayers/Engine.pitch_scale = 1.0 + (velocity.length() / 4.0)

func _physics_process(delta: float) -> void:
	if positionLocked:
		return
	
	acceleration = Vector3.ZERO
	
	if intendedAccelerating:
		acceleration = -transform.basis.z * (enginePower + (coinCount * 0.25))
	
	if intendedBraking:
		acceleration = -transform.basis.z * brakingPower
	
	applyFriction()
	
	calculateSteering(delta)
	
	velocity += acceleration * delta
	velocity.y = 0.0
	velocity = move_and_slide(velocity, Vector3.UP, false, 12)

func getController() -> Controller:
	if has_node("Controller"):
		return $Controller as Controller
	
	return null

func isInRoughZone() -> bool:
	return (roughZoneCounter > 0)

func setColor(color: Color) -> void:
	$Saucer.modulate = color
	$TurnSignals.modulate = color

func hasItem() -> bool:
	return (ownedItem != Global.ItemType.NONE)

func updateDebugDisplay() -> void:
	var forwardIg: ImmediateGeometry = $ForwardIg
	forwardIg.clear()
	
	if Global.debug:
		forwardIg.begin(Mesh.PRIMITIVE_LINES)
		forwardIg.add_vertex(to_local(global_transform.origin))
		forwardIg.add_vertex(to_local(global_transform.origin) + (Vector3.FORWARD * 10.0))
		forwardIg.end()
	
	if positionWaypoint == null:
		return
	
	var nextIg: ImmediateGeometry = $NextIg
	nextIg.clear()
	
	if Global.debug:
		var position: Vector3 = positionWaypoint.global_transform.origin
		
		nextIg.begin(Mesh.PRIMITIVE_LINES)
		nextIg.add_vertex(to_local(global_transform.origin))
		nextIg.add_vertex(to_local(position))
		nextIg.end()

func applyFriction() -> void:
	if velocity.length() < nominalVelocityLength:
		velocity = Vector3.ZERO
	
	var frictionFromRoughZone := 0.0
	if roughZoneCounter > 0:
		frictionFromRoughZone = -1.9
	
	var frictionForce := velocity * (friction + frictionFromRoughZone)
	var dragForce = velocity * velocity.length() * drag
	
	acceleration += dragForce + frictionForce

func calculateSteering(delta: float) -> void:
	var rearWheel := transform.origin + transform.basis.z * wheelBase / 2.0
	var frontWheel := transform.origin - transform.basis.z * wheelBase / 2.0
	
	rearWheel += velocity * delta
	frontWheel += velocity.rotated(Vector3.UP, -steerDirection) * delta
	
	var newHeading := (frontWheel - rearWheel).normalized()
	
	var traction := tractionSlow
	if velocity.length() > slipSpeed:
		traction = tractionFast
	
	var dotProduct := newHeading.dot(velocity.normalized())
	if dotProduct > 0.0:
		velocity = velocity.linear_interpolate(newHeading * velocity.length(), traction)
		
		# NOTE: It's questionable to do rotation like this.
		# TODO: Should try to use newHeading.
		rotate(Vector3.UP, -steerDirection)
	elif dotProduct < 0.0:
		velocity = -newHeading * velocity.length() * reverseSpeedRatio
		rotate(Vector3.UP, steerDirection)

func resetValues() -> void:
	acceleration = Vector3.ZERO
	velocity = Vector3.ZERO
	steerDirection = 0.0
	
	positionLocked = true
	
	intendedTurnDirection = 0.0
	intendedAccelerating = false
	intendedBraking = false
	
	roughZoneCounter = 0
	
	coinCount = 0
	loadingItem = Global.ItemType.NONE
	ownedItem = Global.ItemType.NONE
	
	coinsAhead = []
	questionBlocksAhead = []
	
	positionWaypoint = null

func resetController() -> void:
	var controller := getController()
	if controller != null:
		controller.resetValues()

func startEngine(on: bool) -> void:
	if on:
		$AudioPlayers/Engine.play()
	else:
		$AudioPlayers/Engine.stop()

func startLoadingItem(itemType: int) -> void:
	loadingItem = itemType
	ownedItem = Global.ItemType.UNKNOWN
	$Timers/ItemLoadTimer.start()

func onItemLoadTimerTimeout() -> void:
	ownedItem = loadingItem
	loadingItem = Global.ItemType.NONE
	
	emit_signal("loadedItem", self, ownedItem)

func useItem() -> void:
	match ownedItem:
		Global.ItemType.NONE:
			return
		Global.ItemType.UNKNOWN:
			return
		Global.ItemType.SPEED_UP:
			velocity += -transform.basis.z * 50.0
	
	ownedItem = Global.ItemType.NONE
	emit_signal("usedItem", self)

func onAreaAheadAreaEntered(area: Area) -> void:
	if area is Coin:
		if coinsAhead.find(area) == -1:
			coinsAhead.append(area)
	elif area is QuestionBlock:
		if questionBlocksAhead.find(area) == -1:
			questionBlocksAhead.append(area)

func onAreaAheadAreaExited(area: Area) -> void:
	if area is Coin:
		var coinIndex := coinsAhead.find(area)
		if coinIndex > -1:
			coinsAhead.remove(coinIndex)
	elif area is QuestionBlock:
		var questionBlockIndex := questionBlocksAhead.find(area)
		if questionBlockIndex > -1:
			questionBlocksAhead.remove(questionBlockIndex)

extends Controller
class_name AiController

export (float) var waypointDistanceTolerance = 5.0

var currentWaypoint: Waypoint = null

var previousDistanceToDestination := 0.0

#var path = []
#var pathIndex = 0

#var targetPosition := Vector3.ZERO
var targetCoin: Coin = null
var targetQuestionBlock: QuestionBlock = null

export (NodePath) var trackNodePath = null

func _ready() -> void:
	resetValues()

func _process(delta: float) -> void:
	updateDebugDisplay()

func _physics_process(delta: float) -> void:
	var parent: Spatial = get_parent()
	
	if currentWaypoint == null:
		currentWaypoint = parent.positionWaypoint
	
	currentWaypoint = parent.positionWaypoint
	
	if false:
	#if currentWaypoint != null:
		if parent.global_transform.origin.distance_to(currentWaypoint.global_transform.origin) < waypointDistanceTolerance:
			currentWaypoint = currentWaypoint.nextWaypoint
			if currentWaypoint != null:
				previousDistanceToDestination = getDistanceToWaypoint(currentWaypoint)
		
		if currentWaypoint != null:
			if getDistanceToWaypoint(currentWaypoint) > previousDistanceToDestination:
				currentWaypoint = currentWaypoint.nextWaypoint
				#currentWaypoint = parent.positionWaypoint
				if currentWaypoint != null:
					previousDistanceToDestination = getDistanceToWaypoint(currentWaypoint)
	
	checkForTargetCoin()
	checkForTargetQuestionBlock()
	checkItemUsage()
	
	updateTurnDirectionFromPath()
	
	updateAcceleratingBasedOnRayCast()

func getDistanceToWaypoint(waypoint: Spatial) -> float:
	var parent: Spatial = get_parent()
	return waypoint.getDistanceToPosition(parent.global_transform.origin)

# position: global
func isCloserToCurrentWaypoint(position: Vector3) -> bool:
	var parent: Spatial = get_parent()
	return (currentWaypoint.getDistanceToPosition(position) < getDistanceToWaypoint(currentWaypoint))

func getOptimalClosestCoin() -> Coin:
	var parent: Spatial = get_parent()
	
	var coinsAhead: Array = parent.coinsAhead
	if coinsAhead.empty():
		return null
	
	var closestCoin: Coin = null
	var closestCoinDistance := INF
	
	var parentPosition := parent.global_transform.origin
	
	for coin in coinsAhead:
		if not coin.isEnabled():
			continue
		
		var coinPosition: Vector3 = coin.global_transform.origin
		
		if not isCloserToCurrentWaypoint(coinPosition):
			continue
		
		var distance := parentPosition.distance_to(coinPosition)
		if distance < closestCoinDistance:
			closestCoin = coin
			closestCoinDistance = distance
	
	return closestCoin

func getOptimalClosestQuestionBlock() -> QuestionBlock:
	var parent: Spatial = get_parent()
	
	var questionBlocksAhead: Array = parent.questionBlocksAhead
	if questionBlocksAhead.empty():
		return null
	
	var closestQuestionBlock: QuestionBlock = null
	var closestQuestionDistance := INF
	
	var parentPosition := parent.global_transform.origin
	
	for questionBlock in questionBlocksAhead:
		if not questionBlock.isEnabled():
			continue
		
		var questionBlockPosition: Vector3 = questionBlock.global_transform.origin
		
		if not isCloserToCurrentWaypoint(questionBlockPosition):
			continue
		
		var distance := parentPosition.distance_to(questionBlockPosition)
		if distance < closestQuestionDistance:
			closestQuestionBlock = questionBlock
			closestQuestionDistance = distance
	
	return closestQuestionBlock

func resetValues() -> void:
	.resetValues()
	
	accelerating = false
	
	previousDistanceToDestination = 0.0
	
	#path = []
	#pathIndex = 0
	
	#targetPosition = get_parent().global_transform.origin
	targetCoin = null
	targetQuestionBlock = null

func updateTurnDirectionFromPath() -> void:
	var parent: Spatial = get_parent()
	
	if currentWaypoint == null:
		return
	
	var position: Vector3 = currentWaypoint.global_transform.origin
	
	if not parent.isInRoughZone():
		if areFrontRayCastsCollding():
			var turnDirectionFromRayCasts := getTurnDirectionFromRayCasts()
			if turnDirectionFromRayCasts != 0.0:
				turnDirection = turnDirectionFromRayCasts
				return
		
		if targetCoin != null:
			position = targetCoin.global_transform.origin
		elif targetQuestionBlock != null:
			position = targetQuestionBlock.global_transform.origin
	
	var lookingAtEuler: Vector3 = parent.global_transform.looking_at(position, Vector3.UP).basis.get_euler()
	
	var currentEuler = parent.rotation
	if currentEuler.y != lookingAtEuler.y:
		var angleDifference: float = lookingAtEuler.y - currentEuler.y
		
		if abs(angleDifference) > PI:
			# Switch direction of rotation.
			if angleDifference < 0.0:
				turnDirection = -1.0
			else:
				turnDirection = 1.0
		else:
			if angleDifference > 0.025:
				turnDirection = -1.0
			elif angleDifference < -0.025:
				turnDirection = 1.0
			else:
				turnDirection = 0.0
	else:
		turnDirection = 0.0

func updateAcceleratingBasedOnRayCast() -> void:
	var parent = get_parent()
	
	accelerating = (currentWaypoint != null)
	
	if parent.isInRoughZone():
		return
	
	var rayCast: RayCast = parent.getRayCast(0)
	
	if not rayCast.is_colliding():
		return
	
	var collider := rayCast.get_collider()
	
	if collider is Kart:
		# TODO: Only slow down if parent velocity is faster than collider kart.
		return
		
		var distanceToKart: float = rayCast.global_transform.origin.distance_to(collider.global_transform.origin)
		if distanceToKart < 3.0:
			accelerating = false
			return
	
	# Assume a rough zone at this point.
	var kartVelocityLength: float = parent.velocity.length()
	if kartVelocityLength < 5.0:
		return
	
	#if collider.get_parent().name == "RoughZones":
	if kartVelocityLength > 10.0:
		accelerating = false
		return

func checkForTargetCoin() -> void:
	if targetCoin != null:
		if not targetCoin.isEnabled():
			targetCoin = null
		elif not isCloserToCurrentWaypoint(targetCoin.global_transform.origin):
			targetCoin = null
	
	if targetCoin == null:
		targetCoin = getOptimalClosestCoin()
		#if targetCoin != null:
		#	print("Found coin")

func checkForTargetQuestionBlock() -> void:
	if targetCoin == null:
		return
	
	if targetQuestionBlock != null:
		if not targetQuestionBlock.isEnabled():
			targetQuestionBlock = null
		elif not isCloserToCurrentWaypoint(targetQuestionBlock.global_transform.origin):
			targetQuestionBlock = null
	
	if targetQuestionBlock == null:
		targetQuestionBlock = getOptimalClosestQuestionBlock()

func checkItemUsage() -> void:
	useItem = false
	
	if targetCoin != null:
		return
	
	var parent = get_parent()
	var ownedItem: int = parent.ownedItem
	if ownedItem == Global.ItemType.NONE:
		return
	
	match ownedItem:
		Global.ItemType.SPEED_UP:
			var parentTransform: Transform = parent.global_transform
			# Check to see if facing next waypoint.
			var facingDirection: Vector3 = -parentTransform.basis.z
			var directionToCurrentWaypoint: Vector3 = parentTransform.origin.direction_to(currentWaypoint.global_transform.origin)
			var angleTo := facingDirection.angle_to(directionToCurrentWaypoint)
			if angleTo < 0.25:
				# Check to see if distance between next waypoint is great enough.
				var distanceToCurrentWaypoint := parentTransform.origin.distance_to(currentWaypoint.global_transform.origin)
				if distanceToCurrentWaypoint >= 30.0:
					useItem = true

func areFrontRayCastsCollding() -> bool:
	var parent = get_parent()
	
	if parent.getRayCast(-1).is_colliding():
		return true
	
	if parent.getRayCast(0).is_colliding():
		return true
	
	if parent.getRayCast(1).is_colliding():
		return true
	
	return false

func getRayCastDistanceToItsCollider(rayCast: RayCast) -> float:
	if not rayCast.is_colliding():
		var distance: float = get_parent().to_global(rayCast.cast_to).length()
		return distance
	
	var collider: Spatial = rayCast.get_collider()
	return rayCast.global_transform.origin.distance_to(collider.global_transform.origin)

func getCloserCollisionRayCast(rayCastA: RayCast, rayCastB: RayCast) -> RayCast:
	if getRayCastDistanceToItsCollider(rayCastA) < getRayCastDistanceToItsCollider(rayCastB):
		return rayCastA
	elif getRayCastDistanceToItsCollider(rayCastA) > getRayCastDistanceToItsCollider(rayCastB):
		return rayCastB
	else:
		return null

func getTurnDirectionFromCloserRayCast(leftRayCast: RayCast, rightRayCast: RayCast) -> float:
	match getCloserCollisionRayCast(leftRayCast, rightRayCast):
		leftRayCast:
			return 1.0
		rightRayCast:
			return -1.0
	
	return 0.0

func getTurnDirectionFromRayCasts() -> float:
	var parent = get_parent()
	
	var left15RayCast: RayCast = parent.getRayCast(-2)
	var frontLeftRayCast: RayCast = parent.getRayCast(-1)
	#var frontCenterRayCast: RayCast = parent.getRayCast(0)
	var frontRightRayCast: RayCast = parent.getRayCast(1)
	var right15RayCast: RayCast = parent.getRayCast(2)
	
	var left15RayCastColliding  := left15RayCast.is_colliding()
	var frontLeftRayCastColliding := frontLeftRayCast.is_colliding()
	var frontRightRayCastColliding := frontRightRayCast.is_colliding()
	var right15RayCastColliding := right15RayCast.is_colliding()
	
	var left15RayCastDistance  := getRayCastDistanceToItsCollider(left15RayCast)
	var frontLeftRayCastDistance := getRayCastDistanceToItsCollider(frontLeftRayCast)
	var frontRightRayCastDistance := getRayCastDistanceToItsCollider(frontRightRayCast)
	var right15RayCastDistance := getRayCastDistanceToItsCollider(right15RayCast)
	
	var turnDirection := 0.0
	turnDirection += 0.125 * (left15RayCastDistance) * left15RayCastColliding as int
	turnDirection += (frontLeftRayCastDistance) * frontLeftRayCastColliding as int
	turnDirection += -(frontRightRayCastDistance) * frontRightRayCastColliding as int
	turnDirection += 0.125 * -(right15RayCastDistance) * right15RayCastColliding as int
	
	if turnDirection == 0.0:
		return 0.0
	
	if abs(turnDirection) < 0.125:
		turnDirection = 0.0
	
	if turnDirection != 0.0:
		turnDirection /= abs(turnDirection)
	
	return turnDirection

func updateDebugDisplay() -> void:
	var parent: Spatial = get_parent()
	
	var aiIg: ImmediateGeometry = parent.get_node("AiIg")
	aiIg.clear()
	
	if currentWaypoint == null:
		return
	
	if Global.debug:
		var position: Vector3 = currentWaypoint.global_transform.origin
		
		aiIg.begin(Mesh.PRIMITIVE_LINES)
		aiIg.add_vertex(parent.to_local(parent.global_transform.origin))
		aiIg.add_vertex(parent.to_local(position))
		aiIg.end()

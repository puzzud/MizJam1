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

func getRayCast(rayCastId: int = 0) -> RayCast:
	var centerRayCastIndex := int($RayCasts.get_child_count() / 2)
	var rayCast := $RayCasts.get_child(centerRayCastIndex + rayCastId) as RayCast
	#var name := rayCast.name
	#print(name)
	return rayCast

func areFrontRayCastsColliding() -> bool:
	if getRayCast(-1).is_colliding():
		return true
	
	if getRayCast(0).is_colliding():
		return true
	
	if getRayCast(1).is_colliding():
		return true
	
	return false

func getRayCastScaledDistanceToItsCollider(rayCast: RayCast) -> float:
	if not rayCast.is_colliding():
		return 1.0
	
	var collider: Spatial = rayCast.get_collider()
	return Vector3.ZERO.distance_to(rayCast.to_local(rayCast.get_collision_point())) / 10.0

func getTurnDirectionFromRayCasts() -> float:
	var left15RayCast: RayCast = getRayCast(-2)
	var frontLeftRayCast: RayCast = getRayCast(-1)
	#var frontCenterRayCast: RayCast = getRayCast(0)
	var frontRightRayCast: RayCast = getRayCast(1)
	var right15RayCast: RayCast = getRayCast(2)
	
	var left15RayCastDistance  := getRayCastScaledDistanceToItsCollider(left15RayCast)
	var frontLeftRayCastDistance := getRayCastScaledDistanceToItsCollider(frontLeftRayCast)
	var frontRightRayCastDistance := getRayCastScaledDistanceToItsCollider(frontRightRayCast)
	var right15RayCastDistance := getRayCastScaledDistanceToItsCollider(right15RayCast)
	
	var turnDirection := 0.0
	turnDirection += 0.62 * -(left15RayCastDistance)
	turnDirection += -(frontLeftRayCastDistance)
	turnDirection += (frontRightRayCastDistance)
	turnDirection += 0.62 * (right15RayCastDistance)
	
	if turnDirection != 0.0:
		turnDirection /= abs(turnDirection)
	if turnDirection == 0.0:
		return -1.0
	
	return turnDirection

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
		if areFrontRayCastsColliding():
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
	
	var rayCast: RayCast = getRayCast(0)
	
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

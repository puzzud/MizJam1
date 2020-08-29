extends Controller
class_name AiController

export (float) var waypointDistanceTolerance = 5.0

var currentWaypoint: Waypoint = null

var previousDistanceToDestination := 0.0

#var path = []
#var pathIndex = 0

#var targetPosition := Vector3.ZERO
var targetCoin: Coin = null

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
	
	updateTurnDirectionFromPath()
	
	updateAcceleratingBasedOnRayCast()

func getDistanceToWaypoint(waypoint: Spatial) -> float:
	var parent: Spatial = get_parent()
	return waypoint.getDistanceToPosition(parent.global_transform.origin)

# position: global
func isCloserToCurrentWaypoint(position: Vector3) -> bool:
	var parent: Spatial = get_parent()
	return (currentWaypoint.getDistanceToPosition(position) < getDistanceToWaypoint(currentWaypoint))

func getParentRayCast() -> RayCast:
	return get_parent().get_node("RayCast") as RayCast

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

func resetValues() -> void:
	.resetValues()
	
	accelerating = false
	
	previousDistanceToDestination = 0.0
	
	#path = []
	#pathIndex = 0
	
	#targetPosition = get_parent().global_transform.origin
	targetCoin = null

func updateTurnDirectionFromPath() -> void:
	var parent: Spatial = get_parent()
	
	if currentWaypoint == null:
		return
	
	var position: Vector3 = currentWaypoint.global_transform.origin
	
	if targetCoin != null:
		position = targetCoin.global_transform.origin
	
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
	
	var rayCast := getParentRayCast()
	
	if not rayCast.is_colliding():
		return
	
	var collider := rayCast.get_collider()
	
	if collider is Coin:
		return
	
	if collider is QuestionBlock:
		return
	
	if parent.isInRoughZone():
		return
	
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

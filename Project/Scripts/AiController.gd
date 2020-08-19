extends Controller
class_name AiController

export (float) var waypointDistanceTolerance = 5.0

var currentWaypoint: Waypoint = null

var previousDistanceToDestination := 0.0

var path = []
var pathIndex = 0

#var targetPosition := Vector3.ZERO
var targetCoin: Coin = null

export (NodePath) var trackNodePath = null

func _ready() -> void:
	resetValues()

func _physics_process(delta: float) -> void:
	var parent: Spatial = get_parent()
	
	if parent.global_transform.origin.distance_to(currentWaypoint.global_transform.origin) < waypointDistanceTolerance:
		currentWaypoint = getNextWaypoint()
		previousDistanceToDestination = getDistanceToWaypoint(currentWaypoint)
	
	if getDistanceToWaypoint(currentWaypoint) > previousDistanceToDestination:
		currentWaypoint = getNextWaypoint()
		previousDistanceToDestination = getDistanceToWaypoint(currentWaypoint)
	
	if isParentCloserToNextWaypoint():
		currentWaypoint = getNextWaypoint()
	
	checkForTargetCoin()
	
	updateTurnDirectionFromPath()
	
	updateAcceleratingBasedOnRayCast()

func getClosestWaypoint() -> Waypoint:
	var track := get_node(trackNodePath) as Track
	return track.getClosestWaypoint(get_parent().global_transform.origin)

func getNextWaypoint() -> Waypoint:
	return currentWaypoint.nextWaypoint

# Check if parent is closer to the next way point than the current waypoint.
func isParentCloserToNextWaypoint() -> bool:
	return currentWaypoint.isCloserToNextWaypoint(get_parent().global_transform.origin)

func getDistanceToWaypoint(waypoint: Spatial) -> float:
	var parent: Spatial = get_parent()
	return waypoint.getDistanceToPosition(parent.global_transform.origin)

# position: global
func isCloserToCurrentWaypoint(position: Vector3) -> bool:
	return (currentWaypoint.getDistanceToPosition(position) < getDistanceToWaypoint(currentWaypoint))

func getParentRayCast() -> RayCast:
	return get_parent().get_node("RayCast") as RayCast

func getOptimalClosestCoin() -> Coin:
	var parent: Spatial = get_parent()
	
	var coinsAhead: Array = parent.coinsAhead
	if coinsAhead.empty():
		return null
	
	var closestCoin: Coin = null
	var closestCoinDistance := 10000.0 # TODO: Get largest float.
	
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
	
	accelerating = true
	
	currentWaypoint = null
	
	previousDistanceToDestination = 0.0
	
	path = []
	pathIndex = 0
	
	#targetPosition = get_parent().global_transform.origin
	targetCoin = null
	
	if currentWaypoint == null:
		currentWaypoint = getClosestWaypoint()
		previousDistanceToDestination = getDistanceToWaypoint(currentWaypoint)

func updateTurnDirectionFromPath() -> void:
	var parent: Spatial = get_parent()
	
	var position := currentWaypoint.global_transform.origin
	
	if targetCoin != null:
		position = targetCoin.global_transform.origin
	
	var lookingAtEuler: Vector3 = parent.global_transform.looking_at(position, Vector3.UP).basis.get_euler()
	
	var debug := false
	if debug:
		var ig1: ImmediateGeometry = parent.get_node("ig1")
		ig1.clear()
		ig1.begin(Mesh.PRIMITIVE_LINES)
		ig1.add_vertex(parent.to_local(parent.global_transform.origin))
		ig1.add_vertex(parent.to_local(position))
		ig1.end()
		
		var ig2: ImmediateGeometry = parent.get_node("ig2")
		ig2.clear()
		ig2.begin(Mesh.PRIMITIVE_LINES)
		ig2.add_vertex(parent.to_local(parent.global_transform.origin))
		ig2.add_vertex(parent.to_local(parent.global_transform.origin) + (Vector3.FORWARD * 10.0))
		ig2.end()
	
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
	accelerating = true
	
	var rayCast := getParentRayCast()
	
	if not rayCast.is_colliding():
		return
	
	var collider := rayCast.get_collider()
	
	if collider is Coin:
		return
	
	if collider is QuestionBlock:
		return
	
	var parent = get_parent()
	
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
		if targetCoin != null:
			print("Found coin")

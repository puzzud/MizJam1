extends Spatial
class_name Track

signal startSequenceFinished()
signal kartCrossedFinishLine(kart)
signal kartEnteredRoughZone(kart)
signal kartExitedRoughZone(kart)
signal itemPickedUp(item, kart)

func _ready():
	resetValues()
	initializeWaypoints()

func getPolePositions() -> Array:
	return $PolePositions.get_children()

func getWaypoints() -> Array:
	return $Navigation/Waypoints.get_children()

func getWaypoint(waypointIndex: int) -> Spatial:
	var numberOfWaypoints = $Navigation/Waypoints.get_child_count()
	return $Navigation/Waypoints.get_child(waypointIndex % numberOfWaypoints) as Spatial

func getFinishLineWaypoint() -> Waypoint:
	var waypoints := getWaypoints()
	return waypoints[0]

# position: global
func getClosestWaypoint(position: Vector3) -> Waypoint:
	var closestWaypointDistance := INF
	var closestWaypoint: Waypoint = null
	
	for _waypoint in getWaypoints():
		var waypoint: Waypoint = _waypoint
		var waypointDistance := position.distance_to(waypoint.global_transform.origin)
		if waypointDistance < closestWaypointDistance:
			closestWaypointDistance = waypointDistance
			closestWaypoint = waypoint
	
	return closestWaypoint

# position: global
func getClosestWaypointCloserToFinishLine(position: Vector3) -> Waypoint:
	var closestWaypoint: Waypoint = getClosestWaypoint(position)
	
	var finishLineWaypoint := getFinishLineWaypoint()
	
	if closestWaypoint != finishLineWaypoint:
		if closestWaypoint.isPositionCloserToNextWaypoint(position):
			closestWaypoint = closestWaypoint.nextWaypoint
	else:
		if finishLineWaypoint.isPositionCloserToNextWaypoint(position):
			# Kart is ahead of finish line.
			closestWaypoint = finishLineWaypoint.nextWaypoint
		else:
			# Kart is behind finish line.
			closestWaypoint = finishLineWaypoint
	
	return closestWaypoint

# position: global
func getDistanceToFinishLine(position: Vector3, waypointToUse: Waypoint = null) -> float:
	if waypointToUse == null:
		waypointToUse = getClosestWaypointCloserToFinishLine(position)
	
	return waypointToUse.getDistanceToPosition(position) + waypointToUse.getDistanceToWaypoint(getFinishLineWaypoint())

#func getNavigation() -> Navigation:
#	return $Navigation as Navigation

func resetValues() -> void:
	# Reset track stuff like coins & boxes.
	for _coin in $Items/Coins.get_children():
		var coin: Coin = _coin
		coin.resetValues()
	
	for _questionBlock in $Items/QuestionBlocks.get_children():
		var questionBlock: QuestionBlock = _questionBlock
		questionBlock.resetValues()

func initializeWaypoints() -> void:
	var waypoints := getWaypoints()
	for i in range(0, waypoints.size()):
		var waypoint: Waypoint = waypoints[i] as Waypoint
		
		if (i + 1) < waypoints.size():
			waypoint.nextWaypoint = waypoints[i + 1] as Waypoint
		else:
			waypoint.nextWaypoint = waypoints[0] as Waypoint

func startStartSequence() -> void:
	$TrafficLight.startSequence()

func showLapNumber(lapNumber: int) -> void:
	$TrafficLight.showLapNumber(lapNumber)

func onTrafficLightSequenceFinished() -> void:
	emit_signal("startSequenceFinished")

func onFinishLineBodyEntered(body: Node) -> void:
	emit_signal("kartCrossedFinishLine", body)

func onItemPickedUp(item: Spatial, kart: Kart) -> void:
	emit_signal("itemPickedUp", item, kart)

func onRoughZoneBodyEntered(body: Node) -> void:
	emit_signal("kartEnteredRoughZone", body)

func onRoughZoneBodyExited(body: Node) -> void:
	emit_signal("kartExitedRoughZone", body)

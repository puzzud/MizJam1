extends Spatial
class_name Waypoint

var nextWaypoint: Waypoint = null

# Used for caching distances to other waypoints.
var distanceToWaypoints = {}

# Track which waypoints cannot be reached from this waypoint.
var inaccessibleWaypoints = {}

func _ready() -> void:
	pass

# position: global
func getDistanceToPosition(position: Vector3) -> float:
	return global_transform.origin.distance_to(position)

func getDistanceToWaypoint(targetWaypoint: Waypoint) -> float:
	if distanceToWaypoints.has(targetWaypoint):
		return distanceToWaypoints[targetWaypoint]
	
	if nextWaypoint == null:
		return 0.0
	
	if inaccessibleWaypoints.has(targetWaypoint):
		return inaccessibleWaypoints[targetWaypoint]
	
	var distance := 0.0
	
	var previousWaypoint := self
	var currentWaypoint := nextWaypoint
	while true:
		distance += previousWaypoint.getDistanceToPosition(currentWaypoint.global_transform.origin)
		
		if currentWaypoint == targetWaypoint:
			distanceToWaypoints[targetWaypoint] = distance
			return distance
		
		previousWaypoint = currentWaypoint
		currentWaypoint = currentWaypoint.nextWaypoint
		
		if currentWaypoint == self:
			break
		
	# Error condition.
	inaccessibleWaypoints[targetWaypoint] = -10000.0
	return -10000.0

# position: global
func isCloserToNextWaypoint(position: Vector3) -> bool:
	if nextWaypoint == null:
		return true
	
	var positionDistanceToNextWaypoint := nextWaypoint.getDistanceToPosition(position)
	var distanceToNextWaypoint := getDistanceToWaypoint(nextWaypoint)
	
	return (positionDistanceToNextWaypoint < distanceToNextWaypoint)


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
	if self == targetWaypoint:
		return 0.0
	
	if distanceToWaypoints.has(targetWaypoint):
		return distanceToWaypoints[targetWaypoint]
	
	if nextWaypoint == null:
		return -INF
	
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
	inaccessibleWaypoints[targetWaypoint] = -INF
	return -INF

# Checks to see if the supplied position is closer in waypoint directed distance
# to the next waypoint than this waypoint.
# In other words, is this position considered past this waypoint.
# position: global
func isPositionCloserToNextWaypoint(position: Vector3) -> bool:
	if nextWaypoint == null:
		return true
	
	var positionDistanceToNextWaypoint := nextWaypoint.getDistanceToPosition(position)
	var distanceToNextWaypoint := getDistanceToWaypoint(nextWaypoint)
	
	return (positionDistanceToNextWaypoint < distanceToNextWaypoint)


extends Spatial
class_name Waypoint

var nextWaypoint: Waypoint = null
#var distanceToNextWaypoint := 0.0 # TODO: Precalculate distance.

func _ready() -> void:
	pass

# position: global
func getDistanceToPosition(position: Vector3) -> float:
	return global_transform.origin.distance_to(position)

func getDistanceToWaypoint(targetWaypoint: Waypoint) -> float:
	if nextWaypoint == null:
		return 0.0
	
	var distance := 0.0
	
	var previousWaypoint := self
	var currentWaypoint := nextWaypoint
	while true:
		distance += previousWaypoint.getDistanceToPosition(currentWaypoint.global_transform.origin)
		
		if currentWaypoint == targetWaypoint:
			return distance
		
		previousWaypoint = currentWaypoint
		currentWaypoint = currentWaypoint.nextWaypoint
		
		if currentWaypoint == self:
			break
		
	# Error condition.
	return 0.0

# position: global
func isCloserToNextWaypoint(position: Vector3) -> bool:
	if nextWaypoint == null:
		return true
	
	var positionDistanceToNextWaypoint := nextWaypoint.getDistanceToPosition(position)
	var distanceToNextWaypoint := getDistanceToWaypoint(nextWaypoint) # TODO: Use precalculated distance?
	
	return (positionDistanceToNextWaypoint < distanceToNextWaypoint)


extends Controller
class_name AiController

export (float) var waypointDistanceTolerance = 5.0

var waypointIndex := -1
var currentWaypoint: Spatial = null

var previousDistanceToDestination := 0.0

var path = []
var pathIndex = 0

export (NodePath) var trackNodePath = null

func _ready() -> void:
	accelerating = true
	
	if currentWaypoint == null:
		currentWaypoint = getNextWaypoint()
		previousDistanceToDestination = getDistanceToWaypoint(currentWaypoint)

func _physics_process(delta: float) -> void:
	var parent: Spatial = get_parent()
	
	if get_parent().global_transform.origin.distance_to(currentWaypoint.global_transform.origin) < waypointDistanceTolerance:
		currentWaypoint = getNextWaypoint()
		previousDistanceToDestination = getDistanceToWaypoint(currentWaypoint)
	
	#while not isWaypointAhead(currentWaypoint):
	#	currentWaypoint = getNextAheadWaypoint()
	
	if getDistanceToWaypoint(currentWaypoint) > previousDistanceToDestination:
		currentWaypoint = getNextWaypoint()
		previousDistanceToDestination = getDistanceToWaypoint(currentWaypoint)
	
	updateTurnDirectionFromPath()

func getNextWaypoint() -> Spatial:
	waypointIndex += 1
	print("Waypoint %d" % waypointIndex)
	var track := get_node(trackNodePath) as Track
	return track.getWaypoint(waypointIndex)

func getNextAheadWaypoint() -> Spatial:
	var track := get_node(trackNodePath) as Track
	
	var currentWaypoint := track.getWaypoint(waypointIndex)
	while not isWaypointAhead(currentWaypoint):
		waypointIndex += 1
		currentWaypoint = track.getWaypoint(waypointIndex)
	
	return currentWaypoint

func isWaypointAhead(waypoint: Spatial) -> bool:
	return not doesDirectionRequireTurnaround(getLocalDirectionToWaypoint(waypoint))

func getDistanceToWaypoint(waypoint: Spatial) -> float:
	var parent: Spatial = get_parent()
	return parent.global_transform.origin.distance_to(waypoint.global_transform.origin)

func getLocalDirectionToWaypoint(waypoint: Spatial) -> Vector3:
	var parent: Spatial = get_parent()
	return parent.transform.origin.direction_to(parent.to_local(waypoint.global_transform.origin))

func doesDirectionRequireTurnaround(direction: Vector3) -> bool:
	var dotProduct := Vector3.FORWARD.dot(direction)
	return dotProduct < 0.0

func updateTurnDirectionFromPath() -> void:
	var parent: Spatial = get_parent()
	
	var position := currentWaypoint.global_transform.origin
	var lookingAtEuler: Vector3 = parent.global_transform.looking_at(position, Vector3.UP).basis.get_euler()
	
	if false:
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
			if angleDifference > 0.0:
				turnDirection = -1.0
			else:
				turnDirection = 1.0
	else:
		turnDirection = 0.0
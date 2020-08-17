extends Spatial
class_name Track

signal startSequenceFinished()
signal kartCrossedFinishLine(kart)

func _ready():
	pass

func getWaypoint(waypointIndex: int) -> Spatial:
	var numberOfWaypoints = $Navigation/Waypoints.get_child_count()
	return $Navigation/Waypoints.get_child(waypointIndex % numberOfWaypoints) as Spatial

func getNavigation() -> Navigation:
	return $Navigation as Navigation

func startStartSequence() -> void:
	$TrafficLight.startSequence()

func onTrafficLightSequenceFinished() -> void:
	emit_signal("startSequenceFinished")

func onFinishLineBodyEntered(body: Node) -> void:
	emit_signal("kartCrossedFinishLine", body)

func onItemPickedUp(item, kart) -> void:
	pass

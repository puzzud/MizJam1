extends Spatial
class_name Track

signal startSequenceFinished()
signal kartCrossedFinishLine(kart)
signal kartEnteredRoughZone(kart)
signal kartExitedRoughZone(kart)
signal itemPickedUp(item, kart)

func _ready():
	var trackOutside: Area = $RoughZones/TrackOutside
	var box: CollisionPolygon = trackOutside.get_node("Box")

func getWaypoint(waypointIndex: int) -> Spatial:
	var numberOfWaypoints = $Navigation/Waypoints.get_child_count()
	return $Navigation/Waypoints.get_child(waypointIndex % numberOfWaypoints) as Spatial

func getNavigation() -> Navigation:
	return $Navigation as Navigation

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

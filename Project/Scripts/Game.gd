extends Spatial
class_name Game

var kartLapCounts = []

var kartIds = {}

func _ready():
	initialKartIds()
	initialKartLapCounts()
	
	startTrafficLight()

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_F1):
		Engine.time_scale = 0.125
	else:
		Engine.time_scale = 1.0

func getKartIdFromKart(kart: Kart) -> int:
	return kartIds[kart]

func getKartLapCount(kartId) -> int:
	return kartLapCounts[kartId]

func increaseKartLapCount(kartId) -> void:
	kartLapCounts[kartId] += 1

func getTrack() -> Track:
	return $Track as Track

func initialKartIds() -> void:
	var id = 0
	for kart in $Karts.get_children():
		kartIds[kart] = id
		id += 1

func initialKartLapCounts() -> void:
	for i in range(0, kartIds.size()):
		kartLapCounts.append(-1)

func onTrackKartCrossedFinishLine(kart: Kart) -> void:
	var kartId = getKartIdFromKart(kart)
	
	print(kart.name + ":" + str(kartId) + " crossed finish line.")
	
	increaseKartLapCount(kartId)
	
	var kartLapCount = getKartLapCount(kartId)
	if kartLapCount > 0:
		print("Lap #" + str(kartLapCount))
		
		if kartLapCount >= 3:
			print(kart.name + " is the winner!")
			
			#endRace()

func endRace() -> void:
	get_tree().reload_current_scene()

func startTrafficLight() -> void:
	getTrack().startStartSequence()

func onTrackStartSequenceFinished() -> void:
	unlockAllKarts()

func unlockAllKarts() -> void:
	for _kart in $Karts.get_children():
		var kart: Kart = _kart
		kart.positionLocked = false

extends Spatial
class_name Game

const numberOfLaps := 3

var kartLapCounts = []

var kartIds = {}

var highestLapCountReached := 0
var numberOfKartsStarted := 0

func _ready():
	initializeKartIds()
	initializeKartLapCounts()
	
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

func initializeKartIds() -> void:
	var id = 0
	for kart in $Karts.get_children():
		kartIds[kart] = id
		id += 1

func initializeKartLapCounts() -> void:
	for i in range(0, kartIds.size()):
		kartLapCounts.append(-1)
	
	highestLapCountReached = 0
	numberOfKartsStarted = 0

func onTrackKartCrossedFinishLine(kart: Kart) -> void:
	var kartId = getKartIdFromKart(kart)
	
	print(kart.name + ":" + str(kartId) + " crossed finish line.")
	
	increaseKartLapCount(kartId)
	
	var kartLapCount = getKartLapCount(kartId)
	if kartLapCount > 0:
		if kartLapCount > highestLapCountReached:
			highestLapCountReached = kartLapCount
		
		print("Lap #" + str(kartLapCount))
		
		if kartLapCount >= numberOfLaps:
			print(kart.name + " is the winner!")
			
			#endRace()
	else:
		numberOfKartsStarted += 1
	
	if numberOfKartsStarted == kartIds.size():
		getTrack().showLapCount(highestLapCountReached + 1)

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

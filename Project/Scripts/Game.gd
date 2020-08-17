extends Spatial
class_name Game

const maxNumberOfLaps := 3

var kartLapNumbers = []

var kartIds = {}

func _ready():
	initializeKartIds()
	initializeKartLapNumbers()
	
	startTrafficLight()

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_F1):
		Engine.time_scale = 0.125
	else:
		Engine.time_scale = 1.0

func getKartIdFromKart(kart: Kart) -> int:
	return kartIds[kart]

func getKartLapNumber(kartId) -> int:
	return kartLapNumbers[kartId]

func increaseKartLapNumber(kartId) -> void:
	kartLapNumbers[kartId] += 1

func getHighestLapNumber() -> int:
	var highestLapNumber := 0
	
	for lapNumber in kartLapNumbers:
		if lapNumber > highestLapNumber:
			highestLapNumber = lapNumber
	
	return highestLapNumber

func getNumberOfKartsStarted() -> int:
	var numberOfKartsStarted := 0
	
	for lapNumber in kartLapNumbers:
		if lapNumber > 0:
			numberOfKartsStarted += 1
	
	return numberOfKartsStarted

func getTrack() -> Track:
	return $Track as Track

func initializeKartIds() -> void:
	var id = 0
	for kart in $Karts.get_children():
		kartIds[kart] = id
		id += 1

func initializeKartLapNumbers() -> void:
	for i in range(0, kartIds.size()):
		kartLapNumbers.append(0)

func onTrackKartCrossedFinishLine(kart: Kart) -> void:
	var kartId = getKartIdFromKart(kart)
	
	increaseKartLapNumber(kartId)
	
	var kartLapNumber = getKartLapNumber(kartId)
	print("Kart:%d Lap:%d" % [kartId, kartLapNumber])
	
	if kartLapNumber > maxNumberOfLaps + 1:
		# Race is already over.
		return
	elif kartLapNumber > maxNumberOfLaps:
		endRace()
	
	if getNumberOfKartsStarted() == kartIds.size():
		getTrack().showLapNumber(getHighestLapNumber())

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

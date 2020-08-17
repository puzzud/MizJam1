extends Spatial
class_name Game

const aiControllerPrefab := preload("res://Scenes/AiController.tscn")

const maxNumberOfLaps := 3

var kartLapNumbers = []

var kartIds = {}

var winnerKartId := -1

func _ready():
	initializeKartIds()
	initializeKartLapNumbers()
	
	startTrafficLight()

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_P):
		Engine.time_scale = 0.125
	else:
		Engine.time_scale = 1.0
	
	if Input.is_key_pressed(KEY_F1):
		restartRace()

func getKartIdFromKart(kart: Kart) -> int:
	return kartIds[kart]

func getHumanControlledKart() -> Kart:
	for _kart in $Karts.get_children():
		var kart: Kart = _kart
		if kart.has_node("Controller"):
			if kart.get_node("Controller") is HumanController:
				return kart
	
	return null

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

func haveAllKartsStarted() -> bool:
	for lapNumber in kartLapNumbers:
		if lapNumber == 0:
			return false
	
	return true

func haveAllKartsFinished() -> bool:
	for lapNumber in kartLapNumbers:
		if lapNumber <= maxNumberOfLaps:
			return false
	
	return true

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
		if winnerKartId == -1:
			winnerKartId = kartId
		
		if kartId == getKartIdFromKart(getHumanControlledKart()):
			endRace()
	
	if haveAllKartsStarted():
		getTrack().showLapNumber(getHighestLapNumber())

func endRace() -> void:
	issueRaceResultMessage()
	automateAllHumanControlledKarts()

func restartRace():
	get_tree().reload_current_scene()

func startTrafficLight() -> void:
	getTrack().startStartSequence()

func onTrackStartSequenceFinished() -> void:
	unlockAllKarts()

func unlockAllKarts() -> void:
	for _kart in $Karts.get_children():
		var kart: Kart = _kart
		kart.positionLocked = false

func automateAllHumanControlledKarts() -> void:
	var kart := getHumanControlledKart()
	if kart != null:
		automateKart(kart)

func automateKart(kart: Kart) -> void:
	kart.remove_child(kart.get_node("Controller"))
	var aiController := aiControllerPrefab.instance()
	aiController.name = "Controller"
	kart.add_child(aiController)

func issueRaceResultMessage() -> void:
	var kart := getHumanControlledKart()
	if kart == null:
		return
	
	var kartId := getKartIdFromKart(kart)
	if kartId == winnerKartId:
		$Ui/RaceResultMessage.text = "You Have Become a Winner!"
	else:
		$Ui/RaceResultMessage.text = "Try Again"

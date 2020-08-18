extends Spatial
class_name Game

const aiControllerPrefab := preload("res://Scenes/AiController.tscn")

const maxNumberOfLaps := 3

var kartLapNumbers = []

var kartIds = {}

var winnerKartId := -1

var raceStarted := false
var raceEnded := false
var raceTime := 0.0
var kartFinishTimes := []

func _ready():
	randomize()
	
	initializeKartIds()
	initializeKartLapNumbers()
	initializeKartFinishTimes()
	
	startTrafficLight()

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_P):
		Engine.time_scale = 0.125
	else:
		Engine.time_scale = 1.0
	
	if Input.is_key_pressed(KEY_F1):
		restartRace()

func _process(delta: float) -> void:
	if raceStarted:
		raceTime += delta
		
		if not raceEnded:
			updateTimeDisplay(raceTime)

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

func initializeKartFinishTimes() -> void:
	for i in range(0, kartIds.size()):
		kartFinishTimes.append(0.0)

func onTrackKartCrossedFinishLine(kart: Kart) -> void:
	var kartId = getKartIdFromKart(kart)
	
	increaseKartLapNumber(kartId)
	
	var kartLapNumber = getKartLapNumber(kartId)
	print("Kart:%d Lap:%d" % [kartId, kartLapNumber])
	
	if kartLapNumber > maxNumberOfLaps + 1:
		# Race is already over.
		return
	elif kartLapNumber > maxNumberOfLaps:
		kartFinishTimes[kartId] = raceTime
		
		if winnerKartId == -1:
			winnerKartId = kartId
		
		var humanControlledKart := getHumanControlledKart()
		if humanControlledKart != null:
			if kartId == getKartIdFromKart(humanControlledKart):
				updateTimeDisplay(raceTime)
				endRace()
	
	if haveAllKartsStarted():
		getTrack().showLapNumber(getHighestLapNumber())

func endRace() -> void:
	raceEnded = true
	issueRaceResultMessage()
	automateAllHumanControlledKarts()

func restartRace():
	get_tree().reload_current_scene()

func startTrafficLight() -> void:
	getTrack().startStartSequence()

func onTrackStartSequenceFinished() -> void:
	raceStarted = true
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
		$Ui/RaceResultMessage.text = "Winner!"
	else:
		$Ui/RaceResultMessage.text = "Loser!"

func updateTimeDisplay(time: float) -> void:
	var secondPercent := int((time - int(time)) * 100.0)
	var minutes := int(time / 60.0)
	var seconds := int(time - (minutes * 60))
	
	$Ui/Time.text = "%002d.%002d.%002d" % [minutes, seconds, secondPercent]

func updateCoinDisplay(coinCount: int) -> void:
	$Ui/CoinInfo/Count.text = str(coinCount)

func onTrackItemPickedUp(item: Spatial, kart: Kart) -> void:
	if item is Coin:
		kart.coinCount += 1
		
		if kart == getHumanControlledKart():
			updateCoinDisplay(kart.coinCount)

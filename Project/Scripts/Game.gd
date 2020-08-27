extends Spatial
class_name Game

signal sawInstructions()

const aiControllerPrefab := preload("res://Scenes/AiController.tscn")
const humanControllerPrefab := preload("res://Scenes/HumanController.tscn")

const racerColors := [
	Color("ff7777"),
	Color("0088ff"),
	Color("00cc55"),
	Color("cc44cc"),
	Color("aaffee"),
	Color("880000"),
	Color("333333"),
	Color("eeee77")
]

#const racerIconGemBarMaxWidth := 40

const maxNumberOfLaps := 4

var humanControlledKartId := 7

var kartLapNumbers = []

var kartIds = {}

var winnerKartId := -1

var raceStarted := false
var raceEnded := false
var raceTime := 0.0
var kartFinishTimes := {}
var kartOrders := []
var kartPreviousOrders := []

var instructionMessageIndex := -1

func _ready():
	Global.game = self
	
	connect("sawInstructions", Global, "onSawInstructions")
	
	$Ui/Race/CoinInfo/Symbol/ColorAnimationPlayer.play("Idle")
	
	startTitle()

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_P):
		Engine.time_scale = 0.125
	else:
		Engine.time_scale = 1.0
	
	if Input.is_key_pressed(KEY_F1):
		resetAllKartControls()
	if Input.is_key_pressed(KEY_F5):
		automateAllHumanControlledKarts()
	elif Input.is_key_pressed(KEY_F6):
		removeAllAutomatedKartControls()

func _process(delta: float) -> void:
	match Global.screenState:
		Global.ScreenStates.TITLE:
			# Rotate title cameras.
			$Viewports/ViewportContainerTop/ViewportTop/TitleCamera.rotate(Vector3.UP, deg2rad(1.0 * delta))
			$Viewports/ViewportContainerBottom/ViewportBottom/TitleCamera.rotate(Vector3.UP, deg2rad(1.0 * delta))
		
		Global.ScreenStates.RACE:
			if raceStarted:
				raceTime += delta
				
				if not raceEnded:
					updateTimeDisplay(raceTime)
			
			calculateKartOrders()
			updateOrderDisplay(getKartOrder(humanControlledKartId) + 1)

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

func getKartOrder(kartId: int) -> int:
	for i in range(0, kartOrders.size()):
		if kartOrders[i] == kartId:
			return i
	
	# Error condition.
	return 0

func getKartDistanceToFinishingRace(kartId: int) -> float:
	var track := getTrack()
	var kart := $Karts.get_child(kartId) as Kart
	
	var distanceToFinishLine := track.getDistanceToFinishLine(kart.global_transform.origin, kart.currentWaypoint)
	distanceToFinishLine += track.getTrackLength() * (maxNumberOfLaps - getKartLapNumber(kartId))
	
	return distanceToFinishLine

func isKartCloserToFinishingRace(kartIdA: int, kartIdB: int) -> bool:
	var kartAFinishTime: float = kartFinishTimes.get(kartIdA, INF)
	var kartBFinishTime: float = kartFinishTimes.get(kartIdB, INF)
	if kartAFinishTime < INF or kartBFinishTime < INF:
		return (kartAFinishTime < kartBFinishTime)
	
	#var kartALapNumber := getKartLapNumber(kartIdA)
	#var kartBLapNumber := getKartLapNumber(kartIdB)
	#if kartALapNumber != kartBLapNumber:
	#	return kartALapNumber < kartBLapNumber
	
	#var track := getTrack()
	
	#var kartA := $Karts.get_child(kartIdA) as Kart
	#var kartB := $Karts.get_child(kartIdB) as Kart
	
	#var kartADistanceToFinishLine := track.getDistanceToFinishLine(kartA.global_transform.origin, kartA.currentWaypoint)
	#var kartBDistanceToFinishLine := track.getDistanceToFinishLine(kartB.global_transform.origin, kartB.currentWaypoint)
	#return (kartADistanceToFinishLine < kartBDistanceToFinishLine)
	
	var kartADistanceToFinishingRace := getKartDistanceToFinishingRace(kartIdA)
	var kartBDistanceToFinishingRace := getKartDistanceToFinishingRace(kartIdB)
	return (kartADistanceToFinishingRace < kartBDistanceToFinishingRace)

func getTotalKartCoinCount() -> int:
	var totalKartCoinCount := 0
	
	for _kart in $Karts.get_children():
		var kart: Kart = _kart
		totalKartCoinCount += kart.coinCount
	
	return totalKartCoinCount

func getTrack() -> Track:
	return $Track as Track

func startTitle() -> void:
	$Viewports/ViewportContainerTop/ViewportTop/Camera.current = false
	$Viewports/ViewportContainerTop/ViewportTop/Camera/Listener.current = false
	$Viewports/ViewportContainerTop/ViewportTop/TitleCamera.current = true
	$Viewports/ViewportContainerTop/ViewportTop/TitleCamera/Listener.current = true
	
	$Viewports/ViewportContainerBottom/ViewportBottom/BirdsEyeCamera.current = false
	$Viewports/ViewportContainerBottom/ViewportBottom/TitleCamera.current = true
	
	$Ui/Race.visible = false
	$Ui/Title.visible = true

func startTransitionFromTitleToRace() -> void:
	resetRace()
	
	var tweenTime := 24.0
	
	var topTitleCamera: Camera = $Viewports/ViewportContainerTop/ViewportTop/TitleCamera
	var destTopCamera: Camera = $Viewports/ViewportContainerTop/ViewportTop/Camera
	var topCameraTween: Tween = $Viewports/ViewportContainerTop/ViewportTop/Tween
	topCameraTween.interpolate_property(topTitleCamera, "global_transform", topTitleCamera.global_transform, destTopCamera.global_transform, tweenTime, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	topCameraTween.start()
	
	var bottomTitleCamera: Camera = $Viewports/ViewportContainerBottom/ViewportBottom/TitleCamera
	var destBottomCamera: Camera = $Viewports/ViewportContainerBottom/ViewportBottom/BirdsEyeCamera
	var bottomCameraTween: Tween = $Viewports/ViewportContainerBottom/ViewportBottom/Tween
	bottomCameraTween.interpolate_property(bottomTitleCamera, "global_transform", bottomTitleCamera.global_transform, destBottomCamera.global_transform, tweenTime, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	bottomCameraTween.start()
	
	$Ui/Title.visible = false
	$Ui/TitleToRace.visible = true
	
	instructionMessageIndex = -1
	$Ui/TitleToRace/NumberOfLaps.text = "%d laps" % maxNumberOfLaps
	$Timers/InstructionMessageTimer.start()

func onInstructionMessageTimerTimeout() -> void:
	showNextInstruction()

func showNextInstruction() -> void:
	for message in $Ui/TitleToRace.get_children():
		message.visible = false
	
	instructionMessageIndex += 1
	if instructionMessageIndex >= $Ui/TitleToRace.get_child_count():
		return
	
	$Ui/TitleToRace.get_child(instructionMessageIndex).visible = true
	
	$Timers/InstructionMessageTimer.start()

func onTopCameraTweenCompleted() -> void:
	emit_signal("sawInstructions")
	
	startRace()

func startRace() -> void:
	Global.screenState = Global.ScreenStates.RACE
	
	$Viewports/ViewportContainerTop/ViewportTop/Tween.stop_all()
	$Viewports/ViewportContainerBottom/ViewportBottom/Tween.stop_all()
	
	startTrafficLight()
	
	$Viewports/ViewportContainerTop/ViewportTop/Camera.current = true
	$Viewports/ViewportContainerTop/ViewportTop/Camera/Listener.current = true
	$Viewports/ViewportContainerTop/ViewportTop/TitleCamera.current = false
	$Viewports/ViewportContainerTop/ViewportTop/TitleCamera/Listener.current = false
	
	$Viewports/ViewportContainerBottom/ViewportBottom/BirdsEyeCamera.current = true
	$Viewports/ViewportContainerBottom/ViewportBottom/TitleCamera.current = false
	
	$Ui/TitleToRace.visible = false
	$Ui/Race.visible = true
	
	$Ui/Race/RaceResultMessage.visible = false

func startTransitionFromRaceToRaceEnd() -> void:
	raceEnded = true
	
	var kart := getHumanControlledKart()
	if kart != null:
		var kartId := getKartIdFromKart(kart)
		var humanWinner := (kartId == winnerKartId)
		issueRaceResultMessage(humanWinner)
		playRaceEndMusic(humanWinner)
	
	automateAllHumanControlledKarts()
	
	$Ui/Race/LapInfo.visible = false
	$Ui/Race/PressStart.visible = true

func startTransitionFromRaceEndToRace() -> void:
	calculateKartOrders() # TODO: Not really necessary, replace with unfinished kart calculated finish times.
	resetRace()
	startTrafficLight()
	
	$Ui/Race/PressStart.visible = false
	
	$Ui/Race/RaceResultMessage.visible = false
	
	$AudioPlayers/RaceLoseMusic.stop()
	$AudioPlayers/RaceWinMusic.stop()
	$AudioPlayers/Track1Theme.stop()

func initializeTrack() -> void:
	getTrack().resetValues()

func initializeKarts() -> void:
	initializeKartIds()
	
	resetAllKarts()
	initializeKartsAtPolePositions()
	initializeKartWaypoints()
	initializeKartFinishTimes()
	initializeKartLapNumbers()
	initializeKartOrders()

func initializeKartIds() -> void:
	var id = 0
	for kart in $Karts.get_children():
		kartIds[kart] = id
		id += 1

func initializeKartLapNumbers() -> void:
	kartLapNumbers.clear()
	
	for i in range(0, kartIds.size()):
		kartLapNumbers.append(0)

func initializeKartFinishTimes() -> void:
	kartFinishTimes.clear()

func initializeKartOrders() -> void:
	if kartOrders.empty():
		kartOrders = kartIds.values().duplicate()
		kartOrders.sort()
	else:
		calculateKartOrders()

func initializeKartsAtPolePositions() -> void:
	var polePositionIndex := 0
	
	for kartId in kartOrders:
		initializeKartAtPolePosition(kartId, polePositionIndex)
		polePositionIndex += 1

func initializeKartAtPolePosition(kartId: int, polePositionIndex: int) -> void:
	var polePosition: Spatial = getTrack().getPolePositions()[polePositionIndex]
	
	var kart: Kart = $Karts.get_child(kartId)
	kart.global_transform = polePosition.global_transform

func initializeKartWaypoints() -> void:
	for _kart in $Karts.get_children():
		initializeKartWaypoint(_kart)

func initializeKartWaypoint(kart: Kart) -> void:
	kart.currentWaypoint = getTrack().getFinishLineWaypoint()

func onTrackKartCrossedFinishLine(kart: Kart) -> void:
	# TODO: Temporarily disabled the usage of this callback.
	pass

func onKartPassedWaypoint(kart: Kart, passedWaypoint: Waypoint) -> void:
	if passedWaypoint != getTrack().getFinishLineWaypoint():
		return
	
	# Cross finish line.
	
	var kartId = getKartIdFromKart(kart)
	
	increaseKartLapNumber(kartId)
	
	var kartLapNumber = getKartLapNumber(kartId)
	#print("Kart:%d Lap:%d" % [kartId, kartLapNumber])
	
	if kartLapNumber > maxNumberOfLaps + 1:
		# Race is already over.
		return
	
	var humanControlledKart := getHumanControlledKart()
	
	if kartLapNumber > maxNumberOfLaps:
		kartFinishTimes[kartId] = raceTime
		
		if winnerKartId == -1:
			winnerKartId = kartId
		
		if humanControlledKart != null:
			if kartId == getKartIdFromKart(humanControlledKart):
				updateTimeDisplay(raceTime)
				endRace()
	else:
		if humanControlledKart != null:
			if kartId == getKartIdFromKart(humanControlledKart):
				updateLapDisplay(kartLapNumber)
	
	if haveAllKartsStarted():
		getTrack().showLapNumber(getHighestLapNumber())

func endRace() -> void:
	Global.screenState = Global.ScreenStates.RACE_END
	startTransitionFromRaceToRaceEnd()

func calculateKartOrders() -> void:
	if kartOrders.empty():
		kartOrders = kartIds.values().duplicate()
	
	kartOrders.sort_custom(self, "isKartCloserToFinishingRace")
	
	var kartDistancesToFinishingRace = []
	for kartId in range(0, kartIds.size()):
		kartDistancesToFinishingRace.append(getKartDistanceToFinishingRace(kartId))
	
	if kartPreviousOrders != kartOrders:
		kartPreviousOrders = kartOrders.duplicate()
		updateRacerDisplay()

func resetRace() -> void:
	winnerKartId = -1
	raceStarted = false
	raceEnded = false
	raceTime = 0.0
	
	initializeTrack()
	initializeKarts()
	
	lockAllKarts(true)
	startAllKartEngines(true)
	
	$Ui/Race/LapInfo.visible = true
	updateTimeDisplay(raceTime)
	updateLapDisplay(0)
	updateCoinDisplay(0)
	updateRacerDisplay()

func restartGame() -> void:
	get_tree().reload_current_scene()

func startTrafficLight() -> void:
	getTrack().startStartSequence()

func onTrackStartSequenceFinished() -> void:
	raceStarted = true
	lockAllKarts(false)
	startAllKartEngines(true)
	
	startStartRaceMusic()

func lockAllKarts(lock: bool) -> void:
	for _kart in $Karts.get_children():
		var kart: Kart = _kart
		kart.positionLocked = lock

func startAllKartEngines(on: bool) -> void:
	for _kart in $Karts.get_children():
		var kart: Kart = _kart
		kart.startEngine(on)

func resetAllKarts() -> void:
	# Reset carts.
	for _kart in $Karts.get_children():
		var kart: Kart = _kart
		kart.resetValues()
	
	resetAllKartControls()

func resetAllKartControls() -> void:
	# Reset controls.
	for kartIndex in range(0, $Karts.get_child_count()):
		var kart: Kart = $Karts.get_child(kartIndex)
		if kartIndex == humanControlledKartId:
			giveHumanControlToKart(kart)
		else:
			automateKart(kart)

func automateAllHumanControlledKarts() -> void:
	var kart := getHumanControlledKart()
	if kart != null:
		automateKart(kart)

func removeAllAutomatedKartControls() -> void:
	for _kart in $Karts.get_children():
		var kart: Kart = _kart
		if kart.has_node("Controller") and kart.get_node("Controller") is AiController:
			removeKartController(kart)

func automateKart(kart: Kart) -> void:
	changeKartController(kart, aiControllerPrefab.instance())

func giveHumanControlToKart(kart: Kart) -> void:
	changeKartController(kart, humanControllerPrefab.instance())

func removeKartController(kart: Kart) -> void:
	changeKartController(kart, null)

func changeKartController(kart: Kart, controller: Controller) -> void:
	kart.remove_child(kart.get_node("Controller"))
	
	if controller != null:
		controller.name = "Controller"
		kart.add_child(controller)

func issueRaceResultMessage(humanWinner: bool) -> void:
	if humanWinner:
		$Ui/Race/RaceResultMessage.text = "Winner!"
	else:
		$Ui/Race/RaceResultMessage.text = "Loser!"
	
	$Ui/Race/RaceResultMessage.visible = true

func updateTimeDisplay(time: float) -> void:
	var secondPercent := int((time - int(time)) * 100.0)
	var minutes := int(time / 60.0)
	var seconds := int(time - (minutes * 60))
	
	$Ui/Race/Time.text = "%002d:%002d:%002d" % [minutes, seconds, secondPercent]

func updateOrderDisplay(orderNumber: int) -> void:
	$Ui/Race/Order.text = str(orderNumber)

func updateCoinDisplay(coinCount: int) -> void:
	$Ui/Race/CoinInfo/Count.text = str(coinCount)

func updateLapDisplay(lapNumber: int) -> void:
	var lapNumberString := ""
	if lapNumber > 0:
		lapNumberString = str(lapNumber)
	
	$Ui/Race/LapInfo/Count.text = lapNumberString

func updateRacerDisplay() -> void:
	#var totalKartCoinCount := getTotalKartCoinCount()
	
	for i in range(0, $Ui/Race/RacerInfo.get_child_count()):
		var racerIndex: int = kartOrders[i]
		
		var racerIcon: TextureRect = $Ui/Race/RacerInfo.get_child(i)
		racerIcon.modulate = racerColors[racerIndex]
		
		var racerCoinAmountBar: ColorRect = racerIcon.get_node("ColorRect")
		racerCoinAmountBar.rect_size.x = 1 * $Karts.get_child(racerIndex).coinCount

func onTrackItemPickedUp(item: Spatial, kart: Kart) -> void:
	if item is Coin:
		kart.coinCount += 1
		
		if getKartIdFromKart(kart) == humanControlledKartId:
			updateCoinDisplay(kart.coinCount)
		
		updateRacerDisplay()

func onTrackKartEnteredRoughZone(kart: Kart) -> void:
	kart.roughZoneCounter += 1

func onTrackKartExitedRoughZone(kart: Kart) -> void:
	kart.roughZoneCounter -= 1
	if kart.roughZoneCounter < 0:
		kart.roughZoneCounter = 0

func startStartRaceMusic() -> void:
	$AudioPlayers/StartRaceMusic.play()

func startThemeMusic() -> void:
	$AudioPlayers/Track1Theme.play()

func onStartRaceMusicFinished() -> void:
	startThemeMusic()

func playRaceEndMusic(humanWinner: bool) -> void:
	$AudioPlayers/Track1Theme.stop()
	
	if humanWinner:
		$AudioPlayers/RaceWinMusic.play()
	else:
		$AudioPlayers/RaceLoseMusic.play()

func onAuthorLinkPressed() -> void:
	OS.shell_open("https://puzzud.itch.io")

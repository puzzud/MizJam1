extends Spatial
class_name Game

signal sawInstructions()

const aiControllerPrefab := preload("res://Scenes/AiController.tscn")
const humanControllerPrefab := preload("res://Scenes/HumanController.tscn")

const maxNumberOfLaps := 3

var kartLapNumbers = []

var kartIds = {}

var winnerKartId := -1

var raceStarted := false
var raceEnded := false
var raceTime := 0.0
var kartFinishTimes := []

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
	
	if Input.is_key_pressed(KEY_F5):
		automateAllHumanControlledKarts()
	elif Input.is_key_pressed(KEY_F6):
		resetAllKartControls()

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
	
	$Ui/Race/PressStart.visible = true

func startTransitionFromRaceEndToRace() -> void:
	resetRace()
	startTrafficLight()
	
	$Ui/Race/PressStart.visible = false
	
	$Ui/Race/RaceResultMessage.visible = false
	
	$AudioPlayers/Track1Theme.stop()

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
	
	for i in range(0, kartIds.size()):
		kartFinishTimes.append(0.0)

func initializeKartsAtPolePositions() -> void:
	var polePositions := getTrack().getPolePositions()
	
	for kartIndex in range(0, kartIds.size()):
		var polePosition: Spatial = polePositions[kartIndex]
		var polePositionTransform: Transform = polePosition.global_transform
		
		var kart: Kart = $Karts.get_child(kartIndex)
		kart.global_transform = polePositionTransform

func onTrackKartCrossedFinishLine(kart: Kart) -> void:
	var kartId = getKartIdFromKart(kart)
	
	increaseKartLapNumber(kartId)
	
	var kartLapNumber = getKartLapNumber(kartId)
	print("Kart:%d Lap:%d" % [kartId, kartLapNumber])
	
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

func resetRace() -> void:
	winnerKartId = -1
	raceStarted = false
	raceEnded = false
	raceTime = 0.0
	updateTimeDisplay(raceTime)
	
	initializeKartIds()
	initializeKartLapNumbers()
	initializeKartFinishTimes()
	initializeKartsAtPolePositions()
	lockAllKarts(true)
	startAllKartEngines(true)
	resetAllKarts()
	
	updateLapDisplay(0)
	updateCoinDisplay(0)

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
		if kartIndex == 7:
			giveHumanControlToKart(kart)
		else:
			automateKart(kart)

func automateAllHumanControlledKarts() -> void:
	var kart := getHumanControlledKart()
	if kart != null:
		automateKart(kart)

func automateKart(kart: Kart) -> void:
	changeKartController(kart, aiControllerPrefab.instance())

func giveHumanControlToKart(kart: Kart) -> void:
	changeKartController(kart, humanControllerPrefab.instance())

func changeKartController(kart: Kart, controller: Controller) -> void:
	kart.remove_child(kart.get_node("Controller"))
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

func updateCoinDisplay(coinCount: int) -> void:
	$Ui/Race/CoinInfo/Count.text = str(coinCount)

func updateLapDisplay(lapNumber: int) -> void:
	var lapNumberString := ""
	if lapNumber > 0:
		lapNumberString = str(lapNumber)
	
	$Ui/Race/LapInfo/Count.text = lapNumberString

func onTrackItemPickedUp(item: Spatial, kart: Kart) -> void:
	if item is Coin:
		kart.coinCount += 1
		
		if kart == getHumanControlledKart():
			updateCoinDisplay(kart.coinCount)

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

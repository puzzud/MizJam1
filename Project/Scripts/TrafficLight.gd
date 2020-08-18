extends Spatial
class_name TrafficLight

signal sequenceFinished()

const lightOffColor := Color("333333")
const redLightColor := Color("880000")
const greenLightColor := Color("00cc55")

var lightOnStates := [
	false,
	false,
	false
]

var lightColors := [
	redLightColor,
	redLightColor,
	greenLightColor
]

func _ready() -> void:
	turnOffAllLights()

func getNumberOfLightsOn() -> int:
	var numberOfLightsOn := 0
	
	for on in lightOnStates:
		if on:
			numberOfLightsOn += 1
	
	return numberOfLightsOn

func areAllLightsOn() -> bool:
	return getNumberOfLightsOn() == lightOnStates.size()

func turnOnLight(lightIndex: int, on: bool) -> void:
	if lightIndex >= lightOnStates.size():
		printerr("Attempted to turn on nonexistant light: %d" % lightIndex)
		return
	
	lightOnStates[lightIndex] = on
	
	var light: Sprite3D = $CSGBox/Lights.get_child(lightIndex)
	if on:
		light.modulate = lightColors[lightIndex]
	else:
		light.modulate = lightOffColor

func turnOnNextLight() -> void:
	for i in range(0, lightOnStates.size()):
		if not lightOnStates[i]:
			turnOnLight(i, true)
			return

func turnOffAllLights() -> void:
	for i in range(0, lightOnStates.size()):
		turnOnLight(i, false)

func startSequence() -> void:
	turnOffAllLights()
	$Timers/SequenceTimer.start()

func onSequenceTimerTimeout() -> void:
	turnOnNextLight()
	
	if not areAllLightsOn():
		$AudioPlayers/Beep1.play()
		
		$Timers/SequenceTimer.start()
	else:
		$AudioPlayers/Beep2.play()
		
		emit_signal("sequenceFinished")

func showLapNumber(lapNumber: int) -> void:
	turnOffAllLights()
	for i in range(0, lapNumber):
		turnOnLight(i, true)

extends Spatial
class_name TrafficLight

signal sequenceFinished()

var lightOnStates := [
	false,
	false,
	false
]

var lightOffColor := Color.black + (Color.darkgray / 4.0)

var lightColors := [
	Color.red,
	Color.red,
	Color.green
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
	var light: Sprite3D = $CSGBox/Lights.get_child(lightIndex)
	if on:
		light.modulate = lightColors[lightIndex]
	else:
		light.modulate = lightOffColor

func turnOnNextLight() -> void:
	for i in range(0, lightOnStates.size()):
		if not lightOnStates[i]:
			lightOnStates[i] = true
			turnOnLight(i, true)
			return

func turnOffAllLights() -> void:
	for i in range(0, lightOnStates.size()):
		turnOnLight(i, false)

func startSequence() -> void:
	$Timers/SequenceTimer.start()

func onSequenceTimerTimeout() -> void:
	turnOnNextLight()
	
	if not areAllLightsOn():
		$AudioPlayers/Beep1.play()
		
		$Timers/SequenceTimer.start()
	else:
		$AudioPlayers/Beep2.play()
		
		emit_signal("sequenceFinished")

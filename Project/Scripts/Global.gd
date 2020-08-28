extends Node

const configFileName := "Configuration.ini"
const configFilePath := "user://" + configFileName

enum ScreenStates {
	NONE = -1,
	TITLE,
	TITLE_TO_RACE,
	RACE,
	RACE_END
}

enum ItemType {
	NONE = -1,
	SHIELD,
	MISSILE,
	SPEED_UP
}

const numberOfItemTypes = ItemType.SPEED_UP

var screenState: int = ScreenStates.NONE

var game: Game = null

var debug := false

var hasSeenInstructions := false
var isMuted := false setget setIsMuted

func _ready():
	loadConfiguration()
	randomize()
	
	screenState = ScreenStates.TITLE

func _input(event: InputEvent) -> void:
	match screenState:
		ScreenStates.TITLE:
			if event.is_action_pressed("ui_accept"):
				game.startTransitionFromTitleToRace()
				screenState = ScreenStates.TITLE_TO_RACE
		ScreenStates.TITLE_TO_RACE:
			if hasSeenInstructions:
				if event.is_action_pressed("ui_accept"):
					screenState = ScreenStates.RACE
					game.startRace()
			checkForEscape()
		ScreenStates.RACE:
			checkForEscape()
		ScreenStates.RACE_END:
			if event.is_action_pressed("ui_accept"):
				game.startTransitionFromRaceEndToRace()
				screenState = ScreenStates.RACE
			checkForEscape()
	
	if Input.is_key_pressed(KEY_F2):
		debug = true
	
	if event.is_action_pressed("client_mute_all_sound"):
		setIsMuted(not isMuted)
		saveConfiguration()

func setIsMuted(newIsMuted: bool) -> void:
	isMuted = newIsMuted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), newIsMuted)

func loadConfiguration() -> void:
	var configFile = ConfigFile.new() 
	var result = configFile.load(configFilePath)
	if result != OK:
		return
	
	var _hasSeenInstructions = configFile.get_value("Game", "HasSeenInstructions")
	if _hasSeenInstructions != null:
		hasSeenInstructions = _hasSeenInstructions
	
	var _isMuted = configFile.get_value("Game", "IsMuted")
	if _isMuted != null:
		setIsMuted(_isMuted)

func saveConfiguration() -> void:
	var configFile = ConfigFile.new()
	
	configFile.set_value("Game", "HasSeenInstructions", hasSeenInstructions)
	configFile.set_value("Game", "IsMuted", isMuted)
	
	configFile.save(configFilePath)

func onSawInstructions() -> void:
	if not hasSeenInstructions:
		hasSeenInstructions = true
		saveConfiguration()

func checkForEscape() -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		screenState = ScreenStates.TITLE
		game.restartGame()

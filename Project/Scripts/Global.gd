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

var screenState: int = ScreenStates.NONE

var game: Game = null

var hasSeenInstructions := false

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

func loadConfiguration() -> void:
	var configFile = ConfigFile.new() 
	var result = configFile.load(configFilePath)
	if result != OK:
		return
	
	var _hasSeenInstructions = configFile.get_value("Game", "HasSeenInstructions")
	if _hasSeenInstructions != null:
		hasSeenInstructions = _hasSeenInstructions

func saveConfiguration() -> void:
	var configFile = ConfigFile.new()
	
	configFile.set_value("Game", "HasSeenInstructions", hasSeenInstructions)

func onSawInstructions() -> void:
	if not hasSeenInstructions:
		hasSeenInstructions = true
		saveConfiguration()

func checkForEscape() -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		screenState = ScreenStates.TITLE
		game.restartGame()

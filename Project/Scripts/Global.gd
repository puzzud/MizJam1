extends Node

enum ScreenStates {
	NONE = -1,
	TITLE,
	TITLE_TO_RACE,
	RACE,
	RACE_END
}

var screenState: int = ScreenStates.NONE

var game: Game = null

func _ready():
	screenState = ScreenStates.TITLE

func _input(event: InputEvent) -> void:
	match screenState:
		ScreenStates.TITLE:
			if event.is_action_pressed("ui_accept"):
				game.startTransitionFromTitleToRace()
				screenState = ScreenStates.TITLE_TO_RACE
		ScreenStates.TITLE_TO_RACE:
			if event.is_action_pressed("ui_accept"):
				screenState = ScreenStates.RACE
				game.startRace()
		ScreenStates.RACE:
			if Input.is_key_pressed(KEY_ESCAPE):
				screenState = ScreenStates.TITLE
				game.restartGame()
		ScreenStates.RACE_END:
			if event.is_action_pressed("ui_accept"):
				game.startTransitionFromRaceEndToRace()
				screenState = ScreenStates.RACE

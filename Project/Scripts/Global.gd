extends Node

enum ScreenStates {
	NONE = -1,
	TITLE,
	TITLE_TO_RACE,
	RACE
}

var screenState: int = ScreenStates.NONE

var game: Game = null

func _ready():
	screenState = ScreenStates.TITLE

func _input(event: InputEvent) -> void:
	match screenState:
		ScreenStates.TITLE:
			if event.is_action_pressed("ui_accept"):
				screenState = ScreenStates.TITLE_TO_RACE
				game.startTransitionFromTitleToRace()

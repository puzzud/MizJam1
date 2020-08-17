extends Controller
class_name HumanController

func _process(delta: float) -> void:
	turnDirection = Input.get_action_strength("game_turn_right") - Input.get_action_strength("game_turn_left")
	accelerating = Input.get_action_strength("game_accelerate")
	braking = Input.get_action_strength("game_brake")

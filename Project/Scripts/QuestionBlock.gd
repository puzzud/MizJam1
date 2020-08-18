extends Area
class_name QuestionBlock

signal itemPickedUp(item, kart)

func _ready() -> void:
	#resetValues()
	pass

func resetValues() -> void:
	$CollisionShape.disabled = false
	$AnimationPlayer.play("Idle")

func disable() -> void:
	$CollisionShape.disabled = true
	$Timers/RespawnTimer.start()
	
	$AnimationPlayer.play("PickedUp")

func onBodyEntered(body: Node) -> void:
	emit_signal("itemPickedUp", self, body)
	disable()

func onRespawnTimerTimeout() -> void:
	resetValues()

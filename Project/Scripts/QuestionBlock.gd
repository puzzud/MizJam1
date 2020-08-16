extends Area
class_name QuestionBlock

signal itemPickedUp(item, kart)

func _ready() -> void:
	pass

func onBodyEntered(body: Node) -> void:
	emit_signal("itemPickedUp", self, body)
	
	$CollisionShape.disabled = true
	$Timers/RespawnTimer.start()
	
	$AnimationPlayer.play("PickedUp")

func onRespawnTimerTimeout() -> void:
	$CollisionShape.disabled = false
	$AnimationPlayer.play("Idle")

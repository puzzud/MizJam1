extends Area
class_name Coin

signal itemPickedUp(item, kart)

func _ready() -> void:
	pass

func onCoinBodyEntered(body: Node) -> void:
	emit_signal("itemPickedUp", self, body)
	
	$CollisionShape.disabled = true
	$Timers/RespawnTimer.start()
	
	$AnimationPlayer.play("PickedUp")

func onRespawnTimerTimeout() -> void:
	$CollisionShape.disabled = false
	$Sprite3D.visible = true
	$AnimationPlayer.play("Idle")

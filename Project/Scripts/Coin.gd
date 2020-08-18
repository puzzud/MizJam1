extends Area
class_name Coin

signal itemPickedUp(item, kart)

func _ready() -> void:
	resetValues()

func resetValues() -> void:
	$CollisionShape.disabled = false
	$Sprite3D.visible = true
	$AnimationPlayer.play("Idle")

func onCoinBodyEntered(body: Node) -> void:
	emit_signal("itemPickedUp", self, body)
	
	$CollisionShape.disabled = true
	$Timers/RespawnTimer.start()
	
	$AnimationPlayer.play("PickedUp")
	$AudioPlayers/Pickup.play()

func onRespawnTimerTimeout() -> void:
	resetValues()

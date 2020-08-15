extends Spatial
class_name Track

signal kartCrossedFinishLine(kart)

func _ready():
	pass

func onFinishLineBodyEntered(body: Node) -> void:
	emit_signal("kartCrossedFinishLine", body)

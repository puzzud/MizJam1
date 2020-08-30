extends Camera
class_name FollowingCamera

export (NodePath) var targetNodePath = null

export (float) var followDistance = 3.0

var target: Spatial = null setget setTarget

func _ready():
	pass

func _physics_process(delta: float) -> void:
	if target == null:
		setTarget(get_node(targetNodePath))
	
	look_at(target.global_transform.origin, Vector3.UP)
	
	var followHeight = global_transform.origin.y
	
	global_transform.origin = target.global_transform.origin + (target.global_transform.basis.z * followDistance)
	
	global_transform.origin.y = followHeight

func setTarget(newTarget: Spatial) -> void:
	target = newTarget

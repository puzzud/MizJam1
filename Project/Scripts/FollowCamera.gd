extends Camera
class_name FollowingCamera

export (NodePath) var targetNodePath = null

export (float) var followDistance = 3.0

func _ready():
	pass

func _physics_process(delta: float) -> void:
	var target = get_node(targetNodePath) as Spatial
	if target == null:
		return
	
	look_at(target.global_transform.origin, Vector3.UP)
	
	var followHeight = global_transform.origin.y
	
	global_transform.origin = target.global_transform.origin + (target.global_transform.basis.z * followDistance)
	
	global_transform.origin.y = followHeight

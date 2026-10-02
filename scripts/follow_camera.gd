extends Node
class_name OdeaFollowCamera
## Seguimiento amortiguado con altura de salto atenuada e impacto de aterrizaje.

const OFFSET: Vector3 = Vector3(7.0, 13.0, 12.0)
var camera: Camera3D
var avatar: Node3D
var focus: Vector3 = Vector3.ZERO
var impact_offset: float = 0.0

func setup(view: Camera3D, body: Node3D) -> void:
	camera = view
	avatar = body
	snap()

func snap() -> void:
	focus = avatar.global_position
	impact_offset = 0.0
	camera.global_position = focus + OFFSET
	camera.look_at(focus + Vector3.UP * 1.2, Vector3.UP)

func on_landed(impact: float) -> void:
	impact_offset = -clampf(impact * 0.018, 0.0, 0.22)

func _process(delta: float) -> void:
	if camera == null or avatar == null:
		return
	var body_position: Vector3 = avatar.global_position
	var target: Vector3 = Vector3(body_position.x, body_position.y * 0.35, body_position.z)
	focus = focus.lerp(target, 1.0 - exp(-delta * 5.0))
	impact_offset = lerpf(impact_offset, 0.0, 1.0 - exp(-delta * 12.0))
	var goal: Vector3 = focus + OFFSET + Vector3.UP * impact_offset
	camera.global_position = camera.global_position.lerp(goal, 1.0 - exp(-delta * 6.0))
	camera.look_at(focus + Vector3.UP * 1.2, Vector3.UP)

extends MultiMeshInstance3D
class_name OdeaAvatarDust
## Polvo reutilizable: una malla compartida y un solo draw call.

const CAPACITY: int = 32
var ages: PackedFloat32Array = PackedFloat32Array()
var positions: PackedVector3Array = PackedVector3Array()
var velocities: PackedVector3Array = PackedVector3Array()
var cursor: int = 0

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.4, 1.0, 0.9, 0.55)
	mesh.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = CAPACITY
	ages.resize(CAPACITY)
	positions.resize(CAPACITY)
	velocities.resize(CAPACITY)
	for i: int in range(CAPACITY):
		ages[i] = -1.0
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3.ZERO))
		multimesh.set_instance_color(i, Color(1.0, 1.0, 1.0, 0.0))
	set_physics_process(false)

func puff(origin: Vector3, count: int, impact: float = 1.0) -> void:
	for i: int in range(mini(count, CAPACITY)):
		var angle: float = float(i) * TAU / float(maxi(count, 1)) + float(cursor) * 0.7
		positions[cursor] = origin + Vector3(0.0, 0.05, 0.0)
		velocities[cursor] = Vector3(cos(angle), 0.65, sin(angle)) * impact
		ages[cursor] = 0.0
		cursor = (cursor + 1) % CAPACITY
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	var active: bool = false
	for i: int in range(CAPACITY):
		if ages[i] < 0.0:
			continue
		ages[i] += delta
		var fade: float = 1.0 - ages[i] / 0.42
		if fade <= 0.0:
			ages[i] = -1.0
			multimesh.set_instance_color(i, Color(1.0, 1.0, 1.0, 0.0))
			continue
		active = true
		positions[i] += velocities[i] * delta
		var size: float = 0.055 + ages[i] * 0.12
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), positions[i]))
		multimesh.set_instance_color(i, Color(0.5, 1.0, 0.9, fade))
	if not active:
		set_physics_process(false)

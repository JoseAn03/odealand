extends Node3D
class_name OdeaAvatarRig
## Avatar procedural: pivotes reales, botas solidarias y ciclo de cuatro poses.

const DustSystem = preload("res://scripts/avatar_dust.gd")
const HIP_POSES: PackedFloat32Array = [0.85, 0.0, -0.85, 0.0]
const KNEE_POSES: PackedFloat32Array = [0.10, 0.08, 0.35, 0.95]
var visual: Node3D
var torso: Node3D
var cape: Node3D
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var shoulders: Array[Node3D] = []
var dust: OdeaAvatarDust
var cycle: float = 0.0
var gait_weight: float = 0.0
var landing_weight: float = 0.0
var breath: float = 0.0
var wave_t: float = -1.0
var celebrate_t: float = -1.0

func _ready() -> void:
	visual = Node3D.new()
	add_child(visual)
	var cyan: StandardMaterial3D = _material(Color(0.0, 1.0, 0.85), 0.6)
	var violet: StandardMaterial3D = _material(Color(0.55, 0.4, 1.0), 0.25)
	var pink: StandardMaterial3D = _material(Color(1.0, 0.35, 0.85), 0.6)
	var dark: StandardMaterial3D = _material(Color(0.15, 0.18, 0.3), 0.4)
	_build_legs(cyan, violet)
	torso = _pivot(visual, Vector3(0.0, 1.05, 0.0))
	_capsule(torso, Vector3(0.0, 0.25, 0.0), 0.27, 0.85, cyan)
	_box(torso, Vector3(0.0, 0.33, 0.23), Vector3(0.42, 0.32, 0.14), dark)
	_build_arms(cyan, pink)
	_sphere(torso, Vector3(0.0, 0.95, 0.0), 0.33, dark)
	_box(torso, Vector3(0.0, 0.95, 0.3), Vector3(0.46, 0.16, 0.12), _material(Color(0.6, 1.0, 1.0), 2.0))
	_box(torso, Vector3(0.0, 1.23, -0.05), Vector3(0.08, 0.3, 0.5), pink)
	_box(torso, Vector3(0.0, 0.25, -0.31), Vector3(0.44, 0.5, 0.22), dark)
	var thruster: StandardMaterial3D = _material(Color(1.0, 0.7, 0.2), 1.5)
	for side: float in [-1.0, 1.0]:
		_capsule(torso, Vector3(0.24 * side, 0.06, -0.35), 0.09, 0.28, thruster)
	cape = _pivot(torso, Vector3(0.0, 0.6, -0.24))
	_box(cape, Vector3(0.0, -0.43, 0.0), Vector3(0.6, 0.8, 0.05), pink)
	dust = DustSystem.new()
	add_child(dust)

func _build_legs(boot_material: StandardMaterial3D, suit: StandardMaterial3D) -> void:
	for side: float in [-1.0, 1.0]:
		var hip: Node3D = _pivot(visual, Vector3(0.17 * side, 0.9, 0.0))
		_capsule(hip, Vector3(0.0, -0.17, 0.0), 0.105, 0.34, suit)
		var knee: Node3D = _pivot(hip, Vector3(0.0, -0.34, 0.0))
		_capsule(knee, Vector3(0.0, -0.18, 0.0), 0.09, 0.36, suit)
		_box(knee, Vector3(0.0, -0.46, 0.055), Vector3(0.24, 0.2, 0.34), boot_material)
		hips.append(hip)
		knees.append(knee)

func _build_arms(suit: StandardMaterial3D, sleeves: StandardMaterial3D) -> void:
	for side: float in [-1.0, 1.0]:
		var shoulder: Node3D = _pivot(torso, Vector3(0.4 * side, 0.48, 0.0))
		_sphere(shoulder, Vector3.ZERO, 0.13, suit)
		_capsule(shoulder, Vector3(0.0, -0.25, 0.0), 0.085, 0.5, sleeves)
		# mano (guante)
		_sphere(shoulder, Vector3(0.0, -0.52, 0.0), 0.1, suit)
		shoulders.append(shoulder)

func animate(delta: float, speed: float, running: bool, grounded: bool, vertical_speed: float) -> void:
	var blend: float = 1.0 - exp(-delta * 24.0)
	gait_weight = lerpf(gait_weight, clampf(speed / 2.5, 0.0, 1.0) if grounded else 0.0, blend)
	landing_weight = move_toward(landing_weight, 0.0, delta * 4.0)
	var old_contact: int = int(floor(cycle * 2.0))
	if grounded and speed > 0.1:
		cycle += speed * delta / (5.0 if running else 3.8)
	var new_contact: int = int(floor(cycle * 2.0))
	if grounded and speed > 0.8 and new_contact != old_contact:
		var foot: float = -1.0 if new_contact % 2 == 0 else 1.0
		dust.puff(global_position + global_basis.x * foot * 0.18, 3, 0.8 if running else 0.5)
		AudioManager.play("step", 0.25)
	cycle = fmod(cycle, 2.0)
	var amplitude: float = 1.25 if running else 1.0
	for i: int in range(2):
		var phase: float = fposmod(cycle + float(i) * 0.5, 1.0)
		var hip_angle: float = _pose(HIP_POSES, phase) * amplitude * gait_weight
		var knee_angle: float = _pose(KNEE_POSES, phase) * gait_weight
		var arm_angle: float = -hip_angle * 0.8
		if not grounded:
			hip_angle = -0.4 if i == 0 else 0.35
			knee_angle = 0.8 if vertical_speed > 0.0 else 0.35
			arm_angle = -0.9 if vertical_speed > 0.0 else -0.4
		hips[i].rotation.x = lerpf(hips[i].rotation.x, hip_angle, blend)
		knees[i].rotation.x = lerpf(knees[i].rotation.x, knee_angle, blend)
		if wave_t < 0.0 and celebrate_t < 0.0:
			shoulders[i].rotation.x = lerpf(shoulders[i].rotation.x, arm_angle, blend)
			shoulders[i].rotation.z = lerpf(shoulders[i].rotation.z, 0.0, blend)
	# saludo (wave) y celebración
	if wave_t >= 0.0:
		wave_t += delta
		if wave_t > 1.8:
			wave_t = -1.0
		else:
			shoulders[1].rotation.x = -1.4
			shoulders[1].rotation.z = sin(wave_t * 16.0) * 0.6
	if celebrate_t >= 0.0:
		celebrate_t += delta
		if celebrate_t > 2.0:
			celebrate_t = -1.0
		else:
			for i: int in range(2):
				shoulders[i].rotation.x = -2.2
				shoulders[i].rotation.z = sin(celebrate_t * 14.0 + float(i) * 0.7) * 0.3
	# respiración idle
	var idle: float = clampf(1.0 - speed / 1.0, 0.0, 1.0) * (1.0 if grounded else 0.0)
	if idle > 0.01:
		breath += delta * 2.2
		torso.scale.y = 1.0 + sin(breath) * 0.02 * idle
		torso.scale.x = 1.0 - sin(breath) * 0.012 * idle
		torso.scale.z = 1.0 - sin(breath) * 0.012 * idle
	else:
		breath = 0.0
		torso.scale = Vector3.ONE
	var bob: float = (1.0 - cos(cycle * TAU * 2.0)) * 0.035 * gait_weight
	visual.position.y = bob - landing_weight * 0.14
	torso.rotation.z = sin(cycle * TAU) * 0.07 * gait_weight
	torso.rotation.x = lerpf(torso.rotation.x, (0.16 if running else 0.05) * gait_weight + landing_weight * 0.12, blend)
	cape.rotation.x = -0.1 - speed * 0.025 + sin(cycle * TAU) * 0.12

func land(impact: float) -> void:
	landing_weight = clampf(impact / 12.0, 0.2, 1.0)
	dust.puff(global_position, 12, clampf(impact / 8.0, 0.7, 1.8))

func wave() -> void:
	wave_t = 0.0

func celebrate() -> void:
	celebrate_t = 0.0

func reset_pose() -> void:
	cycle = 0.0
	gait_weight = 0.0
	landing_weight = 0.0
	breath = 0.0
	wave_t = -1.0
	celebrate_t = -1.0
	visual.position = Vector3.ZERO
	torso.rotation = Vector3.ZERO
	torso.scale = Vector3.ONE
	for pivot: Node3D in hips + knees + shoulders:
		pivot.rotation = Vector3.ZERO

func _pose(poses: PackedFloat32Array, phase: float) -> float:
	var sample: float = phase * 4.0
	var index: int = int(floor(sample)) % 4
	var weight: float = smoothstep(0.0, 1.0, sample - floor(sample))
	return lerpf(poses[index], poses[(index + 1) % 4], weight)

func _pivot(parent: Node3D, location: Vector3) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.position = location
	parent.add_child(pivot)
	return pivot

func _material(color: Color, glow: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.45
	material.metallic = 0.3
	material.emission_enabled = glow > 0.0
	material.emission = color
	material.emission_energy_multiplier = glow
	return material

func _mesh(parent: Node3D, location: Vector3, mesh: Mesh, material: StandardMaterial3D) -> void:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = location
	parent.add_child(instance)

func _capsule(parent: Node3D, location: Vector3, radius: float, height: float, material: StandardMaterial3D) -> void:
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 4
	_mesh(parent, location, mesh, material)

func _sphere(parent: Node3D, location: Vector3, radius: float, material: StandardMaterial3D) -> void:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	_mesh(parent, location, mesh, material)

func _box(parent: Node3D, location: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	_mesh(parent, location, mesh, material)

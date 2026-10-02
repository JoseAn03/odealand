extends Node
class_name OdeaAvatarMotion
## Física de la fase 1 sobre el plano de viaje existente, no sobre las esferas.

signal landed(impact: float)
const WALK_SPEED: float = 6.0
const RUN_SPEED: float = 11.0
const GRAVITY: float = 25.0
const JUMP_IMPULSE: float = 9.5
const DOUBLE_IMPULSE: float = 8.5
const GROUND_Y: float = 0.0
var avatar: OdeaAvatarRig
var velocity: Vector3 = Vector3.ZERO
var grounded: bool = true
var jumps_used: int = 0
var jump_buffer: float = 0.0

func setup(body: OdeaAvatarRig) -> void:
	avatar = body

func request_jump() -> void:
	# El tercer salto no queda en cola para producir un salto al aterrizar.
	if jumps_used < 2:
		jump_buffer = 0.12

func step(delta: float, direction: Vector3, running: bool) -> void:
	if avatar == null:
		return
	var horizontal: Vector3 = Vector3(direction.x, 0.0, direction.z).limit_length(1.0)
	var target_velocity: Vector3 = horizontal * (RUN_SPEED if running else WALK_SPEED)
	var acceleration: float = 28.0 if horizontal.length_squared() > 0.01 else 36.0
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	if jump_buffer > 0.0 and jumps_used < 2:
		velocity.y = JUMP_IMPULSE if jumps_used == 0 else DOUBLE_IMPULSE
		jumps_used += 1
		grounded = false
		jump_buffer = 0.0
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if not grounded:
		velocity.y -= GRAVITY * delta
	avatar.position += velocity * delta
	if avatar.position.y <= GROUND_Y and not grounded:
		var impact: float = absf(velocity.y)
		avatar.position.y = GROUND_Y
		velocity.y = 0.0
		grounded = true
		jumps_used = 0
		avatar.land(impact)
		landed.emit(impact)
	var speed: float = Vector2(velocity.x, velocity.z).length()
	if speed > 0.1:
		var heading: float = atan2(velocity.x, velocity.z)
		avatar.rotation.y = lerp_angle(avatar.rotation.y, heading, 1.0 - exp(-delta * 12.0))
	avatar.animate(delta, speed, running, grounded, velocity.y)

func stop_horizontal() -> void:
	velocity.x = 0.0
	velocity.z = 0.0

func reset(location: Vector3 = Vector3.ZERO) -> void:
	velocity = Vector3.ZERO
	grounded = true
	jumps_used = 0
	jump_buffer = 0.0
	avatar.position = Vector3(location.x, GROUND_Y, location.z)
	avatar.reset_pose()

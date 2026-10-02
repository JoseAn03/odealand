extends Node
class_name OdeaAvatarControls
## Entrada PC y multitáctil; liberar un dedo nunca depende de que la UI lo consuma.

signal jump_requested
signal planet_tapped(position: Vector2)
const JOY_RADIUS: float = 70.0
var camera: Camera3D
var overlay: Control
var stick: Control
var jump_button: Button
var run_button: Button
var enabled: bool = true
var pointer_index: int = -1
var run_index: int = -1
var jump_index: int = -1
var start: Vector2 = Vector2.ZERO
var last_position: Vector2 = Vector2.ZERO
var axis: Vector2 = Vector2.ZERO
var dragging: bool = false
var in_stick: bool = false
var mouse_running: bool = false
var mouse_pointer: bool = false
var last_touch_ms: int = -1000

func setup(view: Camera3D, layer: CanvasLayer) -> void:
	camera = view
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	stick = Control.new()
	stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stick.position = Vector2(22.0, -280.0)
	stick.size = Vector2(160.0, 160.0)
	stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick.draw.connect(_draw_stick)
	overlay.add_child(stick)
	jump_button = _button("SALTAR\n×2", Vector2(-132.0, -280.0))
	run_button = _button("CORRER", Vector2(-132.0, -190.0))

func _button(text: String, offset: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.position = offset
	button.size = Vector2(110.0, 76.0)
	# Los contactos se identifican por dedo, sin emular un único ratón.
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	overlay.add_child(button)
	return button

func set_enabled(value: bool) -> void:
	if enabled == value:
		return
	enabled = value
	overlay.visible = value
	if not value:
		clear()

func clear() -> void:
	pointer_index = -1
	run_index = -1
	jump_index = -1
	mouse_pointer = false
	mouse_running = false
	dragging = false
	axis = Vector2.ZERO
	if stick != null:
		stick.queue_redraw()

func movement() -> Vector3:
	if not enabled:
		return Vector3.ZERO
	var keyboard: Vector2 = Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	)
	var input_axis: Vector2 = (axis + keyboard).limit_length(1.0)
	var forward: Vector3 = -camera.global_basis.z
	forward.y = 0.0
	var right: Vector3 = camera.global_basis.x
	right.y = 0.0
	return (right.normalized() * input_axis.x - forward.normalized() * input_axis.y).limit_length(1.0)

func running() -> bool:
	return enabled and (run_index >= 0 or mouse_running or Input.is_physical_key_pressed(KEY_SHIFT))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		last_touch_ms = Time.get_ticks_msec()
		if not touch.pressed:
			if touch.index == pointer_index:
				_release(touch.position)
			if touch.index == run_index:
				run_index = -1
			if touch.index == jump_index:
				jump_index = -1
		elif enabled and jump_button.get_global_rect().has_point(touch.position):
			if jump_index < 0:
				jump_index = touch.index
				jump_requested.emit()
			get_viewport().set_input_as_handled()
		elif enabled and run_button.get_global_rect().has_point(touch.position):
			run_index = touch.index
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		if button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
			mouse_running = false
			if mouse_pointer:
				_release(button.position)
				mouse_pointer = false

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and not key.echo and key.physical_keycode == KEY_SPACE:
			jump_requested.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed and pointer_index < 0:
			_begin(touch.position, touch.index)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == pointer_index:
			_drag(drag.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		# Evitar que el clic emulado repita el toque de Android.
		if Time.get_ticks_msec() - last_touch_ms < 350:
			return
		var button: InputEventMouseButton = event
		if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
			if jump_button.get_global_rect().has_point(button.position):
				jump_requested.emit()
			elif run_button.get_global_rect().has_point(button.position):
				mouse_running = true
			else:
				mouse_pointer = true
				_begin(button.position, -2)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and mouse_pointer:
		var mouse: InputEventMouseMotion = event
		_drag(mouse.position)

func _begin(position: Vector2, index: int) -> void:
	pointer_index = index
	in_stick = stick.get_global_rect().has_point(position)
	start = stick.get_global_rect().get_center() if in_stick else position
	last_position = position
	dragging = in_stick
	axis = Vector2.ZERO
	if in_stick:
		_drag(position)

func _drag(position: Vector2) -> void:
	last_position = position
	var difference: Vector2 = position - start
	if difference.length() > 18.0:
		dragging = true
	axis = (difference / JOY_RADIUS).limit_length(1.0) if difference.length() > 10.0 else Vector2.ZERO
	stick.queue_redraw()

func _release(position: Vector2) -> void:
	var tapped: bool = enabled and not dragging and position.distance_to(start) < 18.0
	pointer_index = -1
	dragging = false
	axis = Vector2.ZERO
	stick.queue_redraw()
	if tapped:
		planet_tapped.emit(position)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear()

func _draw_stick() -> void:
	stick.draw_circle(Vector2(80.0, 80.0), JOY_RADIUS, Color(0.02, 0.08, 0.15, 0.65))
	stick.draw_arc(Vector2(80.0, 80.0), JOY_RADIUS, 0.0, TAU, 32, Color(0.0, 1.0, 0.85, 0.75), 2.0, true)
	stick.draw_circle(Vector2(80.0, 80.0) + axis * 48.0, 24.0, Color(0.0, 1.0, 0.85, 0.7))

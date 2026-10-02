extends Node3D
## ODEALAND — Fase 1: movimiento, avatar articulado y cámara suave.

const CHAPTER_COUNT: int = 8
const AVATAR_SCALE: float = 1.15
const AvatarRig = preload("res://scripts/avatar_rig.gd")
const AvatarMotion = preload("res://scripts/avatar_motion.gd")
const AvatarControls = preload("res://scripts/avatar_controls.gd")
const FollowCamera = preload("res://scripts/follow_camera.gd")

const SKY_SHADER: String = """
shader_type sky;
uniform vec3 top_col : source_color = vec3(0.02, 0.01, 0.06);
uniform vec3 bot_col : source_color = vec3(0.10, 0.02, 0.16);
void sky() {
	float h = clamp(EYEDIR.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 col = mix(bot_col, top_col, h);
	vec3 d = floor(EYEDIR * 340.0);
	float s = step(0.9974, fract(sin(dot(d, vec3(12.9898, 78.233, 45.164))) * 43758.5453));
	float tw = 0.75 + 0.25 * sin(TIME * 2.2 + d.x);
	COLOR = col + vec3(s * tw) * 1.0;
}
"""

const PLANET_SHADER: String = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec3 base_color : source_color = vec3(0.1, 0.3, 0.4);
uniform vec3 city_color : source_color = vec3(0.85, 1.0, 0.95);
uniform float seed = 0.0;
varying vec3 v_local;
float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.23));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
	               mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
	           mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
	               mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
void vertex() { v_local = VERTEX; }
void fragment() {
	float n = fbm(v_local * 1.9 + seed);
	float land = smoothstep(0.42, 0.58, n);
	vec3 col = mix(base_color * 0.25, base_color, land);
	float c = step(0.72, hash(floor(v_local * 26.0) + seed));
	float coast = 1.0 - smoothstep(0.50, 0.70, n);
	ALBEDO = col;
	EMISSION = city_color * c * land * coast * 1.4;
	ROUGHNESS = 0.8;
	METALLIC = 0.1;
}
"""

const ATMO_SHADER: String = """
shader_type spatial;
render_mode blend_add, cull_front, unshaded, depth_draw_never;
uniform vec3 glow_color : source_color = vec3(0.0, 1.0, 0.9);
uniform float power = 2.6;
void fragment() {
	float f = pow(1.0 - abs(dot(NORMAL, VIEW)), power);
	ALBEDO = glow_color * f;
	EMISSION = glow_color * f * 1.7;
}
"""

var planets: Array[Dictionary] = []
var avatar: OdeaAvatarRig = null
var motion: OdeaAvatarMotion = null
var controls: OdeaAvatarControls = null
var camera_rig: OdeaFollowCamera = null
var cam: Camera3D = null
var walking: bool = false
var target_chapter: int = -1
var target_pos: Vector3 = Vector3.ZERO
var current_chapter: int = -1
var ui_layer: CanvasLayer = null
var shot: bool = false
var frames: int = 0

# UI
var hud_level: Label
var hud_xp: Label
var hud_hint: Label
var xp_bar_bg: ColorRect
var xp_bar_fill: ProgressBar
var panel_missions: Control
var missions_box: VBoxContainer
var panel_side: Control
var side_box: VBoxContainer
var toast: Label
var touch_marker: Node2D

func _ready() -> void:
	if OS.get_environment("ODEASHOT") == "1":
		shot = true
	_build_env()
	_build_planets()
	_build_avatar()
	_build_camera()
	_build_ui()
	_refresh_hud()
	_toast("Joystick / WASD: caminar · CORRER / Shift · SALTAR / Espacio ×2")
	if OS.get_environment("ODEATEST") == "1":
		_run_autotest()
	if OS.get_environment("ODEATEST") == "2":
		_run_uitest()
	if OS.get_environment("ODEATEST") == "3":
		_run_layouttest()

func _run_autotest() -> void:
	var log: Array[String] = []
	await get_tree().process_frame
	await get_tree().process_frame
	log.append("UI panel_superior_visible=%s" % str(hud_level != null and is_instance_valid(hud_level)))
	log.append("UI botones=%d" % 3)
	var pos0: Vector3 = avatar.global_position
	var sp: Vector2 = cam.unproject_position(planets[0].node.global_position)
	log.append("planeta0_en_pantalla=%d,%d" % [int(sp.x), int(sp.y)])
	_tap(sp)
	log.append("walking=%s target=%d" % [str(walking), target_chapter])
	await get_tree().create_timer(2.5).timeout
	var moved: float = avatar.global_position.distance_to(pos0)
	log.append("avatar_se_movio=%.2f" % moved)
	await get_tree().create_timer(2.0).timeout
	log.append("panel_misiones_visible=%s" % str(panel_missions.visible))
	log.append("misiones_en_panel=%d" % missions_box.get_child_count())
	# joystick
	panel_missions.visible = false
	controls.axis = Vector2(1.0, 0.0)
	var p1: Vector3 = avatar.global_position
	await get_tree().create_timer(0.8).timeout
	log.append("joystick_movio=%.2f" % avatar.global_position.distance_to(p1))
	controls.axis = Vector2.ZERO
	# progreso lateral
	_fill_side()
	log.append("panel_lateral_items=%d" % side_box.get_child_count())
	# mision completable
	GameState.complete_mission(GameData.MISSIONS[0])
	log.append("xp_tras_completar=%d" % GameState.xp)
	var f: FileAccess = FileAccess.open("user://odeatest.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(log))
		f.close()
	print("AUTOTEST:\n" + "\n".join(log))
	get_tree().quit()

func _physics_process(delta: float) -> void:
	if motion == null or controls == null:
		return
	var modal: bool = panel_missions.visible or panel_side.visible
	controls.set_enabled(not modal)
	var direction: Vector3 = controls.movement()
	var running: bool = controls.running()
	if modal:
		walking = false
		motion.stop_horizontal()
	elif direction.length_squared() > 0.01:
		# La entrada manual cancela el viaje sin competir con él.
		walking = false
	elif walking:
		var difference: Vector3 = target_pos - avatar.global_position
		difference.y = 0.0
		var distance: float = difference.length()
		var stop_at: float = float(planets[target_chapter].radius) + 1.8
		if distance > stop_at + 0.08:
			# Reducir la velocidad cerca del destino para no atravesar el planeta.
			direction = difference.normalized() * clampf((distance - stop_at) / 1.5, 0.0, 1.0)
			running = true
		else:
			motion.stop_horizontal()
			if motion.grounded:
				walking = false
				current_chapter = target_chapter
				_open_missions(target_chapter)
				_toast("¡Llegaste a %s!" % str(GameData.CHAPTERS[target_chapter].title))
	motion.step(delta, direction, running)

func _process(delta: float) -> void:
	for p: Dictionary in planets:
		var node: Node3D = p.node
		node.rotate_y(delta * float(p.spin))
	# marcador de toque
	if touch_marker and marker_t < 1.0:
		marker_t += delta * 1.6
		touch_marker.queue_redraw()
	if shot:
		frames += 1
		if frames == 70:
			var img: Image = get_viewport().get_texture().get_image()
			img.save_png("/tmp/odeashot.png")
			get_tree().quit()

# ─────────────────────────── construccion

func _build_env() -> void:
	var we: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	var sm: ShaderMaterial = ShaderMaterial.new()
	var sh: Shader = Shader.new()
	sh.code = SKY_SHADER
	sm.shader = sh
	sky.sky_material = sm
	env.sky = sky
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_bloom = 0.22
	env.glow_hdr_threshold = 0.9
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.35, 0.5)
	env.ambient_light_energy = 0.55
	we.environment = env
	add_child(we)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_energy = 1.15
	sun.rotation_degrees = Vector3(-40.0, 30.0, 0.0)
	add_child(sun)

func _planet_pos(i: int) -> Vector3:
	var ang: float = float(i) * 0.785
	var rad: float = 12.0 + float(i % 3) * 2.6
	return Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)

func _build_planets() -> void:
	for i: int in range(CHAPTER_COUNT):
		var ch: Dictionary = GameData.CHAPTERS[i]
		var base: Color = Color(ch.color)
		var pos: Vector3 = _planet_pos(i)
		var radius: float = 2.1 + float(i % 3) * 0.45      # planetas PEQUENOS
		var node: Node3D = Node3D.new()
		node.position = pos
		add_child(node)
		var body: MeshInstance3D = MeshInstance3D.new()
		var sph: SphereMesh = SphereMesh.new()
		sph.radius = radius
		sph.height = radius * 2.0
		sph.radial_segments = 40
		sph.rings = 20
		body.mesh = sph
		var pm: ShaderMaterial = ShaderMaterial.new()
		var psh: Shader = Shader.new()
		psh.code = PLANET_SHADER
		pm.shader = psh
		pm.set_shader_parameter("base_color", Vector3(base.r, base.g, base.b))
		pm.set_shader_parameter("city_color", Vector3(0.9, 1.0, 0.95))
		pm.set_shader_parameter("seed", float(i) * 3.7)
		body.material_override = pm
		node.add_child(body)
		var atmo: MeshInstance3D = MeshInstance3D.new()
		var s2: SphereMesh = SphereMesh.new()
		s2.radius = radius * 1.28
		s2.height = radius * 2.56
		s2.radial_segments = 28
		s2.rings = 14
		atmo.mesh = s2
		var am: ShaderMaterial = ShaderMaterial.new()
		var ash: Shader = Shader.new()
		ash.code = ATMO_SHADER
		am.shader = ash
		am.set_shader_parameter("glow_color", Vector3(base.r, base.g, base.b))
		atmo.material_override = am
		node.add_child(atmo)
		if i % 2 == 1:
			var ringm: MeshInstance3D = MeshInstance3D.new()
			var tor: TorusMesh = TorusMesh.new()
			tor.inner_radius = radius * 1.5
			tor.outer_radius = radius * 2.0
			tor.rings = 40
			tor.ring_segments = 10
			ringm.mesh = tor
			var rmat: StandardMaterial3D = StandardMaterial3D.new()
			rmat.albedo_color = Color(base.r, base.g, base.b, 0.6)
			rmat.emission_enabled = true
			rmat.emission = base
			rmat.emission_energy_multiplier = 0.7
			rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ringm.material_override = rmat
			ringm.rotation_degrees = Vector3(16.0, 0.0, 14.0)
			node.add_child(ringm)
		# numero del capitulo flotando
		var lbl: Label3D = Label3D.new()
		lbl.text = str(i + 1)
		lbl.font_size = 128
		lbl.outline_size = 30
		lbl.pixel_size = 0.01
		lbl.modulate = base
		lbl.position = Vector3(0, radius + 1.1, 0)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = false
		node.add_child(lbl)
		planets.append({"node": node, "chapter": i, "radius": radius, "pos": pos, "spin": 0.07 + float(i % 3) * 0.04})

func _build_avatar() -> void:
	avatar = AvatarRig.new()
	avatar.scale = Vector3.ONE * AVATAR_SCALE
	add_child(avatar)
	motion = AvatarMotion.new()
	add_child(motion)
	motion.setup(avatar)

func _build_camera() -> void:
	cam = Camera3D.new()
	cam.position = Vector3(7.0, 13.0, 12.0)
	cam.fov = 68.0
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	camera_rig = FollowCamera.new()
	add_child(camera_rig)
	camera_rig.setup(cam, avatar)
	motion.landed.connect(camera_rig.on_landed)

# ─────────────────────────── UI (menus visibles)

func _btn(text: String, cb: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(cb)
	return b

func _build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	ui_layer = layer

	# ── barra superior (nivel + XP)
	var top: PanelContainer = PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 104
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tsb: StyleBoxFlat = StyleBoxFlat.new()
	tsb.bg_color = Color(0.03, 0.02, 0.09, 0.88)
	tsb.border_color = Color(0.0, 1.0, 0.85, 0.8)
	tsb.border_width_bottom = 2
	tsb.set_content_margin_all(12)
	top.add_theme_stylebox_override("panel", tsb)
	layer.add_child(top)
	var tv: VBoxContainer = VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	top.add_child(tv)
	hud_level = Label.new()
	hud_level.add_theme_font_size_override("font_size", 18)
	hud_level.add_theme_color_override("font_color", Color(0.0, 1.0, 0.85))
	tv.add_child(hud_level)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	tv.add_child(row)
	xp_bar_bg = ColorRect.new()
	xp_bar_bg.color = Color(1, 1, 1, 0.15)
	xp_bar_bg.custom_minimum_size = Vector2(0, 12)
	xp_bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(xp_bar_bg)
	xp_bar_fill = ProgressBar.new()
	xp_bar_fill.show_percentage = false
	xp_bar_fill.custom_minimum_size = Vector2(0, 14)
	xp_bar_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_bar_fill.max_value = 100.0
	xp_bar_fill.value = 0.0
	row.add_child(xp_bar_fill)
	hud_xp = Label.new()
	hud_xp.add_theme_font_size_override("font_size", 12)
	row.add_child(hud_xp)

	# ── pista
	hud_hint = Label.new()
	hud_hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_hint.offset_top = 112
	hud_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_hint.add_theme_font_size_override("font_size", 13)
	hud_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	hud_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_hint)

	# ── barra inferior con botones grandes
	var bottom: PanelContainer = PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -104
	var bsb: StyleBoxFlat = StyleBoxFlat.new()
	bsb.bg_color = Color(0.03, 0.02, 0.09, 0.9)
	bsb.border_color = Color(1.0, 0.35, 0.85, 0.8)
	bsb.border_width_top = 2
	bsb.set_content_margin_all(10)
	bottom.add_theme_stylebox_override("panel", bsb)
	layer.add_child(bottom)
	var bh: HBoxContainer = HBoxContainer.new()
	bh.add_theme_constant_override("separation", 8)
	bottom.add_child(bh)
	bh.add_child(_btn("MISIONES", func() -> void: _open_missions(current_chapter if current_chapter >= 0 else 0)))
	bh.add_child(_btn("PROGRESO", func() -> void: _toggle_side(true)))
	bh.add_child(_btn("CENTRAR", func() -> void: _center_view()))

	# ── marcador de toque
	touch_marker = Node2D.new()
	touch_marker.draw.connect(func() -> void: _draw_touch_marker())
	layer.add_child(touch_marker)

	# ── panel de misiones
	panel_missions = PanelContainer.new()
	panel_missions.set_anchors_preset(Control.PRESET_CENTER)
	panel_missions.custom_minimum_size = Vector2(500, 520)
	panel_missions.position = Vector2(20, 250)
	panel_missions.visible = false
	var msb: StyleBoxFlat = StyleBoxFlat.new()
	msb.bg_color = Color(0.03, 0.02, 0.08, 0.97)
	msb.border_color = Color(0.0, 1.0, 0.85, 0.95)
	msb.set_border_width_all(2)
	msb.set_corner_radius_all(14)
	msb.set_content_margin_all(14)
	panel_missions.add_theme_stylebox_override("panel", msb)
	layer.add_child(panel_missions)
	var mscroll: ScrollContainer = ScrollContainer.new()
	mscroll.custom_minimum_size = Vector2(470, 480)
	panel_missions.add_child(mscroll)
	missions_box = VBoxContainer.new()
	missions_box.custom_minimum_size = Vector2(460, 0)
	missions_box.add_theme_constant_override("separation", 8)
	mscroll.add_child(missions_box)

	# ── panel lateral (barra lateral de progreso)
	panel_side = PanelContainer.new()
	panel_side.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel_side.custom_minimum_size = Vector2(330, 0)
	panel_side.offset_right = 330
	panel_side.offset_top = 104
	panel_side.offset_bottom = -104
	panel_side.visible = false
	var ssb: StyleBoxFlat = StyleBoxFlat.new()
	ssb.bg_color = Color(0.04, 0.02, 0.1, 0.97)
	ssb.border_color = Color(1.0, 0.35, 0.85, 0.9)
	ssb.border_width_right = 2
	ssb.set_content_margin_all(14)
	panel_side.add_theme_stylebox_override("panel", ssb)
	layer.add_child(panel_side)
	var sscroll: ScrollContainer = ScrollContainer.new()
	sscroll.custom_minimum_size = Vector2(300, 600)
	panel_side.add_child(sscroll)
	side_box = VBoxContainer.new()
	side_box.custom_minimum_size = Vector2(290, 0)
	side_box.add_theme_constant_override("separation", 8)
	sscroll.add_child(side_box)

	# ── toast (mensajes)
	toast = Label.new()
	toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast.offset_top = 150
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 16)
	toast.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(toast)
	controls = AvatarControls.new()
	add_child(controls)
	controls.setup(cam, layer)
	controls.jump_requested.connect(motion.request_jump)
	controls.planet_tapped.connect(_tap)
	_fix_text(layer)

func _fix_text(node: Node) -> void:
	## Garantiza legibilidad en movil: tamano minimo + contorno negro.
	if node is Label or node is Button:
		var cur: int = node.get_theme_font_size("font_size")
		var minimo: int = 17 if node is Button else 15
		if cur < minimo:
			node.add_theme_font_size_override("font_size", minimo)
		node.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
		node.add_theme_constant_override("outline_size", 6)
	for c in node.get_children():
		_fix_text(c)

func _min_font(node: Node) -> int:
	var m := 999
	var stack: Array = [node]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is Label or n is Button:
			m = min(m, n.get_theme_font_size("font_size"))
		for c in n.get_children():
			stack.append(c)
	return m

func _scan_clip(root: Node) -> Array:
	## Detecta textos mas anchos que su caja (recortes en movil), ignorando autowrap.
	var out: Array = []
	var stack: Array = [root]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is Label:
			var lbl: Label = n
			if lbl.autowrap_mode == TextServer.AUTOWRAP_OFF and str(lbl.text) != "" and lbl.size.x > 10.0:
				var f: Font = lbl.get_theme_font("font")
				var fs: int = lbl.get_theme_font_size("font_size")
				if f:
					var w: float = f.get_string_size(str(lbl.text), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
					if w > lbl.size.x + 4.0:
						out.append("%s (%.0f>%.0f)" % [str(lbl.text).substr(0, 18), w, lbl.size.x])
		if n is Button:
			var b: Button = n
			var fb: Font = b.get_theme_font("font")
			var fsb: int = b.get_theme_font_size("font_size")
			if fb and b.size.x > 10.0:
				var wb: float = fb.get_string_size(str(b.text), HORIZONTAL_ALIGNMENT_LEFT, -1, fsb).x
				if wb > b.size.x - 10.0:
					out.append("BTN %s (%.0f>%.0f)" % [str(b.text).substr(0, 14), wb, b.size.x])
		for c in n.get_children():
			stack.append(c)
	return out

func _run_uitest() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var log: Array = []
	var vsize: Vector2 = get_viewport().get_visible_rect().size
	log.append("viewport=%.0fx%.0f" % [vsize.x, vsize.y])
	log.append("fuente_minima_global=%d" % _min_font(ui_layer))
	var c1: Array = _scan_clip(ui_layer)
	log.append("recortes_hud=%d :: %s" % [c1.size(), " | ".join(c1).substr(0, 240)])
	_open_missions(0)
	await get_tree().create_timer(0.5).timeout
	var c2: Array = _scan_clip(missions_box)
	log.append("recortes_misiones=%d :: %s" % [c2.size(), " | ".join(c2).substr(0, 240)])
	panel_missions.visible = false
	_toggle_side(true)
	await get_tree().create_timer(0.5).timeout
	var c3: Array = _scan_clip(side_box)
	log.append("recortes_progreso=%d :: %s" % [c3.size(), " | ".join(c3).substr(0, 240)])
	log.append("fuente_minima_paneles=%d" % min(_min_font(missions_box), _min_font(side_box)))
	var fl := FileAccess.open("/tmp/odeauitest.txt", FileAccess.WRITE)
	if fl:
		fl.store_string("\n".join(log))
		fl.close()
	print("UITEST:\n" + "\n".join(log))
	get_tree().quit()

func _rect_info(nm: String, c: Control, v: Vector2) -> String:
	var r: Rect2 = c.get_global_rect()
	var problem := ""
	if r.position.x < -1.0:
		problem += " ⚠SALE_IZQ"
	if r.position.y < -1.0:
		problem += " ⚠SALE_ARRIBA"
	if r.position.x + r.size.x > v.x + 1.0:
		problem += " ⚠SALE_DER"
	if r.position.y + r.size.y > v.y + 1.0:
		problem += " ⚠SALE_ABAJO"
	if r.size.x < 10.0 or r.size.y < 10.0:
		problem += " ⚠TAMANO_CERO"
	return "%s: pos=(%.0f,%.0f) tam=(%.0f,%.0f)%s" % [nm, r.position.x, r.position.y, r.size.x, r.size.y, problem]

func _run_layouttest() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	var log: Array = []
	var v: Vector2 = get_viewport().get_visible_rect().size
	log.append("viewport=%.0fx%.0f" % [v.x, v.y])
	_open_missions(0)
	await get_tree().create_timer(0.6).timeout
	log.append(_rect_info("panel_misiones", panel_missions, v))
	log.append(_rect_info("caja_misiones", missions_box, v))
	log.append(_rect_info("barra_inferior", controls.overlay, v))
	panel_missions.visible = false
	_toggle_side(true)
	await get_tree().create_timer(0.5).timeout
	log.append(_rect_info("panel_lateral", panel_side, v))
	log.append(_rect_info("caja_lateral", side_box, v))
	var f: FileAccess = FileAccess.open("/tmp/odealayout.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(log))
		f.close()
	print("LAYOUT:\n" + "\n".join(log))
	get_tree().quit()

func _toast(msg: String) -> void:
	if toast == null:
		return
	toast.text = msg
	toast.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(toast, "modulate:a", 0.0, 1.2)

func _refresh_hud() -> void:
	if hud_level == null:
		return
	hud_level.text = "NIVEL %d · %s" % [GameState.level_index() + 1, GameState.level_name()]
	if hud_xp:
		hud_xp.text = "%d XP" % GameState.xp
	if xp_bar_fill:
		xp_bar_fill.value = GameState.level_progress() * 100.0
	if hud_hint:
		hud_hint.text = "Joystick / WASD · Correr: Shift · Salto doble: Espacio ×2"

func _center_view() -> void:
	if avatar:
		walking = false
		target_chapter = -1
		current_chapter = -1
		controls.clear()
		motion.reset()
		camera_rig.snap()
		_toast("Volviste al centro de la galaxia")

func _toggle_side(show_it: bool) -> void:
	if panel_side == null:
		return
	panel_side.visible = show_it
	controls.set_enabled(not show_it and not panel_missions.visible)
	if show_it:
		_fill_side()

func _fill_side() -> void:
	if side_box == null:
		return
	for c: Node in side_box.get_children():
		c.queue_free()
	var title: Label = Label.new()
	title.text = "TU PROGRESO"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.85))
	side_box.add_child(title)
	var total: int = 0
	var done: int = 0
	for m: Dictionary in GameData.MISSIONS:
		total += 1
		if GameState.is_done(str(m.id)):
			done += 1
	var gen: Label = Label.new()
	gen.add_theme_font_size_override("font_size", 13)
	gen.text = "Misiones: %d / %d   ·   XP: %d" % [done, total, GameState.xp]
	side_box.add_child(gen)
	side_box.add_child(HSeparator.new())
	for i: int in range(CHAPTER_COUNT):
		var chd: Dictionary = GameData.CHAPTERS[i]
		var lbl: Label = Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(280, 0)
		var dc: int = GameState.chapter_done(i)
		var tc: int = GameState.chapter_total(i)
		var mark: String = "✅" if GameState.chapter_complete(i) else ("🔓" if GameState.chapter_unlocked(i) else "🔒")
		lbl.text = "%s %s — %d/%d" % [mark, str(chd.title), dc, tc]
		lbl.add_theme_color_override("font_color", Color(chd.color))
		side_box.add_child(lbl)
	side_box.add_child(HSeparator.new())
	var close: Button = Button.new()
	close.text = "CERRAR"
	close.custom_minimum_size = Vector2(0, 64)
	close.pressed.connect(func() -> void: _toggle_side(false))
	side_box.add_child(close)
	_fix_text(side_box)

func _open_missions(ch: int) -> void:
	if panel_missions == null:
		return
	for c: Node in missions_box.get_children():
		c.queue_free()
	var chd: Dictionary = GameData.CHAPTERS[ch]
	var title: Label = Label.new()
	title.text = "%s — %s" % [str(chd.code), str(chd.title)]
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(chd.color))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(450, 0)
	missions_box.add_child(title)
	if not GameState.chapter_unlocked(ch):
		var lock_lbl: Label = Label.new()
		lock_lbl.text = "🔒 Completá el capítulo anterior para desbloquear"
		lock_lbl.add_theme_font_size_override("font_size", 13)
		missions_box.add_child(lock_lbl)
	for m: Dictionary in GameData.MISSIONS:
		if int(m.chapter) != ch:
			continue
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(270, 0)
		lbl.text = "%s  (+%d XP)" % [str(m.title), int(m.xp)]
		if GameState.is_done(str(m.id)):
			lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
		row.add_child(lbl)
		if not GameState.is_done(str(m.id)):
			var b: Button = Button.new()
			b.text = "COMPLETAR"
			b.custom_minimum_size = Vector2(160, 58)
			b.add_theme_font_size_override("font_size", 12)
			var mm: Dictionary = m
			var cc: int = ch
			b.pressed.connect(func() -> void:
				GameState.complete_mission(mm)
				_refresh_hud()
				_open_missions(cc)
				_toast("+%d XP!" % int(mm.xp))
			)
			row.add_child(b)
		else:
			var ok: Label = Label.new()
			ok.text = "✔"
			ok.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
			row.add_child(ok)
		missions_box.add_child(row)
	for bs: Dictionary in GameData.BOSSES:
		if int(bs.chapter) != ch:
			continue
		var boss: Label = Label.new()
		boss.add_theme_font_size_override("font_size", 14)
		boss.add_theme_color_override("font_color", Color(1.0, 0.2, 0.33))
		boss.text = ("👑 JEFE DERROTADO: " if GameState.chapter_complete(ch) else "⚔️ JEFE FINAL: ") + str(bs.name)
		boss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boss.custom_minimum_size = Vector2(450, 0)
		missions_box.add_child(boss)
		break
	var close: Button = Button.new()
	close.text = "CERRAR"
	close.custom_minimum_size = Vector2(0, 60)
	close.pressed.connect(func() -> void:
		panel_missions.visible = false
		controls.set_enabled(not panel_side.visible)
	)
	missions_box.add_child(close)
	_fix_text(missions_box)
	panel_missions.visible = true
	walking = false
	controls.set_enabled(false)
	motion.stop_horizontal()

# ─────────────────────────── toques y joystick

func _planet_screen(ch: int) -> Vector2:
	var node: Node3D = planets[ch].node
	return cam.unproject_position(node.global_position)

func _hit_planet(pos: Vector2) -> int:
	var best: int = -1
	var best_d: float = 1e9
	var vsize: Vector2 = get_viewport().get_visible_rect().size
	var umbral: float = max(110.0, vsize.x * 0.22)
	for p: Dictionary in planets:
		var node: Node3D = p.node
		if cam.is_position_behind(node.global_position):
			continue
		var sp: Vector2 = cam.unproject_position(node.global_position)
		var d: float = sp.distance_to(pos)
		if d < best_d:
			best_d = d
			best = int(p.chapter)
	if best >= 0 and best_d <= umbral:
		return best
	return -1

func _tap(pos: Vector2) -> void:
	_show_marker(pos)
	var ch: int = _hit_planet(pos)
	if ch < 0:
		_toast("Tocá un planeta para viajar 🌍")
		return
	if not GameState.chapter_unlocked(ch):
		_toast("🔒 Ese mundo está bloqueado: completá el capítulo anterior")
		return
	walking = true
	target_chapter = ch
	target_pos = planets[ch].pos
	_toast("Viajando a %s..." % str(GameData.CHAPTERS[ch].title))

var marker_pos: Vector2 = Vector2.ZERO
var marker_t: float = 0.0
func _show_marker(p: Vector2) -> void:
	marker_pos = p
	marker_t = 0.0
	if touch_marker:
		touch_marker.queue_redraw()

func _draw_touch_marker() -> void:
	if touch_marker == null or marker_t >= 1.0:
		return
	var a: float = 1.0 - marker_t
	touch_marker.draw_arc(marker_pos, 26.0 + marker_t * 34.0, 0.0, TAU, 32, Color(0.0, 1.0, 0.9, a), 3.0, true)

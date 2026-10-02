class_name ContentCenter
extends CanvasLayer
## ContentCenter — centro de contenido con 8 pestañas y paginación (Fase 1).
## Consume el autoload ContentDB. Emite `closed` al cerrar y `mission_completed` al completar.

signal closed
signal mission_completed

const PAGE_SIZE: int = 20
const TABS: Array[String] = [
	"Campaña", "Plan Diario", "Empleo", "Retos", "Logros", "Vida", "Progreso", "Recompensas",
]

var panel: PanelContainer
var title_lbl: Label
var hoy_streak: Label
var hoy_mission: Label
var hoy_btn: Button
var tabs_box: GridContainer
var scroll: ScrollContainer
var list_box: VBoxContainer
var more_btn: Button
var close_btn: Button
var current_tab: int = 0
var page_offset: int = 0

var detail: PanelContainer
var detail_title: Label
var detail_body: Label

func _ready() -> void:
	layer = 20
	_build()

func _build() -> void:
	# ── panel principal
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 10
	panel.offset_top = 96
	panel.offset_right = -10
	panel.offset_bottom = -120
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.02, 0.10, 0.98)
	sb.border_color = Color(0.0, 1.0, 0.85, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.85))
	col.add_child(title_lbl)

	# ── banner "hoy" (racha + misión del día + evidencia)
	var hoy: PanelContainer = PanelContainer.new()
	var hsb: StyleBoxFlat = StyleBoxFlat.new()
	hsb.bg_color = Color(0.10, 0.05, 0.18, 0.9)
	hsb.border_color = Color(1.0, 0.6, 0.2, 0.8)
	hsb.set_border_width_all(1)
	hsb.set_corner_radius_all(10)
	hsb.set_content_margin_all(10)
	hoy.add_theme_stylebox_override("panel", hsb)
	col.add_child(hoy)
	var hcol: VBoxContainer = VBoxContainer.new()
	hcol.add_theme_constant_override("separation", 6)
	hoy.add_child(hcol)
	hoy_streak = Label.new()
	hoy_streak.add_theme_font_size_override("font_size", 15)
	hoy_streak.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	hcol.add_child(hoy_streak)
	hoy_mission = Label.new()
	hoy_mission.add_theme_font_size_override("font_size", 14)
	hoy_mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hcol.add_child(hoy_mission)
	hoy_btn = Button.new()
	hoy_btn.text = "COMPLETAR CON EVIDENCIA"
	hoy_btn.custom_minimum_size = Vector2(0, 58)
	hoy_btn.add_theme_font_size_override("font_size", 15)
	hoy_btn.pressed.connect(_complete_today)
	hcol.add_child(hoy_btn)

	# pestañas en cuadrícula 4×2 (caben en 540 px)
	tabs_box = GridContainer.new()
	tabs_box.columns = 4
	tabs_box.add_theme_constant_override("h_separation", 6)
	tabs_box.add_theme_constant_override("v_separation", 6)
	col.add_child(tabs_box)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 6)
	scroll.add_child(list_box)

	more_btn = Button.new()
	more_btn.text = "MOSTRAR MÁS"
	more_btn.custom_minimum_size = Vector2(0, 56)
	more_btn.add_theme_font_size_override("font_size", 16)
	more_btn.pressed.connect(_load_more)
	col.add_child(more_btn)

	close_btn = Button.new()
	close_btn.text = "CERRAR"
	close_btn.custom_minimum_size = Vector2(0, 60)
	close_btn.add_theme_font_size_override("font_size", 17)
	close_btn.pressed.connect(close_panel)
	col.add_child(close_btn)

	# ── panel de detalle
	detail = PanelContainer.new()
	detail.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail.offset_left = 24
	detail.offset_top = 160
	detail.offset_right = -24
	detail.offset_bottom = -160
	detail.visible = false
	var dsb: StyleBoxFlat = StyleBoxFlat.new()
	dsb.bg_color = Color(0.05, 0.03, 0.12, 0.98)
	dsb.border_color = Color(1.0, 0.6, 0.2, 0.95)
	dsb.set_border_width_all(2)
	dsb.set_corner_radius_all(14)
	dsb.set_content_margin_all(16)
	detail.add_theme_stylebox_override("panel", dsb)
	add_child(detail)
	var dcol: VBoxContainer = VBoxContainer.new()
	dcol.add_theme_constant_override("separation", 12)
	detail.add_child(dcol)
	detail_title = Label.new()
	detail_title.add_theme_font_size_override("font_size", 18)
	detail_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dcol.add_child(detail_title)
	var dscroll: ScrollContainer = ScrollContainer.new()
	dscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dcol.add_child(dscroll)
	detail_body = Label.new()
	detail_body.add_theme_font_size_override("font_size", 15)
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dscroll.add_child(detail_body)
	var dclose: Button = Button.new()
	dclose.text = "CERRAR"
	dclose.custom_minimum_size = Vector2(0, 60)
	dclose.add_theme_font_size_override("font_size", 17)
	dclose.pressed.connect(func() -> void: detail.visible = false)
	dcol.add_child(dclose)

	_build_tabs()
	_outline(panel)
	_outline(detail)
	visible = false

func _build_tabs() -> void:
	for i: int in range(TABS.size()):
		var b: Button = Button.new()
		b.text = TABS[i]
		b.custom_minimum_size = Vector2(0, 54)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 15)
		var idx: int = i
		b.pressed.connect(func() -> void: _set_tab(idx))
		tabs_box.add_child(b)

func _set_tab(i: int) -> void:
	current_tab = i
	page_offset = 0
	_fill()

func open_panel() -> void:
	visible = true
	current_tab = 0
	page_offset = 0
	_refresh_hoy()
	_fill()

func close_panel() -> void:
	visible = false
	emit_signal("closed")

func _next_mission() -> Dictionary:
	for m: Dictionary in GameData.MISSIONS:
		if not GameState.is_done(str(m.id)):
			return m
	return {}

func _refresh_hoy() -> void:
	var s: int = GameState.streak
	hoy_streak.text = "🔥 Racha: %d día%s" % [s, "s" if s != 1 else ""]
	var nm: Dictionary = _next_mission()
	if nm.is_empty():
		hoy_mission.text = "🎉 ¡Todas las misiones de campaña completadas!"
		hoy_btn.visible = false
	else:
		hoy_mission.text = "📌 Misión del día: %s (+%d XP)" % [str(nm.title), int(nm.xp)]
		hoy_btn.visible = true

func _complete_today() -> void:
	var nm: Dictionary = _next_mission()
	if nm.is_empty():
		return
	GameState.complete_mission(nm)
	GameState.register_day()
	_refresh_hoy()
	_fill()
	emit_signal("mission_completed")

func _tab_data() -> Array:
	match current_tab:
		0: return ContentDB.campaign()
		1:
			var out: Array = []
			out.append_array(ContentDB.daily_obligatorias())
			out.append_array(ContentDB.daily())
			return out
		2: return ContentDB.jobs()
		3: return ContentDB.retos()
		4: return ContentDB.logros()
		5: return ContentDB.vida()
		6: return []
		7: return ContentDB.recompensas()
	return []

func _fill() -> void:
	for c: Node in list_box.get_children():
		c.queue_free()
	title_lbl.text = "CONTENIDO · " + TABS[current_tab]
	if current_tab == 6:
		_fill_progreso()
		more_btn.visible = false
		return
	var items: Array = _tab_data()
	var page: Array = ContentDB.paginate(items, page_offset, PAGE_SIZE)
	for m: Dictionary in page:
		list_box.add_child(_row(m))
	more_btn.visible = (page_offset + PAGE_SIZE) < items.size()

func _fill_progreso() -> void:
	var total: int = GameData.MISSIONS.size()
	var done: int = 0
	for m: Dictionary in GameData.MISSIONS:
		if GameState.is_done(str(m.id)):
			done += 1
	var lbl: Label = Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.text = "Misiones de campaña: %d / %d\n\nXP total: %d\n\nNivel: %s" % [done, total, GameState.xp, GameState.level_name()]
	list_box.add_child(lbl)
	for i: int in range(GameData.CHAPTERS.size()):
		var chd: Dictionary = GameData.CHAPTERS[i]
		var cl: Label = Label.new()
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cl.add_theme_font_size_override("font_size", 14)
		var mark: String = "✅" if GameState.chapter_complete(i) else ("🔓" if GameState.chapter_unlocked(i) else "🔒")
		cl.text = "%s %s — %d/%d" % [mark, str(chd.title), GameState.chapter_done(i), GameState.chapter_total(i)]
		cl.add_theme_color_override("font_color", Color(chd.color))
		list_box.add_child(cl)

func _row(m: Dictionary) -> Button:
	var f: Dictionary = ContentDB.fields(m)
	var b: Button = Button.new()
	b.custom_minimum_size = Vector2(0, 64)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 14)
	var status: String = "✅ " if GameState.is_done(str(f.id)) else "🔓 "
	b.text = status + str(f.title) + "  (+%d XP)" % int(f.xp)
	var t: String = str(f.title)
	var d: String = str(f.desc)
	var x: int = int(f.xp)
	b.pressed.connect(func() -> void: _show_detail(t, d, x))
	return b

func _show_detail(t: String, d: String, xp: int) -> void:
	detail_title.text = t
	var body: String = d
	if xp > 0:
		body += "\n\n⚡ +%d XP" % xp
	detail_body.text = body
	detail.visible = true

func _load_more() -> void:
	page_offset += PAGE_SIZE
	_fill()

func _outline(node: Node) -> void:
	## Contorno negro y legibilidad mínima en móvil.
	if node is Label or node is Button:
		node.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
		node.add_theme_constant_override("outline_size", 6)
	for c in node.get_children():
		_outline(c)

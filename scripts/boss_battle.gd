class_name BossBattle
extends CanvasLayer
## BossBattle — combate de jefe con preguntas de datos (Fase 4).
## Emite `victory(xp, title)` y `closed`. Consume ContentDB.boss_questions().

signal victory(xp: int, title: String)
signal closed

const MAX_HP: int = 3

var panel: PanelContainer
var boss_name: Label
var boss_desc: Label
var player_hp_lbl: Label
var boss_hp_lbl: Label
var question_lbl: Label
var answers_box: VBoxContainer
var feedback: Label
var retry_btn: Button
var close_btn: Button

var boss: Dictionary = {}
var questions: Array = []
var q_index: int = 0
var player_hp: int = MAX_HP
var boss_hp: int = MAX_HP

func _ready() -> void:
	layer = 30
	_build()

func _build() -> void:
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 16
	panel.offset_top = 120
	panel.offset_right = -16
	panel.offset_bottom = -140
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.02, 0.12, 0.98)
	sb.border_color = Color(1.0, 0.25, 0.4, 0.95)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	boss_name = Label.new()
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_font_size_override("font_size", 20)
	boss_name.add_theme_color_override("font_color", Color(1.0, 0.4, 0.5))
	col.add_child(boss_name)

	boss_desc = Label.new()
	boss_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boss_desc.add_theme_font_size_override("font_size", 13)
	boss_desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	col.add_child(boss_desc)

	player_hp_lbl = Label.new()
	player_hp_lbl.add_theme_font_size_override("font_size", 15)
	player_hp_lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
	col.add_child(player_hp_lbl)

	boss_hp_lbl = Label.new()
	boss_hp_lbl.add_theme_font_size_override("font_size", 15)
	boss_hp_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.45))
	col.add_child(boss_hp_lbl)

	col.add_child(HSeparator.new())

	question_lbl = Label.new()
	question_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_lbl.add_theme_font_size_override("font_size", 16)
	col.add_child(question_lbl)

	answers_box = VBoxContainer.new()
	answers_box.add_theme_constant_override("separation", 8)
	col.add_child(answers_box)

	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_font_size_override("font_size", 14)
	feedback.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	col.add_child(feedback)

	retry_btn = Button.new()
	retry_btn.text = "REINTENTAR"
	retry_btn.custom_minimum_size = Vector2(0, 58)
	retry_btn.add_theme_font_size_override("font_size", 16)
	retry_btn.visible = false
	retry_btn.pressed.connect(_retry)
	col.add_child(retry_btn)

	close_btn = Button.new()
	close_btn.text = "CERRAR"
	close_btn.custom_minimum_size = Vector2(0, 58)
	close_btn.add_theme_font_size_override("font_size", 17)
	close_btn.pressed.connect(_close)
	col.add_child(close_btn)

	_outline(panel)
	visible = false

func open(b: Dictionary) -> void:
	boss = b
	var bid: String = str(b.get("id", ""))
	questions = ContentDB.boss_questions(bid)
	if questions.is_empty():
		return
	q_index = 0
	player_hp = MAX_HP
	boss_hp = MAX_HP
	boss_name.text = "⚔️ " + str(b.get("name", "Jefe"))
	boss_desc.text = str(b.get("description", ""))
	feedback.text = ""
	retry_btn.visible = false
	_update_hp()
	_show_question()
	visible = true

func _update_hp() -> void:
	player_hp_lbl.text = "❤️ Tu energía: %d / %d" % [player_hp, MAX_HP]
	boss_hp_lbl.text = "👹 Jefe: %d / %d" % [boss_hp, MAX_HP]

func _show_question() -> void:
	var q: Dictionary = questions[q_index % questions.size()]
	question_lbl.text = str(q.get("q", ""))
	for c: Node in answers_box.get_children():
		c.queue_free()
	var opts: Array = q.get("options", [])
	var correct: int = int(q.get("answer", 0))
	for i: int in range(opts.size()):
		var b: Button = Button.new()
		b.text = str(opts[i])
		b.custom_minimum_size = Vector2(0, 60)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 14)
		var is_correct: bool = (i == correct)
		b.pressed.connect(func() -> void: _answer(is_correct))
		answers_box.add_child(b)

func _answer(correct: bool) -> void:
	q_index += 1
	if correct:
		boss_hp -= 1
		feedback.text = "✅ ¡Correcto! El jefe pierde energía."
	else:
		player_hp -= 1
		feedback.text = "❌ Fallaste. Pierdes energía."
	_update_hp()
	if boss_hp <= 0:
		_win()
	elif player_hp <= 0:
		_lose()
	else:
		_show_question()

func _win() -> void:
	var xp: int = int(boss.get("xp", 0))
	var title: String = str(boss.get("title_reward", ""))
	GameState.add_xp(xp)
	GameState.boss_victory(str(boss.get("id", "")))
	question_lbl.text = "🏆 ¡VICTORIA!"
	for c: Node in answers_box.get_children():
		c.queue_free()
	var msg: String = "+%d XP" % xp
	if title != "":
		msg += "\n🏅 Insignia: %s" % title
	msg += "\n\nEl jefe ha sido derrotado."
	feedback.text = msg
	retry_btn.visible = false
	emit_signal("victory", xp, title)

func _lose() -> void:
	question_lbl.text = "💀 Derrota..."
	for c: Node in answers_box.get_children():
		c.queue_free()
	feedback.text = "El jefe fue demasiado. Repasá y volvé a intentar."
	retry_btn.visible = true

func _retry() -> void:
	open(boss)

func _close() -> void:
	visible = false
	emit_signal("closed")

func _outline(node: Node) -> void:
	if node is Label or node is Button:
		node.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
		node.add_theme_constant_override("outline_size", 6)
	for c in node.get_children():
		_outline(c)

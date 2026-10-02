extends Node2D
## ODEALAND — Mapa cyberpunk (Godot 4)
## Todo se dibuja con la API de canvas (draw_*): cero nodos por elemento = rendimiento máximo.

const VW := 540.0
const VH := 960.0
const HORIZON := 560.0
const VANISH := Vector2(270.0, 548.0)
const NODE_R := 27.0

var stars: Array = []
var layers: Array = []
var nodes: Array = []
var t := 0.0
var selected := -1
var shot := false
var _frames := 0

const NEON := [Color("#00ffc8"), Color("#7de8ff"), Color("#ff6bd6"), Color("#ffd86b"), Color("#9d7bff")]

func _ready() -> void:
	seed(20260911)
	_gen_stars()
	_gen_city()
	_gen_nodes()
	if OS.get_environment("ODEASHOT") == "1":
		shot = true

func _process(delta: float) -> void:
	t += delta
	if shot:
		_frames += 1
		if _frames == 45:
			var img: Image = get_viewport().get_texture().get_image()
			img.save_png("/tmp/odeashot.png")
			get_tree().quit()
	queue_redraw()

# ─────────────────────────────────── generación
func _gen_stars() -> void:
	for i in 90:
		stars.append({
			"x": randf() * VW,
			"y": randf() * (HORIZON - 60.0),
			"r": randf_range(0.6, 1.8),
			"ph": randf() * TAU
		})

func _gen_city() -> void:
	var defs := [
		{"h0": 60.0,  "h1": 130.0, "col": Color("#0a0a20"), "w0": 26.0, "w1": 52.0, "win": 0.22, "neon": 0.22},
		{"h0": 95.0,  "h1": 215.0, "col": Color("#12102e"), "w0": 34.0, "w1": 72.0, "win": 0.32, "neon": 0.45},
		{"h0": 140.0, "h1": 315.0, "col": Color("#1a1236"), "w0": 46.0, "w1": 96.0, "win": 0.42, "neon": 0.65},
	]
	for ld in defs:
		var bl: Array = []
		var x := -34.0
		while x < VW + 34.0:
			var w: float = randf_range(ld.w0, ld.w1)
			var hh: float = randf_range(ld.h0, ld.h1)
			var b := {"x": x, "w": w, "h": hh, "col": ld.col, "windows": [], "antenna": randf() < 0.4, "ah": randf_range(14.0, 34.0)}
			var cols: int = max(2, int(w / 9.0))
			var rows: int = max(2, int(hh / 13.0))
			for cx in range(cols):
				for ry in range(rows):
					if randf() < ld.win:
						var col: Color = NEON[int(randf() * 3.0)]
						b.windows.append({
							"x": x + 4.0 + cx * 9.0,
							"y": HORIZON - hh + 6.0 + ry * 13.0,
							"w": 4.0, "h": 7.0,
							"col": col,
							"on": randf() < ld.neon
						})
			bl.append(b)
			x += w + randf_range(3.0, 14.0)
		layers.append(bl)

func _gen_nodes() -> void:
	var xs := [98.0, 262.0, 424.0, 330.0, 168.0, 296.0, 448.0, 262.0]
	var ys := [628.0, 672.0, 716.0, 782.0, 826.0, 866.0, 900.0, 930.0]
	for i in 8:
		nodes.append({"x": xs[i], "y": ys[i], "i": i})

# ─────────────────────────────────── dibujo
func _draw() -> void:
	_draw_sky()
	_draw_stars()
	_draw_moon()
	_draw_city()
	_draw_ground()
	_draw_path()
	_draw_nodes()
	_draw_hud()
	if selected >= 0:
		_draw_panel(selected)

func _draw_sky() -> void:
	var cols := [
		Color("#04010d"), Color("#0a0520"), Color("#160836"),
		Color("#2a0b4e"), Color("#4a1060"), Color("#7a1a6a"), Color("#b12a6b")
	]
	var n := cols.size() - 1
	var bands := 42
	for i in bands:
		var f := float(i) / float(bands - 1)
		var idx := int(f * float(n))
		var idx2: int = min(idx + 1, n)
		var sub := f * float(n) - float(idx)
		var c: Color = cols[idx].lerp(cols[idx2], sub)
		draw_rect(Rect2(0.0, (VH * f) - 1.0, VW, (VH / float(bands)) + 2.0), c)

func _draw_stars() -> void:
	for s in stars:
		var a: float = 0.35 + 0.45 * (0.5 + 0.5 * sin(t * 1.7 + s.ph))
		draw_circle(Vector2(s.x, s.y), s.r, Color(1, 1, 1, a))

func _draw_moon() -> void:
	var p := Vector2(404.0, 150.0)
	for i in range(7, 0, -1):
		var rr: float = 46.0 + float(i) * 9.0
		draw_circle(p, rr, Color(1.0, 0.35, 0.75, 0.015 * float(8 - i)))
	draw_circle(p, 46.0, Color("#ffb3e0"))
	draw_circle(p, 38.0, Color("#ffe3f4"))
	draw_circle(p + Vector2(10, -8), 34.0, Color("#ff9ed8", 0.55))

func _draw_city() -> void:
	var alphas := [0.85, 0.95, 1.0]
	for li in layers.size():
		var bl: Array = layers[li]
		var a: float = alphas[li]
		for b in bl:
			var top: float = HORIZON - b.h
			draw_rect(Rect2(b.x, top, b.w, b.h), Color(b.col, a))
			# borde neón superior
			var edge: Color = NEON[(li + 1) % NEON.size()]
			draw_line(Vector2(b.x, top), Vector2(b.x + b.w, top), Color(edge.r, edge.g, edge.b, 0.20 + 0.15 * float(li)), 1.0)
			# ventanas
			for w in b.windows:
				var col: Color = w.col
				var aa: float = 0.75 if w.on else 0.14
				if w.on:
					aa *= 0.6 + 0.4 * (0.5 + 0.5 * sin(t * 2.2 + w.x * 0.05 + w.y * 0.03))
				draw_rect(Rect2(w.x, w.y, w.w, w.h), Color(col.r, col.g, col.b, aa))
			# antena con luz
			if b.antenna:
				var ax: float = b.x + b.w * 0.5
				draw_line(Vector2(ax, top), Vector2(ax, top - b.ah), Color(0.6, 0.7, 1.0, 0.5), 1.0)
				var blink: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 3.4 + b.x))
				draw_circle(Vector2(ax, top - b.ah), 2.6, Color(1.0, 0.25, 0.35, blink))

func _draw_ground() -> void:
	draw_rect(Rect2(0, HORIZON, VW, VH - HORIZON), Color("#07030f"))
	draw_rect(Rect2(0, HORIZON, VW, VH - HORIZON), Color(0.0, 1.0, 0.85, 0.02))
	# líneas verticales convergentes
	for i in range(-9, 10):
		var bx: float = VANISH.x + float(i) * 62.0
		draw_line(VANISH, Vector2(bx, VH), Color(0.0, 1.0, 0.85, 0.16), 1.0)
	# horizontales con espaciado creciente
	var y: float = HORIZON + 6.0
	var step := 7.0
	while y < VH:
		draw_line(Vector2(0, y), Vector2(VW, y), Color(1.0, 0.35, 0.85, 0.13), 1.0)
		y += step
		step *= 1.32

func _draw_path() -> void:
	var pts: Array = []
	for n in nodes:
		pts.append(Vector2(n.x, n.y))
	# glow en capas
	for i in range(4, 0, -1):
		var c := Color(0.0, 1.0, 0.85, 0.05 * float(5 - i))
		draw_polyline(pts, c, 3.0 + float(i) * 3.0, true)
	draw_polyline(pts, Color(0.0, 1.0, 0.9, 0.55), 2.0, true)

func _draw_nodes() -> void:
	var font := ThemeDB.fallback_font
	for n in nodes:
		var ch: Dictionary = GameData.CHAPTERS[n.i]
		var col := Color(ch.color)
		var p := Vector2(n.x, n.y)
		var is_sel: bool = selected == n.i
		# onda pulsante
		var ph: float = fmod(t * 0.9 + float(n.i) * 0.35, 1.0)
		var rr: float = NODE_R + ph * 26.0
		draw_circle(p, rr, Color(col.r, col.g, col.b, 0.30 * (1.0 - ph)))
		# glow
		for i in range(5, 0, -1):
			draw_circle(p, NODE_R + float(i) * 4.0, Color(col.r, col.g, col.b, 0.035 * float(6 - i)))
		# cuerpo
		draw_circle(p, NODE_R + (3.0 if is_sel else 0.0), Color("#0b0718"))
		draw_circle(p, NODE_R - 3.0, Color(col.r * 0.22, col.g * 0.22, col.b * 0.35, 0.95))
		draw_arc(p, NODE_R + (3.0 if is_sel else 0.0), 0.0, TAU, 48, col, 2.5, true)
		# número del capítulo
		var num := str(n.i)
		draw_string(font, p + Vector2(-5.0, 8.0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1, 0.95))
		# etiqueta
		if is_sel:
			var label: String = str(ch.title)
			draw_string(font, p + Vector2(-90.0, 52.0), label, HORIZONTAL_ALIGNMENT_CENTER, 180.0, 15, col)

func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	# Título con glow
	var title := "ODEALAND"
	for i in range(4, 0, -1):
		draw_string(font, Vector2(0.0, 58.0), title, HORIZONTAL_ALIGNMENT_CENTER, VW, 40 + i * 2, Color(1.0, 0.3, 0.8, 0.07 * float(5 - i)))
	draw_string(font, Vector2(0.0, 58.0), title, HORIZONTAL_ALIGNMENT_CENTER, VW, 40, Color(1, 1, 1, 0.96))
	draw_string(font, Vector2(0.0, 82.0), "DATA ANALYST RPG", HORIZONTAL_ALIGNMENT_CENTER, VW, 13, Color(0.0, 1.0, 0.85, 0.75))
	# Panel de nivel
	draw_rect(Rect2(16.0, 100.0, 200.0, 44.0), Color(0.04, 0.02, 0.10, 0.75))
	draw_rect(Rect2(16.0, 100.0, 200.0, 44.0), Color(0.0, 1.0, 0.85, 0.5), false, 1.5)
	draw_string(font, Vector2(26.0, 120.0), "NIVEL 1 · NOVATO DE DATOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#7de8ff"))
	draw_rect(Rect2(26.0, 127.0, 180.0, 8.0), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(26.0, 127.0, 54.0, 8.0), Color(0.0, 1.0, 0.85, 0.9))
	draw_string(font, Vector2(150.0, 134.0), "150/500 XP", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.8))
	# Ayuda
	draw_string(font, Vector2(0.0, 948.0), "TOCA UN MUNDO PARA VER SUS MISIONES", HORIZONTAL_ALIGNMENT_CENTER, VW, 11, Color(1, 1, 1, 0.45))

func _draw_panel(i: int) -> void:
	var font := ThemeDB.fallback_font
	var ch: Dictionary = GameData.CHAPTERS[i]
	var col := Color(ch.color)
	var x := 30.0
	var w := VW - 60.0
	var y := 260.0
	var h := 420.0
	draw_rect(Rect2(x + 6.0, y + 8.0, w, h), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(x, y, w, h), Color(0.04, 0.02, 0.09, 0.96))
	draw_rect(Rect2(x, y, w, h), col, false, 2.0)
	draw_string(font, Vector2(x + 18.0, y + 34.0), str(ch.code), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
	draw_string(font, Vector2(x + 18.0, y + 60.0), str(ch.title), HORIZONTAL_ALIGNMENT_LEFT, w - 36.0, 18, Color(1, 1, 1, 0.95))
	var yy := y + 88.0
	# misiones del capítulo
	for m in GameData.MISSIONS:
		if int(m.chapter) != i:
			continue
		draw_circle(Vector2(x + 24.0, yy - 4.0), 5.0, col)
		draw_string(font, Vector2(x + 38.0, yy), str(m.title), HORIZONTAL_ALIGNMENT_LEFT, w - 110.0, 13, Color(1, 1, 1, 0.9))
		draw_string(font, Vector2(x + w - 62.0, yy), "+%d XP" % int(m.xp), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffd86b"))
		yy += 30.0
	# jefe
	for b in GameData.BOSSES:
		if int(b.chapter) != i:
			continue
		yy += 8.0
		draw_rect(Rect2(x + 14.0, yy - 16.0, w - 28.0, 74.0), Color(1.0, 0.2, 0.4, 0.10))
		draw_rect(Rect2(x + 14.0, yy - 16.0, w - 28.0, 74.0), Color("#ff3355"), false, 1.5)
		draw_string(font, Vector2(x + 26.0, yy + 4.0), "JEFE FINAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ff3355"))
		draw_string(font, Vector2(x + 26.0, yy + 26.0), str(b.name), HORIZONTAL_ALIGNMENT_LEFT, w - 52.0, 15, Color(1, 1, 1, 0.95))
		draw_string(font, Vector2(x + 26.0, yy + 46.0), str(b.description).substr(0, 54) + "...", HORIZONTAL_ALIGNMENT_LEFT, w - 52.0, 11, Color(1, 1, 1, 0.7))

# ─────────────────────────────────── interacción
func _unhandled_input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and event.pressed:
		pos = event.position
		pressed = true
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
		pressed = true
	if not pressed:
		return
	selected = -1
	for n in nodes:
		if pos.distance_to(Vector2(n.x, n.y)) < NODE_R + 16.0:
			selected = n.i
			break
	queue_redraw()

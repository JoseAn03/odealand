extends Node
## ODEA — Estado del juego (autoload)
## XP, nivel, misiones completadas y guardado en disco.

const SAVE_PATH := "user://odea_save.json"

var xp: int = 0
var missions_done: Dictionary = {}
var streak: int = 0
var last_day: String = ""
var loaded := false

func _ready() -> void:
	load_game()

# ── Nivel ──────────────────────────────────────────────
func level_index() -> int:
	var idx := 0
	for i in GameData.LEVELS.size():
		if xp >= int(GameData.LEVELS[i].xp):
			idx = i
	return idx

func level_name() -> String:
	return str(GameData.LEVELS[level_index()].name)

func level_xp_start() -> int:
	return int(GameData.LEVELS[level_index()].xp)

func level_xp_next() -> int:
	var i := level_index()
	if i + 1 < GameData.LEVELS.size():
		return int(GameData.LEVELS[i + 1].xp)
	return int(GameData.LEVELS[i].xp)

func level_progress() -> float:
	var a := level_xp_start()
	var b := level_xp_next()
	if b <= a:
		return 1.0
	return clampf(float(xp - a) / float(b - a), 0.0, 1.0)

# ── Misiones ───────────────────────────────────────────
func is_done(id: String) -> bool:
	return missions_done.has(id)

func add_xp(n: int) -> void:
	xp += n
	save_game()

func complete_mission(m: Dictionary) -> void:
	var id := str(m.id)
	if missions_done.has(id):
		return
	missions_done[id] = true
	xp += int(m.xp)
	save_game()

func chapter_total(ch: int) -> int:
	var c := 0
	for m in GameData.MISSIONS:
		if int(m.chapter) == ch:
			c += 1
	return c

func chapter_done(ch: int) -> int:
	var c := 0
	for m in GameData.MISSIONS:
		if int(m.chapter) == ch and missions_done.has(str(m.id)):
			c += 1
	return c

func chapter_complete(ch: int) -> bool:
	var t := chapter_total(ch)
	return t > 0 and chapter_done(ch) >= t

func chapter_unlocked(ch: int) -> bool:
	if ch <= 0:
		return true
	return chapter_complete(ch - 1)

# ── Guardado ───────────────────────────────────────────
func save_game() -> void:
	var d := {"xp": xp, "missions": missions_done, "streak": streak, "last_day": last_day}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
		f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		loaded = true
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		loaded = true
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		var d: Dictionary = parsed
		xp = int(d.get("xp", 0))
		streak = int(d.get("streak", 0))
		last_day = str(d.get("last_day", ""))
		var md: Variant = d.get("missions", {})
		if typeof(md) == TYPE_DICTIONARY:
			missions_done = md
	loaded = true

func reset() -> void:
	xp = 0
	missions_done = {}
	streak = 0
	last_day = ""
	save_game()

## Marca el día actual en la racha. Se llama al abrir el juego.
## (v1: suma 1 por día distinto; el escudo/reglas de racha van en Fase 2).
func register_day() -> void:
	var today: String = Time.get_date_string_from_system()
	if today == last_day:
		return
	if last_day == "":
		streak = 1
	else:
		streak += 1
	last_day = today
	save_game()

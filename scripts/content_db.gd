extends Node
## ContentDB — autoload que carga y normaliza data/odea_content.json (ya filtrado en Fase 0).
## Expone listas de contenido por pestaña y utilidades de paginación/mapeo de campos.

const CONTENT_PATH: String = "res://data/odea_content.json"
const PLAYBOOK_PATH: String = "res://data/playbook_45_days.json"
const BOSS_QUESTIONS_PATH: String = "res://data/boss_questions.json"

var data: Dictionary = {}
var playbook: Dictionary = {}
var boss_questions_data: Dictionary = {}

func _ready() -> void:
	load_content()
	load_playbook()
	load_boss_questions()

func load_content() -> void:
	var f: FileAccess = FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if f == null:
		push_warning("ContentDB: no se pudo abrir %s" % CONTENT_PATH)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		data = parsed

func load_playbook() -> void:
	var f: FileAccess = FileAccess.open(PLAYBOOK_PATH, FileAccess.READ)
	if f == null:
		push_warning("ContentDB: no se pudo abrir %s" % PLAYBOOK_PATH)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		playbook = parsed

func load_boss_questions() -> void:
	var f: FileAccess = FileAccess.open(BOSS_QUESTIONS_PATH, FileAccess.READ)
	if f == null:
		push_warning("ContentDB: no se pudo abrir %s" % BOSS_QUESTIONS_PATH)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		boss_questions_data = parsed

func _list(key: String) -> Array:
	var v: Variant = data.get(key, [])
	if typeof(v) == TYPE_ARRAY:
		return v
	return []

# ── Acceso por pestaña ────────────────────────────────
func campaign() -> Array: return _list("campaignMissions")
func bosses() -> Array: return _list("bossMissions")
func daily() -> Array: return _list("dailyMissions")
func weekly() -> Array: return _list("weeklyMissions")
func jobs() -> Array: return _list("employmentMissions")
func retos() -> Array: return _list("RETOS")
func logros() -> Array: return _list("achievements")
func recompensas() -> Array: return _list("REWARDS")

# ── Playbook 45 días (Fase 2) ─────────────────────────
func playbook_missions() -> Array:
	var v: Variant = playbook.get("missions", [])
	if typeof(v) == TYPE_ARRAY:
		return v
	return []

func playbook_planets() -> Array:
	var v: Variant = playbook.get("planets", [])
	if typeof(v) == TYPE_ARRAY:
		return v
	return []

func playbook_bosses() -> Array:
	var v: Variant = playbook.get("bosses", [])
	if typeof(v) == TYPE_ARRAY:
		return v
	return []

func boss_questions(id: String) -> Array:
	var v: Variant = boss_questions_data.get(id, [])
	if typeof(v) == TYPE_ARRAY:
		return v
	return []

func vida() -> Array:
	var out: Array = []
	out.append_array(_list("HABITOS"))
	out.append_array(_list("VIDA_GROWTH"))
	return out

## Diarias obligatorias (fijas del Playbook, sección 8.1).
func daily_obligatorias() -> Array:
	return [
		{"id": "daily_english", "title": "Inglés hablado (20-30 min)", "desc": "Grabar o practicar en voz alta. Evidencia: nota o grabación corta.", "xp": 25},
		{"id": "daily_sql", "title": "SQL o modelado (30-40 min)", "desc": "Un ejercicio cronometrado. Evidencia: query + tiempo.", "xp": 30},
		{"id": "daily_commit", "title": "Commit o networking", "desc": "Un commit pequeño o un mensaje/seguimiento. Evidencia: hash o registro.", "xp": 30},
	]

# ── Utilidades ────────────────────────────────────────
## Pagina una lista devolviendo como máximo `page_size` elementos desde `offset`.
static func paginate(items: Array, offset: int, page_size: int) -> Array:
	var end: int = mini(offset + page_size, items.size())
	if offset >= end:
		return []
	return items.slice(offset, end)

## Normaliza los campos de una misión (cada tipo del JSON usa claves distintas).
static func fields(m: Dictionary) -> Dictionary:
	var title: String = str(m.get("title", m.get("t", m.get("name", ""))))
	var desc: String = str(m.get("description", m.get("desc", m.get("d", ""))))
	var xp: int = int(m.get("xp", 0))
	var id: String = str(m.get("id", ""))
	return {"id": id, "title": title, "desc": desc, "xp": xp}

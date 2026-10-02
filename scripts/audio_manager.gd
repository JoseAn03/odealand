extends Node
## AudioManager — sonidos procedurales generados en código (sin assets externos).

var _cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Reproduce un efecto de sonido por nombre. Ignora nombres desconocidos.
func play(sfx_name: String, volume: float = 0.5) -> void:
	var stream: AudioStreamWAV = _stream(sfx_name)
	if stream == null:
		return
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = linear_to_db(clampf(volume, 0.0, 1.0))
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _stream(name: String) -> AudioStreamWAV:
	if _cache.has(name):
		return _cache[name]
	var s: AudioStreamWAV
	match name:
		"jump":
			s = _tone(520.0, 0.16, 0.55)
		"double_jump":
			s = _tone(720.0, 0.16, 0.55)
		"land":
			s = _tone(180.0, 0.12, 0.6)
		"step":
			s = _tone(300.0, 0.05, 0.22)
		"coin":
			s = _two_tone(880.0, 1320.0, 0.18, 0.55)
		"boss_hit":
			s = _tone(220.0, 0.14, 0.6)
		"boss_win":
			s = _two_tone(660.0, 990.0, 0.4, 0.65)
		"boss_lose":
			s = _tone(140.0, 0.4, 0.55)
		_:
			return null
	_cache[name] = s
	return s

func _tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var count: int = int(duration * 22050.0)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	for i: int in range(count):
		var t: float = float(i) / 22050.0
		var env: float = 1.0 - float(i) / float(count)
		var v: float = sin(TAU * freq * t) * env * volume
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	stream.data = data
	return stream

func _two_tone(f1: float, f2: float, duration: float, volume: float) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var count: int = int(duration * 22050.0)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	for i: int in range(count):
		var t: float = float(i) / 22050.0
		var half: float = float(i) / float(count)
		var freq: float = f1 if half < 0.5 else f2
		var env: float = 1.0 - float(i) / float(count)
		var v: float = sin(TAU * freq * t) * env * volume
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	stream.data = data
	return stream

extends Node
## Haptics — vibración en móvil. No-op en plataformas sin soporte.

func vibrate(duration_ms: int = 50) -> void:
	Input.vibrate_handheld(duration_ms)

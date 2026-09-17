# ODEALAND — Brief para IA desarrolladora de videojuegos
**Código fuente:** https://github.com/JoseAn03/odealand/raw/main/odealand-fuente-v0.2.zip
**Motor:** Godot 4.7 · **Target:** Android (APK) + PC · **Género:** RPG 3D educativo (Mario Galaxy + cyberpunk)

---

## 0. ROL
Actuá como **desarrollador senior de videojuegos** (Godot 4 + GDScript), experto en juegos móviles 3D con estética **Super Mario Galaxy** (planetas esféricos caminables) y **cyberpunk neón**.

## 1. ARCHIVOS DEL PROYECTO
| Archivo | Qué contiene |
|---|---|
| `project.godot` | Config (autoload `GameState`, escena principal `scenes/galaxy.tscn`, renderer `gl_compatibility`) |
| `scripts/galaxy.gd` (~830 líneas) | Escena 3D: planetas, avatar, cámara, UI, input |
| `scripts/game_data.gd` | 8 capítulos, 24 misiones, 8 jefes, 9 niveles (datos reales) |
| `scripts/game_state.gd` | XP, nivel, misiones completadas, guardado en `user://odea_save.json` |
| `scenes/galaxy.tscn` | Escena principal |

**Ya funciona:** 8 planetas 3D con shader procedural · avatar (casco/visor/capa) · tap en planeta → el avatar camina hacia él · joystick virtual (arrastrar) · panel de misiones con botón COMPLETAR · barra de XP · panel lateral de progreso · guardado.

## 2. PROBLEMAS A CORREGIR (reportados)
1. **La animación de caminar casi no se ve** (las piernas rotan 0.12 rad ≈ imperceptible).
2. Planetas simples (sin superficie caminable ni detalle).
3. **Faltan:** saltos, nave, coleccionables, combate, sonidos, música, partículas, misiones secundarias.
4. UI básica, sin logros ni recompensas.

## 3. OBJETIVOS POR FASES *(trabajar UNA fase por respuesta)*
**FASE 1 — Movimiento y avatar (máxima prioridad)**
- Animación de caminar REAL: piernas y brazos con pivote en cadera/hombro, ciclo de 4 poses, balanceo de torso, partículas de polvo al pisar.
- Correr, **salto** (impulso, gravedad, aterrizaje con impacto) y salto doble.
- Cámara con seguimiento suave y ligero "rig" al saltar.

**FASE 2 — Mundos y arte**
- Planetas con relieve, ciudades, anillos, lunas y props; cada uno con identidad visual propia.
- Nebulosas, estrellas titilando, niebla neón, iluminación dinámica, bloom.

**FASE 3 — Dinámicas**
- **Nave/cohete** para viajar entre planetas (mini-vuelo), **coleccionables** (fragmentos de datos), monedas, power-ups, portales, plataformas flotantes.

**FASE 4 — Jefes y combate**
- 8 jefes con patrones, barra de vida y **"combate de datos"** (mini-retos: elegir la consulta SQL correcta, detectar el error, interpretar una métrica). Recompensas por victoria.

**FASE 5 — Contenido**
- Integrar TODAS las misiones de la app web (`odea.html`: campaña + empleo + diario) y añadir **3 misiones secundarias por planeta** + logros.

**FASE 6 — Pulido**
- Sonidos (pasos, salto, moneda, jefes), música por planeta, transiciones, VFX (explosiones, brillos), vibración háptica, ajustes guardables, 60 fps en móvil medio.

## 4. REGLAS TÉCNICAS (obligatorias)
- **GDScript 4.7 estricto:** tipos explícitos; `:=` solo desde tipos concretos (nunca desde Variant); indentación con tabs.
- **Sin dependencias externas:** solo nodos, shaders y APIs de Godot 4.7.
- **Móvil primero:** `gl_compatibility`, pocos draw calls, < 100k triángulos, texturas procedurales, sin procesos pesados en `_process` (usar `Timer`/señales/`MultiMesh`).
- **No romper:** guardado (`user://odea_save.json`), estructura de `game_data.gd`, export Android (`export_presets.cfg`).
- Si un script supera ~800 líneas, **dividirlo en módulos** (`scripts/<sistema>.gd`).
- Comentarios en español; funciones cortas y con propósito único.

## 5. FORMATO DE RESPUESTA (estricto, para minimizar tokens)
- Devolvé **SOLO los archivos modificados, completos**, con esta cabecera exacta:
  ```
  === FILE: scripts/galaxy.gd ===
  (contenido completo)
  === END FILE ===
  ```
- **PROHIBIDO:** explicaciones largas, fragmentos con `...`, repetir archivos sin cambios, preguntas de vuelta.
- Si algo es ambiguo: elegí la opción más simple y seguí.
- Al final: **máximo 5 bullets** con lo que cambió.
- Trabajá **una fase por respuesta** (empezá por la FASE 1 salvo indicación contraria).

## 6. DATOS CLAVE
- **9 niveles:** Novato de Datos (0) → Aprendiz (500) → Explorador (1500) → Caballero SQL (3000) → Mago de Pandas (5000) → Guerrero de la IA (7500) → Maestro del Dashboard (10000) → Analista Legendario (15000) → Dios de los Datos (20000).
- **8 capítulos:** Cimientos · SQL y Modelado · ETL y Automatización · IA Aplicada · Dashboards y Storytelling · Marketing Analytics · IA Productiva · Empleo (Corona Final).
- **8 jefes:** El Guardián del Entorno · Señor de las Consultas · La Hidra de Datos Sucios · El Oráculo de la IA · Titán del Storytelling · El Mago de las Métricas · Nexus, la Máquina Viva · La Corona Final.

## 7. CRITERIOS DE ÉXITO
- Compila sin errores en Godot 4.7 y corre a **60 fps en móvil medio**.
- El avatar camina, corre y salta con **animación visible**.
- Cada planeta se siente único y explorable; los jefes son memorables.
- Todo el contenido de la web integrado, con progreso guardado.

# ODEALAND — Brief para IA desarrolladora de videojuegos (v0.5)
**Código fuente:** https://github.com/JoseAn03/odealand/raw/main/odealand-fuente-v0.5.zip
**Motor:** Godot 4.7 (GDScript) · **Target:** Android (APK) + PC · **Género:** RPG 3D educativo · **Estética:** Super Mario Galaxy + cyberpunk neón

---

## 0. ROL
Actuá como **desarrollador senior de videojuegos y de UI móvil** (Godot 4). Priorizá: jugabilidad adictiva, **legibilidad perfecta en celular** y 60 fps.

## 1. ARCHIVOS
| Archivo | Contenido |
|---|---|
| `scripts/galaxy.gd` | Escena principal: planetas, UI, misiones, HUD |
| `scripts/avatar_rig.gd` | Avatar articulado (cadera/rodilla/hombro con pivotes) ✅ Fase 1 |
| `scripts/avatar_motion.gd` | Física: caminar/correr/salto/doble salto ✅ Fase 1 |
| `scripts/avatar_controls.gd` | Joystick táctil + botones SALTAR/CORRER + teclado ✅ Fase 1 |
| `scripts/avatar_dust.gd` | Polvo al pisar (MultiMesh, 1 draw call) ✅ Fase 1 |
| `scripts/follow_camera.gd` | Cámara amortiguada con impacto ✅ Fase 1 |
| `scripts/game_data.gd` | 8 capítulos, 24 misiones, 8 jefes, 9 niveles |
| `scripts/game_state.gd` | XP, nivel, guardado (`user://odea_save.json`) |
| `data/odea_content.json` | **TODO el contenido de la app web**: 24 campaña + 8 jefes + 40 campaña extendida + **168 diarias** + 8 semanales + **46 empleo** + 22 retos + 31 recompensas + 24 logros + vida/hábitos |

## 2. ESTADO ACTUAL
✅ Galaxia 3D con 8 planetas (shader procedural, atmósfera, anillos) · avatar articulado que camina/corre/salta · joystick táctil · panel de misiones y de progreso · guardado.

## 3. PROBLEMAS REPORTADOS EN CELULAR (corregir PRIMERO)
1. **Panel de MISIONES cortado** 🔴 (medido en viewport 540×1200):
   `panel_misiones: pos=(290,850) tam=(500,520)` → **se sale por la DERECHA** (790>540) y por **ABAJO** (1370>1200).
   **Causa:** `set_anchors_preset(PRESET_CENTER)` + `position` fija.
   **Solución:** anchors full-rect con offsets (`offset_left=14, offset_top=110, offset_right=-14, offset_bottom=-130`), `ScrollContainer` interno y botón CERRAR siempre visible.
2. **No se entiende cómo entrar a las misiones** → falta una pantalla clara. Debe haber botones grandes y evidentes: **MISIONES · PLAN DIARIO · EMPLEO · RETOS · LOGROS · PROGRESO**.
3. **El conjunto se ve "muy básico"** → falta identidad visual (ver prioridad 3).

## 4. PRIORIDADES (una por respuesta, en este orden)

**PRIORIDAD 1 — UI/UX de misiones (urgente)**
- Panel de misiones **responsive** (arreglar el punto 1) con: título del capítulo, lista scrolleable, botón COMPLETAR (ancho ≥160 px) y CERRAR fijo.
- Pantalla de **CONTENIDO** con pestañas: Campaña · Plan Diario (168) · Empleo (46) · Retos (22) · Logros (24) · Vida.
- Cada misión: título, XP, estado (✅/🔓), y al tocar → detalle.
- Indicador permanente de progreso (X completadas / total) y **guía al jugador** ("tocá un planeta para ver sus misiones", "elegí una pestaña").

**PRIORIDAD 2 — Arte de planetas + CAMINO entre ellos**
- **Camino/cinta luminosa** que conecte los 8 planetas (curva suave, neón, con animación de energía) y que el avatar lo **recorra** al viajar. Estilo Mario Galaxy.
- Planetas con más detalle: relieve, ciudades visibles, lunas, anillos, nubes, cráteres; cada uno con identidad propia (paleta, silueta, props).
- Superficie "pisable" visual alrededor de cada planeta (plataforma/aro).

**PRIORIDAD 3 — Cambio gráfico global (que no se vea básico)**
- Iluminación: luz direccional + luz de relleno con color, sombras suaves, **bloom** y niebla volumétrica.
- Fondo: nebulosas a color, cúmulos de estrellas, polvo estelar, cometa ocasional.
- Post-proceso: viñeta, aberración cromática leve, saturación neón.
- UI con identidad: paneles con cristal/borde neón animado, iconos, transiciones suaves (Tween).

**PRIORIDAD 4 — AVATAR v2 (más elaborado)**
- Personaje con: casco con visor y antena, chaqueta con luces, capa animada, botas con propulsores, manos, y **expresiones** (saludo al llegar a un planeta).
- Animaciones: idle (respirar), caminar, correr, saltar, caer, aterrizar, **saludar** y **celebrar**.

**PRIORIDAD 5 — Jefes interactivos**
- Al completar un capítulo → **combate de jefes**: pantalla dedicada con barra de vida, 3-5 preguntas/retos de datos (elegir la respuesta correcta), daño al fallar del jugador, victoria con recompensa (XP + insignia).

**PRIORIDAD 6 — Contenido completo + pulido**
- Cargar `data/odea_content.json` e integrar las 655 entradas (168 diarias, 46 empleo, retos, logros) con su UI y guardado.
- Sonidos (pasos, salto, monedas, jefes), música por planeta, VFX, vibración, 60 fps.

## 5. REGLAS TÉCNICAS (obligatorias)
- **GDScript 4.7 estricto**: tipos explícitos; `:=` solo desde tipos concretos.
- **No romper**: guardado, `game_data.gd`, paneles existentes, export Android.
- **Móvil primero**: `gl_compatibility`, pocos draw calls, `MultiMesh` para multitudes, sin trabajo pesado en `_process`.
- **Legibilidad móvil obligatoria**: toda fuente ≥15 px (botones ≥17), contorno negro (`outline_size 6`) y nada de texto cortado. El proyecto ya tiene MSDF activado.
- Scripts de más de ~800 líneas → dividir en módulos.

## 6. FORMATO DE RESPUESTA (estricto, anti-tokens)
- Devolvé **SOLO los archivos modificados completos**:
  ```
  === FILE: scripts/galaxy.gd ===
  (contenido completo)
  === END FILE ===
  ```
- **PROHIBIDO**: explicaciones largas, fragmentos con `...`, repetir archivos sin cambios, preguntas de vuelta.
- Si algo es ambiguo: elegí lo más simple y seguí.
- Máximo **5 bullets** al final.
- **Una prioridad por respuesta** (empezá por la PRIORIDAD 1).

## 7. DATOS CLAVE
- **9 niveles:** Novato de Datos (0) → Aprendiz (500) → Explorador (1500) → Caballero SQL (3000) → Mago de Pandas (5000) → Guerrero de la IA (7500) → Maestro del Dashboard (10000) → Analista Legendario (15000) → Dios de los Datos (20000).
- **8 capítulos:** Cimientos · SQL y Modelado · ETL · IA Aplicada · Dashboards · Marketing Analytics · IA Productiva · Empleo.
- **8 jefes:** Guardián del Entorno · Señor de las Consultas · Hidra de Datos Sucios · Oráculo de la IA · Titán del Storytelling · Mago de las Métricas · Nexus la Máquina Viva · Corona Final.

## 8. CRITERIOS DE ÉXITO
- Compila sin errores en Godot 4.7 y corre a 60 fps en móvil medio.
- **Cero recortes de UI** en 540×1200 (verificado con una función de autodiagnóstico).
- El jugador entiende en 5 segundos dónde están las misiones y su progreso.
- Los planetas y el camino se ven **espectaculares**, no "básicos".

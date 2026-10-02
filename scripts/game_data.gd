extends RefCounted

## Datos del juego ODEA - extraidos de la app original (mecanica intacta)

class_name GameData


const LEVELS := [
	{"xp": 0, "name": "Novato de Datos"},
	{"xp": 500, "name": "Aprendiz Analista"},
	{"xp": 1500, "name": "Explorador de Insights"},
	{"xp": 3000, "name": "Caballero SQL"},
	{"xp": 5000, "name": "Mago de Pandas"},
	{"xp": 7500, "name": "Guerrero de la IA"},
	{"xp": 10000, "name": "Maestro del Dashboard"},
	{"xp": 15000, "name": "Analista Legendario"},
	{"xp": 20000, "name": "Dios de los Datos"},
]

const CHAPTERS := [
	{"id": 0, "code": "CAPÍTULO 0", "title": "Cimientos del Analista de Datos", "color": "#00ff88", "icon": "🛡️", "narrative": "Tu arsenal base: entorno profesional, Python limpio y buenas prácticas de código. Sin cimientos sólidos, no hay torre de datos que aguante."},
	{"id": 1, "code": "CAPÍTULO 1", "title": "SQL y Modelado de Negocio", "color": "#00ccff", "icon": "⚔️", "narrative": "El idioma universal de los datos. Domina SQL de verdad y aprende a modelar datos que respondan preguntas de negocio, incluidas las de marketing."},
	{"id": 2, "code": "CAPÍTULO 2", "title": "ETL y Automatización", "color": "#7c6cff", "icon": "🧬", "narrative": "Los datos no llegan solos: extrae, transforma y carga con calidad de producción. Automatiza con n8n y scripts para que el análisis fluya solo."},
	{"id": 3, "code": "CAPÍTULO 3", "title": "IA Aplicada al Análisis", "color": "#ff00ff", "icon": "🤖", "narrative": "La IA es tu escudero: prompts expertos, código asistido y análisis auditados. La máquina acelera, pero tú verificas y decides."},
	{"id": 4, "code": "CAPÍTULO 4", "title": "Dashboards y Storytelling", "color": "#ffaa00", "icon": "📊", "narrative": "Datos sin historia no mueven decisiones. Construye dashboards de nivel consultor y aprende a contar hallazgos con impacto."},
	{"id": 5, "code": "CAPÍTULO 5", "title": "Marketing Analytics", "color": "#ff6600", "icon": "🎯", "narrative": "Tu ventaja diferencial: métricas de negocio, cohortes, A/B testing y web analytics. Convierte el marketing en decisiones basadas en datos."},
	{"id": 6, "code": "CAPÍTULO 6", "title": "IA Productiva y Apps de Datos", "color": "#f72585", "icon": "👾", "narrative": "Del análisis al producto: analistas virtuales con IA, reportes automáticos y un portafolio que demuestra lo que eres capaz de construir."},
	{"id": 7, "code": "CAPÍTULO 7", "title": "Empleo: La Corona Final", "color": "#ff3355", "icon": "🏆", "narrative": "Todo el poder acumulado se lanza al asedio: marca personal, entrevistas impecables y la campaña de aplicaciones que abrirá la puerta."},
]

const MISSIONS := [
	{"id": "m0_1", "chapter": 0, "title": "Entorno de Nivel Profesional", "description": "Configurar VS Code, Python y Git como un profesional: extensiones clave, entornos virtuales, alias y un repo organizado para tus scripts.", "xp": 150, "category": "analyst", "time": "3-4 horas", "verification": "Repo personal organizado con README y estructura clara"},
	{"id": "m0_2", "chapter": 0, "title": "Trío de Scripts Limpios", "description": "Escribir 3 scripts Python con docstrings, manejo de errores y funciones puras: automatización, procesamiento de datos y un caso real.", "xp": 250, "category": "analyst", "time": "5-6 horas", "verification": "3 scripts de calidad publicados en GitHub"},
	{"id": "m0_3", "chapter": 0, "title": "Ritual de Calidad de Código", "description": "Aplicar buenas prácticas: requirements, .gitignore, estructura de carpetas y revisión de estilo (PEP8, linters).", "xp": 150, "category": "analyst", "time": "3-4 horas", "verification": "Repo con requirements, .gitignore y estilo consistente"},
	{"id": "m1_1", "chapter": 1, "title": "SQL Esencial y Avanzado", "description": "Completar 60+ ejercicios (SQLZoo, LeetCode) incluyendo JOINs, window functions y CTEs hasta dominarlos.", "xp": 250, "category": "analyst", "time": "8-10 horas", "verification": "60+ ejercicios SQL resueltos y documentados"},
	{"id": "m1_2", "chapter": 1, "title": "Modelo de Datos de Negocio", "description": "Diseñar tu propia base de datos (4+ tablas con relaciones) y escribir 25 consultas que respondan preguntas de negocio reales.", "xp": 300, "category": "analyst", "time": "10-12 horas", "verification": "BD propia + 25 queries publicadas con README"},
	{"id": "m1_3", "chapter": 1, "title": "SQL para Marketing", "description": "Escribir consultas de cohortes, embudos y segmentación de clientes sobre un dataset de negocio.", "xp": 200, "category": "analyst", "time": "6-8 horas", "verification": "Queries de marketing (cohortes y embudo) funcionando"},
	{"id": "m2_1", "chapter": 2, "title": "Pipeline ETL con Tests", "description": "Llevar tu pipeline ETL a producción: tests automatizados, logging y validación de datos en cada etapa.", "xp": 300, "category": "analyst", "time": "8-10 horas", "verification": "Pipeline con tests y logging funcionando"},
	{"id": "m2_2", "chapter": 2, "title": "Automatización con n8n", "description": "Crear un workflow de automatización real (alertas, reportes o integración) usando n8n, como tu job aggregator.", "xp": 250, "category": "analyst", "time": "6-8 horas", "verification": "Workflow n8n activo y documentado"},
	{"id": "m2_3", "chapter": 2, "title": "Orquestación y Calidad", "description": "Programar tus pipelines (cron/n8n) con monitoreo de errores y notificaciones de éxito o fallo.", "xp": 200, "category": "analyst", "time": "5-6 horas", "verification": "Pipeline programado con alertas automáticas"},
	{"id": "m3_1", "chapter": 3, "title": "Prompt Engineering Maestro", "description": "Construir una biblioteca de 30 prompts avanzados (rol, few-shot, cadena de pensamiento) para análisis y código.", "xp": 150, "category": "ai", "time": "4-5 horas", "verification": "Biblioteca de 30 prompts documentada"},
	{"id": "m3_2", "chapter": 3, "title": "Código Asistido y Auditado", "description": "Refactorizar un proyecto con IA (Copilot/Claude) y auditar cada cambio propuesto contra las reglas del código.", "xp": 200, "category": "ai", "time": "5-6 horas", "verification": "Refactor con IA auditado y documentado"},
	{"id": "m3_3", "chapter": 3, "title": "Análisis Asistido por IA", "description": "Realizar un análisis completo con ayuda de IA y verificar cada respuesta contra los datos reales.", "xp": 250, "category": "ai", "time": "6-8 horas", "verification": "Análisis con IA verificado y publicado"},
	{"id": "m4_1", "chapter": 4, "title": "Dashboard de Nivel Consultor", "description": "Construir un dashboard de 3 páginas con filtros, medidas DAX y una historia clara sobre datos reales (tipo ANC).", "xp": 350, "category": "analyst", "time": "10-12 horas", "verification": "Dashboard de 3 páginas publicado"},
	{"id": "m4_2", "chapter": 4, "title": "Estadística Aplicada", "description": "Proyecto de estadística con Python: distribuciones, intervalos y correlación sobre un dataset real, con scipy.", "xp": 250, "category": "analyst", "time": "6-8 horas", "verification": "Análisis estadístico completo documentado"},
	{"id": "m4_3", "chapter": 4, "title": "Historia con Datos (STAR)", "description": "Grabar un video de 3 minutos explicando tus hallazgos con estructura STAR a audiencia no técnica.", "xp": 200, "category": "employability", "time": "3-4 horas", "verification": "Video STAR de 3 minutos grabado"},
	{"id": "m5_1", "chapter": 5, "title": "Cohortes y Embudo en Acción", "description": "Analizar retención por cohortes y embudo de conversión con Python/SQL sobre un dataset de e-commerce.", "xp": 250, "category": "analyst", "time": "6-8 horas", "verification": "Análisis de cohortes y embudo documentado"},
	{"id": "m5_2", "chapter": 5, "title": "A/B Testing Real (P2)", "description": "Diseñar y ejecutar un A/B test completo: hipótesis, tamaño de muestra, análisis con scipy y reporte ejecutivo.", "xp": 300, "category": "analyst", "time": "8-10 horas", "verification": "Proyecto P2 publicado con reporte y recomendación"},
	{"id": "m5_3", "chapter": 5, "title": "Web Analytics (P4)", "description": "Analizar un dataset público estilo GA4: adquisición, comportamiento y conversión, con 5+ insights accionables.", "xp": 250, "category": "analyst", "time": "6-8 horas", "verification": "Análisis web (P4) publicado con insights"},
	{"id": "m6_1", "chapter": 6, "title": "Analista Virtual con IA (P3)", "description": "Construir una app Streamlit con chat que responda preguntas de negocio sobre tus datos, con verificación de cifras.", "xp": 350, "category": "ai", "time": "10-12 horas", "verification": "App P3 publicada y funcionando en línea"},
	{"id": "m6_2", "chapter": 6, "title": "Reportes Automáticos con IA (P6)", "description": "Automatizar un reporte semanal: datos procesados, resumen generado con IA y entrega programada.", "xp": 300, "category": "ai", "time": "8-10 horas", "verification": "Reporte automático P6 entregándose solo"},
	{"id": "m6_3", "chapter": 6, "title": "Portafolio de Nivel Experto", "description": "Publicar tus proyectos insignia (P1-P5) con casos de estudio, métricas y página STAR en tu portafolio web.", "xp": 300, "category": "employability", "time": "8-10 horas", "verification": "Portafolio experto con P1-P5 publicado"},
	{"id": "m7_1", "chapter": 7, "title": "Marca Personal en Acción", "description": "Publicar contenido en LinkedIn 2 veces por semana contando tus proyectos y aprendizajes, con perfil optimizado.", "xp": 200, "category": "employability", "time": "5-6 horas", "verification": "8+ posts publicados en un mes"},
	{"id": "m7_2", "chapter": 7, "title": "Máquina de Entrevistas", "description": "Completar 5 simulacros de entrevista con IA (SQL, Python, métricas y casos) y pulir tus respuestas STAR.", "xp": 300, "category": "employability", "time": "8-10 horas", "verification": "5 simulacros completados con mejoras aplicadas"},
	{"id": "m7_3", "chapter": 7, "title": "Tracker Estratégico de Aplicaciones", "description": "Gestionar 50+ aplicaciones con seguimiento de respuestas, iteración de CV y métricas de éxito por canal.", "xp": 300, "category": "employability", "time": "8-10 horas", "verification": "Tracker con 50+ aplicaciones y análisis de respuesta"},
]

const BOSSES := [
	{"chapter": 0, "name": "EL GUARDIAN DEL ENTORNO", "description": "Configura tu arsenal: derrota al guardian montando VS Code + Python + Git como un profesional."},
	{"chapter": 1, "name": "SEÑOR DE LAS CONSULTAS", "description": "60 consultas SQL sin fallar: JOINs, window functions y CTEs en un solo combate."},
	{"chapter": 2, "name": "LA HIDRA DE DATOS SUCIOS", "description": "Automatiza el ETL y derrota a la hidra: datos limpios, carga confiable, cero errores manuales."},
	{"chapter": 3, "name": "EL ORACULO DE LA IA", "description": "Audita cada respuesta del oraculo: si no puedes verificar, no puedes confiar."},
	{"chapter": 4, "name": "TITAN DEL STORYTELLING", "description": "Tu dashboard debe contar una historia que mueva una decision: ese es el golpe final."},
	{"chapter": 5, "name": "EL MAGO DE LAS METRICAS", "description": "Cohortes, LTV, A/B testing: convierte el marketing en decisiones con datos."},
	{"chapter": 6, "name": "NEXUS, LA MAQUINA VIVA", "description": "Construye tu analista virtual y demuestra que funciona de punta a punta."},
	{"chapter": 7, "name": "LA CORONA FINAL", "description": "Entrevistas, marca personal y el asedio de aplicaciones: el jefe definitivo."},
]
class_name PlanPartidoUI
extends RefCounted
## «PLAN DE JUEGO» DESDE LA PREVIA DEL PARTIDO (17-11-2026; dueño: «el plan de juego es la alineación, ya tenemos una pantalla de eso»; Auditoría:
## en el flujo del partido no se enseña el resto del juego). Abre la pantalla de TÁCTICA de siempre (`PantallaMenu` con las secciones de
## `TacticaSecciones`: pizarra y formación, el once y el banquillo, órdenes), pero como menú propio del partido: con los colores morados de la previa,
## sin la barra lateral de todo el juego, sin «Portada» y con «Volver a la previa». Al cerrarla, la barra vuelve como estaba.

const MENU := {"id": "plan_partido", "icono": "📋", "nombre": "Plan de juego", "estilo": 8,
	"lema": "La formación, el once, el banquillo y las órdenes de este partido.",
	"colores": ["#170828", "#3a1050", "#e0309a"], "subs": [
	{"tab": "Táctica", "secc": "pizarra", "label": "Pizarra y formación", "icono": "📋", "desc": "El dibujo y la formación."},
	{"tab": "Táctica", "secc": "once", "label": "El once y el banquillo", "icono": "👥", "desc": "Quién sale y quién espera."},
	{"tab": "Táctica", "secc": "ordenes", "label": "Órdenes de juego", "icono": "🎯", "desc": "Mentalidad, presión, ritmo y línea."}]}

static func abrir(p: Principal) -> PantallaMenu:
	var pm := PantallaMenu.abrir(p, MENU, 0)
	if pm == null:
		return null
	var riel: Control = p._menu_lateral
	var se_veia := riel.visible
	riel.visible = false
	if pm._raiz != null:
		pm._raiz.offset_left = 22.0
	if pm._btn_portada != null:
		pm._btn_portada.visible = false
	for b in pm.find_children("*", "Button", true, false):
		var txt := String((b as Button).text)
		if txt.contains(Idiomas.t("Volver")):
			(b as Button).text = "◂  " + Idiomas.t("Volver a la previa")
			break
	pm.cerrada.connect(func() -> void:
		if is_instance_valid(riel):
			riel.visible = se_veia)
	return pm

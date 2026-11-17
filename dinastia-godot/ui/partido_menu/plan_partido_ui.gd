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
	if not pm.has_node("MandoMenuPartido"):   ## Cuadrado = B: del detalle a la portada; de la portada, a la previa
		MandoMenuPartido.escuchar(pm, func() -> void: pm.portada() if pm._activo >= 0 else pm.cerrar(), false)
	pm.cerrada.connect(func() -> void:
		if is_instance_valid(riel):
			riel.visible = se_veia)
	return pm

## (17-11, Auditoría: «al abrir el plan los retratos tienen que estar ya») Mientras se ve la previa, encarga los retratos 3D del plantel propio
## (primero el once) y del once rival a la cola de `Cara`/`Retrato3D`, que los hace de uno en uno en segundo plano. Son las MISMAS claves que piden
## la pizarra (42 px) y la lista del once (30 px): al abrir el plan salen de la caché, sin siluetas.
static func precargar_retratos(mio: Club, rival: Club) -> int:
	var lista: Array = []
	for j: Jugador in mio.once():
		lista.append([j, mio])
	for j: Jugador in mio.plantilla:
		if not mio.once().has(j):
			lista.append([j, mio])
	if rival != null:
		for j: Jugador in rival.once():
			lista.append([j, rival])
	var antes := Retrato3D._cola.size()
	for par: Array in lista:
		var c: Club = par[1]
		Cara.textura(par[0], c.color1, c.color2, 42)
	## Delante de la cola: detrás de la previa está el menú principal, que ya encargó decenas de caras de otras pantallas.
	if Retrato3D._cola.size() > antes:
		var nuevos := Retrato3D._cola.slice(antes)
		Retrato3D._cola.resize(antes)
		Retrato3D._cola = nuevos + Retrato3D._cola
	return lista.size()

## Cuántos titulares de `c` siguen esperando su retrato en la cola.
static func faltan_del_once(c: Club) -> int:
	var n := 0
	for job: Dictionary in Retrato3D._cola:
		if job.has("j") and c.once().has(job["j"]):
			n += 1
	return n

## Si la cola de retratos 3D ya terminó (para las pruebas y las medidas).
static func retratos_listos() -> bool:
	if not Retrato3D.disponible():
		return true
	return Retrato3D._cola.is_empty() and (Retrato3D._inst == null or not is_instance_valid(Retrato3D._inst) or not Retrato3D._inst._ocupado)

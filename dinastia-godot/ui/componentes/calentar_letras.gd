class_name CalentarLetras
extends RefCounted
## CALENTAR LETRAS Y ESCUDOS (15-11-2026, meta del dueño: que los menús no tarden). La primera vez que sale un tamaño de letra o un
## icono (emoji) hay que rasterizar sus glifos, y la primera vez que sale un escudo hay que pintarlo: eso cae en el primer fotograma del
## menú que lo usa. Aquí se hace antes, en reposo (lo llama `AhorroMenu` tras 3 s sin tocar nada), UNA vez por sesión:
##   · letras: un SubViewport fuera de la pantalla dibuja una sola vez el abecedario y los iconos de los menús en los tamaños de la interfaz
##     (la caché de glifos de la fuente es de todo el juego);
##   · escudos: los de los clubes de tu liga en los tamaños de las listas y tablas (`ESCUDOS`), de pocos en pocos por fotograma.
const ESCUDOS := [20, 22, 26, 28]   ## los altos de las listas y las tablas (`TablaCompeticion` usa 20 y 28; `Principal._escudo`, 22)
const TAMANOS := [11, 12, 13, 14, 16, 18, 20, 22, 36, 38, 42]
const TEXTO := "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ abcdefghijklmnñopqrstuvwxyz 0123456789 áéíóúüÁÉÍÓÚ ·%«»▸◂▦★☆▶◀ .,:;!?¡¿()-+/"
static var hecho := false
static var activo := OS.get_environment("SIN_CALENTAR_LETRAS") == ""

static func lanzar(raiz: Node) -> void:
	if hecho or not activo or raiz == null or not raiz.is_inside_tree():
		return
	hecho = true
	var iconos := ""
	for m: Dictionary in MenuLateral.MENUS:
		iconos += String(m.get("icono", ""))
		for s: Dictionary in m["subs"]:
			iconos += String(s.get("icono", ""))
	var vp := SubViewport.new()
	vp.size = Vector2i(512, 64)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var caja := VBoxContainer.new()
	vp.add_child(caja)
	for t: int in TAMANOS:
		var l := Label.new()
		l.text = TEXTO + " " + iconos
		l.add_theme_font_size_override("font_size", t)
		caja.add_child(l)
	raiz.add_child(vp)
	_escudos_y_cerrar(raiz, vp)

static func _escudos_y_cerrar(raiz: Node, vp: SubViewport) -> void:
	await raiz.get_tree().process_frame
	await raiz.get_tree().process_frame
	if is_instance_valid(vp):
		vp.queue_free()
	var p := raiz as Principal
	if p == null or p.mundo == null or p.mundo.mi_club() == null:
		return
	var liga: Liga = null
	for l: Liga in p.mundo.ligas:
		if l.clubes.has(p.mundo.mi_club()):
			liga = l
	if liga == null:
		return
	var n := 0
	for c: Club in liga.clubes:
		for alto: int in ESCUDOS:
			Escudo.textura(c, alto)
		n += 1
		if n % 3 == 0:
			if not is_instance_valid(raiz) or not raiz.is_inside_tree():
				return
			await raiz.get_tree().process_frame

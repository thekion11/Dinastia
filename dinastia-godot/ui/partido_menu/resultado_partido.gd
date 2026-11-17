class_name ResultadoPartido
extends PantallaMaqueta
## EL RESULTADO DEL PARTIDO, COMO LA MAQUETA (17-11-2026): fondo noche con los dos haces rojos, «VICTORIA / EMPATE / DERROTA», los dos escudos con el marcador gigante,
## las barras de las estadísticas reales, los goleadores con su minuto, la figura del partido con su retrato 3D y su nota (todo eso es `ResumenPartidoCine`, común con
## el descanso), la línea de tiempo de 0' a 90' con los goles y los botones CONTINUAR, REPETICIÓN DE LOS GOLES y JUGAR MOMENTOS. Lee el `Partido` ya jugado; no cambia nada del mundo. Emite `elegido("0")` al continuar.

const VERDE := Color("2fa866")
const AMARILLO := Color("e2b84a")
const ROJO := Color("e5484d")
const CLARO := Color("d6dcf0")
const LOCAL := Color("c8102e")

var partido: Partido
var mi_club: Club

static func mostrar(pr: Node, p: Partido, club: Club) -> ResultadoPartido:
	var r := ResultadoPartido.new()
	r.partido = p
	r.mi_club = club
	r._armar(pr)
	MandoMenuPartido.escuchar(r, r._seguir)
	r.visible = false   ## (17-11) entra bajo el barrido de color (`BarridoPartido`): nunca un corte seco
	BarridoPartido.pasar(pr, BarridoPartido.colores_de(p), func() -> void:
		if is_instance_valid(r):
			r.visible = true
			ResumenPartidoCine.enfocar(r._raiz))   ## R2 confirma; Cuadrado (y B / Esc, abajo) siguen: «Continuar»
	return r

## Nombre corto como en la maqueta: «J. Retamal».
static func abreviar(nombre: String) -> String:
	var n := Nombres.visible(nombre).strip_edges()
	var partes := n.split(" ", false)
	if partes.size() < 2:
		return n
	return "%s. %s" % [String(partes[0]).left(1).to_upper(), " ".join(partes.slice(1))]

static func _ancla(c: Control, l: float, t: float, r: float, b: float) -> Control:
	c.anchor_left = l; c.anchor_top = t; c.anchor_right = r; c.anchor_bottom = b
	c.offset_left = 0; c.offset_top = 0; c.offset_right = 0; c.offset_bottom = 0
	return c

func _armar(pr: Node) -> void:
	montar(pr, FondoCine.Modo.NOCHE, Color.BLACK)
	## (17-11, Auditoría) Lo visual es el componente común con el descanso (`ResumenPartidoCine`): marcador, goleadores, barras y figura del partido.
	ResumenPartidoCine.montar(_raiz, partido, mi_club, false)
	_linea_de_tiempo()
	var lista: Array = [["Continuar", _seguir, true]]
	if pr is Principal and DisplayServer.get_name() != "headless" and not MomentosPartido.lista_de(partido, mi_club).is_empty():
		if not partido.cronica.filter(func(e: Dictionary) -> bool: return String(e.get("tipo", "")) == "gol").is_empty():
			lista.append(["Repetición de los goles", _momentos.bind(pr, "goles"), false])
		lista.append(["Jugar momentos", _momentos.bind(pr, "todas"), false])
	if partido.has_meta("cronica_texto"):   ## (17-11, Auditoría) la crónica del partido ya no sale antes del resumen: se lee desde aquí
		lista.append(["Crónica", _ver_cronica.bind(pr), false])
	ResumenPartidoCine.botones(_raiz, lista)

## «Continuar»: sale con el barrido (lo que venga detrás se monta tapado).
func _seguir() -> void:
	BarridoPartido.pasar(_raiz, BarridoPartido.colores_de(partido), func() -> void: elegido.emit("0"))

## Los momentos del partido (filtrados) y, si eliges uno, la réplica desde un minuto antes (la misma lógica que el popup «Partido jugado»).
func _momentos(pr: Principal, filtro: String) -> void:
	var mo := MomentosPartido.mostrar(pr, partido, mi_club, filtro)
	var r: String = await mo.elegido
	var minuto := int(mo._lista[int(r.substr(8))]["min"]) if r.begins_with("momento:") else -1
	mo.queue_free()
	if minuto >= 0:
		load("res://ui/partido_menu/replica_partido.gd").abrir(pr, partido, minuto)

## El color del club para los balones: el de su camiseta, aclarado si es muy oscuro (sobre el fondo noche se tiene que ver).
static func _color_club(c: Club) -> Color:
	var col := Color(c.kit_color1 if c.kit_color1 != "" else c.color1)
	return col.lightened(0.45) if col.get_luminance() < 0.18 else col

func _linea_de_tiempo() -> void:
	var l := _Tiempo.new()
	l.goles = partido.cronica.filter(func(e: Dictionary) -> bool: return String(e.get("tipo", "")) in ["gol", "amarilla", "roja"])
	l.mi_id = mi_club.id
	l.local_id = partido.local.id
	l.col_local = _color_club(partido.local)
	l.col_visita = _color_club(partido.visita)
	ResumenPartidoCine.poner(_raiz, l, "linea")   ## bajo el marcador: los goles y las tarjetas en el tiempo

## La barra de dos colores de las estadísticas (local en rojo, visitante en claro).
class _Barra extends Control:
	var local := 0.5
	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, 0, w, h), Color("d6dcf0"))
		draw_rect(Rect2(0, 0, w * local, h), Color("c8102e"))

## La línea de 0' a 90': el balón de trazo en el minuto de cada gol, del color del club que marcó; los minutos, pequeños y discretos.
class _Tiempo extends Control:
	var goles: Array = []
	var mi_id := ""
	var local_id := ""
	var col_local := Color.WHITE
	var col_visita := Color.WHITE
	func _draw() -> void:
		var y := size.y * 0.35
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.22), 2.0)
		var f := EstiloAvanzar.fuente_titulo()
		for m in [0, 15, 30, 45, 60, 75, 90]:
			var x := size.x * float(m) / 90.0
			draw_string(f, Vector2(x - 6, y + 30), "%d'" % m, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.4))
		for e: Dictionary in goles:
			var x := size.x * clampf(float(e["min"]) / 90.0, 0.0, 1.0)
			var col := col_local if String(e.get("club", "")) == local_id else col_visita
			if String(e.get("tipo", "")) != "gol":   ## las tarjetas, pequeñas sobre la línea (debajo, el color de su club)
				draw_rect(Rect2(x - 4, y - 21, 8, 12), ResumenPartidoCine.ROJO_BARRA if String(e["tipo"]) == "roja" else Color("f2c94c"))
				draw_rect(Rect2(x - 4, y - 7, 8, 2), col)
				continue
			draw_circle(Vector2(x, y), 15.0, Color(1, 1, 1, 0.92))
			draw_texture_rect(EstiloAvanzar.icono("ball", col.darkened(0.25), 36, 2.2), Rect2(x - 13, y - 13, 26, 26), false)

func _unhandled_input(e: InputEvent) -> void:
	if visible and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_seguir()

## LA CRÓNICA DEL PARTIDO (la de `PartidoVivo`, minuto a minuto), a pantalla completa encima del resumen; «Volver», B o Cuadrado la cierran.
func _ver_cronica(pr: Node) -> void:
	var c := _Cronica.new()
	c.montar(pr, FondoCine.Modo.NOCHE, Color.BLACK)
	var z := TactilPartido.zona_segura(c._raiz)
	var titulo := EstiloAvanzar.etiqueta(Idiomas.t("Crónica del partido"), 30, Color.WHITE, true, true)
	z.add_child(_ancla(titulo, 0.05, 0.03, 0.95, 0.1))
	var texto := RichTextLabel.new()
	texto.text = String(partido.get_meta("cronica_texto", ""))
	texto.scroll_following = false
	texto.focus_mode = Control.FOCUS_ALL   ## con el foco, la cruceta la hace correr
	texto.add_theme_font_size_override("normal_font_size", 17)
	z.add_child(_ancla(texto, 0.05, 0.11, 0.95, 0.85))
	var b := PantallaMaqueta.boton(Idiomas.t("Volver"), true)
	b.pressed.connect(c.cerrar_cronica)
	z.add_child(_ancla(b, 0.75, 0.88, 0.95, 0.96))
	MandoMenuPartido.escuchar(c, c.cerrar_cronica)
	texto.grab_focus.call_deferred()

class _Cronica extends PantallaMaqueta:
	func cerrar_cronica() -> void:
		Sonido.toca("clic")
		queue_free()
	func _unhandled_input(e: InputEvent) -> void:
		if visible and e.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			cerrar_cronica()

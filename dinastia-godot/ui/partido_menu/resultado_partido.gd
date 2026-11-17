class_name ResultadoPartido
extends PantallaMaqueta
## EL RESULTADO DEL PARTIDO, COMO LA MAQUETA (17-11-2026): fondo noche con los dos haces rojos, «VICTORIA / EMPATE / DERROTA», los dos escudos con el marcador gigante,
## las barras de posesión, tiros y tiros a puerta, los goles con su minuto, el jugador del partido con su figura y su nota, la línea de tiempo de 0' a 90' con los goles
## marcados y el botón CONTINUAR. Lee el `Partido` ya jugado; no cambia nada del mundo. Emite `elegido("0")` al continuar.

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
	var mio_local := partido.local == mi_club
	var gm := partido.goles_local if mio_local else partido.goles_visita
	var gr := partido.goles_visita if mio_local else partido.goles_local
	var clave := "VICTORIA" if gm > gr else ("DERROTA" if gm < gr else "EMPATE")
	var col := VERDE if gm > gr else (ROJO if gm < gr else AMARILLO)
	var titulo := EstiloAvanzar.etiqueta(Idiomas.t(clave), 20, col, true, true)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_constant_override("outline_size", 0)
	_raiz.add_child(_ancla(titulo, 0.0, 0.04, 1.0, 0.10))
	_equipo(partido.local, 0.22, 0.38)
	_equipo(partido.visita, 0.62, 0.78)
	var marcador := EstiloAvanzar.etiqueta("%d - %d" % [partido.goles_local, partido.goles_visita], 150, EstiloAvanzar.TINTA, true)
	marcador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marcador.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_raiz.add_child(_ancla(marcador, 0.38, 0.10, 0.62, 0.36))
	_barras()
	_goles()
	_mejor()
	_linea_de_tiempo()
	var seguir := boton(Idiomas.t("Continuar"), true)
	seguir.custom_minimum_size = Vector2(240, 58)
	seguir.pressed.connect(func() -> void: elegido.emit("0"))
	seguir.anchor_left = 1.0; seguir.anchor_right = 1.0; seguir.anchor_top = 1.0; seguir.anchor_bottom = 1.0
	seguir.offset_left = -300; seguir.offset_right = -40; seguir.offset_top = -100; seguir.offset_bottom = -40
	_raiz.add_child(seguir)
	seguir.grab_focus.call_deferred()

func _equipo(c: Club, x0: float, x1: float) -> void:
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(c, 220)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_raiz.add_child(_ancla(esc, x0, 0.10, x1, 0.30))
	var n := EstiloAvanzar.etiqueta(c.nombre, 30, EstiloAvanzar.TINTA, true, true)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.clip_text = true
	_raiz.add_child(_ancla(n, x0 - 0.06, 0.31, x1 + 0.06, 0.38))

func _barras() -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	var pl := int(round(partido.posesion_local))
	var datos := [[pl, 100 - pl, "Posesión %"], [partido.remates_local, partido.remates_visita, "Tiros"], [partido.tiros_puerta_local, partido.tiros_puerta_visita, "Tiros a puerta"]]
	for d: Array in datos:
		var a := int(d[0])
		var b := int(d[1])
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 12)
		var na := EstiloAvanzar.etiqueta(str(a), 24, Color.WHITE, true)
		na.custom_minimum_size = Vector2(46, 0)
		na.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(na)
		var barra := _Barra.new()
		barra.local = float(a) / maxf(float(a + b), 1.0)
		barra.custom_minimum_size = Vector2(0, 12)
		barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(barra)
		fila.add_child(EstiloAvanzar.etiqueta(str(b), 24, Color.WHITE, true))
		caja.add_child(fila)
		var rot := EstiloAvanzar.etiqueta(Idiomas.t(String(d[2])), 13, EstiloAvanzar.SUAVE, false, true)
		rot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caja.add_child(rot)
	_raiz.add_child(_ancla(caja, 0.06, 0.45, 0.43, 0.80))

func _goles() -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	caja.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Goles"), 15, EstiloAvanzar.SUAVE, true, true))
	var hay := false
	for e: Dictionary in partido.cronica:
		if String(e.get("tipo", "")) != "gol":
			continue
		hay = true
		var club := partido.local if String(e.get("club", "")) == partido.local.id else partido.visita
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 10)
		f.add_child(EstiloAvanzar.etiqueta("%d'" % int(e["min"]), 18, EstiloAvanzar.SUAVE))
		var ic := TextureRect.new()
		ic.texture = EstiloAvanzar.icono("ball", Color.WHITE, 22)
		f.add_child(ic)
		f.add_child(EstiloAvanzar.etiqueta(abreviar(String(e.get("autor", "?"))), 20, Color.WHITE))
		f.add_child(EstiloAvanzar.etiqueta("(%s)" % _sigla(club), 16, EstiloAvanzar.SUAVE))
		caja.add_child(f)
	if not hay:
		caja.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Sin goles"), 18, EstiloAvanzar.SUAVE))
	_raiz.add_child(_ancla(caja, 0.47, 0.45, 0.72, 0.80))

static func _sigla(c: Club) -> String:
	var partes := c.nombre.split(" ", false)
	if partes.size() >= 2:
		var s := ""
		for p in partes:
			s += String(p).left(1).to_upper()
		return s.left(3)
	return c.nombre.left(3).to_upper()

func _mejor() -> void:
	var vals := partido.valoraciones()
	if vals.is_empty():
		return
	var mvp: Dictionary = vals[0]
	var j: Jugador = mvp["jugador"]
	var club := partido.local if bool(mvp["local"]) else partido.visita
	var c1 := Color(club.kit_color1 if club.kit_color1 != "" else club.color1)
	var c2 := Color(club.kit_color2 if club.kit_color2 != "" else club.color2)
	var fig := TextureRect.new()
	fig.texture = EstiloAvanzar.figura(c1, c2)
	fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_raiz.add_child(_ancla(fig, 0.73, 0.40, 0.83, 0.82))
	var num := EstiloAvanzar.etiqueta(str(j.dorsal) if j.dorsal > 0 else "", 30, Color.WHITE, true)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_raiz.add_child(_ancla(num, 0.73, 0.645, 0.83, 0.70))
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 0)
	t.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Jugador del partido"), 12, EstiloAvanzar.SUAVE, false, true))
	t.add_child(EstiloAvanzar.etiqueta(abreviar(j.nombre), 34, Color.WHITE, true, true))
	t.add_child(EstiloAvanzar.etiqueta(("%.1f" % float(mvp["nota"])).replace(".", ","), 40, AMARILLO, true))
	_raiz.add_child(_ancla(t, 0.835, 0.55, 0.99, 0.82))

func _linea_de_tiempo() -> void:
	var l := _Tiempo.new()
	l.goles = partido.cronica.filter(func(e: Dictionary) -> bool: return String(e.get("tipo", "")) == "gol")
	l.mi_id = mi_club.id
	_raiz.add_child(_ancla(l, 0.04, 0.83, 0.78, 0.97))

## La barra de dos colores de las estadísticas (local en rojo, visitante en claro).
class _Barra extends Control:
	var local := 0.5
	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, 0, w, h), Color("d6dcf0"))
		draw_rect(Rect2(0, 0, w * local, h), Color("c8102e"))

## La línea de 0' a 90' con los goles (rojo los tuyos, claro los rivales).
class _Tiempo extends Control:
	var goles: Array = []
	var mi_id := ""
	func _draw() -> void:
		var y := size.y * 0.35
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.25), 3.0)
		var f := ThemeDB.fallback_font
		for m in [0, 15, 30, 45, 60, 75, 90]:
			var x := size.x * float(m) / 90.0
			draw_string(f, Vector2(x - 8, y + 34), "%d'" % m, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.5))
		for e: Dictionary in goles:
			var x := size.x * clampf(float(e["min"]) / 90.0, 0.0, 1.0)
			var mio := String(e.get("club", "")) == mi_id
			draw_circle(Vector2(x, y), 11.0, Color("c8102e") if mio else Color("d6dcf0"))
			draw_circle(Vector2(x, y), 5.0, Color.WHITE)

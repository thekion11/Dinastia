class_name CarreraJugadorUI
extends Control
## LA CARRERA DE JUGADOR, SU PANTALLA (29-9-2026). Estética propia del modo:
## negro, lima eléctrico y fucsia, con paneles en ángulo, como un videojuego de
## fútbol y no como el despacho del entrenador. Dos estados:
##   - CREAR: nombre, puesto y pie. Empiezas con 17 años en un club de segunda.
##   - LA SEMANA: tu carta (media, atributos, fama, relación con el DT,
##     energía), el próximo partido -jugarlo tú en el `MotorJugable` o
##     simularlo-, el foco de entrenamiento, los eventos con sus decisiones, las
##     ofertas y tu temporada.

const GUARDADO := "carrera_jugador"
const LIMA := Color("c6ff3a")
const FUCSIA := Color("ff2e88")
const CIAN := Color("35e0ff")
const TEXTO := Color(0.93, 0.95, 0.97)
const SUAVE := Color(0.62, 0.66, 0.72)

static var mundo: Mundo
static var nombre_pedido := ""

var carrera: CarreraJugador
var _cuerpo: Control
var _msg := ""
var _puesto := "DC"
var _zurdo := false
var _campo_nombre: LineEdit

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://ui/fondo_menu.gdshader")
	mat.set_shader_parameter("estilo", 3)
	mat.set_shader_parameter("c1", Color("050608"))
	mat.set_shader_parameter("c2", Color("0e1218"))
	mat.set_shader_parameter("c3", LIMA)
	mat.set_shader_parameter("aspecto", Vector2(1.78, 1.0))
	fondo.material = mat
	add_child(fondo)
	_cuerpo = Control.new()
	_cuerpo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_cuerpo)
	if mundo != null and mundo.carrera_jugador != null:
		carrera = mundo.carrera_jugador
		_pintar_semana()
	else:
		_pintar_crear()

# ---------------------------------------------------------------- estilo

func _st(borde: Color, fondo := Color(0.03, 0.035, 0.045, 0.9)) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fondo
	st.border_color = borde
	st.border_width_left = 4
	st.border_width_top = 1
	st.set_corner_radius_all(2)
	st.content_margin_left = 16; st.content_margin_right = 16
	st.content_margin_top = 12; st.content_margin_bottom = 12
	return st

func _lbl(tam: int, col: Color, texto := "") -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	## Solo los textos largos se parten: con las cortas (la media, el puesto,
	## el nombre de un club) el ajuste las dejaba letra por letra en vertical.
	if texto.length() > 40:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _boton(texto: String, col: Color, accion: Callable, alto := 44) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, alto)
	b.add_theme_font_size_override("font_size", 15)
	var n := _st(col, Color(0, 0, 0, 0.55))
	n.content_margin_top = 6; n.content_margin_bottom = 6
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(col, 0.28)
	var pr := n.duplicate() as StyleBoxFlat
	pr.bg_color = col
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("focus", h)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_color_override("font_color", TEXTO)
	b.add_theme_color_override("font_pressed_color", Color.BLACK)
	b.pressed.connect(accion)
	return b

func _panel(borde: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _st(borde))
	return p

func _limpiar() -> void:
	for n in _cuerpo.get_children():
		_cuerpo.remove_child(n)
		n.queue_free()

# ---------------------------------------------------------------- crear

func _pintar_crear() -> void:
	_limpiar()
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cuerpo.add_child(centro)
	var caja := _panel(LIMA)
	caja.custom_minimum_size = Vector2(760, 0)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	caja.add_child(v)
	v.add_child(_lbl(40, LIMA, "CARRERA DE JUGADOR"))
	v.add_child(_lbl(15, SUAVE, "Tienes 17 años y un contrato en un club de segunda. Los partidos los juegas tú: el balón, los pases, los tiros, los córners y los penales. Lo demás -la prensa, el DT, las ofertas, la selección- depende de lo que hagas y de lo que decidas."))
	v.add_child(_lbl(13, FUCSIA, "TU NOMBRE"))
	_campo_nombre = LineEdit.new()
	_campo_nombre.text = nombre_pedido if nombre_pedido != "" else "Tomás Aravena"
	_campo_nombre.custom_minimum_size = Vector2(0, 40)
	_campo_nombre.add_theme_font_size_override("font_size", 18)
	v.add_child(_campo_nombre)
	v.add_child(_lbl(13, FUCSIA, "TU PUESTO"))
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 6)
	fila.add_theme_constant_override("v_separation", 6)
	v.add_child(fila)
	var posd: Dictionary = Datos.tabla("POSD")
	var grupo := ButtonGroup.new()
	for pe: String in CarreraJugador.PUESTOS:
		var nombre := String((posd.get(pe, {}) as Dictionary).get("n", pe))
		var b := _boton("%s  %s" % [pe, nombre], CIAN, func() -> void: _puesto = pe, 38)
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = pe == _puesto
		fila.add_child(b)
	v.add_child(_lbl(13, FUCSIA, "TU PIE"))
	var fila_pie := HBoxContainer.new()
	fila_pie.add_theme_constant_override("separation", 6)
	v.add_child(fila_pie)
	var gp := ButtonGroup.new()
	for par: Array in [["🦶 Diestro", false], ["🦶 Zurdo", true]]:
		var zurdo: bool = par[1]
		var b2 := _boton(String(par[0]), CIAN, func() -> void: _zurdo = zurdo, 38)
		b2.toggle_mode = true
		b2.button_group = gp
		b2.button_pressed = zurdo == _zurdo
		fila_pie.add_child(b2)
	v.add_child(_boton("⚽  EMPEZAR MI CARRERA", LIMA, _crear, 54))
	var guardada := Partida.cargar(GUARDADO) if _hay_guardada() else null
	if guardada != null and guardada.carrera_jugador != null:
		var j := guardada.carrera_jugador.jugador(guardada)
		v.add_child(_boton("▶  Continuar la carrera de %s" % (j.nombre if j != null else "tu jugador"), FUCSIA, func() -> void:
			mundo = guardada
			carrera = mundo.carrera_jugador
			_pintar_semana(), 46))
	v.add_child(_boton("◂  Volver al menú", SUAVE, _salir, 38))
	Idiomas.traducir_arbol(_cuerpo)

func _hay_guardada() -> bool:
	for d: Dictionary in Partida.listar():
		if String(d.get("nombre", "")) == GUARDADO:
			return true
	return false

func _crear() -> void:
	var nombre := _campo_nombre.text.strip_edges()
	if nombre == "":
		nombre = "Tomás Aravena"
	var m := Mundo.new()
	Escudo.limpiar_cache()
	Cara.limpiar_cache()
	m.generar([], 0)
	m.mi_club_id = ""
	m.carrera_jugador = CarreraJugador.crear(m, nombre, _puesto, _zurdo, int(Time.get_unix_time_from_system()))
	mundo = m
	carrera = m.carrera_jugador
	_msg = "Firmaste con %s. Dorsal %d." % [carrera.club(m).nombre, carrera.jugador(m).dorsal]
	_pintar_semana()

func _salir() -> void:
	get_tree().change_scene_to_file("res://escenas/inicio.tscn")

# ---------------------------------------------------------------- la semana

func _pintar_semana() -> void:
	_limpiar()
	var m := mundo
	var c := carrera
	var j := c.jugador(m)
	var club := c.club(m)
	if j == null or club == null:
		_pintar_crear()
		return
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 22; raiz.offset_right = -22; raiz.offset_top = 16; raiz.offset_bottom = -16
	raiz.add_theme_constant_override("separation", 12)
	_cuerpo.add_child(raiz)
	## Cabecera.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 14)
	raiz.add_child(cab)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(club, 52)
	esc.custom_minimum_size = Vector2(52, 52)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab.add_child(esc)
	var tit := VBoxContainer.new()
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(tit)
	tit.add_child(_lbl(30, LIMA, j.nombre.to_upper()))
	tit.add_child(_lbl(14, SUAVE, "%s  ·  %s  ·  %d años  ·  temporada %d, semana %d" % [Nombres.visible(club.nombre), j.pos_e, j.edad, m.anio, m.semana]))
	cab.add_child(_boton("💾 Guardar", CIAN, _guardar, 40))
	cab.add_child(_boton("🏠 Menú", SUAVE, _salir, 40))
	if _msg != "":
		var aviso := _lbl(15, FUCSIA, _msg)
		raiz.add_child(aviso)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	raiz.add_child(cols)
	cols.add_child(_carta(j))
	## Con la convocatoria la columna crece: se desplaza en vez de cortarse.
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(sc)
	var centro := _centro(j, club)
	centro.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sc.add_child(centro)
	cols.add_child(_derecha(j))
	Idiomas.traducir_arbol(_cuerpo)

## LA CARTA DEL JUGADOR: la media en grande, su cara y sus números.
func _carta(j: Jugador) -> Control:
	var p := _panel(LIMA)
	p.custom_minimum_size = Vector2(330, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var fila := HBoxContainer.new()
	v.add_child(fila)
	var media := VBoxContainer.new()
	fila.add_child(media)
	media.add_child(_lbl(64, LIMA, str(j.ovr)))
	media.add_child(_lbl(18, TEXTO, j.pos_e))
	var cara := TextureRect.new()
	var club := carrera.club(mundo)
	cara.texture = Cara.textura(j, club.color1, club.color2, 150)
	cara.custom_minimum_size = Vector2(150, 150)
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cara.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(cara)
	v.add_child(_lbl(12, SUAVE, "Potencial %d  ·  %s  ·  contrato %d año(s)  ·  %s/sem" % [j.pot, "zurdo" if String(j.look.get("pie", "")) == "zurdo" else "diestro", j.anios_contrato, Eco.dinero(j.sueldo)]))
	var nombres := {"rit": "Velocidad", "tir": "Tiro", "pas": "Pase", "reg": "Regate", "def": "Defensa", "fis": "Físico"}
	for k: String in ["rit", "tir", "pas", "reg", "def", "fis"]:
		v.add_child(_barra(String(nombres[k]), int(j.atributos.get(k, 50)), 99, CIAN))
	v.add_child(HSeparator.new())
	v.add_child(_barra("⚡ Energía", carrera.energia, 100, LIMA))
	v.add_child(_barra("🤝 Relación con el DT", carrera.relacion_dt, 100, FUCSIA))
	v.add_child(_barra("⭐ Fama", carrera.fama, 100, Color("ffd24a")))
	v.add_child(_lbl(13, TEXTO, "📱 %s seguidores  ·  %s" % [_miles(carrera.seguidores), carrera.agente if carrera.agente != "" else "sin agente"]))
	return p

func _barra(nombre: String, valor: int, maximo: int, col: Color) -> Control:
	var h := HBoxContainer.new()
	var l := _lbl(13, TEXTO, nombre)
	l.custom_minimum_size = Vector2(150, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	var b := ProgressBar.new()
	b.max_value = maximo
	b.value = valor
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 10)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var f := StyleBoxFlat.new()
	f.bg_color = Color(1, 1, 1, 0.1)
	var ll := StyleBoxFlat.new()
	ll.bg_color = col
	b.add_theme_stylebox_override("background", f)
	b.add_theme_stylebox_override("fill", ll)
	h.add_child(b)
	var n := _lbl(13, col, str(valor))
	n.custom_minimum_size = Vector2(34, 0)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(n)
	return h

func _miles(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

## EL CENTRO: el partido de la semana y el entrenamiento.
func _centro(j: Jugador, club: Club) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	## LA SELECCIÓN (MEGAPLAN fase 3): en fecha FIFA, si te convocan.
	if not carrera.convocatoria.is_empty():
		var ps := _panel(Color("ffd24a"))
		v.add_child(ps)
		var sv := VBoxContainer.new()
		sv.add_theme_constant_override("separation", 8)
		ps.add_child(sv)
		sv.add_child(_lbl(13, Color("ffd24a"), "🌎 FECHA FIFA · ¡CONVOCADO!"))
		sv.add_child(_lbl(20, TEXTO, "%s  vs  %s" % [String(carrera.convocatoria["nombre"]), String(carrera.convocatoria["rival"])]))
		sv.add_child(_lbl(13, SUAVE, "Partidos con la selección: %d  ·  goles: %d" % [carrera.caps, carrera.goles_sel]))
		var fs := HBoxContainer.new()
		fs.add_theme_constant_override("separation", 8)
		sv.add_child(fs)
		var bjs := _boton("🎮  JUGAR CON LA SELECCIÓN", Color("ffd24a"), _jugar_seleccion, 50)
		bjs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fs.add_child(bjs)
		var bss := _boton("⏩  Simular", CIAN, _simular_seleccion, 50)
		bss.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fs.add_child(bss)
	var p := _panel(FUCSIA)
	v.add_child(p)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 8)
	p.add_child(pv)
	pv.add_child(_lbl(13, FUCSIA, "PRÓXIMO PARTIDO"))
	if not mundo.temporada_en_curso():
		pv.add_child(_lbl(20, TEXTO, "La temporada terminó."))
		if carrera.toca_retirarse(mundo):
			pv.add_child(_boton("👟  Colgar las botas", LIMA, _pintar_retiro, 50))
		else:
			pv.add_child(_boton("🗓  Empezar la temporada siguiente", LIMA, _nueva_temporada, 50))
	else:
		var par := _partido_de_la_semana(club)
		if par.is_empty():
			pv.add_child(_lbl(20, TEXTO, "Tu club descansa esta jornada."))
		else:
			var rival: Club = par[1] if par[0] == club else par[0]
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 12)
			pv.add_child(fila)
			for cl: Club in [par[0], par[1]]:
				var e := TextureRect.new()
				e.texture = Escudo.textura(cl, 44)
				e.custom_minimum_size = Vector2(44, 44)
				e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				e.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				fila.add_child(e)
				fila.add_child(_lbl(20, TEXTO, Nombres.visible(cl.nombre)))
				if cl == par[0]:
					fila.add_child(_lbl(20, LIMA, "vs"))
			var titular := carrera.es_titular(mundo)
			pv.add_child(_lbl(15, LIMA if titular else SUAVE, ("✅ El DT te pone de titular." if titular else "🪑 Esta semana empiezas en el banco.") + ("  (en casa)" if par[0] == club else "  (de visita, contra %s)" % Nombres.visible(rival.nombre))))
		var botones := HBoxContainer.new()
		botones.add_theme_constant_override("separation", 8)
		pv.add_child(botones)
		if not par.is_empty() and carrera.es_titular(mundo):
			var bj := _boton("🎮  JUGAR EL PARTIDO", LIMA, _jugar_partido, 56)
			bj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			botones.add_child(bj)
		elif not par.is_empty() and carrera.jugador(mundo) != null and carrera.jugador(mundo).disponible():
			## DESDE EL BANCO (MEGAPLAN fase 3): vas convocado y quizá entras.
			var bb := _boton("🪑  IR AL BANCO (puedes entrar)", LIMA, _ir_al_banco, 56)
			bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			botones.add_child(bb)
		var bs := _boton("⏩  Simular la semana", CIAN, func() -> void: _cerrar_semana({}), 56)
		bs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botones.add_child(bs)
	## El entrenamiento.
	var pe := _panel(CIAN)
	v.add_child(pe)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 6)
	pe.add_child(ev)
	ev.add_child(_lbl(13, CIAN, "ENTRENAMIENTO DE LA SEMANA"))
	var fila_f := HFlowContainer.new()
	fila_f.add_theme_constant_override("h_separation", 6)
	fila_f.add_theme_constant_override("v_separation", 6)
	ev.add_child(fila_f)
	var grupo := ButtonGroup.new()
	for f: String in CarreraJugador.FOCOS:
		var bf := _boton(String(CarreraJugador.FOCOS[f][0]), CIAN, func() -> void: carrera.foco = f, 36)
		bf.toggle_mode = true
		bf.button_group = grupo
		bf.button_pressed = carrera.foco == f
		fila_f.add_child(bf)
	## La temporada.
	var pt := _panel(Color("ffd24a"))
	v.add_child(pt)
	var tv := VBoxContainer.new()
	pt.add_child(tv)
	tv.add_child(_lbl(13, Color("ffd24a"), "TU TEMPORADA"))
	var s := carrera.stats_temp
	tv.add_child(_lbl(18, TEXTO, "%d partidos (%d de titular)  ·  %d goles  ·  %d asistencias  ·  nota %.2f" % [s["pj"], s["titular"], s["goles"], s["asist"], carrera.nota_media()]))
	for t: Dictionary in carrera.temporadas:
		tv.add_child(_lbl(12, SUAVE, "%d · %s · %d PJ · %d goles · %d asist · nota %.2f" % [int(t["anio"]), String(t["club"]), int(t["pj"]), int(t["goles"]), int(t["asist"]), float(t["nota"])]))
	return v

## LA DERECHA: los eventos con sus decisiones y las ofertas.
func _derecha(_j: Jugador) -> Control:
	var p := _panel(FUCSIA)
	p.custom_minimum_size = Vector2(400, 0)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)
	v.add_child(_lbl(13, FUCSIA, "LO QUE TE PASA  (%d)" % carrera.eventos.size()))
	if carrera.eventos.is_empty():
		v.add_child(_lbl(14, SUAVE, "Nada pendiente. Entrena y juega."))
	for i in carrera.eventos.size():
		var e: Dictionary = carrera.eventos[i]
		var caja := _panel(LIMA)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		caja.add_child(cv)
		cv.add_child(_lbl(17, LIMA, String(e["titulo"])))
		cv.add_child(_lbl(13, TEXTO, String(e["texto"])))
		var ops: Array = e["opciones"]
		for k in ops.size():
			var idx := i
			var op := k
			cv.add_child(_boton(String(ops[k]["texto"]), CIAN, func() -> void:
				_msg = "Decidiste: " + carrera.resolver(mundo, idx, op)
				_pintar_semana(), 38))
		v.add_child(caja)
	if not carrera.ofertas.is_empty():
		v.add_child(_lbl(13, Color("ffd24a"), "OFERTAS"))
		for i in carrera.ofertas.size():
			var o: Dictionary = carrera.ofertas[i]
			var cl: Club = mundo.clubes.get(String(o["club_id"]))
			if cl == null:
				continue
			var k := i
			v.add_child(_boton("✈  %s te quiere · %s/sem · %d sem para decidir" % [Nombres.visible(cl.nombre), Eco.dinero(int(o["sueldo"])), int(o["semanas"])], Color("ffd24a"), func() -> void:
				if carrera.aceptar_oferta(mundo, k):
					_msg = "¡Fichaste por %s!" % carrera.club(mundo).nombre
				_pintar_semana(), 44))
	if not carrera.historial.is_empty():
		v.add_child(_lbl(13, SUAVE, "TUS DECISIONES"))
		for h: Dictionary in carrera.historial.slice(maxi(0, carrera.historial.size() - 6)):
			v.add_child(_lbl(12, SUAVE, "%d/%d · %s → %s" % [int(h["anio"]), int(h["semana"]), String(h["titulo"]), String(h["eleccion"])]))
	return p

# ---------------------------------------------------------------- jugar

func _partido_de_la_semana(club: Club) -> Array:
	return CarreraJugador.partido_de_la_semana(mundo, club)

func _jugar_partido() -> void:
	var club := carrera.club(mundo)
	var par := _partido_de_la_semana(club)
	if par.is_empty():
		return
	_msg = carrera.entrenar(mundo)
	var pj := PartidoJugable.abrir(self, mundo, carrera, par[0], par[1], 240.0)
	pj.terminado.connect(func(res: Dictionary) -> void: _cerrar_semana(res, true))

## Suplente: el DT decide si entras y cuándo. Si entras, juegas desde ese
## minuto; si no, la semana se cierra con el partido visto desde el banco.
func _ir_al_banco() -> void:
	var club := carrera.club(mundo)
	var par := _partido_de_la_semana(club)
	if par.is_empty():
		return
	_msg = carrera.entrenar(mundo)
	var minuto := carrera.minuto_entrada_suplente()
	if minuto < 0:
		_msg += "  ·  Calentaste toda la segunda parte, pero el DT no te hizo entrar."
		_cerrar_semana({"sin_minutos": true}, true)
		return
	var pj := PartidoJugable.abrir(self, mundo, carrera, par[0], par[1], 240.0, minuto)
	pj.terminado.connect(func(res: Dictionary) -> void: _cerrar_semana(res, true))

## Cierra la semana: el partido (jugado o simulado), el mundo y lo que te pasa.
func _cerrar_semana(res: Dictionary, ya_entrenado := false) -> void:
	var m := mundo
	var j := carrera.jugador(m)
	var club := carrera.club(m)
	var par := _partido_de_la_semana(club)
	if not ya_entrenado:
		_msg = carrera.entrenar(m)
	var titular := carrera.es_titular(m)
	if bool(res.get("sin_minutos", false)):
		res = {}
	if not res.is_empty() and not par.is_empty():
		var p := Partido.new(par[0], par[1])
		p.goles_local = int(res["goles_local"])
		p.goles_visita = int(res["goles_visita"])
		m.avanzar_semana(p)
		carrera.tras_partido(m, res)
		carrera.partidos_jugables += 1
		_msg += "  ·  Final %d-%d, tu nota %.1f (%d')." % [p.goles_local, p.goles_visita, float(res["nota"]), int(res.get("minutos", 90))]
		if bool(res.get("sustituido", false)):
			_msg += " El DT te cambió."
	else:
		var goles_antes := j.goles if j != null else 0
		m.avanzar_semana()
		if titular and not par.is_empty() and j != null:
			var g := j.goles - goles_antes
			## La nota del simulado: la de tu nivel, más lo que marcaste.
			var nota := clampf(5.6 + float(j.ovr - 55) * 0.04 + float(g) * 0.9 + randf_range(-0.6, 0.6), 4.0, 9.5)
			j.goles = goles_antes
			carrera.tras_partido(m, {"minutos": 90, "goles": g, "asist": 0, "nota": snappedf(nota, 0.1), "titular": true})
			_msg += "  ·  Jugaste (simulado): %d gol(es), nota %.1f." % [g, nota]
		elif not titular and not par.is_empty() and j != null and j.disponible():
			## Suplente simulado: a veces entras un rato.
			var entra := carrera.minuto_entrada_suplente()
			if entra >= 0:
				var minutos := 90 - entra
				var g2 := 1 if randf() < float(minutos) / 90.0 * (0.25 if j.pos == "DEL" else 0.08) else 0
				var nota2 := clampf(5.8 + float(j.ovr - 55) * 0.03 + float(g2) * 0.9 + randf_range(-0.4, 0.4), 4.5, 9.0)
				carrera.tras_partido(m, {"minutos": minutos, "goles": g2, "asist": 0, "nota": snappedf(nota2, 0.1), "titular": false})
				_msg += "  ·  Entraste en el %d' (simulado): nota %.1f." % [entra, nota2]
			else:
				_msg += "  ·  No saliste del banco."
	var nuevos := carrera.semana(m)
	if not nuevos.is_empty():
		_msg += "  ·  ¡%s!" % String(nuevos[0]["titulo"])
	if not m.temporada_en_curso():
		carrera.fin_de_temporada(m)
		_msg += "  ·  Terminó la temporada."
	Partida.guardar(m, GUARDADO)
	_pintar_semana()

## El partido con la selección: clubes de paso, tú del lado de tu país.
func _jugar_seleccion() -> void:
	var eq := carrera.equipos_seleccion(mundo)
	if eq.size() < 2:
		return
	var pj := PartidoJugable.abrir(self, mundo, carrera, eq[0], eq[1], 240.0, -1, eq[0])
	pj.terminado.connect(func(res: Dictionary) -> void: _cerrar_seleccion(res))

func _simular_seleccion() -> void:
	var j := carrera.jugador(mundo)
	var g := 1 if j != null and randf() < (0.35 if j.pos == "DEL" else 0.12) else 0
	_cerrar_seleccion({"goles": g, "goles_local": g + randi_range(0, 2), "goles_visita": randi_range(0, 2), "nota": 6.5 + g})

func _cerrar_seleccion(res: Dictionary) -> void:
	var nombre := String(carrera.convocatoria.get("nombre", "tu selección"))
	var rival := String(carrera.convocatoria.get("rival", ""))
	carrera.tras_seleccion(res)
	if mundo.selecciones != null:
		mundo.selecciones._anotar_resultado("%s %d - %d %s" % [nombre, int(res.get("goles_local", 0)), int(res.get("goles_visita", 0)), rival])
	_msg = "🌎 %s %d - %d %s · tu nota %.1f%s" % [nombre, int(res.get("goles_local", 0)), int(res.get("goles_visita", 0)), rival,
		float(res.get("nota", 6.0)), (" · ¡%d gol(es) con la selección!" % int(res["goles"])) if int(res.get("goles", 0)) > 0 else ""]
	Partida.guardar(mundo, GUARDADO)
	_pintar_semana()

## EL RETIRO (MEGAPLAN fase 3): tu carrera en una página y, si quieres, el
## banquillo. Una vida entera en una partida: dirigirás en el mismo mundo.
func _pintar_retiro() -> void:
	_limpiar()
	var j := carrera.jugador(mundo)
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 60; raiz.offset_right = -60; raiz.offset_top = 40; raiz.offset_bottom = -40
	raiz.add_theme_constant_override("separation", 14)
	_cuerpo.add_child(raiz)
	raiz.add_child(_lbl(40, LIMA, "👟 %s CUELGA LAS BOTAS" % (j.nombre.to_upper() if j != null else "")))
	var temp := 0
	for t: Dictionary in carrera.temporadas:
		temp += 1
	raiz.add_child(_lbl(18, TEXTO, "%d temporadas · %d partidos · %d goles · %d partidos con la selección (%d goles)" % [
		temp, carrera.pj_carrera, carrera.goles_carrera, carrera.caps, carrera.goles_sel]))
	var clubes: Array = carrera.clubes_pasados.duplicate()
	var actual := carrera.club(mundo)
	if actual != null and not clubes.has(actual.nombre):
		clubes.append(actual.nombre)
	raiz.add_child(_lbl(15, SUAVE, "Clubes: %s%s" % [", ".join(clubes.map(func(x: Variant) -> String: return Nombres.visible(String(x)))),
		"  ·  fuiste capitán" if carrera.capitan else ""]))
	var p := _panel(FUCSIA)
	raiz.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(_lbl(15, FUCSIA, "TE OFRECEN EL BANQUILLO" + ("" if carrera.licencia else "  (harás el curso acelerado de la licencia)")))
	v.add_child(_lbl(13, SUAVE, "Dirigirás en este mismo mundo, con tu carrera de jugador como currículum. Se abre como tu partida de entrenador (la que tuvieras se guarda como respaldo)."))
	var ofertas := carrera.ofertas_de_banquillo(mundo)
	if ofertas.is_empty():
		v.add_child(_lbl(15, TEXTO, "Ningún club te ofrece el banquillo por ahora."))
	for c: Club in ofertas:
		var b := _boton("📋  Dirigir a %s (reputación %d)" % [Nombres.visible(c.nombre), c.rep], LIMA, func() -> void: _ser_entrenador(c), 46)
		v.add_child(b)
	raiz.add_child(_boton("🏠  Retirarme del fútbol (volver al menú)", SUAVE, _retiro_final, 44))
	Idiomas.traducir_arbol(_cuerpo)

func _ser_entrenador(c: Club) -> void:
	## Respaldo de la partida de entrenador que hubiera.
	var previa := Partida.cargar("partida")
	if previa != null:
		Partida.guardar(previa, "partida_respaldo")
	if not carrera.pasar_a_entrenador(mundo, c):
		return
	Partida.guardar(mundo, GUARDADO)
	Partida.guardar(mundo, "partida")
	Principal.mundo_a_cargar = mundo
	get_tree().change_scene_to_file("res://escenas/principal.tscn")

func _retiro_final() -> void:
	carrera.retirado = true
	Partida.guardar(mundo, GUARDADO)
	_salir()

func _nueva_temporada() -> void:
	mundo.nueva_temporada()
	_msg = "Nueva temporada. Un año más."
	Partida.guardar(mundo, GUARDADO)
	_pintar_semana()

func _guardar() -> void:
	_msg = "Carrera guardada." if Partida.guardar(mundo, GUARDADO) else "No se pudo guardar."
	_pintar_semana()

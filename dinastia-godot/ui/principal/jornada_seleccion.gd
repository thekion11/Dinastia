class_name JornadaSeleccion
extends RefCounted
## LA SELECCIÓN QUE DIRIGES, EN LA INTERFAZ (10-11, encargo del dueño, punto 2). Lo disparan los eventos de la semana (`JornadaEventos`) y el fin
## de temporada (`JornadaDespedida`), nunca un menú suelto. Sin pantalla (banco) no se muestra: el núcleo (`CargoSeleccion`) se prueba aparte.
## - `ofrecer_cargo`: si una federación te llama, la oferta a pantalla completa (`EventoSeleccion.oferta`) → aceptar o rechazar.
## - `jugar_torneos`: al acabar la liga, si tu selección juega este año el Mundial o su continental, cada partido suyo se JUEGA en directo o se
##   SIMULA (o el resto del torneo de una vez); los demás partidos de la fecha se simulan. Lo que quede lo cierra `Selecciones.cierre_de_temporada`.
static var _abierto := false

static func ofrecer_cargo(pr: Principal) -> bool:
	if _abierto or DisplayServer.get_name() == "headless" or pr.mundo == null or pr.mundo.selecciones == null:
		return false
	var cargo := pr.mundo.selecciones.cargo
	if cargo.oferta.is_empty() or cargo.oferta.has("vista"):
		return false
	cargo.oferta["vista"] = true   ## una vez (si no contestas, sigue en Club › Legado)
	_abierto = true
	var n := String(cargo.oferta["nombre"])
	var sel := SeleccionEquipo.club_de(pr.mundo, n, int(cargo.oferta["fuerza"]), pr.mundo.anio)
	var ev := EventoSeleccion.oferta(pr, sel, int(cargo.oferta["fuerza"]), int(cargo.oferta.get("sueldo", 0)))
	ev.tree_exiting.connect(func() -> void:   ## (10-11, caza de fallos) liberada sin contestar: no bloquear las ofertas para siempre
		_abierto = false)
	var op: String = await ev.elegido
	ev.queue_free()
	_abierto = false
	var msg := cargo.responder(pr.mundo, op == "si")
	Aviso.mostrar(pr, "vida", "🌍", Idiomas.t("Selección"), Idiomas.t(msg))
	pr._refrescar()
	return true

## (10-11) El partido de la fecha FIFA de tu selección, si toca esta semana: jugarlo en directo o simularlo.
static func ofrecer_fecha(pr: Principal) -> bool:
	if _abierto or DisplayServer.get_name() == "headless" or pr.mundo == null or pr.mundo.selecciones == null:
		return false
	var s := pr.mundo.selecciones
	var cargo := s.cargo
	if cargo.fecha_pendiente.is_empty() or cargo.fecha_pendiente.has("vista"):
		return false
	cargo.fecha_pendiente["vista"] = true
	_abierto = true
	var eq := FechaSeleccion.equipos(pr.mundo, s, cargo)
	var ev := EventoSeleccion.fecha(pr, String(cargo.fecha_pendiente["tipo"]), eq[0], eq[1], eq[2])
	ev.tree_exiting.connect(func() -> void: _abierto = false)
	var op: String = await ev.elegido
	ev.queue_free()
	var linea := ""
	if op == "jugar":
		var p := Partido.new(eq[0], eq[1], false)
		await _en_directo(pr, p, eq[2], false)
		linea = FechaSeleccion.cerrar(pr.mundo, cargo, p)
	else:
		linea = FechaSeleccion.simular(pr.mundo, s, cargo)
	_abierto = false
	Aviso.mostrar(pr, "vida", "🌍", Idiomas.t("Fecha FIFA"), linea)
	pr._refrescar()
	return true

static func jugar_torneos(pr: Principal) -> void:
	if DisplayServer.get_name() == "headless" or pr.mundo == null or pr.mundo.selecciones == null:
		return
	var s := pr.mundo.selecciones
	if not s.cargo.activo():
		return
	for t: TorneoSelecciones in s.cargo.torneos_del_anio(pr.mundo, s, pr.mundo.anio):
		await _jugar_torneo(pr, t, s.cargo.mi_equipo(t))
	## (10-11) La FINALISSIMA, si tu selección es campeona de Europa o de América: también se juega en directo (o simulada).
	var fin := Finalissima.preparar(s, pr.mundo, pr.mundo.anio)
	if fin != null and s.cargo.mi_equipo(fin) != null:
		await _jugar_torneo(pr, fin, s.cargo.mi_equipo(fin))
		fin.jugar_entero()
		Finalissima.registrar(s, pr.mundo, fin)

static func _jugar_torneo(pr: Principal, t: TorneoSelecciones, mia: Club) -> void:
	var guard := 0
	while t.en_curso() and guard < 40:
		guard += 1
		var par := t.partido_de(mia)
		if par.is_empty():
			if not t.en_grupos and not t.vivos.has(mia):
				break   ## eliminada: el resto lo cierra el cierre de temporada (simulado)
			t.jugar_fecha()   ## tu selección descansa esta fecha
			continue
		var rival: Club = par[1] if par[0] == mia else par[0]
		var ev := EventoSeleccion.partido(pr, t, mia, rival)
		var op: String = await ev.elegido
		ev.queue_free()
		if op == "resto":
			t.jugar_entero()
			break
		if op == "jugar":
			var p := Partido.new(par[0], par[1], true)
			await _en_directo(pr, p, mia, not t.en_grupos)
			t.jugar_fecha(p)
		else:
			t.jugar_fecha()
		_avisar_resultado(pr, t, mia)
	if not t.en_curso() and t.campeon != null:
		Aviso.mostrar(pr, "titulo", "🏆", t.nombre, "%s %s%s" % [Idiomas.t("Campeón:"), t.campeon.nombre,
			" · " + Idiomas.t("¡Es tu selección!") if t.campeon == mia else ""])

static func _avisar_resultado(pr: Principal, t: TorneoSelecciones, mia: Club) -> void:
	for i in range(t.resultados.size() - 1, -1, -1):
		var r: Dictionary = t.resultados[i]
		if r["local"] == mia or r["visita"] == mia:
			var pen: Array = r["penales"]
			Aviso.mostrar(pr, "vida", "🌍", String(r["fase"]), "%s %d-%d %s%s" % [(r["local"] as Club).nombre, int(r["gl"]), int(r["gv"]),
				(r["visita"] as Club).nombre, "" if pen.is_empty() else " (%d-%d pen.)" % [int(pen[0]), int(pen[1])]])
			return

## El partido en directo con el modo de mirar de Ajustes, igual que uno de liga; «tu club» es la selección.
static func _en_directo(pr: Principal, p: Partido, mia: Club, eliminatoria: bool) -> void:
	var vivo = load("res://ui/partido_vivo.gd").new()
	var modo := String(Callable(load("res://ui/principal/jornada_despedida.gd"), "modo_elegido").call())
	vivo.con_3d = modo != "vivo"
	vivo.destacados = modo == "destacados"
	vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pr.add_child(vivo)
	vivo.datos_pantalla = pr._datos_pantalla_estadio(p.local, "copa")
	pr._fundido_entrada()
	vivo.abrir(p, mia, null, eliminatoria, null, pr._velocidad_partido, {}, Comercial.color_balon(pr.mundo.comercial.balon, mia))
	await vivo.cerrado
	vivo.queue_free()


## En Club › Legado: la oferta de selección sin contestar (aceptar / rechazar), o la selección que diriges (con sus torneos y la dimisión).
static func pintar_legado(p: Principal, lista: Control) -> void:
	if p.mundo == null or p.mundo.selecciones == null:
		return
	var cargo := p.mundo.selecciones.cargo
	if cargo.oferta.is_empty() and not cargo.activo():
		return
	lista.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_ORO)
	lista.add_child(t)
	var opciones: Array = []
	if not cargo.oferta.is_empty():
		t.text = "%s %s" % [Idiomas.t("🌍 TE QUIERE LA SELECCIÓN DE"), String(cargo.oferta["nombre"]).to_upper()]
		p._dato("Fuerza", str(int(cargo.oferta["fuerza"])), Principal.COL_VERDE, lista)
		p._dato("Sueldo", Idiomas.t("%s / semana") % p._dinero(int(cargo.oferta.get("sueldo", 0))), Principal.COL_ORO, lista)
		opciones = [["Aceptar (sin dejar el club)", func() -> String: return cargo.responder(p.mundo, true)],
			["Rechazar", func() -> String: return cargo.responder(p.mundo, false)]]
	else:
		t.text = "%s %s" % [Idiomas.t("🌍 SELECCIONADOR DE"), cargo.seleccion.to_upper()]
		p._dato("Desde", str(cargo.desde), Principal.COL_SUAVE, lista)
		p._dato("Títulos", str(cargo.titulos()), Principal.COL_ORO, lista)
		for f: Dictionary in cargo.fechas.slice(0, 3):   ## (10-11) las últimas fechas FIFA
			p._dato(Idiomas.t("Fecha FIFA"), String(f["linea"]), Principal.COL_SUAVE, lista)
		for h: Dictionary in cargo.historial.slice(maxi(0, cargo.historial.size() - 4)):
			p._dato("%s %d" % [String(h["torneo"]), int(h["anio"])], Idiomas.t(String(Selecciones.PUESTOS_TORNEO[int(h["puesto"])])), Principal.COL_SUAVE, lista)
		opciones = [["📋 %s (%d/%d)" % [Idiomas.t("Convocatoria"), cargo.convocados.size(), SeleccionEquipo.MAX_CONVOCADOS],
			func() -> String: return _abrir_sin_mensaje(p)],
			["Dimitir", func() -> String: return cargo.dimitir(p.mundo)]]
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	lista.add_child(fila)
	for o: Array in opciones:
		var b := Button.new()
		b.text = String(o[0]) if String(o[0]).begins_with("📋") else Idiomas.t(String(o[0]))
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var accion: Callable = o[1]
		b.pressed.connect(func() -> void:
			var msg := String(accion.call())
			if msg != "":
				p._escribir("[color=#c9a227]%s[/color]" % Idiomas.t(msg))
				p._refrescar())
		fila.add_child(b)

static func _abrir_sin_mensaje(p: Principal) -> String:
	abrir_convocatoria(p)
	return ""

## LA CONVOCATORIA: los 60 mejores del país en todo el mundo del juego; marcas hasta 26. Sin marcar a nadie, van los mejores por puesto.
## Si a un puesto le faltan (menos de 2 porteros, 6 defensas, 6 medios o 3 delanteros), se completa con jugadores generados.
static func abrir_convocatoria(p: Principal) -> void:
	var cargo := p.mundo.selecciones.cargo
	var ev := EventoSeleccion.new()
	ev.paleta_noche = true
	ev._montar_base(p)
	var c := ev._centro
	var de_pie := EscalaMovil.es_vertical()   ## (12-11) teléfono de pie: una sola columna de candidatos, a lo ancho
	c.add_child(EventoPantallaCompleta.etiqueta("📋 %s · %s" % [Idiomas.t("Convocatoria"), cargo.seleccion], 24 if de_pie else 34, Color.WHITE, true, de_pie))
	var cuenta := EventoPantallaCompleta.etiqueta("", 18, Tema.ORO)
	c.add_child(cuenta)
	c.add_child(EventoPantallaCompleta.etiqueta(Idiomas.t("Sin marcar a nadie van los mejores por puesto. Si a un puesto le faltan jugadores, se completa con jóvenes del país."), 14, Tema.SUAVE))
	var pintar_cuenta := func() -> void:
		cuenta.text = "%s: %d/%d" % [Idiomas.t("Convocados"), cargo.convocados.size(), SeleccionEquipo.MAX_CONVOCADOS]
	pintar_cuenta.call()
	var listo := EventoPantallaCompleta.boton("✔ " + Idiomas.t("Listo"), true)
	listo.pressed.connect(func() -> void:
		ev.queue_free()
		p._refrescar())
	c.add_child(listo)
	listo.call_deferred("grab_focus")
	var rej := GridContainer.new()
	rej.columns = 1 if de_pie else 2
	rej.add_theme_constant_override("h_separation", 10)
	c.add_child(rej)
	var cands := SeleccionEquipo.candidatos(p.mundo, cargo.seleccion, 60)
	if cands.is_empty():
		c.add_child(EventoPantallaCompleta.etiqueta(Idiomas.t("Este país no tiene liga en el juego: la lista sale de jugadores generados."), 16, Tema.TEXTO))
	for j: Jugador in cands:
		var cb := CheckBox.new()
		var club: Club = p.mundo.clubes.get(j.club_id)
		cb.text = "%s · %s · %s · %d" % [j.pos, j.nombre, club.nombre if club != null else Idiomas.t("libre"), j.ovr]
		cb.add_theme_font_size_override("font_size", Tema.letra(14))
		cb.custom_minimum_size = Vector2(480 if de_pie else 370, 0)
		cb.clip_text = true
		cb.button_pressed = cargo.convocados.has(j.id)
		var id := j.id
		cb.toggled.connect(func(_on: bool) -> void:
			cb.set_pressed_no_signal(cargo.alternar(id))
			pintar_cuenta.call())
		rej.add_child(cb)

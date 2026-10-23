extends "res://ui/partido_vivo_p1.gd"
## [Capa 2/3 de `partido_vivo.gd`] _presionar_desde_el_palco, _pintar_palco, _perilla, _gritar_desde_la_banda, _mis_cambios, _hacer_cambio … (+13)

## `presionarDesdePalco()` del HTML: una vez por partido, desde el palco no se
## dirige pero se puede bajar al borde del campo. 55% de que salga bien -sube
## la moral del once 3 puntos-, 45% de que se lea como desconfianza -baja 2-.
## Cueste lo que cueste, la sintonía con el DT cae 9 puntos: la injerencia
## siempre tiene un precio. El HTML de paso sube el ritmo a "a mil"
## (`M.instr.ritmo=2`) cuando sale bien -no portado a propósito: Godot no
## tiene una capa efímera de ritmo, solo la perilla PERSISTENTE de
## `Club.tactica`, y tocarla desde el palco contradiría la premisa de que
## desde ahí no se toca la pizarra-.
func _presionar_desde_el_palco() -> void:
	if _palco_usado or partido.terminado_ya or roles == null:
		return
	_palco_usado = true
	var cargo := roles.nombre_del_cargo()
	if Azar.suerte(0.55):
		_escribir("[color=#8ea595]👔 El %s baja al borde del campo. El equipo se sacude y sube una marcha.[/color]" % cargo)
		for j in _mi_once():
			j.moral = clampi(j.moral + 3, 10, 99)
	else:
		_escribir("[color=#e0a832]👔 Bajas al borde del campo y las cámaras lo enfocan todo. El vestuario lo lee como desconfianza.[/color]")
		for j in _mi_once():
			j.moral = clampi(j.moral - 2, 10, 99)
	if not roles.dt_empleado.is_empty():
		var s := clampi(int(roles.dt_empleado.get("sintonia", 60)) - 9, 0, 100)
		roles.dt_empleado["sintonia"] = s
		if s < 18:
			_escribir("[color=#e05555]Ruptura en el cuerpo técnico:[/color] %s no aguanta más la injerencia desde arriba." % roles.dt_nombre())
	Sonido.toca("clic", Sonido.Bus.INTERFAZ)
	_refrescar()

## `🥂 PALCO PRESIDENCIAL` del HTML: no diriges, así que no hay perillas, ni
## cambios, ni arengas, ni instrucciones en vivo -eso es cosa de tu DT
## empleado-. Solo puedes mirar la sintonía y, una vez por partido, bajar al
## borde del campo a presionar.
func _pintar_palco() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("🥂 PALCO PRESIDENCIAL")
	_banquillo.add_child(t)
	var cargo := roles.nombre_del_cargo() if roles != null else "directivo"
	var p := _texto(11, COL_SUAVE)
	p.text = Idiomas.t("Dirige %s. Los cambios, la charla y las instrucciones son cosa suya: tú solo puedes mirar… o hacerte notar.") % (roles.dt_nombre() if roles != null else "tu DT")
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banquillo.add_child(p)
	if roles != null and not roles.dt_empleado.is_empty():
		var sin := int(roles.dt_empleado.get("sintonia", 60))
		_dato_banquillo("Sintonía con %s" % roles.dt_nombre(), "%d/100" % sin,
			COL_VERDE if sin >= 50 else COL_ROJO)
	var bp := Button.new()
	bp.text = Idiomas.t("😠 Bajar al borde del campo")
	bp.disabled = partido.terminado_ya or _palco_usado
	bp.pressed.connect(_presionar_desde_el_palco)
	_banquillo.add_child(bp)
	_banquillo.add_child(HSeparator.new())
	var t2 := _texto(11, COL_SUAVE)
	t2.text = Idiomas.t("%s  (cargo: %s)") % [Idiomas.t("EL ONCE"), cargo]
	_banquillo.add_child(t2)
	for j in _mi_once():
		var l := _texto(12, COL_TEXTO)
		l.text = "%s  %s  %d" % [j.pos_e, j.nombre, j.ovr]
		_banquillo.add_child(l)

func _perilla(etiqueta: String, opciones: Array, actual: int, al_cambiar: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	_banquillo.add_child(h)
	var l := _texto(11, COL_SUAVE)
	l.text = etiqueta
	l.custom_minimum_size = Vector2(74, 0)
	h.add_child(l)
	for i in opciones.size():
		var b := Button.new()
		b.text = String(opciones[i])
		b.toggle_mode = true
		b.button_pressed = (i == actual)
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			al_cambiar.call(i)
			partido.invalidar_fuerza()
			_escribir("[color=#8ea595]%d'  %s: %s.[/color]" % [partido.minuto, etiqueta, opciones[i]])
			_refrescar())
		h.add_child(b)

func _gritar_desde_la_banda() -> void:
	if _expulsado_banda or partido.terminado_ya or vestuario == null:
		return
	var fed := vestuario._mundo().federacion if vestuario._mundo() != null else null
	if fed != null and fed.enojo_arbitral >= 2 and Azar.suerte(0.16):
		_expulsado_banda = true
		## Y ya no es solo este partido (estadio 2.0): el tribunal sanciona.
		var fechas := 1 + (1 if fed.enojo_arbitral >= 4 else 0)
		fed.sancionar_dt(fechas)
		_escribir("[color=#e05555][b]🟥 ¡Te expulsan a ti![/b][/color] Protestar de forma airada al cuarto árbitro. Te vas a la tribuna, y el tribunal te sanciona con %d partido(s) más desde la grada." % fechas)
		_refrescar()
		return
	_escribir("[color=#8ea595]%s[/color]" % Azar.uno(_FRASES_BANDA))
	for j in _mi_once():
		var m := vestuario.mente(j)
		m["ansiedad"] = clampi(int(m["ansiedad"]) - Azar.ent(1, 4), 0, 100)
	_refrescar()

func _mis_cambios() -> int:
	return partido.cambios_local if partido.local == mi_club else partido.cambios_visita

func _hacer_cambio(entra: Jugador) -> void:
	if _saliendo == null:
		return
	var problema := partido.cambiar(_saliendo, entra)
	if problema != "":
		_escribir("[color=#e05555]No se puede: %s.[/color]" % problema)
	_saliendo = null
	_refrescar()

func _pintar_banquillo() -> void:
	_limpiar(_banquillo)
	if _entretiempo:
		_pintar_camarin()
	if _en_palco():
		_pintar_palco()
		return
	## La pizarra: las perillas se pueden mover con el partido en marcha, y se
	## nota en el minuto siguiente porque `Partido` vuelve a medir los onces.
	_perilla("Mentalidad", ["Defensiva", "Equilibrada", "Ofensiva"], mi_club.tactica.mentalidad,
		func(v: int) -> void: mi_club.tactica.mentalidad = v)
	_perilla("Presión", ["Baja", "Media", "Alta"], mi_club.tactica.presion,
		func(v: int) -> void: mi_club.tactica.presion = v)
	_perilla("Ritmo", ["Lento", "Medio", "Alto"], mi_club.tactica.ritmo,
		func(v: int) -> void: mi_club.tactica.ritmo = v)
	_perilla("Línea", ["Baja", "Media", "Adelantada"], mi_club.tactica.linea,
		func(v: int) -> void: mi_club.tactica.linea = v)

	## INSTRUCCIONES EN VIVO -`instrViva('riesgo'/'tiempo'/'banda')` del HTML-:
	## a diferencia de la pizarra de arriba (persistente), esto se resetea solo
	## con el partido. Estaba escrito en `Partido` pero sin ningún botón que lo
	## tocara.
	_banquillo.add_child(HSeparator.new())
	var ti := _texto(11, COL_SUAVE)
	ti.text = Idiomas.t("INSTRUCCIONES EN VIVO")
	_banquillo.add_child(ti)
	var fi := HFlowContainer.new()
	_banquillo.add_child(fi)
	var br := Button.new()
	br.text = Idiomas.t("%s Todo al ataque") % ("✅" if partido.instr_riesgo else "⬜")
	br.disabled = partido.terminado_ya
	br.pressed.connect(func() -> void:
		partido.instr_riesgo = not partido.instr_riesgo
		_escribir("[color=#8ea595]%d'  📋 %s.[/color]" % [partido.minuto,
			"Todos arriba: se juega a todo o nada." if partido.instr_riesgo else "Vuelve el orden: se deja de arriesgar."])
		_refrescar())
	fi.add_child(br)
	var bt := Button.new()
	bt.text = Idiomas.t("%s Perder tiempo") % ("✅" if partido.instr_tiempo else "⬜")
	bt.disabled = partido.terminado_ya
	bt.pressed.connect(func() -> void:
		partido.instr_tiempo = not partido.instr_tiempo
		_escribir("[color=#8ea595]%d'  📋 %s.[/color]" % [partido.minuto,
			"Ordenas perder tiempo y cerrar el partido." if partido.instr_tiempo else "Se acabó el manejo de tiempos: a jugar."])
		_refrescar())
	fi.add_child(bt)
	var bb := Button.new()
	bb.text = Idiomas.t("🗣️ Gritar desde la banda")
	bb.disabled = partido.terminado_ya or _expulsado_banda
	bb.pressed.connect(_gritar_desde_la_banda)
	fi.add_child(bb)

	var sep := HSeparator.new()
	_banquillo.add_child(sep)
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("SUPLENTES  (%d de %d cambios usados)") % [_mis_cambios(), Partido.MAX_CAMBIOS]
	_banquillo.add_child(t)

	var en_campo := _mi_once()
	for j in mi_club.plantilla:
		if en_campo.has(j):
			continue
		var b := Button.new()
		b.text = "%s  %s  %d%s" % [j.pos_e, j.nombre, j.ovr, "" if j.disponible() else Idiomas.t("  (fuera)")]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", COL_TEXTO if j.disponible() else COL_ROJO)
		## Solo se puede meter a alguien cuando ya se ha elegido a quién sacar:
		## así no hay forma de terminar con doce en el campo por un clic de más.
		b.disabled = partido.terminado_ya or _saliendo == null or not j.disponible()
		b.pressed.connect(func() -> void: _hacer_cambio(j))
		_banquillo.add_child(b)

## Las estadísticas mientras corre el reloj. Cada fila es TU número contra el
## suyo, con una barra que reparte los dos: leer "6-3" cuesta más que ver una
## barra que se llena, y aquí hay que enterarse de un vistazo sin dejar de
## mirar el partido.
func _pintar_estadisticas_vivo() -> void:
	_limpiar(_panel_stats)
	var p := partido
	var mio_local := p.local == mi_club
	var pos_l := int(round(p.posesion_local))
	var filas := [
		["Posesión", pos_l, 100 - pos_l],
		["Remates", p.remates_local, p.remates_visita],
		["Al arco", p.tiros_puerta_local, p.tiros_puerta_visita],
		["Córners", p.corners_local, p.corners_visita],
		["Faltas", p.faltas_local, p.faltas_visita],
		["Fuera de juego", p.fueras_local, p.fueras_visita],
	]
	for f: Array in filas:
		var mio: int = int(f[1]) if mio_local else int(f[2])
		var suyo: int = int(f[2]) if mio_local else int(f[1])
		var cab := HBoxContainer.new()
		_panel_stats.add_child(cab)
		var a := _texto(12, COL_ACENTO)
		a.text = str(mio)
		a.custom_minimum_size = Vector2(30, 0)
		cab.add_child(a)
		var n := _texto(11, COL_SUAVE)
		n.text = String(f[0])
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.clip_text = true
		cab.add_child(n)
		var b := _texto(12, COL_TEXTO)
		b.text = str(suyo)
		b.custom_minimum_size = Vector2(30, 0)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cab.add_child(b)
		var barra := ProgressBar.new()
		barra.min_value = 0.0
		barra.max_value = 100.0
		## Con los dos a cero la barra va al 50: repartir 0 entre 0 no significa
		## que domine nadie, significa que todavía no ha pasado nada.
		barra.value = 50.0 if mio + suyo == 0 else float(mio) * 100.0 / float(mio + suyo)
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(0, 6)
		var relleno := StyleBoxFlat.new()
		relleno.bg_color = COL_ACENTO
		relleno.set_corner_radius_all(2)
		barra.add_theme_stylebox_override("fill", relleno)
		_panel_stats.add_child(barra)
	## El xG aparte, con dos decimales: es el único que no es un contador.
	var xg_mio: float = p.xg_local if mio_local else p.xg_visita
	var xg_suyo: float = p.xg_visita if mio_local else p.xg_local
	var xg := _texto(12, COL_ORO)
	xg.text = "xG   %.2f  ·  %.2f" % [xg_mio, xg_suyo]
	xg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_stats.add_child(xg)
	## Y la lectura, que es lo que convierte el xG en algo que se entiende sin
	## saber qué es el xG.
	var goles_mios: int = p.goles_local if mio_local else p.goles_visita
	if xg_mio >= 1.0 or goles_mios > 0:
		var l := _texto(10, COL_SUAVE)
		if float(goles_mios) < xg_mio - 0.9:
			l.text = Idiomas.t("Generas más de lo que metes: es cuestión de que entre una.")
		elif float(goles_mios) > xg_mio + 0.9:
			l.text = Idiomas.t("Vas por delante de lo que has generado. Ojo con confiarse.")
		else:
			l.text = Idiomas.t("El marcador se parece a lo que has hecho.")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_panel_stats.add_child(l)

# --- pintado ----------------------------------------------------------------

func _refrescar() -> void:
	_marcador.text = "%s   %d - %d   %s" % [
		partido.local.nombre, partido.goles_local, partido.goles_visita, partido.visita.nombre]
	_reloj.text = "%d'" % partido.minuto if not partido.terminado_ya else Idiomas.t("FINAL")
	## La línea de arriba, en vivo: lo que se mira de reojo mientras corre el
	## reloj. El desglose completo -xG, córners, faltas, fueras- va al final, en
	## la crónica, que es donde el HTML lo pone (`vPost`).
	_estadisticas.text = Idiomas.t("Posesión  %d%% - %d%%      Remates  %d - %d      Al arco  %d - %d      Cambios  %d - %d de %d") % [
		int(round(partido.posesion_local)), 100 - int(round(partido.posesion_local)),
		partido.remates_local, partido.remates_visita,
		partido.tiros_puerta_local, partido.tiros_puerta_visita,
		partido.cambios_local, partido.cambios_visita, Partido.MAX_CAMBIOS]
	## `M.mom` del HTML: quién está encima AHORA MISMO según el ritmo reciente
	## de ocasiones, no la posesión acumulada -eso ya se ve aparte, en el texto
	## de estadísticas de más arriba-. La barra siempre mide LO TUYO, seas local
	## o visitante: si midiera al local el jugador tendría que acordarse de en
	## qué lado juega para interpretarla, y entonces ya no se lee de un vistazo.
	var mom := float(partido.momentum_local())
	var mia := mom if partido.local == mi_club else 100.0 - mom
	_momentum.value = mia
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = COL_VERDE if mia >= 55.0 else (COL_ROJO if mia <= 45.0 else COL_ORO)
	relleno.set_corner_radius_all(3)
	_momentum.add_theme_stylebox_override("fill", relleno)
	_pintar_campo()
	_pintar_banquillo()
	_pintar_estadisticas_vivo()

func _a_la_invasion(_minuto: int) -> void:
	_invasion_pendiente = true
	_entretiempo = true
	_acumulado = 0.0
	Sonido.toca("silbato")
	_escribir("[color=#e05555][b]🚨 INVASIÓN DE CAMPO.[/b][/color] La barra salta al césped y lanza bengalas. El partido se para: la policía desaloja y los dos equipos se meten al túnel. Vuelve a abrirse el camarín, con otro clima.")
	_refrescar()

# --- señales del partido ----------------------------------------------------

func _al_gol(club: Club, autor: Jugador, minuto: int, _asistente: Jugador = null) -> void:
	var mio := club == mi_club
	## El sonido va aqui y no en `Partido`: el simulador no sabe si hay alguien
	## mirando, y en el banco de pruebas se juegan miles de partidos sin pantalla.
	## EL SONIDO DE GOL QUE ELEGISTE EN TU ESTADIO -`sfxGol(estilo)` del HTML-.
	## Se podía elegir entre ocho y pagar la reforma, pero aquí sonaba siempre
	## el mismo. Solo en los goles TUYOS: el del rival lleva su propio
	## silencio incómodo. Si el estilo guardado no existe como banco -una
	## partida vieja, un valor raro-, cae al "gol" de siempre en vez de sonar
	## a nada.
	if mio:
		var estilo := "bombo"
		var mu := vestuario._mundo() if vestuario != null else null
		if mu != null and mu.estadio != null:
			estilo = String(mu.estadio.ajustes.get("sonidoGol", "bombo"))
		Sonido.toca("gol_" + estilo if Sonido.catalogo().has("gol_" + estilo) else "gol")
	else:
		Sonido.toca("gol_rival")
	_escribir("[color=%s][b]%d'  ¡GOL de %s![/b][/color]  %s" % [
		"#4caf6d" if mio else "#e05555", minuto, club.nombre,
		autor.nombre if autor else ""])

## LA FRASE DE LA CRÓNICA, SIN TOCAR `Azar` (25-9-2026). Antes salía de
## `Azar.uno()`: narrar una atajada consumía el generador del partido, así que
## el MISMO partido terminaba distinto mirado en texto que en 3D o simulado (lo
## cazó la prueba "MODOS DE SIMULACIÓN" del banco). Contar no puede decidir
## nada: la frase sale de un generador propio sembrado con quién y cuándo.
func _frase(frases: Array, quien: String, minuto: int) -> String:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%s|%d" % [quien, minuto])
	return String(frases[r.randi_range(0, frases.size() - 1)])

func _al_remate(club: Club, autor: Jugador, tipo: String, minuto: int) -> void:
	var mio := club == mi_club
	var nombre := autor.nombre if autor else ""
	match tipo:
		"atajada":
			if mio:
				Sonido.toca("atajada")
			_escribir("[color=#8ea595]%d'  %s%s[/color]" % [minuto, _frase(_FRASES_ATAJADA, nombre, minuto), nombre])
		"poste":
			if mio:
				Sonido.toca("ocasion")
			_escribir("[color=#8ea595]%d'  🪵 ¡Al palo! Increíble ocasión de %s[/color]" % [minuto, nombre])
		_:
			var frase: String = _frase(_FRASES_FALLO, nombre, minuto)
			if nombre != "":
				frase += " — " + nombre
			_escribir("[color=#8ea595]%d'  %s[/color]" % [minuto, frase])

func _a_la_tarjeta(j: Jugador, roja: bool, minuto: int) -> void:
	Sonido.toca("roja" if roja else "amarilla")
	if roja:
		_escribir("[color=#e05555]%d'  ROJA a %s.[/color] Se va a la calle." % [minuto, j.nombre])
	elif j.club_id == mi_club.id:
		## Solo se cuentan las amarillas de los tuyos: las del rival son ruido
		## que tapa lo que sí importa.
		_escribir("[color=#c9a227]%d'  Amarilla a %s.[/color]" % [minuto, j.nombre])

## Lo que decide el árbitro por su cuenta -`_arb`/`decision_arbitral` de
## `Partido`-. Se narra siempre, pase lo que pase con la tarjeta o el gol de
## penal que la misma jugada pueda traer detrás: es la frase que explica el
## PORQUÉ, y esa nadie más la cuenta.
func _a_la_decision_arbitral(texto: String, minuto: int) -> void:
	_escribir("[color=#c9a227]%d'  %s[/color]" % [minuto, texto])

func _a_la_lesion(j: Jugador, semanas: int, minuto: int) -> void:
	var mio := j.club_id == mi_club.id
	## Sonido nuevo, sin equivalente en el HTML: hasta hoy una lesión sonaba
	## exactamente igual que nada -Godot no tenia mas efectos que los que ya
	## traia sfx()-. Solo suena cuando es tuyo: la lesión del rival es una
	## buena noticia y no merece el mismo golpe seco.
	if mio:
		Sonido.toca("lesion")
	_escribir("[color=%s]%d'  %s cae lesionado: %d semana%s fuera.[/color]%s" % [
		"#e05555" if mio else "#8ea595", minuto, j.nombre, semanas,
		"" if semanas == 1 else "s",
		"  [color=#c9a227]Te toca mover el banquillo.[/color]" if mio else ""])
	if mio:
		_poner_velocidad(0)   ## se para el reloj: hay una decisión que tomar

func _al_cambio(sale: Jugador, entra: Jugador, minuto: int) -> void:
	## Otro sonido nuevo: `cambio_hecho` solo lo dispara ESTE lado (el rival
	## cambia sin pasar por aqui), asi que suena siempre, sin comprobar "mio".
	Sonido.toca("cambio")
	_escribir("[color=#3fa06a]%d'  Cambio: entra %s por %s.[/color]" % [minuto, entra.nombre, sale.nombre])

## LA LISTA DE GOLES de `vPost()`. `Partido.cronica` guarda cada gol con minuto y
## autor desde siempre; lo que faltaba era volver a leerla al terminar, para que
## el resultado no sea solo un marcador sino quién lo hizo y cuándo.
func _escribir_goles() -> void:
	var hubo := false
	for e: Dictionary in partido.cronica:
		if String(e.get("tipo", "")) != "gol":
			continue
		if not hubo:
			_escribir("")
			_escribir("[color=#8ea595]GOLES[/color]")
			hubo = true
		var de_los_mios := String(e.get("club", "")) == mi_club.id
		_escribir("[color=%s]  %d'  %s[/color]" % [
			"#4caf6d" if de_los_mios else "#e05555",
			int(e.get("min", 0)), String(e.get("autor", "?"))])

## El cuadro de "ESTADÍSTICAS DEL PARTIDO" de `vPost()`, en texto: siete filas
## con el tuyo primero, ganes o pierdas, seas local o visitante -leer tu propia
## columna a la izquierda es lo que hace que un vistazo baste.
func _escribir_estadisticas(mio_local: bool) -> void:
	var p := partido
	var pos_l := int(round(p.posesion_local))
	var filas := [
		["Posesión", "%d%%" % pos_l, "%d%%" % (100 - pos_l)],
		["Remates", str(p.remates_local), str(p.remates_visita)],
		["Al arco", str(p.tiros_puerta_local), str(p.tiros_puerta_visita)],
		["xG (goles esperados)", "%.2f" % p.xg_local, "%.2f" % p.xg_visita],
		["Córners", str(p.corners_local), str(p.corners_visita)],
		["Faltas", str(p.faltas_local), str(p.faltas_visita)],
		["Fuera de juego", str(p.fueras_local), str(p.fueras_visita)],
	]
	_escribir("")
	_escribir("[color=#8ea595]ESTADÍSTICAS DEL PARTIDO[/color]")
	for f: Array in filas:
		var mio: String = f[1] if mio_local else f[2]
		var suyo: String = f[2] if mio_local else f[1]
		_escribir("[color=#8ea595]%s[/color]   [b]%s[/b] - %s" % [String(f[0]), mio, suyo])

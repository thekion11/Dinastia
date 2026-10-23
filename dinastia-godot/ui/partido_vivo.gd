class_name PartidoVivo
extends "res://ui/partido_vivo_p2.gd"
## (Parte 3 de 3 de `partido_vivo.gd`.)

## `infPostPartido()` del HTML, frase por frase: el ayudante te cuenta lo que
## las cifras dicen y el marcador no. Es lo que convierte el xG en algo que se
## entiende sin saber qué es el xG.
func _informe(mio_local: bool, mios: int, suyos: int) -> String:
	var p := partido
	var pos := int(round(p.posesion_local)) if mio_local else 100 - int(round(p.posesion_local))
	var xg_mio: float = p.xg_local if mio_local else p.xg_visita
	var xg_suyo: float = p.xg_visita if mio_local else p.xg_local
	var faltas_mias: int = p.faltas_local if mio_local else p.faltas_visita
	var cambios_mios: int = p.cambios_local if mio_local else p.cambios_visita
	var dif := mios - suyos
	var frases: Array[String] = []
	frases.append("Nos llevamos los tres puntos." if dif > 0 else ("Reparto de puntos." if dif == 0 else "Se nos escapó."))
	if pos >= 60:
		frases.append("Tuvimos la pelota casi todo el partido (%d%%): el plan de circulación funcionó." % pos)
	elif pos <= 42:
		frases.append("Les cedimos la pelota (%d%%) y jugamos al contragolpe." % pos)
	else:
		frases.append("Partido parejo en el control del balón (%d%%)." % pos)
	if float(mios) > xg_mio + 1.0:
		frases.append("Los delanteros estuvieron finísimos: convertimos más de lo que la estadística decía (xG %.2f)." % xg_mio)
	elif xg_mio > float(mios) + 1.0:
		frases.append("Generamos mucho más de lo que anotamos (xG %.2f): falta puntería." % xg_mio)
	if xg_suyo > float(suyos) + 1.0:
		frases.append("El arquero nos salvó: el rival mereció más.")
	elif float(suyos) > xg_suyo + 1.0:
		frases.append("Nos hicieron goles baratos, con poco.")
	if faltas_mias > 16:
		frases.append("Cometimos demasiadas faltas: con otro árbitro terminamos con diez.")
	if absi(dif) >= 3:
		frases.append("Goleada que va a levantar el ánimo de todo el club." if dif > 0 else "Goleada en contra: hay que hablar en el camarín.")
	if cambios_mios == 0:
		frases.append("No usaste cambios: el once terminó fundido.")
	return " ".join(frases)

## LAS NOTAS DEL ONCE y la FIGURA DEL PARTIDO. El motor puntúa a cada jugador y
## la nota se guarda en `Jugador.notas` —la usa la satisfacción del vestuario y
## la media de temporada— pero al acabar un partido no se veía por ningún lado:
## había que ir jugador por jugador a su ficha para saber quién había jugado
## bien. Es de las cosas que más se miran al pitido final.
func _escribir_notas() -> void:
	## 17-10-2026 (M-141): las notas salen de `Partido.valoraciones()`. Antes se
	## leía la última de `Jugador.notas`, pero en un partido mirado (en vivo o
	## en 3D) esa nota no se cierra hasta avanzar la semana: se enseñaba la del
	## partido ANTERIOR. Y el mejor del partido es el de los dos equipos.
	var vals := partido.valoraciones()
	if vals.is_empty():
		return
	var mvp: Dictionary = vals[0]
	var mj: Jugador = mvp["jugador"]
	var club_mvp: Club = partido.local if bool(mvp["local"]) else partido.visita
	_escribir("")
	_escribir("[color=#c9a227][b]%s:[/b][/color] [b]%s[/b] (%s)  [color=#c9a227][b]%.1f[/b][/color]" % [
		Idiomas.t("⭐ MEJOR DEL PARTIDO"), mj.nombre, club_mvp.nombre, float(mvp["nota"])])
	var mio_local := partido.local == mi_club
	var mias: Array = []
	for v: Dictionary in vals:
		if bool(v["local"]) == mio_local:
			mias.append(v)
	if mias.is_empty():
		return
	var mejor: Dictionary = mias[0]
	var peor: Dictionary = mias[mias.size() - 1]
	if mejor != mvp:
		_escribir("[color=#c9a227][b]🏅 Figura del partido:[/b][/color] %s (%.1f)" % [
			(mejor["jugador"] as Jugador).nombre, float(mejor["nota"])])
	## El aviso del peor solo si de verdad fue mal: por debajo de 5,6, que es el
	## umbral del HTML. Señalar al menos bueno de un partido bueno es ruido.
	if float(peor["nota"]) < 5.6:
		_escribir("[color=#8ea595]⚠️ %s terminó con %.1f: conviene revisar su puesto o darle descanso.[/color]" % [
			(peor["jugador"] as Jugador).nombre, float(peor["nota"])])
	_escribir("")
	_escribir("[color=#8ea595]%s[/color]" % Idiomas.t("VALORACIONES"))
	for v: Dictionary in mias:
		var j: Jugador = v["jugador"]
		var n2 := float(v["nota"])
		var col := "#4caf6d" if n2 >= 7.5 else ("#e05555" if n2 < 5.5 else "#e9eeea")
		_escribir("[color=#8ea595]  %s[/color] %s%s   [color=%s][b]%.1f[/b][/color]" % [
			j.pos_e, ("⭐ " if v == mvp else ""), j.nombre, col, n2])

func _al_final(gl: int, gv: int) -> void:
	Sonido.toca("pitido_final")
	var mio_local := partido.local == mi_club
	var mios := gl if mio_local else gv
	var suyos := gv if mio_local else gl
	var texto := "VICTORIA" if mios > suyos else ("DERROTA" if mios < suyos else "EMPATE")
	var color := "#4caf6d" if mios > suyos else ("#e05555" if mios < suyos else "#8ea595")
	_escribir("")
	_escribir("[color=%s][b]FINAL. %s.[/b][/color]  %s %d-%d %s" % [
		color, texto, partido.local.nombre, gl, gv, partido.visita.nombre])
	_escribir_goles()
	## LOS PENALES. En una eliminatoria un empate no se queda así -`Copa.
	## jugar_ronda()` los va a pedir de todos modos al avanzar la semana, para
	## saber quién sigue vivo-, así que se juegan aquí mismo y se cuentan: sin
	## esto el jugador veía "EMPATE" y se enteraba de quién pasaba de ronda la
	## semana siguiente, leyéndolo en un aviso. `Partido.penales()` queda
	## memoizado, así que cuando `Copa` los vuelva a pedir sobre este mismo
	## objeto recibe el MISMO resultado, no uno tirado de nuevo.
	if es_eliminatoria and gl == gv:
		var pen := partido.penales()
		var gano_local := int(pen[0]) > int(pen[1])
		var pase_mio := gano_local == mio_local
		_escribir("")
		_escribir("[color=#c9a227][b]🥅 PENALES.[/b][/color]  %s %d-%d %s" % [
			partido.local.nombre, int(pen[0]), int(pen[1]), partido.visita.nombre])
		_escribir("[color=%s][b]%s[/b][/color]" % [
			"#4caf6d" if pase_mio else "#e05555",
			"Pasas de ronda en la tanda de penales." if pase_mio else "Quedas eliminado en la tanda de penales."])
	_escribir_estadisticas(mio_local)
	_escribir("")
	_escribir("[color=#c9a227][b]📋 Informe del ayudante.[/b][/color] %s" % _informe(mio_local, mios, suyos))
	_escribir_notas()
	_btn_volver.visible = true
	_refrescar()

func _hasta_el_proximo_gol() -> void:
	var goles_antes := partido.goles_local + partido.goles_visita
	while not partido.terminado_ya and partido.goles_local + partido.goles_visita == goles_antes:
		partido.simular_minuto()
	_refrescar()

func _columna(padre: HBoxContainer, titulo: String, ratio: float, con_scroll: bool = true) -> VBoxContainer:
	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = COL_PANEL
	e.border_color = COL_BORDE
	e.set_border_width_all(1)
	e.set_corner_radius_all(8)
	caja.add_theme_stylebox_override("panel", e)
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = ratio
	padre.add_child(caja)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12; v.offset_top = 10; v.offset_right = -12; v.offset_bottom = -10
	caja.add_child(v)
	var t := _texto(11, COL_SUAVE)
	t.text = titulo
	v.add_child(t)
	if not con_scroll:
		return v
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(s)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 2)
	s.add_child(lista)
	return lista

func _hasta_el_final() -> void:
	while not partido.terminado_ya:
		partido.simular_minuto()
	_refrescar()

func _montar_cajon() -> void:
	var cajon := CajonAjustes.crear(self, "partido_vivo")
	cajon.seccion("Reloj")
	for i in VELOCIDADES.size():
		var b := cajon.boton(String(VELOCIDADES[i]["txt"]), func() -> void: _poner_velocidad(i))
		b.toggle_mode = true
		_botones_vel.append(b)
	cajon.boton("⏭ Saltar al final", _hasta_el_final)
	cajon.seccion("En pantalla")
	cajon.interruptor("Barra de dominio", _momentum.visible, func(si: bool) -> void: _momentum.visible = si)
	cajon.interruptor("Columna de estadísticas", true, func(si: bool) -> void:
		## `_panel_stats` es la lista de dentro; se oculta su tarjeta entera.
		var caja: Node = _panel_stats
		while caja != null and not (caja is PanelContainer):
			caja = caja.get_parent()
		if caja != null:
			(caja as Control).visible = si)
	cajon.interruptor("Datos bajo el marcador", true, func(si: bool) -> void: _estadisticas.visible = si)
	cajon.deslizador("Tamaño de la crónica", 0.3, func(v: float) -> void:
		_cronica.add_theme_font_size_override("normal_font_size", int(lerpf(11.0, 20.0, v))))
	cajon.seccion("Sonido")
	cajon.deslizador("Efectos", float(Sonido.volumen.get(Sonido.Bus.EFECTOS, 0.8)), func(v: float) -> void:
		Sonido.volumen[Sonido.Bus.EFECTOS] = v)
	cajon.deslizador("Música", Musica.volumen, func(v: float) -> void:
		Musica.volumen = v
		Musica.aplicar_volumen())

# --- construcción -----------------------------------------------------------

func _construir() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 18; raiz.offset_top = 14
	raiz.offset_right = -18; raiz.offset_bottom = -14
	raiz.add_theme_constant_override("separation", 10)
	add_child(raiz)

	_marcador = _texto(34, COL_TEXTO)
	_marcador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_marcador)
	_reloj = _texto(15, COL_ORO)
	_reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_reloj)
	_estadisticas = _texto(12, COL_SUAVE)
	_estadisticas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_estadisticas)

	## LA BARRA DE MOMENTUM. Es la única cosa de la pantalla que se lee sin leer:
	## de un vistazo dice quién está encima ahora mismo, y cambia de color mucho
	## antes de que cambie el marcador. Mide `Partido.momentum_local()` -el log
	## de los últimos 12 remates y goles, `M.mom` del HTML-, no la posesión: la
	## posesión es una media lenta y ya se ve aparte, en las estadísticas.
	_momentum = ProgressBar.new()
	_momentum.min_value = 0.0
	_momentum.max_value = 100.0
	_momentum.show_percentage = false
	_momentum.custom_minimum_size = Vector2(0, 10)
	raiz.add_child(_momentum)

	## A LA VISTA SOLO LO QUE SE USA A CADA RATO (25-9-2026, plan maestro B1):
	## la velocidad actual (un clic la pasa a la siguiente), "Ver en 3D" y "Al
	## próximo gol". Las cinco velocidades sueltas, "Al final", qué paneles se
	## ven, el tamaño de la crónica y el sonido van en el cajón del ⚙.
	var barra := HBoxContainer.new()
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override("separation", 6)
	raiz.add_child(barra)
	_btn_vel_actual = Button.new()
	_btn_vel_actual.custom_minimum_size = Vector2(120, 30)
	_btn_vel_actual.tooltip_text = Idiomas.t("Pulsa para cambiar la velocidad")
	_btn_vel_actual.pressed.connect(func() -> void: _poner_velocidad((_velocidad + 1) % VELOCIDADES.size()))
	barra.add_child(_btn_vel_actual)
	## El estadio en 3D del club que hace de local. Se abre encima del partido y
	## el reloj se para solo mientras se mira.
	var ver3d := Button.new()
	ver3d.text = Idiomas.t("Ver en 3D")
	ver3d.custom_minimum_size = Vector2(110, 30)
	ver3d.pressed.connect(_ver_estadio)
	barra.add_child(ver3d)
	## `saltarAlGol()` del HTML: avanza sin pausas hasta el próximo gol -de
	## cualquiera de los dos-, o hasta el final si no llega ninguno.
	var saltar_gol := Button.new()
	saltar_gol.text = Idiomas.t("Al próximo gol")
	saltar_gol.custom_minimum_size = Vector2(100, 30)
	saltar_gol.pressed.connect(_hasta_el_proximo_gol)
	barra.add_child(saltar_gol)
	## LA PUERTA DE SALIDA. Vivía después de un `return` dentro de `_informe()`
	## -código muerto que nunca se ejecutaba, ni un error lo delataba- así que
	## al terminar un partido en vivo NO había ninguna forma de volver al club:
	## la pantalla se quedaba ahí para siempre. Se crea una vez, oculta, y
	## `_al_final()` la muestra.
	_btn_volver = Button.new()
	_btn_volver.text = Idiomas.t("Volver al club")
	_btn_volver.custom_minimum_size = Vector2(110, 30)
	_btn_volver.visible = false
	_btn_volver.pressed.connect(func() -> void: cerrado.emit())
	barra.add_child(_btn_volver)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	raiz.add_child(cols)

	_campo = _columna(cols, "EN EL CAMPO", 1.4)
	## OJO: la crónica NO va dentro de un ScrollContainer.
	##
	## Un RichTextLabel tiene altura mínima cero, así que metido en un scroll se
	## queda con cero de alto y el panel sale VACÍO aunque el texto esté escrito.
	## Costó una captura entera darse cuenta, porque no hay error ni aviso: solo
	## un recuadro en blanco. El RichTextLabel ya sabe hacer scroll él solo, que
	## para eso tiene `scroll_following`.
	var medio := _columna(cols, "CRÓNICA", 2.0, false)
	_cronica = RichTextLabel.new()
	_cronica.bbcode_enabled = true
	_cronica.scroll_following = true
	_cronica.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cronica.add_theme_font_size_override("normal_font_size", 13)
	medio.add_child(_cronica)
	_banquillo = _columna(cols, "BANQUILLO Y PIZARRA", 1.4)
	## LAS ESTADÍSTICAS EN VIVO. `Partido` calcula xG, córners, faltas y fueras
	## cada minuto, y hasta ahora solo se veían al FINAL, en la crónica. Verlas
	## mientras corre el reloj es lo que permite darse cuenta de que estás
	## generando y no entrando -o al revés- a tiempo de hacer algo.
	_panel_stats = _columna(cols, "ESTADÍSTICAS", 1.1)

	_pie = _texto(12, COL_SUAVE)
	_pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_pie)
	_montar_cajon()
	_poner_velocidad(_velocidad)

## `velocidad_inicial`: "Velocidad de partido por defecto" de `vAjustes()`, que
## hasta esta tanda no existía en Godot -cada partido arrancaba siempre en
## el mismo índice fijo (2, "Normal"), sin que el jugador pudiera dejar
## puesta su preferencia-. Sigue el mismo índice que `VELOCIDADES`.
func abrir(p: Partido, club: Club, vest: Vestuario = null, eliminatoria: bool = false, rol: Roles = null, velocidad_inicial: int = -1, perfil_est: Dictionary = {}, colores_bal: Array = []) -> void:
	partido = p
	mi_club = club
	vestuario = vest
	es_eliminatoria = eliminatoria
	roles = rol
	perfil_estadio = perfil_est
	colores_balon = colores_bal
	if velocidad_inicial >= 0 and velocidad_inicial < VELOCIDADES.size():
		_velocidad = velocidad_inicial
	partido.preparar()
	## SANCIONADO (estadio 2.0): sin banda; el partido se ve desde la grada.
	var m_s := vestuario._mundo() if vestuario != null else null
	if m_s != null and m_s.federacion != null and m_s.federacion.dt_sancionado():
		_expulsado_banda = true
		PersonajeDT.sancionado = true
		call_deferred("_escribir", "[color=#e0a040][b]🟥 Sancionado[/b][/color] Ves el partido desde la grada (quedan %d). No puedes dar órdenes desde la banda." % m_s.federacion.dt_suspension)
	else:
		PersonajeDT.sancionado = false
	if partido._hinchada_club == null and mi_club != null:
		var animo_hoy := 60
		if vestuario != null and vestuario._mundo() != null and vestuario._mundo().prensa != null:
			animo_hoy = vestuario._mundo().prensa.animo
		partido.fijar_hinchada(mi_club, animo_hoy)
	partido.invasion_de_campo.connect(_a_la_invasion)
	partido.gol.connect(_al_gol)
	partido.remate.connect(_al_remate)
	partido.tarjeta.connect(_a_la_tarjeta)
	partido.decision_arbitral.connect(_a_la_decision_arbitral)
	partido.lesion.connect(_a_la_lesion)
	partido.cambio_hecho.connect(_al_cambio)
	partido.terminado.connect(_al_final)
	_construir()
	_refrescar()
	Sonido.toca("silbato")
	Sonido.toca("murmullo", Sonido.Bus.AMBIENTE)
	_escribir("[color=#8ea595]Empieza el partido en %s.[/color]" % partido.local.nombre)
	## EL VISOR 3D, DE ENTRADA (13-9-2026). Pedido explícito hace semanas
	## ("el visor 3D pasa a ser el ESTÁNDAR de la vista de partido, no un
	## extra opcional") y repetido ahora ("no podemos ver realmente en vivo
	## el partido, el visor debe ser de forma nativa"): `_ver_estadio()`
	## siempre hizo todo lo necesario -abre con el partido de VERDAD dentro,
	## no una maqueta, y el reloj de esta pantalla se para para que mande el
	## de la vista 3D-, pero había que ENCONTRAR el botón "Ver en 3D" para
	## llegar a él. Ahora se abre solo al empezar cualquier partido dirigido:
	## lo primero que se ve ya es el estadio, no un panel de texto con un
	## botón escondido. Cerrar el 3D (✕/"Volver") te devuelve aquí para
	## seguir con cambios, arengas y demás, exactamente como ya funcionaba.
	## `con_3d` (25-9-2026, plan maestro B2): el modo "En vivo (texto)" lo
	## apaga; "3D destacados" lo abre con el reloj rápido.
	if con_3d:
		_ver_estadio()

func _process(delta: float) -> void:
	if partido == null or partido.terminado_ya:
		return
	var ms: float = VELOCIDADES[_velocidad]["ms"]
	if ms <= 0.0:
		return
	_acumulado += delta * 1000.0
	while _acumulado >= ms and not partido.terminado_ya:
		## EL ENTRETIEMPO. El reloj se para solo al llegar al 45 y no sigue
		## hasta que salgas del camarín: si no parara, la charla sería un botón
		## que hay que pulsar a tiempo, y eso no es una decisión, es un reflejo.
		if partido.minuto >= 45 and not _entretiempo_hecho:
			_entretiempo_hecho = true
			_entretiempo = true
			_acumulado = 0.0
			Sonido.toca("silbato")
			_escribir("[color=#c9a227][b]🔵 ENTRETIEMPO.[/b][/color] Camarín abierto: charla, cambios e instrucciones.")
			_refrescar()
			return
		if _entretiempo:
			return
		_acumulado -= ms
		partido.simular_minuto()
		if _invasion_pendiente:
			_invasion_pendiente = false
			return
	_refrescar()

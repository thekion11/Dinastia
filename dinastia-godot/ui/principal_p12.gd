extends "res://ui/principal_p10.gd"
## [Capa 11/17 de `principal.gd`] _modo_simulacion, _dirigir, _jugar_temporada, _retrato… (y los puentes a `PantallaElegirClub`)

## Puentes (fase 6, paso 4): elegir club vive en `PantallaElegirClub`.
func _al_elegir_club(indice: int) -> void: _ui_elegir_club._al_elegir_club(indice)
func _llenar_selector() -> void: _ui_elegir_club._llenar_selector()
func _tomar_club(id: String) -> void: _ui_elegir_club._tomar_club(id)
func _pintar_elegir_club(col: VBoxContainer) -> void: _ui_elegir_club._pintar_elegir_club(col)
func _abrir_elegir_club() -> void: _ui_elegir_club._abrir_elegir_club()

## El modo elegido para una competición (se guarda por separado: la copa en 3D
## y la liga en resumen, por ejemplo). Por defecto, 3D completo, que es lo que
## hacía "Dirigir" hasta hoy.
func _modo_simulacion(comp: String) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return "completo"
	return String(cfg.get_value(SECCION_SIMULACION, comp, "completo"))

## La competición del partido de esta semana, con el mismo orden que
## `_dirigir()`: copa, después continental, después liga.
func _competicion_de_la_semana() -> String:
	if not mundo.partido_de_copa().is_empty():
		return "copa"
	if mundo.mi_continental() != null and not mundo.partido_continental().is_empty():
		return "conti"
	return "liga"

## Apunta el partido dirigido y lo pone al día (goles y cada 5'): si se cierra
## el juego a medias, al cargar se completa desde ahí (`PartidoPendiente`).
func _apuntar_partido_en_curso(p: Partido) -> void:
	PartidoPendiente.abrir(mundo, p)
	p.gol.connect(func(_c: Club, _a: Jugador, _m: int, _s: Jugador) -> void: PartidoPendiente.actualizar(mundo, p))
	p.minuto_jugado.connect(func(mi: int) -> void:
		if mi % 5 == 0:
			PartidoPendiente.actualizar(mundo, p))

func _seguir_tras_partido(p: Partido) -> void:
	PartidoPendiente.cerrar()
	mundo.avanzar_semana(p)
	_escribir("[color=#3fa06a]J%d  %s %d-%d %s[/color]" % [
		mundo.liga_de(mundo.mi_club()).jornada_actual,
		p.local.nombre, p.goles_local, p.goles_visita, p.visita.nombre])
	## (17-10: tras un partido dirigido no se autoguardaba; ahora sí, como al
	## avanzar la semana sin jugarlo.)
	_partida.autoguardar_si_toca()
	_refrescar()
	## Seis partidos seguidos con el mismo cambio del plan: se pregunta.
	PreguntaPlan.mostrar_si_toca(self, mundo.mi_club())

## Se avanza la semana con el partido ya jugado en la mano. Si se avanzara sin
## él, la jornada se volvería a simular por dentro y en la tabla aparecería un
## marcador distinto del que se acaba de ver. Lo usan todos los modos.
func _cerrar_partido_dirigido(p: Partido) -> void:
	PartidoPendiente.actualizar(mundo, p)
	## A PIE DE CAMPO (B5): antes de volver al despacho, una pregunta con el
	## partido todavía caliente. No en "instantáneo": quien lo eligió quiere el
	## resultado y nada más.
	if mundo.prensa != null and _modo_simulacion(_competicion_de_la_semana()) != "instantaneo":
		var mio := mundo.mi_club()
		var local := p.local == mio
		var gf := p.goles_local if local else p.goles_visita
		var gc := p.goles_visita if local else p.goles_local
		var pie := PieDeCampo.mostrar(self, mundo.prensa, gf > gc, gf == gc, gf, gc)
		pie.cerrado.connect(func() -> void: _seguir_tras_partido(p))
		return
	_seguir_tras_partido(p)

## El estadio del local, con el cielo del día (no el que se eligió en el
## diseñador: el clima lo pone la ciudad).
func _perfil_con_clima(p: Partido) -> Dictionary:
	var perfil := mundo.perfil_estadio_de(p.local).duplicate()
	if not p.clima_info.is_empty():
		perfil["clima"] = String(p.clima_info["clave"])
	return perfil

## Abre el partido de esta jornada en directo. Al terminar, el resultado que
## salga en la pantalla es el que va a la tabla: el mundo simula el resto de la
## jornada pero NO vuelve a jugar el tuyo.
func _dirigir() -> void:
	if not mundo.temporada_en_curso():
		_escribir("[color=#e05555]La temporada está terminada.[/color]")
		return
	## Si esta semana hay copa, manda la copa: es la que se juega a un solo
	## partido y la que se puede perder para siempre.
	var par := mundo.partido_de_copa()
	var es_copa := not par.is_empty()
	## SI NO HAY COPA, ¿HAY CONTINENTAL? Hasta esta tanda `_dirigir()` nunca
	## miraba esto: `partido_continental()` no existía, así que un partido de
	## Libertadores/Champions/etc. jamás se podía dirigir en vivo -se
	## auto-simulaba solo, sin que el jugador se enterara de que existía esa
	## fecha-. El motor de abajo (`Continental.jugar_ronda(ya_jugado)`) ya
	## sabía recibirlo; solo faltaba esta puerta.
	var conti: Continental = null
	if not es_copa:
		conti = mundo.mi_continental()
		par = mundo.partido_continental()
		if par.is_empty():
			conti = null
	if conti == null and not es_copa:
		par = mundo.proximo_partido()
	if par.is_empty():
		_escribir("[color=#8ea595]Tu club descansa esta jornada.[/color]")
		return
	## La eliminatoria -penales, sin revancha- es la copa siempre, y el
	## continental solo cuando ya salió de la fase de grupos.
	var es_eliminatoria := es_copa or (conti != null and not conti.en_fase_de_grupos())
	if es_copa:
		_escribir("[color=#c9a227]%s — %s.[/color]" % [mundo.copa.nombre, mundo.copa.nombre_de_ronda()])
	elif conti != null:
		_escribir("[color=#c9a227]%s — %s.[/color]" % [Continental.nombre_conti(conti.clave), conti.nombre_de_ronda()])
	var p := Partido.new(par[0], par[1])
	## EL TIEMPO DE LA CIUDAD (plan maestro C1): el mismo que se juega y el
	## mismo cielo que se ve. Sale del país del local y la época del año.
	var info_clima := Clima.del_partido(p.local.pais, mundo.semana, mundo.anio, p.local.id + p.visita.id)
	p.fijar_clima(info_clima)
	_escribir("[color=#8ea595]%s Parte del tiempo: %s.[/color]" % [Clima.icono(info_clima), String(info_clima["texto"])])
	var consejo := Clima.consejo(info_clima, p.local == mundo.mi_club())
	if consejo != "":
		MentorVoz.decir(self, mundo, "%s %s" % [Clima.icono(info_clima), String(info_clima["texto"])], consejo)
	## El nodo «Bloque» del arbol hace que lo que dices desde el banquillo pegue
	## un 50% mas. En este motor eso es la arenga.
	if mundo.entrenamiento != null:
		p._factor_arenga = mundo.entrenamiento.factor_instrucciones()
	## CÓMO SE MIRA (25-9-2026, plan maestro B2). Los cinco modos juegan el
	## MISMO `Partido` con los mismos `simular_minuto()`: solo cambia la vista.
	var modo := _modo_simulacion(_competicion_de_la_semana())
	if modo == "instantaneo" or modo == "resumen":
		p.preparar()
		p.fijar_hinchada(mundo.mi_club(), mundo.prensa.animo if mundo.prensa != null else 60)
		_apuntar_partido_en_curso(p)
		var res := ResumenPartido.mostrar(self, p, mundo.mi_club(), es_eliminatoria, modo == "resumen")
		res.cerrado.connect(func() -> void:
			res.queue_free()
			_cerrar_partido_dirigido(p))
		return
	## EL INFORME DEL RIVAL (17-10-2026) antes de salir a jugar, como en FM/FC.
	## Sin pantalla (banco) o con SIN_INFORME_RIVAL no se enseña.
	if InformeRival.activo and DisplayServer.get_name() != "headless" and OS.get_environment("SIN_INFORME_RIVAL") == "":
		var inf := InformeRival.mostrar(self, p, mundo.mi_club(), mundo.liga_de(p.visita if p.local == mundo.mi_club() else p.local), mundo)
		await inf.cerrado
		inf.queue_free()
	_apuntar_partido_en_curso(p)
	var vivo := PartidoVivo.new()
	vivo.con_3d = modo != "vivo"
	vivo.destacados = modo == "destacados"
	vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vivo)
	## El perfil del ESTADIO LOCAL -que puede ser el tuyo o el del rival, según
	## quién juegue en casa-, no siempre "el tuyo": `perfil_estadio_de()` ya
	## decide sola cuándo corresponde tu diseño y cuándo el genérico por hash.
	## El BALÓN sí es siempre el tuyo -`Comercial` es tu departamento comercial,
	## el rival no tiene uno propio en este juego-.
	## Lo de la PANTALLA GIGANTE va antes de `abrir()`: `PartidoVivo` abre el
	## visor 3D de entrada, así que asignarlo después llegaría tarde.
	vivo.datos_pantalla = _datos_pantalla_estadio(p.local, "copa" if es_copa else ("conti" if conti != null else "liga"))
	_fundido_entrada()
	vivo.abrir(p, mundo.mi_club(), mundo.vestuario, es_eliminatoria, mundo.roles,
		_velocidad_partido, _perfil_con_clima(p),
		Comercial.color_balon(mundo.comercial.balon, mundo.mi_club()))
	vivo.cerrado.connect(func() -> void:
		vivo.queue_free()
		_cerrar_partido_dirigido(p))

func _jugar_temporada() -> void:
	if not mundo.temporada_en_curso():
		_escribir("[color=#e05555]La temporada ya está terminada.[/color]")
		return
	var t0 := Time.get_ticks_msec()
	mundo.jugar_temporada()
	var t := _liga_de(mundo.mi_club()).tabla()
	var puesto := 1
	for fila: Dictionary in t:
		if fila["club"] == mundo.mi_club():
			break
		puesto += 1
	_escribir("[color=#3fa06a]Temporada %d completa en %d ms.[/color] Campeón: [b]%s[/b]. Acabas [b]%d.º[/b]." % [
		mundo.anio, Time.get_ticks_msec() - t0, t[0]["club"].nombre, puesto])
	_partida.autoguardar_si_toca()
	_refrescar()

## Una fila de jugador que se puede pulsar. El botón va en la primera celda y
## ocupa el ancho: así toda la fila responde al clic sin tener que inventar un
## control nuevo ni capturar eventos a mano.
## EL RETRATO DE UN JUGADOR, EN UN SOLO SITIO. Antes cada pantalla lo montaba
## por su cuenta -cuatro trozos de código casi iguales- y por eso la mayoría
## simplemente no lo ponía: en cantera, enfermería, camarín, contratos,
## selección o el árbol genealógico un futbolista era una línea de texto.
##
## Y eso se notaba justo donde más duele: un jugador REAL con su foto de verdad
## encontrada en Commons aparecía con foto en el plantel y sin ella en la
## enfermería, como si fuera otra persona. `Cara.textura()` ya resuelve foto real
## primero y dibujo procedural después; lo único que faltaba era llamarla desde
## todas partes.
func _retrato(j: Jugador, tam: int = 26) -> TextureRect:
	var equipo: Club = mundo.clubes.get(j.club_id)
	var r := TextureRect.new()
	r.texture = Cara.textura(j, equipo.color1 if equipo else "#2b6b45",
		equipo.color2 if equipo else "#ffffff", tam)
	r.custom_minimum_size = Vector2(tam, tam)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _nombres(clubes: Array) -> String:
	var l: Array[String] = []
	for c: Club in clubes:
		l.append(c.nombre)
	return ", ".join(l)

func _nombres_jugadores(l: Array[Jugador]) -> String:
	var n: Array[String] = []
	for j in l:
		n.append(j.nombre)
	return ", ".join(n)

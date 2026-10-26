extends BaseIdea
## LA ENTRADA AL JUEGO (fase 1, 25-10-2026): `OrquestadorEntrada` recorrido entero emitiendo
## `terminado` en cada etapa (sea la pantalla de verdad o su sustituto), y la partida que
## sale de ahí con lo elegido. Sin fundidos (`duracion_fundido = 0`) ni cambio de escena.

var _vistas: Array[String] = []
var _resultado: Dictionary = {}
var _cancelado := false

func _probar() -> void:
	_titulo("FASE 1 · ENTRADA: orquestador de etapas 0-6")
	OrquestadorEntrada.ruta_prefs = "user://f1o_entrada_prueba.cfg"
	OrquestadorMundo.ruta_preferencias = "user://f1o_preferencias_prueba.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorEntrada.ruta_prefs))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorMundo.ruta_preferencias))
	var idioma_antes: String = Idiomas.idioma
	var mujer_antes := Genero.mujer
	_contrato()
	_flujo_reemplazar()
	_volver_y_saltar_intro()
	_flujo_pagar()
	_flujo_club_existente()
	_flujo_jugador()
	Idiomas.idioma = idioma_antes
	Genero.fijar(mujer_antes)
	Principal.mundo_pregenerado = null
	Principal.modo_elegido = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorEntrada.ruta_prefs))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorMundo.ruta_preferencias))

func _nuevo(estado: Dictionary = {}) -> OrquestadorEntrada:
	_vistas.clear()
	_resultado = {}
	_cancelado = false
	OrquestadorEntrada.estado_inicial = estado
	var o := OrquestadorEntrada.new()
	o.cambiar_escena = false
	o.duracion_fundido = 0.0
	o.etapa_cambiada.connect(func(k: String) -> void: _vistas.append(k))
	o.partida_lista.connect(func(r: Dictionary) -> void: _resultado = r)
	o.cancelado.connect(func() -> void: _cancelado = true)
	add_child(o)
	o._empezar()
	return o

## Emite `terminado` en la pantalla que esté, con lo que diga `respuestas` para su etapa.
## Devuelve la lista de etapas por las que pasó (en orden).
func _recorrer(o: OrquestadorEntrada, respuestas: Dictionary, parar_en: String = "") -> Array[String]:
	var pasos: Array[String] = []
	for _i in 12:
		if not _resultado.is_empty() or _cancelado:
			break
		var k := o.etapa_actual()
		if k == parar_en:
			break
		var p := o.pantalla_actual()
		if p == null:
			break
		pasos.append(k)
		p.emit_signal("terminado", (respuestas.get(k, {}) as Dictionary).duplicate(true))
	return pasos

func _contrato() -> void:
	var o := _nuevo()
	for i in OrquestadorEntrada.ETAPAS.size():
		var n := o.crear_pantalla(i)
		var clave := String(OrquestadorEntrada.ETAPAS[i]["clave"])
		_comprobar(n is Control and n.has_signal("terminado") and n.has_signal("volver") and n.has_method("configurar"),
			"la etapa «%s» cumple el contrato (%s)" % [clave, "sustituto" if bool(n.get_meta("sustituto", false)) else "pantalla real"])
		var ruta := String(OrquestadorEntrada.ETAPAS[i]["ruta"])
		if not ResourceLoader.exists(ruta):
			_comprobar(bool(n.get_meta("sustituto", false)), "sin «%s» todavía, va el sustituto" % ruta.get_file())
		n.free()
	## El sustituto confirma con los valores por defecto de su etapa.
	var s: Control = (load(OrquestadorEntrada.SUSTITUTO) as Script).new()
	s.set("clave", "pais")
	s.set("por_defecto", OrquestadorMundo.por_defecto("pais", {}))
	var recibido: Array = []
	s.connect("terminado", func(d: Dictionary) -> void: recibido.append(d))
	s.call("confirmar")
	_comprobar(recibido.size() == 1 and String((recibido[0] as Dictionary).get("pais", "")) == "CHI",
		"el sustituto de país confirma con Chile por defecto")
	s.free()
	o.queue_free()

func _flujo_reemplazar() -> void:
	_linea("-- crear tu club y reemplazar a otro (mundo entero, 24 ligas)")
	var o := _nuevo({"dificultad": "facil"})
	_comprobar(o.etapa_actual() == "intro", "la primera vez arranca con la intro")
	var vp := get_viewport().get_visible_rect().size
	_comprobar(o.size == vp and o.pantalla_actual().size == vp,
		"orquestador y etapa a pantalla completa (%s, %s de %s)" % [o.size, o.pantalla_actual().size, vp])
	var respuestas := {
		"idioma": {"idioma": "en"},
		"modo": {"modo": "creador"},
		"pais": {"pais": "ARG"},
		"config": {"nombre_club": "Club Prueba F1O", "color1": "#112233", "color2": "ddeeff", "estadio": "Estadio F1O",
			"casa": "casa", "fps": 60, "mascota": "Firulais", "densidad": "alta"},
		"entrada": {"entrada": {"tipo": "reemplazar"}},
		"personaje": {"personaje": {"nombre": "Ana Prueba", "aspecto": {"cuerpo": "female", "barba": true}}},
	}
	var pasos := _recorrer(o, respuestas, "entrada")
	## Antes de entrar: a quién reemplazará (sin elegir, el más flojo de la liga más baja) y sus cifras.
	var m0: Mundo = o.estado.get("mundo")
	_comprobar(m0 != null and m0.ligas.size() >= 20, "el mundo entero se generó antes de enseñar países (%d ligas)" % (m0.ligas.size() if m0 else 0))
	var victima := EntradaCampeonato.candidato_sugerido(m0, "ARG") if m0 else null
	var prev := EntradaCampeonato.previsualizar(m0, "reemplazar", "ARG", victima.id) if victima else {}
	var plantel_victima := victima.plantilla.duplicate() if victima else []
	pasos.append_array(_recorrer(o, respuestas))
	_comprobar(pasos == ["intro", "idioma", "modo", "pais", "config", "entrada", "personaje"],
		"recorre las 7 etapas en orden (%s)" % ", ".join(pasos))
	_comprobar(_vistas == pasos, "cada etapa avisa al terminar")
	_comprobar(OrquestadorEntrada.intro_vista(), "la intro queda marcada como vista")
	var cf := ConfigFile.new()
	cf.load(OrquestadorMundo.ruta_preferencias)
	_comprobar(Idiomas.idioma == "en" and String(cf.get_value("juego", "idioma", "")) == "en",
		"el idioma se aplica al momento y se guarda donde lo lee Principal")
	_comprobar(int(cf.get_value("pantalla", "fps", -1)) == 60, "los FPS elegidos quedan en las preferencias")
	Idiomas.idioma = "es"
	_comprobar(String(_resultado.get("escena", "")) == OrquestadorMundo.PRINCIPAL, "termina en Principal")
	var m: Mundo = _resultado.get("mundo")
	_comprobar(m != null and Principal.mundo_pregenerado == m, "la partida pasa a Principal por `mundo_pregenerado`")
	if m == null:
		return
	var c := m.mi_club()
	_comprobar(c != null and c.nombre == "Club Prueba F1O" and c.pais == "ARG", "diriges tu club, en Argentina")
	_comprobar(c != null and c == victima and m.clubes.size() == 384,
		"reemplazar: ocupa la plaza del más flojo de la liga más baja y el mundo sigue con 384 clubes (%d)" % m.clubes.size())
	_comprobar(c != null and not prev.is_empty() and c.rep == int(prev["rep"]) and c.rep == int(prev["rep_reemplazado"]) - 10
		and c.saldo == int(prev["presupuesto"]), "reputación del reemplazado −10 y presupuesto B (rep %d, caja %s)" % [c.rep if c else 0, _dinero(c.saldo if c else 0)])
	_comprobar(c != null and c.color1.to_lower() == "#112233" and c.color2.to_lower() == "#ddeeff" and c.estadio_nombre == "Estadio F1O",
		"colores y estadio del club elegidos")
	_comprobar(m.directiva != null and m.directiva.confianza == 60, "confianza de la directiva 60")
	_comprobar(not plantel_victima.is_empty() and plantel_victima.all(func(j: Jugador) -> bool: return m.libres.has(j) and j.club_id == ""),
		"los %d jugadores del club reemplazado quedan libres" % plantel_victima.size())
	_comprobar(c != null and c.plantilla.size() >= 18, "tu club tiene plantel nuevo (%d)" % (c.plantilla.size() if c else 0))
	_comprobar(m.vida != null and m.vida.vivienda == "casa" and String(m.vida.perfil.get("mascota", "")) == "Firulais",
		"la casa y la mascota de la configuración")
	_comprobar(String((m.roles.look.get("p3d", {}) as Dictionary).get("cuerpo", "")) == "female" and int(m.roles.look.get("barba", 1)) == 0,
		"el aspecto del personaje (3D y retrato: una entrenadora no lleva barba)")
	_comprobar(Principal.dt_nombre_elegido == "Ana Prueba" and Principal.modo_elegido == "dt" and Principal.dificultad_elegida == "facil",
		"nombre, modo y dificultad (la del menú viejo) llegan a Principal")
	_comprobar(String((OrquestadorMundo.ultima_eleccion.get("config", {}) as Dictionary).get("densidad", "")) == "alta"
		and not OrquestadorMundo.ultima_eleccion.has("mundo"), "lo demás de la configuración queda a mano para las fases siguientes")
	## Lo que haría `Principal._arrancar_con()`: el rol no pisa el aspecto ni el nombre.
	m.roles.arrancar(Principal.modo_elegido, Principal.dt_nombre_elegido)
	_comprobar(m.roles.nombre == "Ana Prueba" and m.roles.look.has("p3d"), "al arrancar el rol se conservan nombre y aspecto")
	o.queue_free()

func _volver_y_saltar_intro() -> void:
	_linea("-- volver atrás y la intro solo la primera vez")
	var mini := Mundo.new()
	mini.generar(["CHI", "ARG"], 4242)
	var o := _nuevo({"mundo": mini})
	_comprobar(o.etapa_actual() == "idioma", "con la intro ya vista se empieza por el idioma")
	o.pantalla_actual().emit_signal("terminado", {"idioma": "es"})
	o.pantalla_actual().emit_signal("terminado", {"modo": "creador"})
	o.pantalla_actual().emit_signal("terminado", {"pais": "CHI"})
	_comprobar(o.etapa_actual() == "config", "llega a la configuración")
	_comprobar(o.pantalla_actual().size == o.size, "la etapa de configuración ocupa la pantalla entera")
	var antes := o.pantalla_actual()
	o.pantalla_actual().emit_signal("volver")
	_comprobar(o.etapa_actual() == "pais" and String(o.estado.get("pais", "")) == "CHI",
		"«volver» lleva al país y conserva lo elegido")
	_comprobar(o.get_children().filter(func(n: Node) -> bool: return n.has_signal("terminado") and not n.is_queued_for_deletion()).size() == 1,
		"nunca hay dos pantallas a la vez")
	antes.emit_signal("terminado", {"config": {}})
	_comprobar(o.etapa_actual() == "pais", "una pantalla ya cerrada no puede hacer avanzar el flujo")
	o.pantalla_actual().emit_signal("volver")
	o.pantalla_actual().emit_signal("volver")
	_comprobar(o.etapa_actual() == "idioma", "volviendo dos veces más se llega al idioma, sin pasar por la intro")
	o.pantalla_actual().emit_signal("volver")
	_comprobar(_cancelado and _resultado.is_empty(), "volver desde la primera etapa sale al menú sin crear partida")
	o.queue_free()

func _flujo_pagar() -> void:
	_linea("-- pagar a la confederación: un club más en la liga más baja")
	var mini := Mundo.new()
	mini.generar(["CHI", "ARG"], 777)
	var baja := EntradaCampeonato.liga_mas_baja(mini, "CHI")
	var n_antes := baja.clubes.size()
	var total_antes := mini.clubes.size()
	var prev := EntradaCampeonato.previsualizar(mini, "pagar", "CHI")
	var reps_antes := baja.clubes.map(func(c: Club) -> int: return c.rep)
	var o := _nuevo({"mundo": mini})
	var pasos := _recorrer(o, {
		"idioma": {"idioma": "es"}, "modo": {"modo": {"id": "creador"}}, "pais": {"pais": "CHI"},
		"config": {"config": {"nombre_club": "Afiliados FC"}}, "entrada": {"entrada": "pagar"},
		"personaje": {"personaje": _personaje_real()},
	})
	_comprobar(pasos.has("entrada"), "crear club pasa por la entrada al campeonato")
	_comprobar(o.estado.get("modo") is String and String(o.estado["modo"]) == "creador" and o.estado.has("modo_datos"),
		"un modo que llega como diccionario queda como texto para las pantallas siguientes")
	var m: Mundo = _resultado.get("mundo")
	var c := m.mi_club() if m != null else null
	_comprobar(c != null and c.nombre == "Afiliados FC" and baja.clubes.has(c), "tu club está en la liga más baja")
	_comprobar(baja.clubes.size() == n_antes + 1 and mini.clubes.size() == total_antes + 1, "la liga tiene un club más (%d)" % baja.clubes.size())
	_comprobar(baja.clubes.slice(0, n_antes).map(func(x: Club) -> int: return x.rep) == reps_antes, "los otros clubes no se tocan")
	_comprobar(c != null and c.saldo == int(prev["presupuesto_base"]) - int(round(float(prev["presupuesto_base"]) * 0.25))
		and c.rep == Mundo.REP_FUNDACION - 20, "presupuesto 0,75·B y reputación de recién fundado −20 (caja %s)" % _dinero(c.saldo if c else 0))
	var juega := false
	for j: Array in baja.calendario:
		for par: Array in j:
			if par.has(c):
				juega = true
	_comprobar(juega and baja.tabla_puntos.has(c.id) if c != null else false, "el calendario y la tabla lo incluyen")
	_comprobar(m != null and m.directiva.confianza == 40 and m.prensa.animo == 60 - 15, "confianza 40 y ánimo de la afición −15")
	## La etapa 6 de verdad emite su propio formato (`PersonajeDatos`): se aplica con su «aplicar».
	_comprobar(Principal.dt_nombre_elegido == "Paula Pago" and m != null
		and String((m.roles.look.get("perfil", {}) as Dictionary).get("apellido", "")) == "Pago" and int(m.roles.look.get("edad", 0)) == 51,
		"personaje con nombre completo, edad y perfil (%s)" % Principal.dt_nombre_elegido)
	o.queue_free()

func _personaje_real() -> Dictionary:
	var p: Dictionary = PersonajeDatos.nuevo("CHI")
	p["nombre"] = "paula"
	p["apellido"] = "pago"
	p["edad"] = 51
	(p["aspecto"] as Dictionary)["cuerpo"] = "female"
	return PersonajeDatos.cerrar(p)

func _flujo_club_existente() -> void:
	_linea("-- dirigir un club que ya existe")
	var mini := Mundo.new()
	mini.generar(["CHI", "ARG"], 99)
	var elegido: Club = EntradaCampeonato.liga_mas_baja(mini, "ARG").clubes[3]
	var o := _nuevo({"mundo": mini})
	var pasos := _recorrer(o, {
		"modo": {"modo": "dir"}, "pais": {"pais": "ARG", "club_id": elegido.id},
		"personaje": {"personaje": {"nombre": "Directora"}},
	})
	_comprobar(not pasos.has("entrada"), "sin crear club no hay etapa de entrada al campeonato (%s)" % ", ".join(pasos))
	var m: Mundo = _resultado.get("mundo")
	_comprobar(m != null and m.mi_club_id == elegido.id and m.clubes.size() == mini.clubes.size(), "diriges el club elegido en el globo")
	_comprobar(Principal.modo_elegido == "dir" and Principal.dificultad_elegida == "normal", "modo Director Deportivo, dificultad normal")
	o.queue_free()

func _flujo_jugador() -> void:
	_linea("-- la Carrera de Jugador tiene su propia creación")
	var o := _nuevo()
	var pasos := _recorrer(o, {"modo": {"modo": "carrera-m"}, "idioma": {"idioma": "es"}})
	_comprobar(pasos == ["idioma", "modo"] and String(_resultado.get("escena", "")) == OrquestadorMundo.CARRERA_JUGADOR,
		"tras elegir el modo va a la Carrera de Jugador (%s)" % ", ".join(pasos))
	o.queue_free()

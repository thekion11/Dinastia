extends BaseIdea
## ARRANQUE COMPLETO DE UN JUGADOR NUEVO (onboarding, 26-10-2026): menú de inicio → «Nuevo juego» →
## las 7 etapas de la entrada (`OrquestadorEntrada`, navegación calcada de `f1o_flujo.gd`) → la primera
## pantalla de `Principal` → el primer partido (simulado con «avanzar semana») → dos semanas más.
## Cronometra cada tramo y lo imprime («TIEMPO …»); los errores de consola los caza `ideas.sh`
## (SCRIPT ERROR). Comprueba también la guía de bienvenida y la ayuda «?» de las 5 pantallas densas.

const AJUSTES := "user://ajustes.cfg"
var _resultado: Dictionary = {}

func _probar() -> void:
	OrquestadorMundo.ranura_al_salir = ""   ## no pisar la partida de la máquina (autoguardado de la entrada)
	_titulo("ONBOARDING · ARRANQUE COMPLETO HASTA EL PRIMER PARTIDO")
	## La entrada se prueba hasta Principal; el prólogo 3D de la fase 2 tiene su propia prueba (f2p_prologo).
	OrquestadorMundo.sin_prologo = true
	OrquestadorEntrada.ruta_prefs = "user://onb_entrada_prueba.cfg"
	OrquestadorMundo.ruta_preferencias = "user://onb_preferencias_prueba.cfg"
	_borrar(OrquestadorEntrada.ruta_prefs)
	_borrar(OrquestadorMundo.ruta_preferencias)
	## El tutorial se marca «visto» en los ajustes del jugador: se guardan y se reponen al final.
	var ajustes_antes := FileAccess.get_file_as_string(AJUSTES) if FileAccess.file_exists(AJUSTES) else ""
	_borrar(AJUSTES)
	var idioma_antes: String = Idiomas.idioma
	var mujer_antes := Genero.mujer
	var t0 := Time.get_ticks_msec()
	var t := t0
	# --- 1. el menú de inicio y su botón ------------------------------------------------
	var inicio: Control = (load("res://escenas/inicio.tscn") as PackedScene).instantiate()
	add_child(inicio)
	var empezar: Button = null
	for n: Node in inicio.find_children("*", "Button", true, false):
		if (n as Button).text == Idiomas.t("▶ Empezar"):
			empezar = n
	_comprobar(empezar != null and empezar.is_visible_in_tree(), "el menú de inicio enseña «▶ Empezar»")
	## `_nuevo_juego()` cambia de escena (mataría la prueba): se hace lo mismo que él a mano.
	OrquestadorEntrada.estado_inicial = {"dificultad": String(inicio.get("_dificultad"))}
	inicio.queue_free()
	t = _tramo("menú de inicio", t)
	# --- 2. la entrada entera -------------------------------------------------------------
	var o := OrquestadorEntrada.new()
	o.cambiar_escena = false
	o.duracion_fundido = 0.0
	o.partida_lista.connect(func(r: Dictionary) -> void: _resultado = r)
	add_child(o)
	o._empezar()
	var respuestas := {
		"idioma": {"idioma": "es"}, "modo": {"modo": "creador"}, "pais": {"pais": "CHI"},
		"config": {"nombre_club": "Club Novato ONB"}, "entrada": {"entrada": {"tipo": "reemplazar"}},
		"personaje": {"personaje": {"nombre": "Nora Novata"}},
	}
	var pasos: Array[String] = []
	for _i in 12:
		if not _resultado.is_empty() or o.pantalla_actual() == null:
			break
		var k := o.etapa_actual()
		pasos.append(k)
		var tp := Time.get_ticks_msec()
		o.pantalla_actual().emit_signal("terminado", (respuestas.get(k, {}) as Dictionary).duplicate(true))
		_linea("    etapa %-10s %5d ms" % [k, Time.get_ticks_msec() - tp])
	_comprobar(pasos == ["intro", "idioma", "modo", "pais", "config", "entrada", "personaje"],
		"recorre las 7 etapas de la entrada (%s)" % ", ".join(pasos))
	_comprobar(String(_resultado.get("escena", "")) == OrquestadorMundo.PRINCIPAL and PedidoPartida.mundo_pregenerado != null,
		"la entrada termina en Principal con la partida lista")
	o.queue_free()
	t = _tramo("entrada (7 etapas, con el mundo)", t)
	# --- 3. la primera pantalla de Principal ----------------------------------------------
	var p: Principal = (load("res://escenas/principal.tscn") as PackedScene).instantiate()
	add_child(p)
	_comprobar(p.mundo != null and p.mundo.mi_club() != null and p.mundo.mi_club().nombre == "Club Novato ONB",
		"Principal arranca con tu club")
	var tuto: Variant = p._guia.get("_tutorial")
	_comprobar(tuto is Tutorial and is_instance_valid(tuto), "un jugador nuevo ve el tutorial guiado al llegar")
	if tuto is Tutorial and is_instance_valid(tuto):
		(tuto as Node).queue_free()
	t = _tramo("primera pantalla de Principal", t)
	_ayudas(p)
	# --- 4. el primer partido y dos semanas más -------------------------------------------
	p._autoguardado = false
	var mio := p.mundo.mi_club()
	var liga := p._liga_de(mio)
	var jugados := {"n": 0}
	var oyente := func(_n: int, rs: Array) -> void:
		for r: Dictionary in rs:
			if r["local"] == mio or r["visita"] == mio:
				jugados["n"] += 1
	liga.jornada_terminada.connect(oyente)
	var semanas := 0
	while int(jugados["n"]) == 0 and semanas < 8:
		p._avanzar_semana()
		semanas += 1
	_comprobar(int(jugados["n"]) == 1, "el primer partido de liga se juega (%d semana/s)" % semanas)
	t = _tramo("primer partido (simulado)", t)
	_linea("TIEMPO TOTAL hasta el primer partido: %d ms" % (Time.get_ticks_msec() - t0))
	var sem0 := p.mundo.semana
	p._avanzar_semana()
	p._avanzar_semana()
	_comprobar(p.mundo.semana == sem0 + 2 and int(jugados["n"]) >= 2, "avanza dos semanas más (semana %d, %d partidos)" % [p.mundo.semana, int(jugados["n"])])
	liga.jornada_terminada.disconnect(oyente)
	t = _tramo("dos semanas más", t)
	p.queue_free()
	# --- limpieza ---------------------------------------------------------------------------
	Idiomas.idioma = idioma_antes
	Genero.fijar(mujer_antes)
	PedidoPartida.mundo_pregenerado = null
	PedidoPartida.modo_elegido = ""
	_borrar(OrquestadorEntrada.ruta_prefs)
	_borrar(OrquestadorMundo.ruta_preferencias)
	_borrar(AJUSTES)
	if ajustes_antes != "":
		var f := FileAccess.open(AJUSTES, FileAccess.WRITE)
		f.store_string(ajustes_antes)
		f.close()

## La ayuda «?» de las cinco pantallas densas: aparece en el carril de chips, despliega 2-3 líneas
## traducidas y no sale en las pantallas que no la tienen.
func _ayudas(p: Principal) -> void:
	_linea("-- la ayuda «?» de las pantallas densas")
	for titulo: String in ["Mi plantel", "Táctica", "Finanzas", "Mercado", "Cantera"]:
		p._ir_a_pestana(titulo)
		var b := p._fila_sub.get_node_or_null("AyudaPestana") as Button
		_comprobar(b != null and String(b.get_meta("titulo_ayuda", "")) == titulo, "«%s» tiene su botón «?»" % titulo)
		var n := AyudaPestana.lineas(titulo).size()
		_comprobar(n >= 2 and n <= 3, "«%s»: %d líneas de ayuda" % [titulo, n])
		if b != null:
			var pop := AyudaPestana.abrir(b)
			_comprobar(pop.visible, "«%s»: la nota se despliega" % titulo)
			pop.hide()
	p._ir_a_pestana("Calendario")
	_comprobar(p._fila_sub.get_node_or_null("AyudaPestana") == null, "el calendario no lleva «?» (no hace falta)")
	Idiomas.idioma = "en"
	_comprobar(AyudaPestana.lineas("Finanzas")[0].begins_with("The balance"), "la ayuda sale traducida (inglés)")
	Idiomas.idioma = "es"

func _tramo(que: String, desde: int) -> int:
	var ahora := Time.get_ticks_msec()
	_linea("TIEMPO %-34s %6d ms" % [que, ahora - desde])
	return ahora

func _borrar(ruta: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))

extends Node
## EL TIEMPO HASTA JUGAR, EN LA EXPERIENCIA REAL (10-11-2026, orden del líder): imita lo que hace la interfaz y apunta, en ms desde «pulsar»: cuándo se DIBUJA la pantalla de carga (lo que ve el jugador), cuándo acaba
## de montarse el estadio (`abrir`), cuándo acaban los fotogramas de calentado bajo la carga (`estabilizar`) y cuándo se quita la carga. Con TIEMPOS=1 imprime además cada fase de la construcción (`TIEMPO estadio.…`).
##   MODO=partido  (lo de `partido_vivo_p1._ver_estadio`, hasta que terminan la intro y la ceremonia, o hasta el tope)
##   MODO=club     (lo de `vistas_menu._ver_estadio_con_carga`: «Entrar al estadio» a pie, hasta tener el explorador)
##   PAIS=ESP CLUB=5 herramientas/hw_modesto.sh res://pruebas/medir_hasta_jugar.tscn -- ultrabaja|baja|medio
var _t0 := 0
var _m: Mundo
var _t_pintada := -1
var _carga: Node

func _ms() -> int:
	return Time.get_ticks_msec() - _t0

func _dibujado() -> void:
	if _t_pintada < 0 and _carga != null and is_instance_valid(_carga):
		_t_pintada = _ms()

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ULTRA_BAJA)
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	_m = Mundo.new()
	_m.generar([pais], 4711)
	_m.tomar_el_mando(_m.ligas[0].clubes[int(OS.get_environment("CLUB")) % _m.ligas[0].clubes.size()].id)
	## Como el menú: el calentado de caras y animaciones ya está en marcha desde que se entró.
	PrecalentarCaras.presupuesto_ms = 0.0
	PrecalentarCaras.por_fotograma = 80
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.frame_post_draw.connect(_dibujado)
	if OS.get_environment("MODO") == "club":
		await _club()
	else:
		await _partido()
	get_tree().quit()

func _partido() -> void:
	var par := _m.proximo_partido()
	_t0 = Time.get_ticks_msec()   ## «Jugar partido»
	_carga = PantallaCarga.mostrar(self, Idiomas.t("Levantando el estadio…"))
	await PantallaCarga.dejar_pintar(get_tree())
	var t_pre := _ms()
	var vista := VistaEstadio.new()
	vista.por_partes = true
	add_child(vista)
	await vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	var t_montado := _ms()
	await PantallaCarga.estabilizar(get_tree())
	var t_estab := _ms()
	_carga.cerrar()
	var t_cerrada := _ms()
	## Hasta que terminan la intro y la ceremonia (el jugador puede saltarlas): su duración natural.
	var t_libre := -1
	while _ms() < 120000:
		await get_tree().process_frame
		var intro: Variant = vista.get("_intro")
		var cer: Variant = vista.get("_ceremonia")
		var ocupada: bool = (intro != null and is_instance_valid(intro) and intro.activa) or (cer != null and is_instance_valid(cer) and cer.activa)
		if not ocupada and _ms() > t_cerrada + 500:
			t_libre = _ms()
			break
	print("HASTA_JUGAR partido: carga dibujada a los %d ms · montaje (abrir) listo a los %d ms · calentado bajo la carga listo a los %d ms · carga quitada a los %d ms · intro+ceremonia terminan a los %d ms (saltables) · [empieza a montar a los %d ms]" % [_t_pintada, t_montado, t_estab, t_cerrada, t_libre, t_pre])

func _club() -> void:
	_t0 = Time.get_ticks_msec()   ## «Entrar al estadio»
	_carga = PantallaCarga.mostrar(self, Idiomas.t("Levantando el estadio…"))
	await PantallaCarga.dejar_pintar(get_tree())
	var t_pre := _ms()
	var c := _m.mi_club()
	var vista := VistaEstadio.new()
	vista.por_partes = true
	vista.arrancar_a_pie = true
	vista.datos_pantalla = {}
	add_child(vista)
	await vista.abrir(c, 0.5, null, null, _m.perfil_estadio_de(c), Comercial.color_balon(_m.comercial.balon, c))
	var t_montado := _ms()
	await PantallaCarga.estabilizar(get_tree())
	var t_estab := _ms()
	_carga.cerrar()
	var t_cerrada := _ms()
	var t_pie := -1
	while _ms() < 60000:
		await get_tree().process_frame
		var ex: Variant = vista.get("_explorador")
		if ex != null and is_instance_valid(ex):
			t_pie = _ms()
			break
	print("HASTA_JUGAR club a pie: carga dibujada a los %d ms · montaje (abrir) listo a los %d ms · calentado bajo la carga listo a los %d ms · carga quitada a los %d ms · explorador a pie listo a los %d ms · [empieza a montar a los %d ms]" % [_t_pintada, t_montado, t_estab, t_cerrada, t_pie, t_pre])

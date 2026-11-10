extends BaseIdea
## A4-INT · REPASO 3: 20 vueltas de «jugar la temporada + temporada siguiente» (con las pantallas de fin de temporada cerradas como lo haría un jugador) con la interfaz montada (`avanzar_semana` de Principal), guardando y cargando por el camino: nodos y objetos estables, el registro de noticias acotado, el
## guardado crece poco y carga igual, y la interfaz sigue abriendo todos los menús al final.
var _p: Principal

func _frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame

## Lo que una persona cierra con un clic al acabar la temporada: portadas de prensa, sorteos y cualquier ventana.
func _cerrar_pantallas_de_temporada() -> void:
	for c in _p.get_children():
		if c is Control and not c is Tutorial and c.get_script() != null and (c as Control).mouse_filter == Control.MOUSE_FILTER_STOP and (c as Control).anchor_right == 1.0 and (c as Control).anchor_bottom == 1.0 and (c as Control).visible:
			c.queue_free()
		elif c is EventoPantallaCompleta:   ## (10-11) los eventos a pantalla completa son capas de lienzo (regla del 9-11): sin esto, el que quedaba
			c.queue_free()                  ## abierto al medir hacía de pico (≈ +600 nodos) y parecía que los nodos crecían sin fin
	for w in _p.find_children("*", "Window", true, false):
		if (w as Window).visible:
			(w as Window).hide()
	_p.visible = true

func _probar() -> void:
	_titulo("AUDITORÍA 4 · INTERFAZ · 20 TEMPORADAS")
	_respaldar_user()
	var m := _mundo(20261104)
	PedidoPartida.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _frames(6)
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	CapasTutorial.poner_activas(false)
	_p._autoguardado = false
	var t0 := Time.get_ticks_msec()
	var semanas := 0
	var nodos: Array[int] = []
	var objetos: Array[int] = []
	var tam_guardado: Array[int] = []
	var ms_guardado: Array[int] = []
	var anio0 := m.anio
	var limite_s := float(OS.get_environment("LIMITE_S")) if OS.get_environment("LIMITE_S") != "" else 420.0
	var objetivo_temporadas := int(OS.get_environment("TEMPORADAS")) if OS.get_environment("TEMPORADAS") != "" else 20
	while semanas / 52 < objetivo_temporadas and (Time.get_ticks_msec() - t0) / 1000.0 < limite_s:
		_p._al_elegir_calendario(2)   ## «Jugar la temporada»
		await _frames(2)
		_p._al_elegir_calendario(3)   ## «Temporada siguiente»
		await _frames(2)
		_cerrar_pantallas_de_temporada()
		await _frames(2)
		## (10-11) Y otra vez: al cerrar una se abre la siguiente de la cola (la cinemática de un sorteo, ~820 nodos; la rueda de prensa, ~680).
		## Medidas con una de ellas abierta, los nodos parecían crecer sin fin (884, 1692, 923…, 1619) sin que nada se quedara colgado.
		_cerrar_pantallas_de_temporada()
		await _frames(2)
		semanas += 52
		nodos.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		objetos.append(int(Performance.get_monitor(Performance.OBJECT_COUNT)))
		var t1 := Time.get_ticks_msec()
		Partida.guardar(m, "aud4_largo")
		ms_guardado.append(Time.get_ticks_msec() - t1)
		var f := FileAccess.open(Partida.ruta_de("aud4_largo"), FileAccess.READ)
		tam_guardado.append(f.get_length() if f != null else 0)
		if f != null:
			f.close()   ## (6-11) abierto, en Windows el guardado de la vuelta siguiente no puede renombrarlo y se quedaba el primero (año 2026 de 2029)
	var temporadas := m.anio - anio0
	_linea("  %d semanas (%d temporadas) en %d s; nodos %s; objetos %s; guardado KB %s; ms guardar %s" % [semanas, temporadas, (Time.get_ticks_msec() - t0) / 1000, str(nodos), str(objetos), str(tam_guardado.map(func(b: int) -> int: return b / 1024)), str(ms_guardado)])
	## «Jugar la temporada» se detiene en las decisiones del jugador (ofertas, votos, entrevistas): 20 vueltas a «jugar + siguiente» avanzan unas pocas temporadas, y la interfaz aguanta todas.
	_comprobar(m.anio - anio0 >= 2, "avanzaron al menos 2 temporadas en 20 vueltas de «jugar + siguiente» (%d)" % (m.anio - anio0))
	if nodos.size() >= 4:
		var medio := nodos.size() / 2
		_comprobar(nodos[nodos.size() - 1] - nodos[medio] <= 120, "los nodos no crecen sin fin (de %d a %d en la segunda mitad)" % [nodos[medio], nodos[nodos.size() - 1]])
		_comprobar(objetos[objetos.size() - 1] - objetos[medio] <= 40000, "ni los objetos (de %d a %d)" % [objetos[medio], objetos[objetos.size() - 1]])
		_comprobar(tam_guardado[tam_guardado.size() - 1] <= tam_guardado[medio] * 2, "el guardado no se dispara (%d KB → %d KB)" % [tam_guardado[medio] / 1024, tam_guardado[tam_guardado.size() - 1] / 1024])
	_comprobar(ms_guardado.is_empty() or ms_guardado.max() < 5000, "guardar tarda menos de 5 s (máx %d ms)" % (ms_guardado.max() if not ms_guardado.is_empty() else 0))
	## El registro de «lo que va pasando» no crece sin fin.
	var largo_registro := 0
	if _p._registro != null:
		largo_registro = _p._registro.get_parsed_text().length()
	_comprobar(largo_registro < 200000, "el registro de la pantalla tiene %d caracteres (< 200.000)" % largo_registro)
	## Cargar lo guardado da el mismo mundo.
	var c := Partida.cargar("aud4_largo")
	_comprobar(c != null and c.anio >= m.anio - 1 and c.mi_club().id == m.mi_club().id, "lo guardado se carga (año %d de %d)" % [c.anio if c != null else -1, m.anio])
	## La interfaz sigue entera: todos los menús abren.
	var mal: Array[String] = []
	for mn: Dictionary in MenusLaterales.MENUS:
		var subs: Array = mn["subs"]
		for i in subs.size():
			if (subs[i] as Dictionary).has("accion") or String((subs[i] as Dictionary).get("secc", "")) == "kits":
				continue
			_p._menu_lateral.abrir_menu(String(mn["id"]), i)
			await _frames(4)
			var pm: Variant = _p._menu_lateral.pantalla_abierta
			if not is_instance_valid(pm) or (pm as PantallaMenu).cerrando():
				mal.append("%s/%d" % [mn["id"], i])
			else:
				(pm as PantallaMenu).cerrar()
			await _frames(20)
	_comprobar(mal.is_empty(), "tras %d temporadas se abren los submenús %s" % [temporadas, str(mal.slice(0, 5))])
	Partida.borrar("aud4_largo")
	for e in DirAccess.get_files_at(Partida.CARPETA):
		if e.begins_with("aud4_largo"):
			DirAccess.remove_absolute(Partida.CARPETA + "/" + e)
	_restaurar_user()

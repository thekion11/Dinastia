extends BaseIdea
## EL GUARDADO DEL MENÚ CENTRAL (3-11-2026, rediseño etapa 4): autoguardado SIEMPRE activo (cada día, cada semana, cada partido) en segundo plano, y al
## SALIR (cerrar la ventana / «atrás» de Android) la pregunta «¿Guardar antes de salir?» (Guardar y salir / Salir sin guardar / Cancelar). Sin salir de verdad.

const RANURA := "zz_gua_prueba"

func _esperar_guardado() -> void:
	var n := 0
	while GuardadoSegundoPlano.en_curso() and n < 600:
		await get_tree().process_frame
		n += 1

func _probar() -> void:
	_titulo("GUARDADO: AUTOGUARDADO EN SEGUNDO PLANO Y PREGUNTA AL SALIR")
	load("res://ui/principal/ciclo_partida.gd").ranura_prueba = RANURA
	SalidaGuardada.salir_de_verdad = false
	Partida.borrar(RANURA)
	AvanceSemana.partido_obliga = false   ## (10-11) la prueba recorre días a mano: sin esto, el sábado con partido abre solo el menú del partido (`VidaApp`) y el «atrás» es suyo
	var m := _mundo(3102)
	PedidoPartida.mundo_pregenerado = m
	var pr: Principal = (load("res://escenas/principal.tscn") as PackedScene).instantiate()
	add_child(pr)
	await get_tree().process_frame
	## Con un user:// limpio (el CI) sale el tutorial de la primera vez, y «atrás» lo
	## cierra a él antes que preguntar por salir (A4-MOVIL-008): aquí se cierra antes.
	for t in get_tree().root.find_children("*", "Tutorial", true, false):
		(t as Tutorial)._terminar(false)
	CapasTutorial.poner_activas(false)
	await get_tree().process_frame
	var salida := pr.get_node_or_null("SalidaGuardada") as SalidaGuardada
	_comprobar(bool(pr.get("_autoguardado")), "el autoguardado viene activo por defecto")
	_comprobar(salida != null and not get_tree().auto_accept_quit and not get_tree().quit_on_go_back, "Principal retiene el cierre del juego y el «atrás» (para preguntar)")
	## Cada día: guarda sin bloquear. El hilo principal solo hace la instantánea.
	m.mi_club().mover_saldo(1234)
	pr.call("_avanzar_dia")
	_comprobar(GuardadoSegundoPlano.en_curso() or FileAccess.file_exists(Partida.ruta_de(RANURA)), "al pasar un día se pide guardar (en segundo plano)")
	await _esperar_guardado()
	_comprobar(GuardadoSegundoPlano.ultimo_ok and FileAccess.file_exists(Partida.ruta_de(RANURA)), "y el archivo queda escrito")
	var c1 := Partida.cargar(RANURA)
	_comprobar(c1 != null and c1.mi_club().saldo == m.mi_club().saldo, "se carga con el estado del momento (caja %d)" % m.mi_club().saldo)
	_linea("  hilo principal %d ms · en total %d ms" % [GuardadoSegundoPlano.ms_principal, GuardadoSegundoPlano.ms_total])
	## Pedidos seguidos mientras se escribe: no se apilan, y el último guardado es el estado MÁS NUEVO.
	for i in 4:
		m.mi_club().mover_saldo(1000)
		pr.call("_avanzar_dia")
	await _esperar_guardado()
	var c2 := Partida.cargar(RANURA)
	_comprobar(c2 != null and c2.mi_club().saldo == m.mi_club().saldo, "cuatro días seguidos: queda guardado el último estado (%d)" % m.mi_club().saldo)
	## Guardar a mano espera al autoguardado y no lo pisa con algo más viejo.
	m.mi_club().mover_saldo(7)
	pr.call("_avanzar_dia")
	_comprobar(Partida.guardar(m, RANURA), "guardar a mano (espera al autoguardado en curso)")
	await _esperar_guardado()
	var c3 := Partida.cargar(RANURA)
	_comprobar(c3 != null and c3.mi_club().saldo == m.mi_club().saldo, "y el archivo tiene el estado más nuevo")
	## Cerrar la ventana: pregunta, no sale.
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	await get_tree().process_frame
	var dlg := pr.get_node_or_null("DialogoSalir") as ConfirmationDialog
	_comprobar(dlg != null and dlg.visible, "cerrar la ventana con una partida en marcha abre «¿Guardar antes de salir?»")
	if dlg != null:
		_comprobar(dlg.ok_button_text == Idiomas.t("Guardar y salir") and dlg.cancel_button_text == Idiomas.t("Cancelar"), "con «Guardar y salir» y «Cancelar»")
		var textos: Array[String] = []
		for b in dlg.find_children("*", "Button", true, false):
			textos.append((b as Button).text)
		_comprobar(textos.has(Idiomas.t("Salir sin guardar")), "y «Salir sin guardar» (%s)" % str(textos))
		## «Atrás» de Android con el diálogo abierto: lo cierra (es lo que espera el dedo).
		get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
		await get_tree().process_frame
		_comprobar(not dlg.visible, "«atrás» con el diálogo abierto lo cierra")
		get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
		await get_tree().process_frame
		_comprobar(dlg.visible, "y «atrás» sin diálogo lo abre")
		dlg.hide()
	## Guardar y salir: guarda de verdad (en la prueba no sale del proceso).
	Partida.borrar(RANURA)
	m.mi_club().mover_saldo(99)
	salida.guardar_y_salir()
	var c4 := Partida.cargar(RANURA)
	_comprobar(c4 != null and c4.mi_club().saldo == m.mi_club().saldo, "«Guardar y salir» deja la partida guardada")
	## Si el autoguardado está apagado y no hay desafío, no guarda al pasar un día.
	Partida.borrar(RANURA)
	pr.set("_autoguardado", false)
	pr.call("_avanzar_dia")
	await _esperar_guardado()
	_comprobar(not FileAccess.file_exists(Partida.ruta_de(RANURA)), "con el interruptor de Ajustes apagado no autoguarda")
	pr.queue_free()
	await get_tree().process_frame
	_comprobar(get_tree().auto_accept_quit, "al salir de Principal el árbol vuelve a aceptar el cierre")
	Partida.borrar(RANURA)
	load("res://ui/principal/ciclo_partida.gd").ranura_prueba = ""
	SalidaGuardada.salir_de_verdad = true

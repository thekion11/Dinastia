extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): Escape / «atrás» de Android en el TUTORIAL y el PRÓLOGO, y la música con la app en segundo plano.
##   godot --headless --path . res://pruebas/auditoria_atras_pantallas_limite.tscn
## Tutorial: con el texto escribiéndose, Escape lo completa; después cierra el tutorial (como «Saltar tutorial»). Prólogo: con «¿Saltar el prólogo?» abierta, Escape es «Seguir aquí».
## Música: pasar a segundo plano la pausa donde está (también con un partido abierto) y al volver sigue (sin reiniciar).
var _fallos := 0

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _escape() -> void:
	for pulsa in [true, false]:
		var e := InputEventKey.new()
		e.keycode = KEY_ESCAPE
		e.physical_keycode = KEY_ESCAPE
		e.pressed = pulsa
		Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	await _tutorial()
	await _prologo()
	await _musica()
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

func _tutorial() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var cierres := [0, 0]
	var t := Tutorial.new()
	add_child(t)
	t.terminado.connect(func(completo: bool) -> void: cierres[0] += 1; cierres[1] += 1 if completo else 0)
	t.iniciar(null, "dt", m.mi_club_id)
	await get_tree().process_frame
	_comprobar(t.escribiendo(), "el tutorial empieza escribiendo su texto")
	await _escape()
	_comprobar(is_instance_valid(t) and not t.escribiendo() and cierres[0] == 0, "Escape con el texto escribiéndose lo completa (y no cierra el tutorial)")
	await _escape()
	_comprobar(cierres[0] == 1 and cierres[1] == 0, "otro Escape cierra el tutorial como «Saltar» (cerrado %d vez, completo: %d)" % [cierres[0], cierres[1]])

func _prologo() -> void:
	var hud := PrologoHud.new()
	add_child(hud)
	hud.pedir_saltar()
	_comprobar(hud.confirmando_salto(), "«¿Saltar el prólogo?» está abierta")
	hud.pedir_saltar()
	_comprobar(hud.confirmando_salto(), "pedirla otra vez no la duplica")
	await _escape()
	_comprobar(not hud.confirmando_salto(), "Escape con la pregunta abierta es «Seguir aquí»: la cierra")
	await _escape()   ## sin pregunta, el Escape no hace nada raro en el HUD
	_comprobar(not hud.confirmando_salto(), "Escape sin pregunta no la abre")
	hud.queue_free()

func _musica() -> void:
	var antes: bool = Musica.encendida
	Musica.encendida = true
	Musica.en_segundo_plano(true)
	var v: AudioStreamPlayer = Musica.get("_voz")
	_comprobar(v != null and Musica.en_fondo, "en segundo plano la música queda en pausa donde está")
	Musica.en_segundo_plano(true)
	_comprobar(Musica.en_fondo, "pedirlo dos veces no cambia nada")
	Musica.en_segundo_plano(false)
	_comprobar(not Musica.en_fondo, "al volver la música sigue (sin reiniciar)")
	VidaGlobal.forzar_movil = true
	get_tree().root.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await get_tree().process_frame
	_comprobar(Musica.en_fondo and get_tree().paused, "VidaGlobal: pausa el árbol y la música")
	get_tree().root.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	for i in 4:
		await get_tree().process_frame
	_comprobar(not Musica.en_fondo and not get_tree().paused, "…y al volver reanuda las dos")
	VidaGlobal.forzar_movil = false
	Musica.encendida = antes

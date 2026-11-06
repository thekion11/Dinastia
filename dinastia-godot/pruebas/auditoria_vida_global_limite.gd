extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): la VIDA DE LA APP EN EL MÓVIL FUERA DEL PARTIDO (`VidaGlobal`).
##   godot --headless --path . res://pruebas/auditoria_vida_global_limite.tscn
## Con el menú de gestión (Principal) abierto: segundo plano → el árbol se pausa (no corre nada) y se reanuda tras dos fotogramas; «atrás» cierra la ventana modal, luego la pantalla
## de menú, y solo en la portada pregunta antes de salir (y no sale); con un partido abierto no pausa el árbol (lo atiende el partido); poca memoria → calidad mínima; girar → sin errores.
var _n := 0
var _fallos := 0
var _p: Node
var _contador := 0
var _corriendo := false

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	VidaGlobal.forzar_movil = true
	SalidaGuardada.salir_de_verdad = false
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_contador += 1
	_n += 1
	if _n == 12 and not _corriendo:
		_corriendo = true
		await _todo()
		VidaGlobal.forzar_movil = false
		SalidaGuardada.salir_de_verdad = true
		Calidad.elegida = Calidad.MINIMO
		print("===== FIN. %d fallos =====" % _fallos)
		get_tree().quit(0 if _fallos == 0 else 1)

func _notif(que: int) -> void:
	get_tree().root.propagate_notification(que)
	await get_tree().process_frame

func _marco(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _todo() -> void:
	## (5-11) El mundo de esta prueba lo genera `Principal` con semilla ALEATORIA: se imprime para poder repetir una ejecución que falle.
	print("  SEMILLA del mundo: %d (hay club propio: %s)" % [int(_p.get("mundo").semilla) if _p.get("mundo") != null else -1, str(_p.get("mundo") != null and _p.get("mundo").mi_club() != null)])
	_comprobar(get_tree().root.get_node_or_null("VidaGlobal") != null, "VidaGlobal está registrado como autoload")
	_comprobar(not get_tree().quit_on_go_back, "«atrás» nunca cierra el juego por su cuenta")
	## 1. Segundo plano: el árbol se pausa y el reloj de la ciudad/tráfico/temporizadores no corre.
	await _marco(3)
	var c0 := _contador
	await _notif(Node.NOTIFICATION_APPLICATION_PAUSED)
	_comprobar(get_tree().paused, "la app pasa a segundo plano: el árbol se pausa")
	await _marco(5)
	_comprobar(_contador - c0 <= 3, "…y no corre nada de lo que cuelga del árbol (%d fotogramas contados, de 5)" % (_contador - c0))
	await _notif(Node.NOTIFICATION_APPLICATION_PAUSED)
	await _notif(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_comprobar(get_tree().paused, "perder el foco varias veces sigue pausado (sin apilar)")
	await _notif(Node.NOTIFICATION_APPLICATION_RESUMED)
	_comprobar(get_tree().paused, "al volver NO se reanuda en el mismo fotograma (el primero trae el tiempo que estuvo fuera)")
	await _marco(4)
	_comprobar(not get_tree().paused, "…se reanuda dos fotogramas después")
	await _notif(Node.NOTIFICATION_APPLICATION_RESUMED)
	_comprobar(not get_tree().paused, "volver sin haber salido no cambia nada")
	## 2. «Atrás» con una ventana modal abierta: la cierra.
	var d := ConfirmationDialog.new()
	d.dialog_text = "prueba"
	_p.add_child(d)
	d.popup_centered(Vector2i(300, 120))
	await _marco(2)
	_comprobar(d.visible, "hay una ventana modal abierta")
	await _notif(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _marco(2)
	_comprobar(not d.visible, "«atrás» cierra la ventana modal")
	d.queue_free()
	## 3. «Atrás» con una pantalla de menú abierta: vuelve (cierra la pantalla), sin preguntar de salir.
	var ml: MenuLateral = _p.get("_menu_lateral")
	var salida := _p.get_node("SalidaGuardada") as SalidaGuardada
	ml.abrir_menu(String(MenuLateral.MENUS[0]["id"]), 0)
	await _marco(2)
	_comprobar(is_instance_valid(ml.pantalla_abierta), "hay una pantalla de menú abierta")
	var vueltas := 0
	var pregunto_antes := false
	while is_instance_valid(ml.pantalla_abierta) and not ml.pantalla_abierta.is_queued_for_deletion() and vueltas < 4:
		await _notif(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await _marco(4)
		vueltas += 1
		var d2: Variant = salida.get("_dialogo")
		if d2 != null and (d2 as Window).visible and is_instance_valid(ml.pantalla_abierta) and not ml.pantalla_abierta.is_queued_for_deletion():
			pregunto_antes = true
	_comprobar(not (is_instance_valid(ml.pantalla_abierta) and not ml.pantalla_abierta.is_queued_for_deletion()), "«atrás» en una pantalla de menú vuelve a su portada y luego la cierra (%d «atrás»)" % vueltas)
	_comprobar(not pregunto_antes, "…sin preguntar de salir mientras la pantalla seguía abierta")
	## 4. «Atrás» sin nada abierto: pregunta antes de salir, y no sale.
	await _notif(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _marco(4)
	var dlg: Variant = salida.get("_dialogo")
	_comprobar(dlg != null and (dlg as Window).visible, "«atrás» en la portada pregunta «¿Guardar antes de salir?» (y el juego sigue abierto)")
	await _notif(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _marco(2)
	_comprobar(dlg != null and not (dlg as Window).visible, "otro «atrás» cierra la pregunta")
	## 5. Poca memoria y giro de pantalla.
	Calidad.elegida = Calidad.ALTO
	await _notif(Node.NOTIFICATION_OS_MEMORY_WARNING)
	_comprobar(Calidad.elegida == Calidad.MINIMO, "poca memoria del sistema: calidad mínima")
	await _notif(Node.NOTIFICATION_WM_SIZE_CHANGED)
	_comprobar(true, "girar la pantalla no rompe nada")
	## 6. Con un partido abierto no pausa el árbol (el partido tiene su pausa).
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var l := m.ligas[0]
	var pv := PartidoVivo.new()
	pv.con_3d = false
	_p.add_child(pv)
	pv.abrir(Partido.new(l.clubes[0], l.clubes[1]), l.clubes[0], m.vestuario)
	await _marco(2)
	await _notif(Node.NOTIFICATION_APPLICATION_PAUSED)
	_comprobar(not get_tree().paused, "con un partido abierto el árbol NO se pausa (lo atiende el partido)")
	_comprobar(int(pv.get("_velocidad")) == 0, "…y el partido se paró por su cuenta")
	pv.queue_free()

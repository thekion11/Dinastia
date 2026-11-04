class_name VidaApp
extends Node
## LA VIDA DE LA APP DURANTE UN PARTIDO (caza de fallos, 4-11-2026, orden de la líder: móvil). Se cuelga de cada pantalla de partido (el 3D jugable, el estadio del DT y el simulado
## en vivo) y atiende lo que le pasa a una app de móvil:
##   · pasa a segundo plano / llamada / pantalla bloqueada / pierde el foco → el partido se PAUSA solo (no corre el reloj) y se sueltan los botones táctiles y las direcciones
##     (si no, volvías con el stick «pulsado» y el jugador corriendo solo); al volver NO se reanuda solo: el jugador elige;
##   · botón «atrás» de Android → abre la pausa (nunca cierra el juego sin preguntar: mientras el partido está abierto el árbol no acepta el «atrás» solo);
##   · poca memoria del sistema → calidad mínima al momento;
##   · girar la pantalla / cambiar la ventana → se sueltan los dedos (un dedo apoyado en el stick ya no está donde estaba) y se repinta el mando.
## Es una cuña fina: la lógica de pausa es de cada pantalla (se le pide la suya).
var _host: Control
var _atras_antes := true
## Para las pruebas: cuántas veces se pausó por salir de la app.
var pausas := 0

static func poner(host: Control) -> void:
	if host.get_node_or_null("VidaApp") != null:
		return
	var v := VidaApp.new()
	v.name = "VidaApp"
	v._host = host
	host.add_child(v)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   ## sigue atento aunque el partido esté en pausa
	_atras_antes = get_tree().quit_on_go_back
	get_tree().quit_on_go_back = false

func _exit_tree() -> void:
	var arbol := get_tree()
	if arbol != null:
		arbol.quit_on_go_back = _atras_antes

func _notification(que: int) -> void:
	match que:
		## (Diferido: mientras el árbol reparte la notificación no se pueden colgar hijos, y el menú de pausa es un hijo: sin esto la pausa quedaba puesta pero SIN pantalla.)
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			soltar_dedos()
			pausar.call_deferred()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			atras.call_deferred()
		NOTIFICATION_OS_MEMORY_WARNING:
			poca_memoria()
		NOTIFICATION_WM_SIZE_CHANGED:
			soltar_dedos()

## El botón «atrás» de Android: con el partido en juego abre la pausa; con la pausa abierta la cierra (lo que espera el dedo). Nunca cierra el juego.
func atras() -> void:
	if _host != null and is_instance_valid(_host) and _host.has_method("_alternar_pausa") and _host.get("_pausa") != null and _host.get("_controles") == null:
		_host.call("_alternar_pausa")
	else:
		pausar()

## Pausa la pantalla de partido que cuelga de aquí (cada una a su manera) y suelta los mandos.
func pausar() -> void:
	soltar_dedos()
	if _host == null or not is_instance_valid(_host):
		return
	pausas += 1
	if _host.has_method("_alternar_pausa"):   ## el partido 3D jugable (carrera / «jugar partido»)
		var m: Variant = _host.get("motor")
		if _host.get("_pausa") == null and m != null and String(m.estado) != "fin" and not bool(_host.call("ceremonia_activa")):
			_host.call("_alternar_pausa")
	elif _host.has_method("_poner_velocidad"):   ## el simulado en vivo: velocidad 0 = reloj parado
		if int(_host.get("_velocidad")) != 0:
			_host.call("_poner_velocidad", 0)
	elif _host.get("_juego") != null and _host.get("_juego").get("vel_idx") != null:   ## el estadio del DT
		_host.get("_juego").set("vel_idx", 0)

func soltar_dedos() -> void:
	for a: String in ["jugar_pase", "jugar_tiro", "jugar_pase_largo", "jugar_regate", "jugar_mod", "jugar_cambiar", "jugar_sprint", "jugar_centro"]:
		if InputMap.has_action(a):
			Input.action_release(a)
	if _host != null and is_instance_valid(_host):
		var ct := _host.get_node_or_null("ControlesTactiles")
		if ct != null and ct.has_method("soltar_todo"):
			ct.call("soltar_todo")
			ct.queue_redraw()

## El sistema avisa de poca memoria: calidad mínima ya (lo que se puede quitar sin que el partido se pare).
func poca_memoria() -> void:
	Calidad.elegida = Calidad.MINIMO
	var vp: Variant = _host.get("_vp") if _host != null and is_instance_valid(_host) else null
	if vp is Viewport:
		Calidad.aplicar_viewport(vp as Viewport, Calidad.MINIMO)
	Calidad.aplicar_viewport(get_viewport(), Calidad.MINIMO)

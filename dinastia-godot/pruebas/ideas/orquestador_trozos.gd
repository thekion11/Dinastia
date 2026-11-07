extends Node
## LA ENTRADA GENERA EL MUNDO POR TROZOS (7-11): con fundido (el camino real), al pasar a la primera etapa que enseña clubes el orquestador genera el mundo repartido entre fotogramas
## (la pantalla sigue viva) y luego monta la etapa; el mundo sale completo y la etapa es la pedida.
var _fallos := 0

func _comprobar(ok: bool, msg: String) -> void:
	print("  ", "ok   " if ok else "FALLO ", msg)
	if not ok:
		_fallos += 1

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	OrquestadorEntrada.ruta_prefs = "user://orq_trozos_prueba.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorEntrada.ruta_prefs))
	OrquestadorEntrada.estado_inicial = {}
	var o := OrquestadorEntrada.new()
	o.cambiar_escena = false
	o.duracion_fundido = 0.05
	add_child(o)
	o._empezar()
	for i in 30:
		await get_tree().process_frame
	_comprobar(o.etapa_actual() != "" and not (o.estado.get("mundo") is Mundo), "empezó en una etapa sin clubes (%s) y aún no hay mundo" % o.etapa_actual())
	var pais := o.indice_de("pais")
	var fotogramas := 0
	o._ir_a(pais, true)
	while fotogramas < 3000 and not (o.etapa_actual() == "pais" and o.estado.get("mundo") is Mundo and not o._en_transicion):
		await get_tree().process_frame
		fotogramas += 1
	var m: Variant = o.estado.get("mundo")
	_comprobar(m is Mundo and (m as Mundo).cuantos_jugadores() > 10000, "el mundo salió completo (%d jugadores)" % ((m as Mundo).cuantos_jugadores() if m is Mundo else 0))
	_comprobar(o.etapa_actual() == "pais" and o.pantalla_actual() != null, "y se montó la etapa «país»")
	_comprobar(fotogramas > 20, "se repartió entre fotogramas (%d)" % fotogramas)
	o.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorEntrada.ruta_prefs))
	print(("===== FIN. %d FALLOS =====" if _fallos > 0 else "===== FIN. 0 fallos =====") % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

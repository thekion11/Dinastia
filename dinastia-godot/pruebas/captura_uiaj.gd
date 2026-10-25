extends Node
## CAPTURAS DEL PAQUETE uiaj (ajustes, controles, pausa del DT y estadísticas).
## Un solo arranque del motor, seis fotos con el sufijo SUFIJO (antes/despues):
##   SUFIJO=antes RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_uiaj.tscn
## Sale con código 0 siempre: es para mirar, no para probar.

var _p: Node
var _mundo: Mundo

func _esperar(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _foto(nombre: String) -> void:
	var suf := OS.get_environment("SUFIJO")
	var ruta := "res://pruebas/capturas/uiaj_%s_%s.png" % [nombre, suf if suf != "" else "x"]
	get_viewport().get_texture().get_image().save_png(ruta)
	print("captura guardada: ", ruta)

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _esperar(12)
	_p.call("_elegir_grupo", "ajustes")
	await _esperar(3)
	for secc: String in ["pantalla", "acceso"]:
		_p.set("_secc_ajustes", secc)
		(_p.get("_ui_ajustes") as PantallaAjustes)._pintar_ajustes()
		await _esperar(4)
		_foto("ajustes_" + secc)
	## La pantalla de controles, con el mando y con el teclado.
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p.add_child(raiz)
	var panel := PanelControles.abrir(raiz)
	panel.dispositivo = "xbox"
	panel._pestana = "p1"
	panel._pintar()
	await _esperar(40)
	_foto("controles_xbox")
	panel.dispositivo = "teclado"
	panel._pestana = "p0"
	panel._pintar()
	await _esperar(20)
	_foto("controles_teclado")
	panel.queue_free()
	await _esperar(2)
	## La pausa del DT y las estadísticas, con un partido a medias de verdad.
	_mundo = _p.get("mundo")
	var par := _mundo.proximo_partido()
	var pa := Partido.new(par[0], par[1])
	pa.preparar()
	for i in 60:
		pa.simular_minuto()
	var ev := EstadisticasVivo.new()
	for i in 9:
		ev.anotar_tiro(i % 3 != 0, Vector2(randf_range(-20, 20), randf_range(25, 48) * (1.0 if i % 3 != 0 else -1.0)), 5 + i * 6)
		ev.cerrar_tiro(i % 3 != 0, ["atajada", "fuera", "gol"][i % 3])
	for i in 200:
		ev.anotar_calor(i % 2, Vector2(randf_range(-30, 30), randf_range(-50, 50)))
	var club: Club = _mundo.mi_club()
	var dt := PanelDTPartido.abrir(raiz, pa, club if (pa.local == club or pa.visita == club) else pa.local, null,
		func() -> void: pass, func() -> void: pass)
	await _esperar(10)
	_foto("pausa_dt")
	dt.queue_free()
	PanelEstadisticas.abrir(raiz, pa, null, ev)
	await _esperar(40)
	_foto("estadisticas")
	get_tree().quit()

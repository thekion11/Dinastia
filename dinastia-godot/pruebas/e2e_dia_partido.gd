extends Node
## EL DÍA DE PARTIDO DE EXTREMO A EXTREMO (17-11-2026, Auditoría). Con la pantalla principal de verdad y tres clubes de tres países (orden 34):
##   menú central → «Avanzar» hasta el día de partido → «Jugar partido» → previa → uniforme alternativo y cámara → plan de juego (otra formación y
##   otro titular) → Confirmar → partido jugable (C4) unos minutos con entradas simuladas → pausa → táctica y cambios (un cambio de verdad) → reanudar →
##   simular el resto → resultado final (tarjetas y goleadores) → repetición de los goles → «Jugar desde el minuto N» → vuelta → popup «Partido jugado»
##   → menú central con la tabla y el último resultado al día.
## En cada paso se comprueba que lo elegido se aplicó DE VERDAD (el uniforme en el 3D, la formación en el motor, el cambio en el acta, el resultado en la
## liga) y, al volver al menú, que no quedan nodos huérfanos ni sube la memoria. Los pasos los da `E2EPasos` (pruebas/e2e_dia_partido_pasos.gd).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/e2e_dia_partido.tscn      (SOLO=0|1|2: un club)

var p: Principal
var fallos := 0
var _prefs_antes: Variant = null
var resumen: Array = []

func ok(cond: bool, texto: String) -> bool:
	print(("  ok     " if cond else "  FALLO  ") + texto)
	if not cond:
		fallos += 1
	return cond

func esperar(n := 10) -> void:
	for i in n:
		await get_tree().process_frame

## Espera hasta que `cond` sea cierta (como mucho `seg` segundos de reloj). Devuelve si se cumplió.
func hasta(cond: Callable, seg := 30.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(seg * 1000.0):
		if cond.call():
			return true
		await get_tree().process_frame
	return bool(cond.call())

## El primer nodo vivo de una clase (por nombre de clase de script o de motor) bajo `raiz`.
func buscar(raiz: Node, clase: String) -> Node:
	for n: Node in raiz.find_children("*", "", true, false):
		if n.is_queued_for_deletion():
			continue
		var s: Script = n.get_script()
		if (s != null and s.get_global_name() == clase) or n.get_class() == clase:
			return n
	return null

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("hace falta pantalla (xvfb): el menú del partido y el 3D no se abren sin ella")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	if FileAccess.file_exists(CajonAjustes.RUTA):
		_prefs_antes = FileAccess.get_file_as_bytes(CajonAjustes.RUTA)
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	EleccionPartido.fijar_preguntar(true)
	p = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await esperar(60)
	var pasos = load("res://pruebas/e2e_dia_partido_pasos.gd").new(self)
	var clubes: Array = pasos.elegir_clubes()
	var solo := OS.get_environment("SOLO")
	for i in clubes.size():
		if solo != "" and int(solo) != i:
			continue
		await pasos.dia_de_partido(clubes[i])
	print("RESUMEN")
	for r: String in resumen:
		print("  " + r)
	print("===== FIN. %d fallos =====" % fallos)
	_devolver_preferencias()
	get_tree().quit(0 if fallos == 0 else 1)

func _devolver_preferencias() -> void:
	if _prefs_antes is PackedByteArray:
		var f := FileAccess.open(CajonAjustes.RUTA, FileAccess.WRITE)
		if f != null:
			f.store_buffer(_prefs_antes)
			f.close()

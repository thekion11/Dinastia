extends Node
## LAS TRANSICIONES DEL PARTIDO, MEDIDAS (17-11-2026, Auditoría: «barridos de color, nunca un corte seco, < 300 ms»). Con tres clubes de países
## distintos: previa → partido (Confirmar), partido → descanso, descanso → segunda parte (Continuar), partido → final y final → lo siguiente
## (Continuar). En cada una: hay barrido, la pantalla estaba TAPADA del todo cuando se cambió lo de debajo y el barrido entero dura < 300 ms.
## FOTOS=1 guarda una foto a mitad de un barrido en CAPTURA_DIR (barrido_<país>.jpg).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/prueba_barridos_partido.tscn

const MAX_MS := 300
var _fallos := 0
var _medidas: Array = []

class VivoFalso extends Node:
	var partido: Partido
	var mi_club: Club
	var segunda := false
	func _salir_segunda() -> void: segunda = true

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no hay barridos (el cambio es inmediato)")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	for cfg: Array in [["POR", 3], ["MEX", 6], ["JPN", 9]]:
		var m := Mundo.new()
		var ps: Array[String] = [String(cfg[0])]
		m.generar(ps, 950 + int(cfg[1]))
		var liga: Liga = m.ligas[0]
		m.tomar_el_mando(liga.clubes[int(cfg[1]) % liga.clubes.size()].id)
		var mio := m.mi_club()
		var rival: Club = liga.clubes[(int(cfg[1]) + 2) % liga.clubes.size()]
		var p := Partido.new(mio, rival)
		await _caso(String(cfg[0]), p, mio, liga)
	print("MEDIDAS (ms hasta tapar / en total):")
	for t: String in _medidas:
		print("  " + t)
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

## Espera a que el barrido en marcha termine y comprueba lo medido.
func _medir(pais: String, que: String) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 3000 and not get_tree().root.find_children("*", "BarridoPartido", false, false).is_empty():
		await get_tree().process_frame
	await get_tree().process_frame
	var u := BarridoPartido.ultima
	_medidas.append("%s %-28s %3d / %3d ms (montar lo de debajo, tapado: %d ms; fotograma más lento %d ms)" % [pais, que, int(u.get("cubrir_ms", -1)), int(u.get("total_ms", -1)), int(u.get("cambio_ms", -1)), int(u.get("cuadro_max_ms", -1))])
	_comprobar(not u.is_empty() and not u.has("sin_pantalla"), "[%s %s] hay barrido" % [pais, que])
	_comprobar(bool(u.get("tapado", false)), "[%s %s] la pantalla estaba tapada del todo al cambiar (nunca un corte seco)" % [pais, que])
	## En un equipo con GPU el fotograma es de ~16 ms; aquí (sin GPU) de 40-100: se descuentan como mucho DOS fotogramas (uno por punta del tween).
	var neto := int(u.get("total_ms", 9999)) - 2 * int(u.get("cuadro_max_ms", 0))
	_comprobar(int(u.get("disenado_ms", 9999)) <= 250 and (int(u.get("total_ms", 9999)) < MAX_MS or neto < MAX_MS - 40),
		"[%s %s] dura %d ms (diseño %d; fotograma más lento %d ms; sin los fotogramas lentos, < %d)" % [pais, que, int(u.get("total_ms", -1)), int(u.get("disenado_ms", -1)), int(u.get("cuadro_max_ms", -1)), MAX_MS])
	BarridoPartido.ultima = {}

func _foto(nombre: String) -> void:
	if OS.get_environment("FOTOS") != "1":
		return
	var dir := OS.get_environment("CAPTURA_DIR") if OS.get_environment("CAPTURA_DIR") != "" else "user://"
	get_viewport().get_texture().get_image().save_jpg(dir.path_join(nombre + ".jpg"), 0.88)

func _caso(pais: String, p: Partido, mio: Club, liga: Liga) -> void:
	## previa → partido
	var menu := MenuPartido.mostrar(self, p, mio, liga, {})
	for i in 10:
		await get_tree().process_frame
	var elegido := [false]
	menu.elegido.connect(func(_e: Variant) -> void: elegido[0] = true)
	menu.confirmar()
	await get_tree().create_timer(BarridoPartido.CUBRIR * 0.95).timeout
	await _foto("barrido_%s" % pais)
	await _medir(pais, "previa → partido")
	_comprobar(elegido[0], "[%s] la previa elige (el partido empieza) bajo el barrido" % pais)
	menu.queue_free()
	## partido → descanso → segunda parte
	p.preparar()
	while p.minuto < 45:
		p.simular_minuto()
	var vivo := VivoFalso.new()
	vivo.partido = p
	vivo.mi_club = mio
	add_child(vivo)
	var d := DescansoPartido.mostrar(vivo)
	await _medir(pais, "partido → descanso")
	_comprobar(d.visible, "[%s] el descanso se ve al destapar" % pais)
	d._continuar()
	await _medir(pais, "descanso → segunda parte")
	_comprobar(vivo.segunda, "[%s] «Continuar» sale a la segunda parte" % pais)
	vivo.queue_free()
	## partido → final → lo siguiente
	while not p.terminado_ya:
		p.simular_minuto()
	var r := ResultadoPartido.mostrar(self, p, mio)
	await _medir(pais, "partido → final")
	_comprobar(r.visible, "[%s] el final se ve al destapar" % pais)
	var salida := [""]
	r.elegido.connect(func(op: String) -> void: salida[0] = op)
	r._seguir()
	await _medir(pais, "final → menú")
	_comprobar(salida[0] == "0", "[%s] «Continuar» del final sigue" % pais)
	r.queue_free()
	await get_tree().process_frame

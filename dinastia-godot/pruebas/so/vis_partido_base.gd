extends "res://pruebas/so/vis_base.gd"
## Monta el partido 3D real (VistaEstadio, como `medir_partido`), salta la intro y la ceremonia, deja correr unos fotogramas con la cámara de TV
## (la REAL del partido: lejos, no de cerca) y fotografía. Lo comparten las pruebas de Forward+ y de Compatibilidad.
const CALENTAR := 45
var vista: VistaEstadio

func _montar_partido() -> void:
	Calidad.elegida = Calidad.MEDIO
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var par := m.proximo_partido()
	vista = VistaEstadio.new()
	add_child(vista)
	vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	var n := 0
	while n < CALENTAR:
		await get_tree().process_frame
		var intro: Variant = vista.get("_intro")
		if intro != null and is_instance_valid(intro) and intro.activa:
			intro.terminar()
			continue
		var cer: Variant = vista.get("_ceremonia")
		if cer != null and is_instance_valid(cer) and cer.activa:
			cer.terminar()
			continue
		n += 1
		if n == 5:
			(vista.get("_rig") as CameraRig).switch_to(0)

func _probar_partido(nombre: String, metodo_esperado: String) -> void:
	_titulo("VISUALIZACIÓN · partido con la cámara real, %s [%s]" % [metodo_esperado, sistema()])
	_comprobar(DisplayServer.get_name() != "headless", "hay pantalla (no es --headless): %s" % DisplayServer.get_name())
	_comprobar(_metodo() == metodo_esperado, "el renderizador es %s (es %s)" % [metodo_esperado, _metodo()])
	await _montar_partido()
	await _frames(3)
	var img := _foto()
	_no_vacia(img, nombre)
	var rig := vista.get("_rig") as CameraRig
	_comprobar(rig != null and get_viewport().get_camera_3d() != null, "hay una cámara 3D activa")
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		_comprobar(cam.global_position.length() > 8.0, "la cámara está lejos del césped, como la de TV (a %.0f m del origen)" % cam.global_position.length())
	_guardar(img, nombre)
	_comparar(img, nombre)
	vista.queue_free()
	await _frames(2)

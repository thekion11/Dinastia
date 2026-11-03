extends Node
## Revisión de la oclusión del entorno del estadio en MÍNIMO (R2 del 3-11): para cada cámara del partido, la misma imagen con el entorno oculto por `EntornoOclusion` y con el entorno forzado a verse; si difieren, esa cámara ve el exterior y hay un hueco.
##   OUT=/ruta xvfb-run -a godot --path . --rendering-driver vulkan --resolution 960x540 res://pruebas/captura_oclusion_estadio.tscn
var _vista: VistaEstadio
var _n := 0
var _cam := 0
var _fase := 0
var _k := 0
var _img_a: Image
var _out := "/tmp"
var _oc: EntornoOclusion

func _ready() -> void:
	process_priority = 1000
	_out = OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp"
	Calidad.elegida = Calidad.MINIMO
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
		return
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
		return
	var rig: CameraRig = _vista.get("_rig")
	if rig == null or _n < 30:
		return
	if _oc == null:
		_oc = _vista.find_children("EntornoOclusion", "", true, false)[0] if not _vista.find_children("EntornoOclusion", "", true, false).is_empty() else null
		if _oc == null:
			print("SIN EntornoOclusion (¿no es MÍNIMO o el estadio es abierto?)")
			get_tree().quit()
			return
	if _cam >= rig.cameras.size():
		get_tree().quit()
		return
	if _fase == 0:
		rig.switch_to(_cam)
		_oc.set_process(true)
		_k = 0
		_fase = 1
		return
	_k += 1
	if _fase == 1 and _k == 8:
		_img_a = get_viewport().get_texture().get_image()
		_oc.set_process(false)
		_oc.entorno.visible = true
		_k = 0
		_fase = 2
	elif _fase == 2 and _k == 4:
		var b := get_viewport().get_texture().get_image()
		var dif := 0
		for y in range(0, _img_a.get_height(), 2):
			for x in range(0, _img_a.get_width(), 2):
				if _img_a.get_pixel(x, y).is_equal_approx(b.get_pixel(x, y)) == false:
					dif += 1
		var tot := (_img_a.get_height() / 2) * (_img_a.get_width() / 2)
		print("OCLUSION cámara %d «%s»: %d de %d píxeles difieren (%.2f %%)  oculto=%s" % [_cam, rig.camera_names[_cam], dif, tot, 100.0 * dif / tot, str(_oc.tapado(rig.cameras[_cam].global_position))])
		_img_a.save_png("%s/ocl_%d_con.png" % [_out, _cam])
		b.save_png("%s/ocl_%d_sin.png" % [_out, _cam])
		_oc.entorno.visible = not _oc.tapado(rig.cameras[_cam].global_position)
		_cam += 1
		_fase = 0

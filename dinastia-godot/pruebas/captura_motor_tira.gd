extends Node
## Tira de fotogramas del partido con el motor real, con la cámara cercana:
## para mirar animaciones (conducir, recorrer atrás, golpeos, controles).
## Salida: pruebas/capturas/motor_tira.png
var _n := 0
var _vista: VistaEstadio
var _fotos: Array[Image] = []

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		return
	var rig: CameraRig = _vista.get("_rig")
	if _n == 20 and rig != null:
		var i := rig.camera_names.find(OS.get_environment("CAMARA") if OS.get_environment("CAMARA") != "" else "Tele Dinámica")
		if i >= 0:
			rig.switch_to(i)
	## Avanza a un ritmo fijo: 1/30 s de juego por fotograma.
	for k in 2:
		motor.paso(1.0 / 60.0)
	if _n >= 60 and (_n - 60) % 6 == 0 and _fotos.size() < 12:
		var img := get_viewport().get_texture().get_image()
		img.resize(640, 360)
		_fotos.append(img)
	if _fotos.size() >= 12:
		var hoja := Image.create(640 * 3, 360 * 4, false, _fotos[0].get_format())
		for k in _fotos.size():
			hoja.blit_rect(_fotos[k], Rect2i(0, 0, 640, 360), Vector2i((k % 3) * 640, (k / 3) * 360))
		hoja.save_png("res://pruebas/capturas/motor_tira.png")
		print("TIRA guardada")
		get_tree().quit()

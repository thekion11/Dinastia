extends Node
## LOS OCHO ESTILOS NUEVOS DE ESTADIO (25-9-2026), cada uno en su foto con la
## cámara general. `pruebas/estadio_<clave>.png` y una hoja con los ocho,
## `pruebas/capturas/estadios_nuevos.png`.
##
##   godot --path . --rendering-driver opengl3 --resolution 960x540 \
##         res://pruebas/captura_estadios_nuevos.tscn

const CLAVES := ["montana", "retro", "futurista", "campus", "oasis", "muralla", "jardin", "tormenta"]
var _i := 0
var _n := 0
var _vista: VistaEstadio
var _club: Club
var _rival: Club
var _imgs: Array[Image] = []

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	_club = m.ligas[0].clubes[0]
	_rival = m.ligas[0].clubes[1]
	_abrir()

func _abrir() -> void:
	if _vista != null:
		_vista.queue_free()
	var ep := EstadioPropio.new()
	var p := ep.preset(CLAVES[_i])
	var perfil := ep.perfil(_club)
	for k: String in (p["cambios"] as Dictionary):
		perfil[k] = p["cambios"][k]
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(_club, 0.85, _rival, null, perfil)
	_n = 0

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		var rig: CameraRig = _vista.get("_rig")
		if rig != null:
			rig.switch_to(maxi(0, rig.camera_names.find("Dron orbital")))
	if _n == 18:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/estadio_%s.png" % CLAVES[_i])
		img.resize(480, 270)
		_imgs.append(img)
		_i += 1
		if _i >= CLAVES.size():
			var hoja := Image.create(480 * 4, 270 * 2, false, Image.FORMAT_RGBA8)
			for k in _imgs.size():
				hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 4) * 480, (k / 4) * 270))
			hoja.save_png("res://pruebas/capturas/estadios_nuevos.png")
			get_tree().quit()
			return
		_abrir()

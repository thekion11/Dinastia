extends Node
## La celebración de un título (idea 327): corro con la copa, vuelta olímpica y panorámica. → /tmp/celebracion_<n>.png
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_celebracion.tscn
const MOMENTOS := [2.0, 5.8, 12.0, 20.0, 30.0, 37.0]
var _n := 0
var _vista: VistaEstadio
var _mundo: Mundo
var _cel: CelebracionTrofeo
var _sig := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 2026)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), 1.0, null, null, _mundo.perfil_estadio_de(_mundo.mi_club()))

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		_cel = CelebracionTrofeo.iniciar(_vista._raiz3d, _mundo.mi_club(), "Liga de Chile", _vista)
	if _cel != null and is_instance_valid(_cel):
		if _sig < MOMENTOS.size() and _cel._t >= float(MOMENTOS[_sig]):
			get_viewport().get_texture().get_image().save_png("/tmp/celebracion_%d.png" % _sig)
			print("t=%.1f capi=%s cam=%s" % [_cel._t, (_cel._capi["nodo"] as Node3D).global_position, _cel._cam.global_position])
			_sig += 1
	elif _sig > 0 and (_cel == null or not is_instance_valid(_cel)):
		get_tree().quit()
	if _n > 4000:
		get_tree().quit()

extends Node
## Matas de pasto del Drive en los parques: a la altura de una persona y desde la cámara alta del paseo.
## PASTO_DRIVE=0 apaga el pasto (captura «antes»).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_pasto.tscn → /tmp/pasto_<antes|despues>_<n>.png
var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo
var _parques: Array[Vector3] = []

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad, _mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)

func _process(_d: float) -> void:
	_n += 1
	var cam: Camera3D = _vista.get("_camara")
	if _n == 10:
		_vista.set_process(false)
		for p: Dictionary in (_vista.get("_ciudad") as CityBuilder).puntos_clic:
			if String(p["k"]).begins_with("ciudad_parque"):
				_parques.append(p["pos"])
		print("parques: ", _parques.size(), " matas: ", PastoCiudad.total_sembradas)
	if _n >= 12 and not _parques.is_empty():
		var tag := "antes" if OS.get_environment("PASTO_DRIVE") == "0" else "despues"
		var c := _parques[0]
		var vistas := [
			[c + Vector3(-20, 1.7, 22), c + Vector3(-4, 0.4, 8)],
			[c + Vector3(-34, 14.0, 36), c + Vector3(0, 0, 0)],
			[c + Vector3(-9, 1.0, 12), c + Vector3(-14, 0.2, 5)],
		]
		var i := (_n - 12) / 6
		if (_n - 12) % 6 == 0 and i < vistas.size():
			cam.global_position = vistas[i][0]
			cam.look_at(vistas[i][1], Vector3.UP)
		if (_n - 12) % 6 == 4 and i < vistas.size():
			get_viewport().get_texture().get_image().save_png("/tmp/pasto_%s_%d.png" % [tag, i])
			print("COSTE %s vista %d: %d triángulos, %d llamadas, %d matas sembradas" % [tag, i, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), PastoCiudad.total_sembradas])
		if i >= vistas.size():
			get_tree().quit()

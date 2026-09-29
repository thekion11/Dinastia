extends Node
## LOS OCHO ESTILOS NUEVOS DEL ESTADIO (25-9-2026, plan maestro B6), vistos
## desde fuera -fachada, techo, focos y exterior- y juntos en una hoja de 4x2.
##   godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/captura_estilos_b6.tscn
## Por fotogramas: sin tarjeta gráfica cada uno tarda casi medio segundo.

var _mundo: Mundo
var _cam: Camera3D
var _raiz: Node3D
var _i := -1
var _frame := 0
var _fotos: Array[Image] = []
var _presets: Array = []

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	_presets = EstadioPropio.PRESETS_B6
	_cam = Camera3D.new()
	add_child(_cam)

func _montar(i: int) -> void:
	if _raiz != null:
		_raiz.queue_free()
	_raiz = Node3D.new()
	add_child(_raiz)
	var c := _mundo.mi_club()
	var e := EstadioPropio.new()
	var cambios: Dictionary = _presets[i][3]
	for k: String in cambios:
		e.ajustes[k] = cambios[k]
	var perfil := e.perfil(c)
	perfil["niveles"] = int(cambios.get("niveles", 2))
	perfil["aforo"] = int(perfil["niveles"]) * 26000
	Ambience.apply(_raiz, perfil, null, Calidad.elegida)
	StadiumBuilder.build_pitch(_raiz, perfil, c)
	StadiumBuilder.build(_raiz, perfil, int(perfil["aforo"]), 0.85, c._hash_id(), c)
	var g := StadiumBuilder.geom_de_forma(String(perfil["forma"]))
	var alto := StadiumBuilder.altura_de(perfil, int(perfil["aforo"]))
	## Desde fuera, por la esquina de las taquillas y la tienda.
	_cam.fov = 58.0
	_cam.position = Vector3(float(g["dx"]) * 1.35, alto + 34.0, float(g["dz"]) * 1.55 + 30.0)
	_cam.look_at(Vector3(0, alto * 0.4, float(g["dz"]) * 0.35), Vector3.UP)
	_cam.current = true
	print("%s · fachada %s · techo %s · luz %s" % [_presets[i][0], perfil["fachada"], perfil["techo"], perfil["luzFocos"]])

func _process(_d: float) -> void:
	_frame += 1
	if _frame % 6 != 1:
		return
	if _i >= 0:
		var img := get_viewport().get_texture().get_image()
		img.resize(480, 270)
		_fotos.append(img)
	_i += 1
	if _i >= _presets.size():
		var hoja := Image.create(480 * 4, 270 * 2, false, _fotos[0].get_format())
		for k in _fotos.size():
			hoja.blit_rect(_fotos[k], Rect2i(0, 0, 480, 270), Vector2i((k % 4) * 480, (k / 4) * 270))
		hoja.save_png("res://pruebas/capturas/estilos_b6.png")
		get_tree().quit()
		return
	_montar(_i)

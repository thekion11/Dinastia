extends Node
## EL TÚNEL DE VERDAD Y EL ESTADIO A PIE (7-10-2026). Recorre de verdad (con
## `ExploradorEstadio.paso()`) del vestuario a la cancha y saca 6 fotos en una
## hoja: `pruebas/capturas/tunel_recorrido.png`.
##
##   godot --path . --rendering-driver opengl3 --resolution 960x540 \
##         res://pruebas/captura_tunel_recorrido.tscn
##   FORMA=oval TUNEL=esquina ... (opcional)

var _vista: VistaEstadio
var _imgs: Array[Image] = []
var _n := 0
var _fase := 0
var _ex: ExploradorEstadio

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var club: Club = m.ligas[0].clubes[0]
	var ep := EstadioPropio.new()
	var perfil := ep.perfil(club)
	perfil["forma"] = OS.get_environment("FORMA") if OS.get_environment("FORMA") != "" else "cuenco"
	perfil["tunel"] = OS.get_environment("TUNEL") if OS.get_environment("TUNEL") != "" else "central"
	perfil["niveles"] = 2
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, perfil)

## Camina `seg` segundos con la entrada `e` (en pasos de 1/30 s).
func _caminar(e: Vector2, seg: float, corre := false) -> void:
	for i in int(seg * 30.0):
		_ex.paso(e, corre, 1.0 / 30.0)
	_ex._colocar_camara(1.0)

func _foto() -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(480, 270)
	_imgs.append(img)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
		_ex = _vista._explorador
		print("zona inicial: ", _ex.zona_en(_ex.cuerpo.position).get("nombre", "?"))
	if _n == 14:
		_foto()                                    # 1: vestuario
		_caminar(Vector2(-0.6, 0), 0.4)
		_caminar(Vector2(0, 1), 4.0)
	if _n == 20:
		_foto()                                    # 2: hacia la puerta del túnel
		## Que mire recto por el pasillo y avance por él.
		_ex.rumbo = PI
		_ex.cuerpo.position.x = float(_ex._datos["x0"])
		_caminar(Vector2(0, 1), 3.0)
	if _n == 26:
		_foto()                                    # 3: dentro del túnel
		## Hasta la boca, caminando: sin pasarse.
		while _ex.cuerpo.position.z > float(_ex._datos["z_boca"]) + 1.2:
			_ex.paso(Vector2(0, 1), true, 1.0 / 30.0)
		_ex._colocar_camara(1.0)
	if _n == 32:
		_foto()                                    # 4: en la boca, la cancha delante
		_caminar(Vector2(0, 1), 3.5, true)
		print("zona tras salir: ", _ex.zona_en(_ex.cuerpo.position).get("nombre", "?"), " z=", _ex.cuerpo.position.z)
	if _n == 38:
		_foto()                                    # 5: ya en el campo
		## Darse la vuelta y mirar el túnel desde la cancha.
		_ex.set_physics_process(false)
		_ex.camara.position = Vector3(float(_ex._datos["x0"]) + 7.0, 3.2, float(_ex._datos["z_boca"]) - 11.0)
		_ex.camara.look_at(Vector3(float(_ex._datos["x0"]), 2.6, float(_ex._datos["z_boca"]) + 2.0), Vector3.UP)
	if _n == 44:
		_foto()                                    # 6: el túnel visto desde la cancha
		var hoja := Image.create(480 * 3, 270 * 2, false, Image.FORMAT_RGBA8)
		for k in _imgs.size():
			hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 3) * 480, (k / 3) * 270))
		hoja.save_png("res://pruebas/capturas/tunel_recorrido.png")
		print("HOJA OK")
		get_tree().quit()

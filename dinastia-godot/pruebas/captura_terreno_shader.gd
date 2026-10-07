extends Node
## Prueba del shader de ladera (12-9-2026): una foto apuntando a la zona de
## lomas del terreno (más allá de `LLANO_RADIO+LLANO_TRANSICION`, donde el
## relieve deja de ser plano), para comprobar a ojo que las pendientes
## empinadas se ven de roca/tierra y no de césped estirado.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_terreno_shader.tscn

var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo

var _cam: Camera3D

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad,
		_mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)
	_vista.call("alternar_ciclo")
	_vista.set("_hora", 12.5)
	_vista.call("_aplicar_hora")

	## Barre el radio buscando la pendiente MAS empinada de verdad (no una
	## posicion fija a ciegas), comparando la altura del terreno cada 6 m a
	## lo largo del eje +X.
	var ciudad3d: Node = _vista.get("_ciudad")
	var mejor_r := 900.0
	var mejor_pend := 0.0
	var r := 650.0
	while r < 2400.0:
		var h0: float = ciudad3d.call("altura_en", r, 0.0)
		var h1: float = ciudad3d.call("altura_en", r + 6.0, 0.0)
		var pend: float = absf(h1 - h0)
		if pend > mejor_pend:
			mejor_pend = pend
			mejor_r = r
		r += 6.0
	print("pendiente mas fuerte en radio=%.0f (delta=%.2f en 6 m)" % [mejor_r, mejor_pend])

	## Camara propia, pegada al suelo justo en ese punto, mirando a lo largo
	## de la ladera -no la orbital de `VistaCiudad`, que mira al centro-.
	var y0: float = ciudad3d.call("altura_en", mejor_r, 0.0)
	_cam = Camera3D.new()
	_cam.fov = 60.0
	var raiz3d: Node3D = _vista.get("_raiz3d")
	raiz3d.add_child(_cam)
	_cam.global_position = Vector3(mejor_r - 40.0, y0 + 6.0, -60.0)
	_cam.look_at(Vector3(mejor_r + 20.0, y0 - 10.0, 40.0), Vector3.UP)
	_cam.current = true

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/terreno_ladera.png")
		print("captura terreno_ladera guardada")
		get_tree().quit()

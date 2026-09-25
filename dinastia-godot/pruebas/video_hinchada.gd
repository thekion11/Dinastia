extends Node
## Video corto de la grada, para ver el MOVIMIENTO del público (23-9-2026).
##
##   godot --path . --rendering-driver opengl3 --resolution 960x540 \
##         --fixed-fps 30 --write-movie salida\hinchada.avi \
##         res://pruebas/video_hinchada.tscn
##
## Una foto no puede probar que la hinchada se mueve. El balanceo y los saltos
## viven en `visor/hinchada.gdshader` y dependen de `TIME`, así que la única
## verificación honesta es una grabación -misma técnica que ya documenta
## `reference-godot-write-movie` en la memoria del proyecto-.
##
## La cámara se planta cerca de la tribuna, a la altura de las primeras filas:
## es el plano donde el público se ve grande y donde un público congelado
## canta más.

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _cam: Camera3D
var _frame := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.9, par[1], _partido)
	_cam = Camera3D.new()
	add_child(_cam)

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 4:
		## Después de que el `CameraRig` haya elegido la suya, si no se la
		## queda él (el mismo tropiezo que ya documenta `captura_pantalla_
		## gigante.gd`).
		## Encuadre que enseña la tribuna DE ABAJO ARRIBA: hace falta para ver
		## a la vez el movimiento (que se nota de cerca) y que el público llega
		## hasta la última fila (que solo se nota si entra el borde de arriba).
		_cam.fov = 52.0
		_cam.position = Vector3(10.0, 6.0, 26.0)
		_cam.look_at(Vector3(42.0, 13.0, 40.0), Vector3.UP)
		_cam.current = true
	if _frame > 4 and _cam != null:
		_cam.current = true
	## ~5 s a 30 fps fijos.
	if _frame >= 150:
		print("FIN. 0 fallos")
		get_tree().quit()

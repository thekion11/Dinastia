extends Node
## Verifica a ojo el arreglo de "las esquinas tambien llevan gente" (22-9-2026,
## pedido directo del usuario: "Falta un tramo" al ver las capturas del
## banquillo/butacas reales). Las 4 esquinas de un estadio "cuenco" (u oval/
## caldera/ingles/herradura) deben verse con gente, no con un bloque de
## hormigon liso.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_esquina_estadio.tscn

var _vista: VistaEstadio
var _mundo: Mundo
var _frame := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var mio := _mundo.mi_club()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(mio, 0.85)
	print("club: %s" % mio.nombre)

	## Vista de pajaro apuntando a la esquina sur-este (dx-3, dz-3), desde
	## afuera del recinto para ver el bloque completo, no solo su cara
	## interior.
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 55.0
	cam.position = Vector3(78.0, 32.0, 88.0)
	cam.look_at(Vector3(46.0, 9.0, 65.0), Vector3.UP)
	cam.current = true

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 25:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_esquina_estadio.png")
		print("captura guardada: pantalla_esquina_estadio.png (%dx%d)" % [img.get_width(), img.get_height()])
		print("FIN. 0 fallos")
		get_tree().quit()

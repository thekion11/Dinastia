extends Node
## Verifica el arreglo de _banquillos_detalle() en stadium_builder.gd (X/Z
## cambiados: el banquillo quedaba metido en el area en vez de en la banda,
## junto al circulo central). Camara elevada apuntando al lateral de la
## cancha donde deberian estar los dos banquillos ahora.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         --position 0,0 res://pruebas/verificar_banca.tscn

var _vista: VistaEstadio

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 55)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 55, 0.01)
	add_child(cam)
	cam.look_at(Vector3(0, 0, 0), Vector3(0, 0, -1))
	cam.current = true

func _process(_d: float) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://pruebas/capturas/verificar_banca.png")
	print("FIN. 0 fallos")
	get_tree().quit(0)

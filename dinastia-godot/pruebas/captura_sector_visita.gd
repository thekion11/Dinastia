extends Node
## M-021: el sector visitante en el fondo −Z (colores del rival y franja vacía).
##   herramientas/captura.sh res://pruebas/captura_sector_visita.tscn
var _vista: VistaEstadio
var _n := 0

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	print("LOCAL ", (par[0] as Club).color1, " ", (par[0] as Club).color2, "  VISITA ", (par[1] as Club).color1, " ", (par[1] as Club).color2)

func _process(_d: float) -> void:
	for k in ["_intro", "_ceremonia"]:
		var x: Variant = _vista.get(k)
		if x != null and is_instance_valid(x) and x.activa:
			x.terminar()
			return
	_n += 1
	if _n == 20:
		var raiz: Node3D = _vista.get("_raiz3d")
		var cam := Camera3D.new()
		raiz.add_child(cam)
		cam.global_position = Vector3(0, 9, -30)
		cam.look_at(Vector3(0, 7, -70))
		cam.fov = 70.0
		cam.current = true
		_vista.set_process(false)
	if _n == 24:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/sector_visita.png")
		print("FOTO sector_visita")
		get_tree().quit()

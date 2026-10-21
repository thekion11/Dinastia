extends Node
## La directiva en el palco (21-10-2026, M-040): presidente y dos directivos de
## traje en la segunda fila de la tribuna principal, en un partido de verdad.
##   herramientas/captura.sh res://pruebas/captura_directiva.tscn
var _vista: VistaEstadio
var _n := 0
var _cam: Camera3D

func _ready() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.95, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var raiz: Node3D = _vista.get("_raiz3d")
		var gente := raiz.find_children("Directiva_*", "", true, false)
		print("DIRECTIVA ", gente.size())
		if gente.is_empty():
			get_tree().quit()
			return
		var p: Vector3 = (gente[1] as Node3D).global_position
		_cam = Camera3D.new()
		raiz.add_child(_cam)
		_cam.global_position = p + Vector3(-6.0, 1.2, 1.5)
		_cam.look_at(p + Vector3(0, 0.6, 0))
		_cam.fov = 40.0
		_cam.current = true
		_vista.set_process(false)
	if _n == 16:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/directiva_palco.png")
		print("FOTO")
		get_tree().quit()

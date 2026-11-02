extends Node
## Pasada visual en el PARTIDO (peinados del Drive y postura de la ciudad en los futbolistas): cámara real de TV y un plano cercano.
## Antes: SIN_PELO_DRIVE=1 SIN_POSTURA=1. → /tmp/pelopart_<A|B>_<n>.png (n = 0 TV, 1 cerca, 2 cerca otro jugador)
var _n := 0
var _vista: VistaEstadio

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
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
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _process(_d: float) -> void:
	_n += 1
	var etiqueta := "A" if OS.get_environment("SIN_PELO_DRIVE") != "" else "B"
	if _n == 150:
		get_viewport().get_texture().get_image().save_png("/tmp/pelopart_%s_0.png" % etiqueta)
	if _n == 155:
		## Balón parado: se congela el partido para que el plano cercano sea el mismo jugador en el antes y el después.
		_vista.process_mode = Node.PROCESS_MODE_DISABLED
	if _n == 160 or _n == 200:
		var motor: MotorJugable = _vista.get("_motor")
		var elegidos: Array = []
		for p: Dictionary in motor.jugadores:
			if not bool(p["por"]) and bool(p["es_local"]):
				elegidos.append(p)
		var p: Dictionary = elegidos[3 if _n == 160 else 7]
		var nodo: Node3D = p["node"]
		var cam := Camera3D.new()
		add_child(cam)
		cam.global_position = nodo.global_position + nodo.global_transform.basis.z * 2.2 + Vector3(0, 1.75, 0)
		cam.fov = 35.0
		cam.look_at(nodo.global_position + Vector3(0, 1.65, 0), Vector3.UP)
		cam.make_current()
		set_meta("cam", cam)
	if _n == 170 or _n == 210:
		get_viewport().get_texture().get_image().save_png("/tmp/pelopart_%s_%d.png" % [etiqueta, 1 if _n == 170 else 2])
		(get_meta("cam") as Camera3D).queue_free()
	if _n == 212:
		get_tree().quit()

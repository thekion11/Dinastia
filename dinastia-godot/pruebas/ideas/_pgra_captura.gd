extends Node
## CAPTURAS DE LA GRADA Y EL EXTERIOR (pgra, 26-10-2026): con la vista REAL del
## partido (VistaEstadio + CameraRig) y tomas fijas por fuera. Imprime el coste
## (llamadas de dibujo y triángulos del fotograma) de cada toma.
##   CLIMA=dia|noche SUFIJO=_antes herramientas/captura.sh res://pruebas/ideas/_pgra_captura.tscn
## (empieza por «_»: ideas.sh todo no la corre; no es una prueba).
var _vista: VistaEstadio
var _n := 0
var _cam: Camera3D
var _tomas: Array = []

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	var mundo := Mundo.new()
	mundo.generar(["CHI"], int(OS.get_environment("SEMILLA")) if OS.get_environment("SEMILLA") != "" else 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	## GRANDE=1: el club de más reputación de la liga (techo de anillo, más bandejas).
	if OS.get_environment("GRANDE") != "":
		var mejor: Club = mundo.ligas[0].clubes[0]
		for cl: Club in mundo.ligas[0].clubes:
			if cl.rep > mejor.rep:
				mejor = cl
		mundo.mi_club_id = mejor.id
	var par := mundo.proximo_partido()
	var c: Club = par[0] if par[0].id == mundo.mi_club_id else par[1]
	var rival: Club = par[1] if c == par[0] else par[0]
	var perfil := c.perfil_estadio()
	var clima := OS.get_environment("CLIMA")
	perfil["clima"] = clima if clima != "" else "dia"
	## TECHO=anillo: el mismo estadio con cubierta (para ver el techo desde la tele).
	if OS.get_environment("TECHO") != "":
		perfil["techo"] = OS.get_environment("TECHO")
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(c, 0.9, rival, Partido.new(c, rival), perfil)
	var g := StadiumBuilder.geom_de_forma(String(perfil["forma"]))
	var niv := StadiumBuilder.niveles_de(perfil, int(perfil.get("aforo", 20000)))
	var hx := float(g["dx"]) + StadiumBuilder.fondo_tribuna(niv) + 10.0
	var hz := float(g["dz"]) + StadiumBuilder.fondo_tribuna(niv) + 10.0
	var alto := StadiumBuilder.altura_de(perfil, int(perfil.get("aforo", 20000)))
	print("PERFIL forma=%s niveles=%d techo=%s alto=%.1f hx=%.1f hz=%.1f" % [perfil["forma"], niv, perfil["techo"], alto, hx, hz])
	## [nombre, rig (índice de cámara) o -1, desde, mira, fov]
	_tomas = [
		["1_tv", 0, Vector3.ZERO, Vector3.ZERO, 0.0],
		["2_principal", 1, Vector3.ZERO, Vector3.ZERO, 0.0],
		["3_tribuna", -1, Vector3(-12.0, 8.0, 6.0), Vector3(float(g["dx"]) + 12.0, alto * 0.55, -4.0), 62.0],
		["4_llegada", -1, Vector3(hx + 30.0, 1.7, hz + 26.0), Vector3(hx * 0.3, alto * 0.45, hz * 0.2), 62.0],
		["5_fuera", -1, Vector3(hx + 95.0, 48.0, hz + 80.0), Vector3(0.0, 6.0, 0.0), 50.0],
		["6_dron", 9, Vector3.ZERO, Vector3.ZERO, 0.0],
	]
	var solo := OS.get_environment("TOMAS")
	if solo != "":
		_tomas = _tomas.filter(func(t: Array) -> bool: return solo.split(",").has(String(t[0]).substr(0, 1)))

func _process(_d: float) -> void:
	for k in ["_intro", "_ceremonia"]:
		var x: Variant = _vista.get(k)
		if x != null and is_instance_valid(x) and x.activa:
			x.terminar()
			return
	_n += 1
	var i := (_n - 30) / 8
	if _n < 30:
		return
	if i >= _tomas.size():
		get_tree().quit()
		return
	var t: Array = _tomas[i]
	if (_n - 30) % 8 == 0:
		var rig: CameraRig = _vista.get("_rig")
		if int(t[1]) >= 0:
			if _cam != null:
				_cam.current = false
			_vista.set_process(true)
			if rig != null:
				rig.set_process(true)
				rig.switch_to(int(t[1]))
		else:
			_vista.set_process(false)
			if rig != null:
				rig.set_process(false)
			if _cam == null:
				_cam = Camera3D.new()
				_cam.far = 3000.0
				(_vista.get("_raiz3d") as Node3D).add_child(_cam)
			_cam.global_position = t[2]
			_cam.look_at(t[3])
			_cam.fov = float(t[4])
			_cam.current = true
			## Por fuera se ve TODO el techo (la vista lo esconde ante sus cámaras).
			for n in get_tree().get_nodes_in_group("techo_estadio"):
				(n as GeometryInstance3D).layers = 1
	if (_n - 30) % 8 == 6:
		var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var tri := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var obj := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
		print("COSTE %s %s: llamadas=%d triangulos=%d objetos=%d" % [t[0], OS.get_environment("CLIMA"), dc, tri, obj])
		var clima := OS.get_environment("CLIMA")
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/pgra_%s_%s%s.png" % [t[0], clima if clima != "" else "dia", OS.get_environment("SUFIJO")])
		print("FOTO ", t[0])

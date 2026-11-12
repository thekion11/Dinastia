extends Node3D
## LAS ACCIONES DEL PARTIDO, CONGELADAS (sesión 14, 12-11): una fila de futbolistas (creados como en el partido,
## clubes de 3 países) y cada uno con un clip; se fotografía el mismo instante de todos a 0,0 / 0,15 / … s.
##   CLIPS=cabezazo,cabezazo_potente,entrada_de_pie SUFIJO=x herramientas/captura.sh res://pruebas/captura_acciones.tscn
## `DESFASE=0,0.3,…`: segundos que se adelanta el clip de cada uno; `BALON=x,y,z`: un balón en ese punto (el instante del contacto).
## `LEJOS=1`: cámara a la distancia de la de TV (para ver si se lee). Salida: pruebas/capturas/acciones_<SUFIJO>_<n>.png
## `TIEMPOS=0,1,2…` cambia los instantes (s).
var TIEMPOS := [0.0, 0.15, 0.3, 0.45, 0.6, 0.8, 1.1, 1.5]
var _n := 0
var _k := 0
var _cam: Camera3D
var _jug: Array = []
var _clips: Array = []

func _ready() -> void:
	if OS.get_environment("TIEMPOS") != "":
		TIEMPOS = Array(OS.get_environment("TIEMPOS").split(",")).map(func(x: String) -> float: return float(x))
	_clips = Array((OS.get_environment("CLIPS") if OS.get_environment("CLIPS") != "" else "cabezazo,cabezazo_potente,pase_cabeza,entrada_de_pie,barrida_real").split(","))
	var paises: Array[String] = ["ENG", "ARG", "JPN"]
	var m := Mundo.new()
	m.generar(paises, 4711)
	_cam = Camera3D.new()
	add_child(_cam)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.25, 0.42, 0.25)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.57, 0.6)
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 35, 0)
	sol.shadow_enabled = true
	add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.2, 0.45, 0.18)
	suelo.material_override = ms
	add_child(suelo)
	var sp := PlayerSpawner.new()
	var clubes: Array = []
	for l: Liga in m.ligas:
		clubes.append(l.clubes[2 % l.clubes.size()])
	for i in _clips.size():
		var c: Club = clubes[i % clubes.size()]
		var kit := Puente3D.kit(c)
		sp._kit_x = kit["x"]
		var j: Jugador = c.plantel()[3 + i]
		var datos := Puente3D.jugador(j)
		var look: Array = PlayerSpawner._look_de(datos)
		var nodo := sp._crear_jugador(self, j.id, j.pos, "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]),
			5 + i, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
		var n3 := nodo["nodo"] as Node3D
		n3.position = Vector3((i - (_clips.size() - 1) * 0.5) * 1.6, 0, 0)
		n3.rotation_degrees.y = float(OS.get_environment("GIRO")) if OS.get_environment("GIRO") != "" else 60.0
		nodo["node"] = n3
		nodo["id"] = j.id
		var ap: AnimationPlayer = nodo["anim"]
		var clip := String(_clips[i])
		var esq := FutbolistaQ.esqueleto_de(n3)
		if not ap.has_animation(clip):
			AnimExtra.asegurar(ap, esq, clip)
		if not ap.has_animation(clip) and clip.begins_with("cmu_"):
			LeagueAcciones._cmu(nodo, clip)
			clip = "ext_" + clip
		print("clip ", i, " ", clip, " existe=", ap.has_animation(clip), " dur=", ap.get_animation(clip).length if ap.has_animation(clip) else 0.0)
		_jug.append([nodo, clip])
	if OS.get_environment("BALON") != "":
		var c := OS.get_environment("BALON").split(",")
		for i in _clips.size():
			var bola := MeshInstance3D.new()
			var esf := SphereMesh.new()
			esf.radius = 0.11
			esf.height = 0.22
			bola.mesh = esf
			add_child(bola)
			bola.position = (_jug[i][0]["node"] as Node3D).position + Vector3(float(c[0]), float(c[1]), float(c[2]))
	var ancho := _clips.size() * 1.6
	if OS.get_environment("LEJOS") != "":
		_cam.position = Vector3(0, 19, 30)
		_cam.fov = 28
		_cam.look_at(Vector3(0, 0.9, 0))
	else:
		_cam.position = Vector3(0, 1.3, maxf(ancho * 1.25, 5.0))
		_cam.fov = 36
		_cam.look_at(Vector3(0, 1.0, 0))
	_posar(0.0)

func _posar(tt: float) -> void:
	var desfase := Array(OS.get_environment("DESFASE").split(",", false))
	for k in _jug.size():
		var par: Array = _jug[k]
		var tk := tt + (float(desfase[k]) if k < desfase.size() else 0.0)
		var nodo: Dictionary = par[0]
		var ap: AnimationPlayer = nodo["anim"]
		if ap.has_animation(String(par[1])):
			ap.play(String(par[1]), 0.0)
			ap.seek(minf(tk, ap.get_animation(String(par[1])).length - 0.001), true)

func _process(_d: float) -> void:
	_n += 1
	if _n < 10:
		return
	if (_n - 10) % 3 == 0:
		_posar(float(TIEMPOS[_k]))
	elif (_n - 10) % 3 == 2:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/acciones_%s_%d.png" % [OS.get_environment("SUFIJO"), _k])
		_k += 1
		if _k >= TIEMPOS.size():
			get_tree().quit()

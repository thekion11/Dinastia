extends Node3D
## Intermedias del original construidas (fase 4c, 10-11, `LeagueAuto`): 3 filas (de parado a trote girando 90° a la izquierda; su
## espejo, a la derecha; de trote a trote con el cuerpo pasando a 135°), 6 instantes del clip, vistas desde arriba y delante; los
## jugadores miran a +X al empezar. Dos clubes de países distintos (orden 34). Salida: CAPTURA_DIR/auto_league.jpg
##   herramientas/captura.sh res://pruebas/_sonda/captura_auto_league.tscn
var _n := 0
var _cuerpos: Array = []
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["ESP", "ARG"], 77)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.65, 0.75)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, 30, 0)
	sol.shadow_enabled = true
	add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 10)
	suelo.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.5, 0.25)
	suelo.material_override = mat
	add_child(suelo)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 9.0, 11.0)
	cam.fov = 42
	add_child(cam)
	cam.look_at(Vector3(0, -0.5, 0))
	var clubes: Array = [m.ligas[0].clubes[2], m.ligas[m.ligas.size() - 1].clubes[4]]
	var sp := PlayerSpawner.new()
	var clips := ["ls_auto__idleD000__dribbleD000__90", "ls_auto__idleD000__dribbleD000__90_espejo", "ls_auto__dribbleD000__dribbleD135__45"]
	var datos_clip := {}
	for c0: Dictionary in LeagueMovimiento.clips():
		if String(c0["nombre"]) in clips:
			datos_clip[String(c0["nombre"])] = c0
	for fila in 3:
		var c: Club = clubes[fila % 2]
		var kit := Puente3D.kit(c)
		sp._kit_x = kit["x"]
		var j: Jugador = c.plantel()[6]
		var datos := Puente3D.jugador(j)
		var look: Array = PlayerSpawner._look_de(datos)
		for k in 6:
			var nodo := sp._crear_jugador(self, j.id, "MC", "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 8, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
			var n3 := nodo["nodo"] as Node3D
			n3.position = Vector3(-6.25 + k * 2.5, 0.0, -3.0 + fila * 3.0)
			n3.rotation.y = PI * 0.5
			var ap: AnimationPlayer = nodo["anim"]
			var clip: String = clips[fila]
			if datos_clip.has(clip) and not ap.has_animation(clip):
				print("CONSTRUIDA ", clip, " ", LeagueAuto.construir(datos_clip[clip], ap, String(ap.get_animation("correr").track_get_path(0)).get_slice(":", 0)))
			var largo := ap.get_animation(clip).length if ap.has_animation(clip) else 1.0
			print("CLIP ", clip, " existe=", ap.has_animation(clip), " largo=", largo, " club=", c.nombre, " (", c.pais, ")")
			_cuerpos.append([ap, clip, largo * float(k) / 6.0])
func _process(_d: float) -> void:
	_n += 1
	for c: Array in _cuerpos:
		var ap: AnimationPlayer = c[0]
		if not ap.has_animation(String(c[1])):
			continue
		if ap.current_animation != String(c[1]):
			ap.play(String(c[1]))
		ap.seek(float(c[2]), true)
		ap.pause()
	if _n == 30:
		var dir := OS.get_environment("CAPTURA_DIR") if OS.get_environment("CAPTURA_DIR") != "" else "user://"
		get_viewport().get_texture().get_image().save_jpg(dir.path_join("auto_league.jpg"), 0.9)
		get_tree().quit()

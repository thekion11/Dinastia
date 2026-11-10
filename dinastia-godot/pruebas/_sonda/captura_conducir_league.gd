extends Node3D
## Conducir de lado (fase 4c, 10-11): fila 1 nuestro «conducir», fila 2 «conducir_ls» (5 m/s), fila 3 «conducir_ls_rapido» (7 m/s),
## 6 instantes del ciclo; las filas alternan jugadores de DOS clubes de países distintos (orden 34). Salida: CAPTURA_DIR/conducir_league.jpg
##   herramientas/captura.sh res://pruebas/_sonda/captura_conducir_league.tscn
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
	cam.position = Vector3(0, 0.0, 13.5)
	cam.fov = 42
	add_child(cam)
	cam.look_at(Vector3(0, 0.0, 0))
	var clubes: Array = [m.ligas[0].clubes[2], m.ligas[m.ligas.size() - 1].clubes[4]]
	var sp := PlayerSpawner.new()
	var clips := ["conducir", "conducir_ls", "conducir_ls_rapido"]
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
			n3.position = Vector3(-6.25 + k * 2.5, 2.4 - fila * 2.4, 0)
			n3.rotation.y = PI * 0.5
			var ap: AnimationPlayer = nodo["anim"]
			var clip: String = clips[fila]
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
		get_viewport().get_texture().get_image().save_jpg(dir.path_join("conducir_league.jpg"), 0.9)
		get_tree().quit()

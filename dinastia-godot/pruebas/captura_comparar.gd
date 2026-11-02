extends Node3D
## Comparar un gesto nuestro con uno de League-Soccer (01-11), de lado: arriba el nuestro desde su inicio, abajo el de League-Soccer
## desde CONTACTO−0,3 s; 6 instantes cada `PASO` s. NUESTRO=pase LS=ls_pass__sprint__000 CONTACTO=0.27 PASO=0.12 SALIDA=pase
##   herramientas/captura.sh res://pruebas/captura_comparar.tscn
var _n := 0
var _cuerpos: Array = []
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
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
	pm.size = Vector2(20, 8)
	suelo.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.5, 0.25)
	suelo.material_override = mat
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.6, 11.5)
	cam.fov = 40
	add_child(cam)
	cam.look_at(Vector3(0, 0.6, 0))
	var c: Club = m.clubes.values()[0]
	var sp := PlayerSpawner.new()
	var kit := Puente3D.kit(c)
	sp._kit_x = kit["x"]
	var j: Jugador = c.plantel()[5]
	var datos := Puente3D.jugador(j)
	var look: Array = PlayerSpawner._look_de(datos)
	var nuestro := OS.get_environment("NUESTRO")
	var ls := OS.get_environment("LS")
	var contacto := float(OS.get_environment("CONTACTO"))
	var paso := float(OS.get_environment("PASO")) if OS.get_environment("PASO") != "" else 0.12
	for fila in 2:
		for k in 6:
			var nodo := sp._crear_jugador(self, j.id, "DEL", "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 10, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
			var n3 := nodo["nodo"] as Node3D
			n3.position = Vector3(-6.25 + k * 2.5, 1.3 - fila * 2.5, 0)
			n3.rotation.y = PI * 0.5
			var ap: AnimationPlayer = nodo["anim"]
			var esq := FutbolistaQ.esqueleto_de(n3)
			var clip := nuestro if fila == 0 else ls
			if not ap.has_animation(clip):
				if not AnimExtra.asegurar(ap, esq, clip):
					AnimExtra.unir(ap, esq, clip, AnimExtra.BARRIDA_REAL) if clip == "barrida_real" else null
			var t0 := 0.0 if fila == 0 else maxf(contacto - 0.3, 0.0)
			_cuerpos.append([ap, clip, t0 + paso * k])

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
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/comparar_%s.png" % OS.get_environment("SALIDA"))
		get_tree().quit()

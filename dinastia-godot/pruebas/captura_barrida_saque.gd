extends Node3D
## Tira de fotogramas (de lado) de la barrida de la UAL2 (`AnimExtra.BARRIDA_REAL`), del saque de mano del portero y de la
## caída por falta seguida del levantarse de la UAL2 (31-10).
##   herramientas/captura.sh res://pruebas/captura_barrida_saque.tscn
var _n := 0
var _cuerpos: Array = []
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.25, 0.42, 0.28)
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
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.4, 10.5)
	cam.fov = 40
	add_child(cam)
	cam.look_at(Vector3(0, 1.0, 0))
	var c: Club = m.clubes.values()[0]
	var sp := PlayerSpawner.new()
	var kit := Puente3D.kit(c)
	sp._kit_x = kit["x"]
	var j: Jugador = c.plantel()[3]
	var datos := Puente3D.jugador(j)
	var look: Array = PlayerSpawner._look_de(datos)
	var tiempos := [[0.15, 0.5, 0.85, 1.15, 1.5, 1.75], [0.1, 0.35, 0.6, 0.85, 1.05, 1.3], [0.6, 9.0, 0.05, 0.5, 0.95, 1.4]]
	for fila in 3:
		for k in 6:
			var nodo := sp._crear_jugador(self, j.id, "DEL", "", Color(kit["c1"]), Color(kit["c2"]), String(kit["estilo"]), 10, look[0], look[1], look[2], Color(0, 0, 0, 0), datos)
			var n3 := nodo["nodo"] as Node3D
			n3.position = Vector3(-5.0 + k * 2.0, 2.6 - fila * 2.3, 0)
			n3.rotation_degrees.y = 90.0
			var ap: AnimationPlayer = nodo["anim"]
			var esq := FutbolistaQ.esqueleto_de(n3)
			var clip := "barrida_real" if fila == 0 else ("saque_mano" if fila == 1 else ("caida_lesion" if k < 2 else "levantarse_suelo"))
			if fila == 2:
				AnimExtra.asegurar(ap, esq, "levantarse_suelo")
			elif fila == 0:
				AnimExtra.unir(ap, esq, clip, AnimExtra.BARRIDA_REAL)
			else:
				AnimExtra.asegurar(ap, esq, clip)
			_cuerpos.append([ap, clip, tiempos[fila][k]])
func _process(_d: float) -> void:
	_n += 1
	for c: Array in _cuerpos:
		var ap: AnimationPlayer = c[0]
		if ap.current_animation != String(c[1]):
			ap.play(String(c[1]))
		ap.seek(float(c[2]), true)
		ap.pause()
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/barrida_saque.png")
		get_tree().quit()

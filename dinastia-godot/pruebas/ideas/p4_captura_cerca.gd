extends Node3D
## CAPTURA DE CERCA DE LOS PERSONAJES (calidad visual P4, 27-10-2026), en Forward+:
##   herramientas/captura.sh res://pruebas/ideas/p4_captura_cerca.tscn
## Tres peatones (`PeatonQ`, semillas fijas) con la luz de día: la cara a 0,6 m y el cuerpo
## entero a 3 m. Sale en pruebas/capturas/p4_cerca_{cara,cuerpo}.jpg. Solo mira; no cambia nada.

var _cam: Camera3D

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/p4_cerca_%s.png" % nombre)
	print("captura ", nombre)

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var cielo := Sky.new()
	cielo.sky_material = ProceduralSkyMaterial.new()
	e.background_mode = Environment.BG_SKY
	e.sky = cielo
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.ssao_enabled = true
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-42.0, 35.0, 0.0)
	sol.light_energy = 1.3
	sol.shadow_enabled = true
	add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.55, 0.55, 0.57)
	suelo.material_override = ms
	add_child(suelo)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.current = true
	var cuerpos: Array = []
	for i in 3:
		var rng := RandomNumberGenerator.new()
		rng.seed = 101 + i * 7
		var d := PeatonQ.crear(rng)
		if d.is_empty():
			continue
		var n: Node3D = d["nodo"]
		add_child(n)
		n.position = Vector3(float(i - 1) * 0.9, 0, 0)
		n.rotation.y = PI
		PeatonQ.terminar(d)
		Mini3D.anim(d, "parado", "")
		cuerpos.append(d)
	await get_tree().create_timer(1.5).timeout
	if cuerpos.is_empty():
		print("sin cuerpos")
		get_tree().quit()
		return
	## La cara del primero, a 0,6 m (la cabeza, por el hueso).
	var d0: Dictionary = cuerpos[1]
	var esq: Skeleton3D = d0["esqueleto"]
	var hb := esq.find_bone("Head")
	var cabeza := esq.global_transform * esq.get_bone_global_pose(hb).origin if hb >= 0 else Vector3(0, 1.6, 0)
	cabeza.y += 0.08
	_cam.fov = 35.0
	_cam.position = cabeza + Vector3(0, 0, -0.6)
	_cam.look_at(cabeza, Vector3.UP)
	await _foto("cara")
	## Los tres de cuerpo entero, a 3 m.
	_cam.fov = 50.0
	_cam.position = Vector3(0, 1.1, -3.4)
	_cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	await _foto("cuerpo")
	## El de la izquierda mira el móvil; el de la derecha habla por teléfono (P3, pasada 3).
	var d_izq: Dictionary = cuerpos[0]
	AnimExtra.asegurar(d_izq["anim"], d_izq["esqueleto"], "mirar_movil")
	Mini3D.anim(d_izq, "mirar_movil", "")
	PeatonVida.movil({"nodo": d_izq["nodo"]}, true)
	var d_der: Dictionary = cuerpos[cuerpos.size() - 1]
	AnimExtra.asegurar(d_der["anim"], d_der["esqueleto"], "charla")
	Mini3D.anim(d_der, "charla", "")
	PeatonVida.movil({"nodo": d_der["nodo"]}, true)
	await get_tree().create_timer(1.2).timeout
	await _foto("espera")
	print("capturas hechas")
	get_tree().quit()

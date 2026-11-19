extends Node
## SENTARSE AL PC (`PcAnimacion`, 18-11): con un escritorio de mentira y una cámara en primera persona, comprueba que la animación
## de sentarse acaba con la cámara mirando a la pantalla, de cerca y con el negro del fundido, y que levantarse devuelve la cámara
## a su sitio (pose y campo de visión) sin dejar manos, luz ni fundido. Con SALIDA=<carpeta> guarda fotos de cada fase (en JPG).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/prueba_pc_animacion.tscn
var _fallos := 0

func _comprobar(ok: bool, que: String) -> void:
	print(("  ok    " if ok else "  FALLO ") + que)
	if not ok:
		_fallos += 1

class Explorador extends Node3D:
	var camara: Camera3D

func _foto(carpeta: String, nombre: String) -> void:
	if carpeta == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(carpeta)
	img.save_jpg(carpeta.path_join(nombre + ".jpg"), 0.9)

func _caja(padre: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	padre.add_child(m)
	m.position = pos

func _ready() -> void:
	var salida := OS.get_environment("SALIDA")
	var exp := Explorador.new()
	add_child(exp)
	_caja(exp, Vector3(0, -0.05, 0), Vector3(8, 0.1, 8), Color(0.45, 0.4, 0.35))             ## suelo
	_caja(exp, Vector3(0, 0.38, -1.2), Vector3(1.6, 0.76, 0.8), Color(0.35, 0.22, 0.12))     ## mesa (a 1,2 del punto de uso... ver abajo)
	_caja(exp, Vector3(0, 1.0, -2.0 + 0.2), Vector3(0.7, 0.4, 0.04), Color(0.05, 0.05, 0.06)) ## pantalla
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	exp.add_child(sol)
	var cam := Camera3D.new()
	exp.add_child(cam)
	cam.current = true
	exp.camara = cam
	var punto := Vector3(0, 0, 1.0)   ## el punto de uso (la oficina real lo pone 0,9 m delante de la mesa)
	cam.global_position = punto + Vector3(0, 1.62, 1.2)
	cam.look_at(punto + Vector3(0, 1.4, -2.0), Vector3.UP)
	await get_tree().process_frame
	_comprobar(PcAnimacion.puede(exp), "con un explorador y su cámara dentro del árbol hay animación")
	_comprobar(not PcAnimacion.puede(null), "sin explorador no la hay (el PC enciende de golpe)")
	var pie := cam.global_transform
	var fov0 := cam.fov
	var a := PcAnimacion.new()
	add_child(a)
	var fin := [false]
	var coro := func() -> void:
		await a.sentarse(exp, punto)
		fin[0] = true
	coro.call()
	var fases := {0.3: "1_pasos", 1.0: "2_sentado", 1.7: "3_pantalla_encendida", 2.2: "4_acercando"}
	var t := 0.0
	while not fin[0] and t < 8.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		for k in fases.keys():
			if t >= k and fases[k] != "":
				await _foto(salida, String(fases[k]))
				fases[k] = ""
	_comprobar(fin[0], "sentarse termina (%.1f s)" % t)
	_comprobar(t > 2.0 and t < 4.0, "dura entre 2 y 4 s (%.1f s)" % t)
	var sentado := cam.global_position
	_comprobar(absf(sentado.y - (punto.y + 1.03)) < 0.05, "la cámara acaba a la altura de los ojos sentado y cerca de la pantalla (y=%.2f)" % sentado.y)
	_comprobar(cam.fov < fov0 - 10.0, "el campo de visión se cierra al entrar (%.0f → %.0f)" % [fov0, cam.fov])
	var mira := -cam.global_transform.basis.z
	_comprobar(mira.z < -0.95, "mira de frente a la pantalla (z=%.2f)" % mira.z)
	_comprobar(exp.find_child("PcSentado", true, false) != null and a._manos.size() == 2, "se ven las dos manos sobre el teclado")
	_comprobar(a._velo != null and a._velo.color.a > 0.95, "el fundido a negro cubre la vista para entregar el menú")
	await a.revelar()
	_comprobar(a._velo.color.a < 0.05, "tras encender el menú el negro se retira")
	await a.levantarse()
	_comprobar(cam.global_position.distance_to(pie.origin) < 0.01, "al levantarse la cámara vuelve a su sitio")
	_comprobar(absf(cam.fov - fov0) < 0.01, "y recupera su campo de visión")
	_comprobar(exp.find_child("PcSentado", true, false) == null or exp.find_child("PcSentado", true, false).is_queued_for_deletion(), "no quedan manos ni luz")
	await _planos(exp, cam)
	print("FIN. %d fallos" % _fallos)
	get_tree().quit(_fallos)

## (18-11) LOS PLANOS DEL PRÓLOGO (`PrologoPlanos`): los tres tipos caen dentro de la sala y miran hacia el fondo, la fachada mira a la puerta,
## el plano se rueda entero (y saltado) devolviendo la cámara a los ojos y al explorador su modo. En el juego, un fallo aquí congelaba el prólogo
## en cada sala (las pruebas rápidas del prólogo no ruedan planos), por eso se prueba aparte.
func _planos(exp: Node3D, cam: Camera3D) -> void:
	var r := Rect2(-3.0, -2.0, 6.0, 4.0)
	var tipos := {}
	for semilla in [11, 12, 13, 14, 15, 16]:
		var p := PrologoPlanos.poses(r, 0.0, semilla)
		tipos[PrologoPlanos.tipo_de(semilla)] = true
		var dentro := true
		for t: Transform3D in p:
			dentro = dentro and r.grow(0.01).has_point(Vector2(t.origin.x, t.origin.z)) and t.origin.y > 0.8 and t.origin.y < 3.0 and (-t.basis.z).z < 0.0
		_comprobar(p.size() == 2 and dentro, "plano %s (semilla %d): dos poses dentro de la sala, mirando al fondo" % [PrologoPlanos.tipo_de(semilla), semilla])
	_comprobar(tipos.size() == 3, "salen los tres tipos de plano (%s)" % str(tipos.keys()))
	var f := PrologoPlanos.poses_fachada(Vector3(10, 0, 5), 3)
	_comprobar((-f[1].basis.z).z < 0.0 and f[0].origin.z > f[1].origin.z, "la fachada se acerca a la puerta mirándola")
	_comprobar(PrologoPlanos.tiene("puerta") and PrologoPlanos.tiene("oficina") and not PrologoPlanos.tiene("llegada"), "qué pasos tienen plano")
	var ojos := cam.global_transform
	for saltar in [false, true]:
		var pl := PrologoPlanos.new()
		add_child(pl)
		var t0 := Time.get_ticks_msec()
		var coro := func() -> void:
			await pl.rodar(exp, r, 0.0, 12, "Oficina del DT", "Club Prueba", Color(0.8, 0.1, 0.1))
		coro.call()
		if saltar:
			await get_tree().process_frame
			var ev := InputEventKey.new()
			ev.keycode = KEY_E
			ev.pressed = true
			pl._unhandled_input(ev)
		while pl._activo:
			await get_tree().process_frame
		var seg := (Time.get_ticks_msec() - t0) / 1000.0
		_comprobar(cam.global_transform.origin.distance_to(ojos.origin) < 0.01 and exp.process_mode == Node.PROCESS_MODE_INHERIT,
			"%s: la cámara vuelve a los ojos y el explorador a moverse (%.1f s)" % ["saltado" if saltar else "entero", seg])
		_comprobar(seg < (1.0 if saltar else 5.0), "y dura lo que debe")
		pl.queue_free()

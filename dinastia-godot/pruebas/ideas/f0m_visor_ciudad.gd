extends BaseIdea
## FASE 0 (M-404/M-279): pruebas directas de `Autopista`, `CamarografosSiguen`,
## `ControlPartido` y `Mini3D` (la utilería; las personas van en f0m_visor_personas).
## Lógica y estructura: dónde queda cada cosa, hacia dónde mira y qué se mueve.

func _probar() -> void:
	_titulo("FASE 0 · VISOR: AUTOPISTA, CÁMARAS, CONTROL Y MINIJUEGOS (f0m)")
	_probar_autopista()
	_probar_camarografos()
	_probar_control_partido()
	_probar_mini3d()

func _nodos() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) + Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))

## Una animación vacía de un segundo.
func _anim(bucle: bool) -> Animation:
	var a := Animation.new()
	a.length = 1.0
	a.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	return a

func _reproductor(nombres: Dictionary) -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for n: String in nombres:
		lib.add_animation(n, _anim(bool(nombres[n])))
	ap.add_animation_library("", lib)
	return ap

# ----------------------------------------------------------------- Autopista

func _probar_autopista() -> void:
	_linea("· Autopista")
	var n0 := _nodos()
	var b := CityBuilder.new()
	b._rotulos = Node3D.new()
	b.add_child(b._rotulos)
	var r := Autopista.montar(b)
	_comprobar(r == {"enlaces": 4, "carreteras": 2}, "cuatro enlaces y dos carreteras al horizonte")
	var por_tramo := int((2.0 * Autopista.R + Autopista.ANCHO) / 40.0)
	var cuentas: Array[int] = []
	for h: Node in b.get_children():
		if h is MultiMeshInstance3D:
			cuentas.append((h as MultiMeshInstance3D).multimesh.instance_count)
	cuentas.sort()
	_comprobar(cuentas == [4 * por_tramo, 4 * por_tramo, 16 * por_tramo], "pilares y farolas (%d de cada) y las líneas de carril en tres MultiMesh %s" % [4 * por_tramo, str(cuentas)])
	_comprobar(b._rotulos.get_child_count() == 4, "un cartel de salida en cada enlace")
	## Las carreteras bajan del anillo (8 m) al terreno: en esos primeros tramos el
	## extremo que se aleja de la ciudad tiene que quedar MÁS BAJO que el otro.
	var mal: Array[String] = []
	var tramos_bajada := 0
	for h: Node in b.get_children():
		if not (h is MeshInstance3D and (h as MeshInstance3D).mesh is BoxMesh):
			continue
		var mi := h as MeshInstance3D
		var tam := (mi.mesh as BoxMesh).size
		if not is_equal_approx(tam.y, 0.5) or mi.position.y < 0.6:
			continue
		var eje := Vector3(0, 0, tam.z * 0.5) if is_equal_approx(tam.x, Autopista.ANCHO * 0.8) else Vector3(tam.x * 0.5, 0, 0)
		var p1 := mi.transform * eje
		var p2 := mi.transform * -eje
		var lejos := p1 if Vector2(p1.x, p1.z).length() > Vector2(p2.x, p2.z).length() else p2
		var cerca := p2 if lejos == p1 else p1
		tramos_bajada += 1
		if lejos.y >= cerca.y:
			mal.append("tramo en %s (lejos %.1f m, cerca %.1f m)" % [str(mi.position.round()), lejos.y, cerca.y])
	_comprobar(tramos_bajada == 4 and mal.is_empty(), "las dos carreteras bajan del anillo hacia fuera (%d tramos) %s" % [tramos_bajada, str(mal)])
	var rutas := Autopista.rutas()
	var rutas_ok := rutas.size() == 2
	for ru: PackedVector3Array in rutas:
		rutas_ok = rutas_ok and ru.size() == 4
		for p in ru:
			rutas_ok = rutas_ok and is_equal_approx(p.y, Autopista.ALTO + 0.6) and absf(absf(p.x) - Autopista.R) <= Autopista.ANCHO * 0.5 and absf(absf(p.z) - Autopista.R) <= Autopista.ANCHO * 0.5
	_comprobar(rutas_ok and (rutas[0] as PackedVector3Array)[0] != (rutas[1] as PackedVector3Array)[0], "el tráfico va por el tablero, en los dos sentidos")
	b.free()
	_comprobar(_nodos() == n0, "sin nodos sueltos")

# -------------------------------------------------------- CamarografosSiguen

func _probar_camarografos() -> void:
	_linea("· CamarografosSiguen")
	var n0 := _nodos()
	var raiz := Node3D.new()
	add_child(raiz)
	var balon := Node3D.new()
	raiz.add_child(balon)
	balon.position = Vector3(0, 0, 20)
	var banda := Node3D.new()
	banda.position = Vector3(40, 0, 0)
	banda.rotation.y = -PI * 0.5
	raiz.add_child(banda)
	var ap := _reproductor({"caminar": true, "parado": true})
	banda.add_child(ap)
	var fondo := Node3D.new()
	fondo.position = Vector3(0, 5, -50)
	raiz.add_child(fondo)
	var sig := CamarografosSiguen.new()
	raiz.add_child(sig)
	sig.balon = balon
	sig.agregar(banda, {"anim": ap})
	sig.agregar(fondo, {})
	_comprobar(bool(sig._puestos[0][2]) and not bool(sig._puestos[1][2]), "el de la banda camina por su carril; el del fondo, no")
	sig._process(0.5)
	_comprobar(is_equal_approx(banda.position.z, CamarografosSiguen.VEL_CARRIL * 0.5) and ap.current_animation == "caminar", "camina hacia la altura de la jugada, a su paso, y con su animación")
	for i in 60:
		sig._process(0.1)
	_comprobar(absf(banda.position.z - 20.0 * 0.85) <= 1.5 and ap.current_animation == "parado", "llega a la altura del balón y se para (z = %.1f)" % banda.position.z)
	var hacia := balon.global_position - banda.global_position
	_comprobar(absf(wrapf(banda.rotation.y - atan2(hacia.x, hacia.z), -PI, PI)) < 0.05, "y apunta la cámara al balón")
	balon.position = Vector3(60, 0, -50)
	for i in 40:
		sig._process(0.1)
	_comprobar(is_equal_approx(fondo.rotation.y, CamarografosSiguen.GIRO_MAX), "sin pasarse de su abanico (%.2f rad)" % fondo.rotation.y)
	var antes := fondo.rotation.y
	sig._process(0.0)
	balon.position = Vector3(-60, 0, -50)
	sig._process(0.1)
	_comprobar(absf(fondo.rotation.y - antes) <= CamarografosSiguen.VEL_GIRO * 0.1 + 1e-4, "con inercia de trípode: no da latigazos")
	var quieto := banda.transform
	balon.free()
	sig._process(0.1)
	_comprobar(banda.transform.is_equal_approx(quieto), "sin balón no se mueve nadie (ni falla)")
	raiz.free()
	_comprobar(_nodos() == n0, "sin nodos sueltos")

# ----------------------------------------------------------- ControlPartido

func _jug(raiz: Node3D, id: String, pos: Vector3, local: bool, puesto := "MED", arbitro := false) -> Dictionary:
	var n := Node3D.new()
	n.name = id
	raiz.add_child(n)
	n.position = pos
	return {"id": id, "node": n, "es_local": local, "slot_code": puesto, "arbitro": arbitro, "anim": null}

func _probar_control_partido() -> void:
	_linea("· ControlPartido")
	var n0 := _nodos()
	var raiz := Node3D.new()
	add_child(raiz)
	var balon := Balon3D.crear(Vector3(0, 0.11, 0.6), Color.WHITE, Color.BLACK)
	raiz.add_child(balon)
	var a := _jug(raiz, "A", Vector3(0, 0, 0), true)
	var b := _jug(raiz, "B", Vector3(0, 0, 12), true)
	var c := _jug(raiz, "C", Vector3(0, 0, -12), true)
	var d := _jug(raiz, "D", Vector3(8, 0, 0), true)
	var rival := _jug(raiz, "R", Vector3(0, 0, 0.5), false)
	var arb := _jug(raiz, "ARB", Vector3(0.3, 0, 0.6), true, "", true)
	var por := _jug(raiz, "POR", Vector3(0, 0, 0.4), true, "POR")
	var ctl := ControlPartido.new()
	raiz.add_child(ctl)
	var modos: Array = []
	ctl.modo_cambiado.connect(func(v: bool) -> void: modos.append(v))
	ctl.setup([a, b, c, d, rival, arb, por], balon, null, true, null)
	_comprobar(ctl.jugadores_equipo.size() == 5, "controla a los suyos: ni al rival ni al árbitro (%d)" % ctl.jugadores_equipo.size())
	_comprobar(String(ctl.jugador_activo.get("id", "")) == "POR", "elige al más cercano al balón (el portero, a bocajarro)")
	(por["node"] as Node3D).position = Vector3(6.5, 0, 0.6)
	(a["node"] as Node3D).position = Vector3(0, 0, -7.0)
	ctl.seleccionar_mas_cercano_al_balon()
	_comprobar(String(ctl.jugador_activo.get("id", "")) == "A", "pero al portero lejos (> 6 m) no lo coge aunque esté más cerca")
	(a["node"] as Node3D).position = Vector3.ZERO
	var cursor := ctl.get_node_or_null("CursorJugador") as Node3D
	_comprobar(cursor != null and cursor.get_child_count() == 2 and not cursor.visible and modos == [false], "cursor (flecha y anillo) apagado al empezar")
	ctl.alternar_modo()
	_comprobar(ctl.activo and cursor.visible and modos == [false, true], "alternar_modo() lo enciende")
	ctl._process(0.016)
	_comprobar(cursor.global_position.is_equal_approx(Vector3.ZERO) and ctl.tiene_posesion, "el cursor sigue a su jugador, que tiene el balón al pie")
	## Correr hacia -Z (W) con el balón: el propio _process orienta al jugador
	## hacia donde va, y la conducción tiene que llevar el balón DELANTE.
	var w := InputEventKey.new()
	w.keycode = KEY_W
	w.physical_keycode = KEY_W
	w.pressed = true
	Input.parse_input_event(w)
	Input.flush_buffered_events()
	for i in 40:
		ctl._process(0.05)
	w.pressed = false
	Input.parse_input_event(w)
	Input.flush_buffered_events()
	var na: Node3D = a["node"]
	_comprobar(na.position.z < -5.0, "con W corre hacia -Z (z = %.1f)" % na.position.z)
	_comprobar(balon.position.z < na.position.z, "y conduce el balón por delante, no a la espalda (balón %.2f, jugador %.2f)" % [balon.position.z, na.position.z])
	## Pase corto mirando a +Z (como queda tras correr hacia +Z): al compañero de delante.
	na.position = Vector3.ZERO
	na.rotation = Vector3.ZERO
	balon.position = Vector3(0, 0.11, 0.6)
	ctl.seleccionar_jugador(a)
	var pases: Array = []
	ctl.pase_efectuado.connect(func(p: Vector3) -> void: pases.append(p))
	ctl._ejecutar_pase_corto()
	_comprobar(pases.size() == 1 and String(ctl.jugador_activo.get("id", "")) == "B", "pase corto al compañero que tiene delante (no al de atrás) → %s" % str(ctl.jugador_activo.get("id", "")))
	_comprobar(balon._destino.is_equal_approx(Vector3(0, balon.radio, 12)), "y el balón va a sus pies")
	ctl.seleccionar_jugador(a)
	balon.position = Vector3(0, 0.11, 0.6)
	ctl._ejecutar_pase_largo()
	_comprobar(balon._destino.z > 20.0, "el pase largo sale hacia delante (z = %.1f)" % balon._destino.z)
	ctl._ejecutar_disparo(0.8)
	var al_arco := (Vector3(0, 0, -52.5) - na.global_position).normalized()
	_comprobar(na.global_transform.basis.z.dot(al_arco) > 0.9, "al tirar, el jugador queda de cara al arco rival")
	_comprobar(balon._destino.z < -52.0 and balon._destino.y <= 2.2, "y el balón va al arco de -Z, bajo el travesaño")
	var goles := 0
	for i in 30:
		ctl._ejecutar_disparo(float(i % 10) / 10.0)
		goles += 1 if balon._en_red else 0
	if goles == 30:
		_linea("  (aviso) los 30 tiros de prueba fueron gol: el desvío máximo (2 m) nunca sale del umbral de 3,2 m")
	na.rotation = Vector3.ZERO
	na.position = Vector3.ZERO
	ctl._ejecutar_barrida()
	_comprobar(is_equal_approx(na.position.z, 2.4), "la barrida lo lanza 2,4 m hacia delante (z = %.2f)" % na.position.z)
	raiz.free()
	_comprobar(_nodos() == n0, "sin nodos sueltos")

# -------------------------------------------------------------------- Mini3D

func _probar_mini3d() -> void:
	_linea("· Mini3D (utilería)")
	var n0 := _nodos()
	var panel := Control.new()
	add_child(panel)
	var otro := Control.new()
	panel.add_child(otro)
	var v := Mini3D.vista(panel, Calidad.DIA)
	var vp: SubViewport = v["vp"]
	var raiz: Node3D = v["raiz"]
	_comprobar(panel.get_child(0) == v["cont"] and vp.own_world_3d and (v["cam"] as Camera3D).current, "vista(): el visor queda DEBAJO de la interfaz, con mundo propio y su cámara")
	var we: WorldEnvironment = raiz.find_children("*", "WorldEnvironment", false, false)[0]
	_comprobar(is_equal_approx(we.environment.tonemap_exposure, 0.82) and not we.environment.fog_enabled and (v["sol"] as Node).get_parent() == raiz, "a pleno sol sin lavar: exposición 0,82, sin niebla y con su sol")
	var m := Mini3D.mat(Color(1, 0, 0, 0.5), 0.3, 2.0)
	_comprobar(m.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and m.emission_enabled and m.emission_energy_multiplier == 2.0 and Mini3D.mat(Color.RED).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED,
		"mat(): transparente si el color lo es, y con brillo si se pide")
	var cj := Mini3D.caja(raiz, Vector3(1, 2, 3), Vector3(2, 1, 4), m)
	var ci := Mini3D.cilindro(raiz, Vector3.ZERO, 0.5, 2.0, m, 0.2)
	var es := Mini3D.esfera(raiz, Vector3.ZERO, 0.3, m)
	_comprobar((cj.mesh as BoxMesh).size == Vector3(2, 1, 4) and cj.position == Vector3(1, 2, 3) and is_equal_approx((ci.mesh as CylinderMesh).top_radius, 0.2)
		and is_equal_approx((es.mesh as SphereMesh).height, 0.6) and cj.get_parent() == raiz, "caja, cilindro (con su cono) y esfera, colgados de la raíz")
	var hijos0 := raiz.get_child_count()
	var red := Mini3D.campo_y_arco(raiz)
	_comprobar(red != null and red.get_child_count() == 4 + 25 + 9 and raiz.get_child_count() > hijos0 + 30, "campo_y_arco(): la red (4 paños, 25 hilos verticales y 9 horizontales) y el resto del campo")
	_comprobar(Mini3D.kit("res://no/existe.glb") == null, "kit() de un modelo que no existe: null")
	## El suelo bajo el ratón, con una cámara que mira al centro desde arriba.
	var svp := SubViewport.new()
	svp.size = Vector2i(200, 200)
	add_child(svp)
	var cam := Camera3D.new()
	svp.add_child(cam)
	cam.position = Vector3(0, 10, 10)
	cam.look_at(Vector3.ZERO)
	var p: Variant = Mini3D.suelo_bajo(cam, Vector2(100, 100))
	_comprobar(p is Vector3 and (p as Vector3).length() < 0.05, "suelo_bajo(): el centro de la pantalla cae en el origen")
	cam.look_at(Vector3(0, 20, 0))
	_comprobar(Mini3D.suelo_bajo(cam, Vector2(100, 100)) == null, "y mirando al cielo no hay suelo")
	## anim(): un gesto que no es de bucle vuelve solo a «parado».
	var ap := _reproductor({"parado": true, "saludar": false})
	add_child(ap)
	var dd := {"anim": ap}
	Mini3D.anim(dd, "saludar")
	var cola := Array(ap.get_queue())
	_comprobar(ap.current_animation == "saludar" and cola.size() == 1 and String(cola[0]) == "parado", "anim(): el gesto y, en cola, vuelta a «parado» (%s, %s)" % [ap.current_animation, str(cola)])
	Mini3D.anim(dd, "no_existe")
	_comprobar(ap.current_animation == "parado" and ap.get_queue().is_empty(), "un clip que no existe: «parado»")
	Mini3D.anim({}, "saludar")
	ap.free()
	svp.free()
	panel.free()
	_comprobar(_nodos() == n0, "sin nodos sueltos")

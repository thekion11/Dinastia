extends "res://ui/componentes/minijuegos_ciudad_p1.gd"
## (Parte 2 de 3 de `minijuegos_ciudad.gd`.)

func _suelo_verde() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	mi.mesh = pm
	mi.material_override = Mini3D.mat(Color(0.3, 0.5, 0.25), 0.95)
	return mi

func _largo_pista() -> float:
	return 4.0 * RECTA + TAU * RADIO

## Punto de la línea central a una distancia `s` (sentido de la carrera:
## recta de abajo hacia +x, curva derecha, recta de arriba hacia -x, curva izquierda).
func _centro_pista(s: float) -> Dictionary:
	var total := 4.0 * RECTA + TAU * RADIO
	s = fposmod(s, total)
	var semi := PI * RADIO
	if s < 2.0 * RECTA:
		return {"p": Vector3(-RECTA + s, 0, RADIO), "dir": Vector3(1, 0, 0)}
	s -= 2.0 * RECTA
	if s < semi:
		var a := s / RADIO
		return {"p": Vector3(RECTA + sin(a) * RADIO, 0, cos(a) * RADIO), "dir": Vector3(cos(a), 0, -sin(a))}
	s -= semi
	if s < 2.0 * RECTA:
		return {"p": Vector3(RECTA - s, 0, -RADIO), "dir": Vector3(-1, 0, 0)}
	s -= 2.0 * RECTA
	var b := s / RADIO
	return {"p": Vector3(-RECTA - sin(b) * RADIO, 0, -cos(b) * RADIO), "dir": Vector3(-cos(b), 0, sin(b))}

func _multimalla(ts: Array[Transform3D], malla: Mesh, m: Material) -> void:
	if ts.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = m
	_raiz.add_child(mi)

## Un piloto sentado, en coordenadas del kit (que va escalado ×2,2): mono de
## carreras del color del kart, brazos al volante y casco con visera.
func _piloto(k: Node3D, col: Color) -> void:
	var mono := Mini3D.mat(col, 0.6)
	var casco := Mini3D.mat(col.lightened(0.35), 0.25)
	var visera := Mini3D.mat(Color(0.08, 0.09, 0.12), 0.1)
	var torso := Mini3D.cilindro(k, Vector3(0, 0.5, -0.16), 0.085, 0.28, mono, 0.1)
	torso.rotation.x = -0.25
	for lado in [-1.0, 1.0]:
		var brazo := Mini3D.cilindro(k, Vector3(lado * 0.11, 0.49, -0.04), 0.03, 0.22, mono)
		brazo.rotation.x = 1.15
	Mini3D.cilindro(k, Vector3(0, 0.66, -0.18), 0.035, 0.06, Mini3D.mat(Color(0.2, 0.2, 0.22), 0.6))
	Mini3D.esfera(k, Vector3(0, 0.73, -0.17), 0.075, casco)
	var vis := Mini3D.caja(k, Vector3(0, 0.735, -0.105), Vector3(0.11, 0.04, 0.02), visera)
	vis.rotation.x = 0.15

func _nuevo_kart(i: int) -> Node3D:
	var n := Node3D.new()
	_raiz.add_child(n)
	var k := Mini3D.kit("res://assets/ciudad/kenney_cars_extra/%s.glb" % CityBuilder.KARTS[i % CityBuilder.KARTS.size()])
	if k != null:
		k.scale = Vector3.ONE * 2.2
		n.add_child(k)
		## El muñeco cabezón del kit (cabeza como el kart entero) se cambia
		## por un piloto con proporciones de persona (etapa 1, 8-10-2026).
		var muneco := k.find_child("character", true, false) as Node3D
		if muneco != null:
			muneco.visible = false
		_piloto(k, Color.from_hsv(float(i) * 0.23 + 0.02, 0.75, 0.85))
	else:
		Mini3D.caja(n, Vector3(0, 0.35, 0), Vector3(1.2, 0.4, 2.0), Mini3D.mat(Color.from_hsv(float(i) * 0.25, 0.8, 0.9), 0.4))
	return n

## Lo recorrido en la vuelta (para la posición).
func _progreso(p: Vector3) -> float:
	var semi := PI * RADIO
	if absf(p.x) <= RECTA:
		return (p.x + RECTA) if p.z > 0.0 else (2.0 * RECTA + semi + (RECTA - p.x))
	if p.x > 0.0:
		return 2.0 * RECTA + atan2(p.x - RECTA, p.z) * RADIO if p.z > 0.0 else 2.0 * RECTA + (PI - atan2(p.x - RECTA, -p.z)) * RADIO
	var a := atan2(-(p.x + RECTA), -p.z)
	return 4.0 * RECTA + semi + (a if a >= 0.0 else a + TAU) * RADIO

func _colocar_kart(delta: float) -> void:
	_kart_n.position = _kp
	_kart_n.rotation.y = _kr
	var adelante := Vector3(sin(_kr), 0, cos(_kr))
	var deseo := _kp - adelante * 9.5 + Vector3(0, 4.2, 0)
	_cam.position = _cam.position.lerp(deseo, clampf(delta * 6.0, 0.0, 1.0)) if delta < 1.0 else deseo
	_cam.look_at(_kp + adelante * 3.0 + Vector3(0, 0.8, 0), Vector3.UP)

func _kart_empezar() -> void:
	_raiz.add_child(_suelo_verde())
	## El asfalto, en una tira de triángulos a lo largo del eje.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 160
	var total := _largo_pista()
	var bordes: Array = []
	for k in n + 1:
		var c := _centro_pista(total * float(k) / float(n))
		var lat := Vector3(-(c["dir"] as Vector3).z, 0, (c["dir"] as Vector3).x)
		bordes.append([(c["p"] as Vector3) - lat * ANCHO_PISTA * 0.5, (c["p"] as Vector3) + lat * ANCHO_PISTA * 0.5, lat, c["p"]])
	for k in n:
		var a: Array = bordes[k]
		var b: Array = bordes[k + 1]
		for v: Vector3 in [a[0], b[0], a[1], a[1], b[0], b[1]]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v + Vector3(0, 0.03, 0))
	var asfalto := MeshInstance3D.new()
	asfalto.mesh = st.commit()
	asfalto.material_override = Mini3D.mat(Color(0.2, 0.2, 0.22), 0.85)
	_raiz.add_child(asfalto)
	## Pianos rojos y blancos en los dos bordes y barreras de neumáticos fuera.
	var rojo := Mini3D.mat(Color(0.85, 0.12, 0.1), 0.6)
	var blanco := Mini3D.mat(Color(0.95, 0.95, 0.95), 0.6)
	var goma := Mini3D.mat(Color(0.08, 0.08, 0.09), 0.9)
	var mm_r: Array[Transform3D] = []
	var mm_b: Array[Transform3D] = []
	var mm_g: Array[Transform3D] = []
	for k in n:
		var a: Array = bordes[k]
		var b: Array = bordes[k + 1]
		for lado in 2:
			var p: Vector3 = ((a[lado] as Vector3) + (b[lado] as Vector3)) * 0.5
			var d: Vector3 = (b[lado] as Vector3) - (a[lado] as Vector3)
			var base := Basis.looking_at(d.normalized(), Vector3.UP) * Basis.from_scale(Vector3(0.9, 0.08, d.length()))
			var lat: Vector3 = a[2]
			var hacia := -1.0 if lado == 0 else 1.0
			var t := Transform3D(base, p + lat * hacia * 0.45 + Vector3(0, 0.05, 0))
			if k % 2 == 0:
				mm_r.append(t)
			else:
				mm_b.append(t)
		if k % 2 == 0:
			var lat2: Vector3 = a[2]
			var fuera: Vector3 = (a[1] as Vector3) + lat2 * 3.2
			for piso in 2:
				mm_g.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.9, 0.35, 0.9)), fuera + Vector3(0, 0.18 + float(piso) * 0.36, 0)))
			var dentro: Vector3 = (a[0] as Vector3) - lat2 * 2.6
			mm_g.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.9, 0.35, 0.9)), dentro + Vector3(0, 0.18, 0)))
	_multimalla(mm_r, BoxMesh.new(), rojo)
	_multimalla(mm_b, BoxMesh.new(), blanco)
	var rueda := CylinderMesh.new()
	rueda.top_radius = 0.5
	rueda.bottom_radius = 0.5
	rueda.height = 1.0
	_multimalla(mm_g, rueda, goma)
	## La meta a cuadros, el pórtico y la grada con público.
	for i in 11:
		for j in 2:
			Mini3D.caja(_raiz, Vector3(0.25 + float(j) * 0.5, 0.04, RADIO - ANCHO_PISTA * 0.5 + 0.5 + float(i)), Vector3(0.5, 0.02, 1.0),
				blanco if (i + j) % 2 == 0 else Mini3D.mat(Color(0.05, 0.05, 0.05), 0.6))
	var portico := Mini3D.mat(Color(0.9, 0.75, 0.1), 0.5)
	for z: float in [RADIO - ANCHO_PISTA * 0.5 - 1.0, RADIO + ANCHO_PISTA * 0.5 + 1.0]:
		Mini3D.caja(_raiz, Vector3(0.5, 2.6, z), Vector3(0.4, 5.2, 0.4), portico)
	Mini3D.caja(_raiz, Vector3(0.5, 5.4, RADIO), Vector3(0.6, 0.9, ANCHO_PISTA + 2.6), portico)
	var cartel := Label3D.new()
	cartel.text = Idiomas.t("🏁 META")
	cartel.font_size = 96
	cartel.pixel_size = 0.012
	cartel.position = Vector3(-0.1, 5.4, RADIO)
	cartel.rotation.y = -PI * 0.5
	_raiz.add_child(cartel)
	var grada := Node3D.new()
	grada.position = Vector3(0, 0, RADIO + ANCHO_PISTA * 0.5 + 9.0)
	_raiz.add_child(grada)
	for f in 4:
		Mini3D.caja(grada, Vector3(0, 0.4 + float(f) * 0.8, float(f) * 1.2), Vector3(40, 0.8, 1.2), Mini3D.mat(Color(0.55, 0.57, 0.6), 0.8))
	Mini3D.caja(grada, Vector3(0, 5.6, 2.5), Vector3(42, 0.2, 6.5), Mini3D.mat(Color(0.15, 0.35, 0.6), 0.6))
	for k in 10:
		var d := Mini3D.persona(grada, _rng, Vector3(-15.0 + float(k) * 3.3, 0.8 + float(k % 3) * 0.8, float(k % 3) * 1.2))
		if not d.is_empty():
			(d["nodo"] as Node3D).rotation.y = PI
			Mini3D.anim(d, ["aplaudir", "saludar_publico", "puno_al_aire"][k % 3], "")
	_fondo_ciudad(Vector3.ZERO, 95.0, -PI, PI, 22)
	## Los karts: el tuyo y tres rivales en la parrilla.
	_kart_n = _nuevo_kart(0)
	_kp = Vector3(-6.0, 0, RADIO + 2.0)
	for i in 3:
		var r := _nuevo_kart(i + 1)
		## En la recta de abajo, s = x + RECTA: tú en x = -6, ellos al lado y detrás.
		_rivales.append({"n": r, "s": RECTA - 4.0 - float(i) * 4.5, "v": 0.0, "tope": _rng.randf_range(19.0, 22.5), "lado": [-2.5, 2.5, -2.5][i]})
	_mi_total = _progreso(_kp)
	_semaforo = _lbl("", 80, Color(1, 0.3, 0.2))
	_semaforo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_semaforo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_semaforo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_semaforo.add_theme_constant_override("outline_size", 12)
	_semaforo.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(_semaforo)
	_aviso.text = Idiomas.t("Flechas o WASD. Tres vueltas. ¡Que no se te vaya del asfalto!")
	_colocar_kart(1.0)

func _montar() -> void:
	_rng.seed = Time.get_ticks_usec()
	_v = Mini3D.vista(self, Calidad.DIA)
	_cam = _v["cam"]
	_raiz = _v["raiz"]
	var banda := ColorRect.new()
	banda.color = Color(0, 0, 0, 0.45)
	banda.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banda.offset_bottom = 58
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banda)
	_titulo = _lbl("", 22, Color.WHITE)
	_titulo.position = Vector2(24, 16)
	add_child(_titulo)
	_aviso = _lbl("", 20, Color(1, 0.92, 0.6))
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.offset_top = -70
	_aviso.offset_left = -460
	_aviso.offset_right = 460
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_constant_override("outline_size", 6)
	_aviso.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	add_child(_aviso)
	var salir := Button.new()
	salir.text = Idiomas.t("Salir")
	salir.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	salir.offset_left = -110
	salir.offset_right = -20
	salir.offset_top = 12
	salir.offset_bottom = 48
	salir.pressed.connect(queue_free)
	add_child(salir)
	match juego:
		"autografos":
			_autografos_empezar()
		"pesca":
			_pesca_empezar()
		"karting":
			_kart_empezar()

func _caminar_hacia(n: Node3D, destino: Vector3, vel: float, delta: float) -> bool:
	var d := destino - n.position
	d.y = 0.0
	if d.length() < 0.15:
		return true
	n.rotation.y = lerp_angle(n.rotation.y, atan2(d.x, d.z), clampf(delta * 8.0, 0.0, 1.0))
	n.position += d.normalized() * minf(vel * delta, d.length())
	return false

func _autografos(delta: float) -> void:
	var ch := _raiz.get_node_or_null("Chorro") as Node3D
	if ch != null:
		ch.scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.12
	for h: Dictionary in _hinchas:
		var n: Node3D = h["d"]["nodo"]
		match String(h["estado"]):
			"llega":
				if _caminar_hacia(n, h["objetivo"], 3.4, delta):
					h["estado"] = "espera"
					## Paciencia: menos cuanto más avanzado el reloj.
					h["t"] = _rng.randf_range(1.6, 2.6) * lerpf(0.8, 1.0, _t / 30.0)
					var mira := -n.position
					n.rotation.y = atan2(mira.x, mira.z)
					Mini3D.anim(h["d"], "saludar_publico", "")
					(h["firma"] as Label3D).visible = true
			"espera":
				h["t"] = float(h["t"]) - delta
				var f: Label3D = h["firma"]
				f.position.y = 2.25 + absf(sin(Time.get_ticks_msec() * 0.01)) * 0.18
				f.modulate = Color.WHITE if float(h["t"]) > 0.6 else Color(1, 0.5, 0.4)
				if float(h["t"]) <= 0.0:
					h["estado"] = "triste"
					h["t"] = 1.0
					f.visible = false
					Mini3D.anim(h["d"], "manos_cabeza", "")
			"firmado", "triste":
				h["t"] = float(h["t"]) - delta
				if float(h["t"]) <= 0.0:
					h["estado"] = "se_va"
					Mini3D.anim(h["d"], "caminar", "")
			"se_va":
				if _caminar_hacia(n, h["salida"], 2.2, delta):
					h["estado"] = "fuera"
					n.position.y = -50.0
	if not _activo:
		return
	_t -= delta
	_titulo.text = Idiomas.t("✍️ Autógrafos en la Plaza Mayor  ·  %d s  ·  firmados: %d  ·  récord: %d") % [int(ceil(_t)), _puntos, records["autografos"]]
	if _t <= 0.0:
		_activo = false
		records["autografos"] = maxi(int(records["autografos"]), _puntos)
		_aviso.text = Idiomas.t("¡Firmaste %d autógrafos! %s") % [_puntos, Idiomas.t("La plaza entera coreó tu nombre.") if _puntos >= 14 else Idiomas.t("La gente se fue contenta.")]
		Mini3D.anim(_yo, "celebrar" if _puntos >= 14 else "aplaudir", "parado")
		for h: Dictionary in _hinchas:
			if String(h["estado"]) in ["llega", "espera"]:
				h["estado"] = "triste"
				h["t"] = 0.2
				(h["firma"] as Label3D).visible = false
		return
	_prox_hincha -= delta
	if _prox_hincha <= 0.0:
		## Con más reputación, llegan más seguido.
		_prox_hincha = _rng.randf_range(0.7, 1.4) * lerpf(1.3, 0.7, float(rep) / 100.0)
		for h: Dictionary in _hinchas:
			if String(h["estado"]) != "fuera":
				continue
			## Llegan por los lados, desde la gente que pasea.
			var lado := -1.0 if _rng.randf() < 0.5 else 1.0
			var a := lado * _rng.randf_range(1.2, 2.3)
			var n: Node3D = h["d"]["nodo"]
			n.position = Vector3(sin(a) * 10.0, 0, cos(a) * 8.0)
			h["salida"] = Vector3(sin(a + lado * _rng.randf_range(0.0, 0.4)) * 18.0, 0, cos(a) * 14.0)
			## Un hueco libre alrededor tuyo (no se pisan entre ellos).
			var ang := a
			for intento in 6:
				var libre := true
				for o: Dictionary in _hinchas:
					if o != h and String(o["estado"]) in ["llega", "espera"] and (o["objetivo"] as Vector3).distance_to(Vector3(sin(ang), 0, cos(ang)) * 2.6) < 1.3:
						libre = false
				if libre:
					break
				ang = _rng.randf_range(-1.3, 1.3)
			h["objetivo"] = Vector3(sin(ang), 0, cos(ang)) * 2.6
			h["estado"] = "llega"
			Mini3D.anim(h["d"], "caminar", "")
			break

func _dibujar_sedal() -> void:
	_sedal_mesh.clear_surfaces()
	if not _corcho.visible:
		return
	_sedal_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var a := _punta.global_position
	var b := _corcho.position + Vector3(0, 0.3, 0)
	for k in 13:
		var f := float(k) / 12.0
		var p := a.lerp(b, f)
		p.y -= sin(f * PI) * (0.35 if _estado_pesca != "pica" else 0.05)
		_sedal_mesh.surface_add_vertex(p)
	_sedal_mesh.surface_end()

func _pesca(delta: float) -> void:
	_titulo.text = Idiomas.t("🎣 Pesca en el puerto fluvial  ·  puntos: %d  ·  récord: %d") % [_puntos, records["pesca"]]
	var ms := Time.get_ticks_msec()
	if _bote != null:
		_bote.rotation.z = sin(ms * 0.0011) * 0.05
		_bote.position.y = 0.05 + sin(ms * 0.0013) * 0.05
	if _estado_pesca == "espera" or _estado_pesca == "pica":
		var hundir := 0.0
		var temblor := Vector3.ZERO
		if _estado_pesca == "pica":
			hundir = -0.16 + sin(ms * 0.03) * 0.05
			temblor = Vector3(sin(ms * 0.05) * 0.05, 0, cos(ms * 0.043) * 0.05)
			_cana.rotation.x = 0.0 + sin(ms * 0.04) * 0.05
		_corcho.position = _corcho_base + Vector3(0, sin(ms * 0.004) * 0.04 + hundir, 0) + temblor
	_dibujar_sedal()
	if _estado_pesca in ["fin", "lanzando", "sacando"]:
		return
	_t -= delta
	if _estado_pesca == "espera" and _t <= 0.0:
		_estado_pesca = "pica"
		_t = 0.75
		_aviso.text = Idiomas.t("¡¡PICA!!")
		_salpicar(_corcho_base, 0.8)
	elif _estado_pesca == "pica" and _t <= 0.0:
		_lanzadas += 1
		_aviso.text = Idiomas.t("Se escapó… demasiado lento.")
		Mini3D.anim(_yo, "manos_cabeza", "brazos_al_frente")
		_recoger(1.4)

## Distancia a la línea central (para saber si vas por el asfalto).
func _fuera_de_eje(p: Vector3) -> float:
	if absf(p.x) <= RECTA:
		return absf(absf(p.z) - RADIO)
	return absf(Vector2(p.x - signf(p.x) * RECTA, p.z).length() - RADIO)

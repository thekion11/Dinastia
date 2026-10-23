extends "res://visor/explorador_ciudad_p1.gd"
## (Parte 2 de 6 de `explorador_ciudad.gd`.)

func buscar_libre(desde: Vector3) -> Vector3:
	var r := RADIO_COCHE if modo == "coche" else RADIO_PIE
	for k in 400:
		var ang := float(k) * 0.7
		var d := float(k) * 2.0
		var p := desde + Vector3(cos(ang) * d, 0, sin(ang) * d)
		if libre_total(p, r):
			return Vector3(p.x, altura_suelo(p.x, p.z), p.z)
	return desde

## ¿Pantalla táctil? En PC (21-10-2026, vídeo de gameplay) la cruceta, la E y
## «Salir» tapaban la imagen: ahí se usan las teclas, y la E solo aparece,
## brillando, cuando hay algo con lo que interactuar.
static func es_tactil() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.get_environment("TACTIL") != ""

## Un gesto de tu personaje (saludar, charlar) y vuelta a estar parado.
func _gesto_propio(gesto: String) -> void:
	if _anim == null or not AnimExtra.UAL.has(gesto):
		return
	var lib := _anim.get_animation_library("")
	if lib != null and not lib.has_animation(gesto):
		var esq := FutbolistaQ.esqueleto_de(cuerpo)
		var clip: Animation = AnimQuaternius.cargar_real(String(AnimExtra.UAL[gesto]), str(_anim.get_path_to(esq)) if esq != null else "")
		if clip != null:
			lib.add_animation(gesto, clip)
	if _anim.has_animation(gesto):
		_anim.speed_scale = 1.0
		_anim.play(gesto, 0.25)
		_t_gesto_propio = minf(_anim.get_animation(gesto).length, 3.0)

func _hablar_con_vecino(v: Dictionary) -> void:
	var nodo: Node3D = v["nodo"]
	if not is_instance_valid(nodo):
		return
	_hablando_con = nodo
	## Si el texto aún se escribe, E lo completa en vez de pasar de turno.
	if _cuadro != null and _cuadro.escribiendo() and _hablando_con == nodo:
		_cuadro.completar()
		_t_burbuja = maxf(_t_burbuja, 4.0)
		return
	if not v.has("oficio"):
		## Oficio acorde a quien es (antes un hombre podía ser «La panadera»)
		## y un nombre propio, ficticio.
		var semilla := absi(hash(String(nodo.name)) + int(nodo.position.x * 7.0))
		var mujer := bool(nodo.get_meta("mujer", semilla % 2 == 0))
		var lista: Array = ["panadera", "estudiante", "kiosquera", "enfermera"] if mujer else ["jubilado", "taxista", "hincha", "barrendero", "repartidor"]
		## Dentro de un edificio, un oficio que pegue con el sitio.
		if estado == "interior" and is_instance_valid(_int):
			var sala := String(_int.call("_sala_nombre")).to_lower()
			if sala.contains("hospital") or sala.contains("clínica"):
				lista = ["enfermera"] if mujer else ["repartidor"]
			elif sala.contains("panader"):
				lista = ["panadera"] if mujer else ["repartidor"]
			else:
				lista = ["estudiante", "kiosquera"] if mujer else ["hincha", "repartidor"]
		v["oficio"] = String(lista[semilla % lista.size()])
		var nombres: Array = NOMBRES_M if mujer else NOMBRES_H
		v["nombre"] = String(nombres[(semilla / 7) % nombres.size()])
	var ahora := Time.get_ticks_msec()
	if ahora - int(v.get("t_charla", 0)) > 25000:
		v["turno"] = 0
	var turno := int(v.get("turno", 0))
	v["t_charla"] = ahora
	var oficio: String = v["oficio"]
	var frase := DialogosCiudad.linea(oficio, turno, animo, _rng_dialogo)
	if frase.contains("%s"):
		frase = frase % club_nombre
	## El texto va al CUADRO DE DIÁLOGO; sobre la cabeza solo queda un aviso.
	if _cuadro == null:
		_cuadro = CuadroDialogo.new()
		add_child(_cuadro)
	var tono := Color.from_hsv(fposmod(float(hash(oficio)) / 1000.0, 1.0), 0.45, 1.0)
	_cuadro.decir("%s · %s" % [String(v.get("nombre", "")), DialogosCiudad.nombre(oficio)], frase, tono, turno, 3)
	## Con el plano de conversación el globo sobra: solo en primera persona.
	_burbuja.text = "💬"
	_burbuja.pixel_size = 0.006
	_burbuja.position = nodo.global_position + Vector3(0, 2.3, 0)
	_burbuja.visible = primera_persona
	_t_burbuja = 6.0
	v["turno"] = (turno + 1) % 3
	v["espera"] = 6.0
	## Y la cara acompaña: alegre al saludar y despedirse; en la charla, según
	## cómo va el club.
	var cara: String = "alegre" if turno != 1 else {"euforia": "alegre", "bien": "alegre", "mal": "triste", "crisis": "enfado"}.get(animo, "neutral")
	Expresion.de(nodo).poner(cara, 5.0)
	## Se gira hacia ti y hace el gesto que toca (saluda, charla, se despide).
	var d := cuerpo.global_position - nodo.global_position
	nodo.rotation.y = atan2(d.x, d.z)
	## Y tú hacia esa persona, con tu propio gesto (13-10-2026).
	if not primera_persona:
		rumbo = atan2(-d.x, -d.z)
		cuerpo.rotation.y = rumbo
		_vel_pie = 0.0
		vel = 0.0
		_gesto_propio("saludo_mano" if turno == 0 else "charla")
	var gesto := "saludo_mano" if turno != 1 else "charla"
	for ap: AnimationPlayer in nodo.find_children("*", "AnimationPlayer", true, false):
		var lib := ap.get_animation_library("")
		if lib != null and not lib.has_animation(gesto):
			var esq := FutbolistaQ.esqueleto_de(nodo)
			var clip: Animation = AnimQuaternius.cargar_real(String(AnimExtra.UAL[gesto]), str(ap.get_path_to(esq)) if esq != null else "")
			if clip != null:
				lib.add_animation(gesto, clip)
		if lib != null and lib.has_animation(gesto):
			ap.play(gesto, 0.2)
			get_tree().create_timer(6.0).timeout.connect(func() -> void:
				if is_instance_valid(ap) and ap.has_animation("caminar"):
					ap.play("caminar", 0.3))

func _fundido() -> void:
	if _capa == null:
		return
	if not is_instance_valid(_velo):
		_velo = ColorRect.new()
		_velo.color = Color.BLACK
		_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
		_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_capa.add_child(_velo)
		_capa.move_child(_velo, 0)
	_velo.modulate.a = 1.0
	var tw := _velo.create_tween()
	tw.tween_property(_velo, "modulate:a", 0.0, 0.45).set_delay(0.05)

func _bajo_tierra(si: bool) -> void:
	## El entorno se guarda con lo demás: al cerrar el explorador bajo tierra la
	## cámara ya no está en el mundo, pero hay que devolver el sol igual.
	var env: Environment = _env_guardado.get("env") as Environment
	if env == null and camara != null and camara.is_inside_tree() and camara.get_world_3d() != null:
		env = camara.get_world_3d().environment
	if env == null:
		return
	if si and _env_guardado.is_empty():
		_env_guardado = {"env": env, "fog": env.fog_enabled, "amb": env.ambient_light_energy, "exp": env.tonemap_exposure,
			"vol": env.volumetric_fog_enabled}
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
		env.ambient_light_energy = 0.25
		env.tonemap_exposure = 0.9
		for n in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
			if (n as DirectionalLight3D).visible:
				(n as DirectionalLight3D).visible = false
				_soles_apagados.append(n)
		get_tree().call_group("rotulo_mapa", "hide")
	elif not si and not _env_guardado.is_empty():
		env.fog_enabled = _env_guardado["fog"]
		env.volumetric_fog_enabled = _env_guardado["vol"]
		env.ambient_light_energy = _env_guardado["amb"]
		env.tonemap_exposure = _env_guardado["exp"]
		for n in _soles_apagados:
			if is_instance_valid(n):
				(n as DirectionalLight3D).visible = true
		_soles_apagados.clear()
		if is_inside_tree():
			get_tree().call_group("rotulo_mapa", "show")
		_env_guardado = {}

func _caja_cabina(tam: Vector3, en: Vector3, giro: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	m.mesh = bm
	m.material_override = mat
	m.position = en
	m.rotation_degrees = giro
	_cabina.add_child(m)

## Una barra de `a` a `b` (pilares y techo).
func _barra_cabina(a: Vector3, b: Vector3, grosor: float, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(grosor, a.distance_to(b), grosor)
	m.mesh = bm
	m.material_override = mat
	var eje := (b - a).normalized()
	var lado := eje.cross(Vector3.FORWARD)
	if lado.length() < 0.01:
		lado = eje.cross(Vector3.RIGHT)
	lado = lado.normalized()
	m.transform = Transform3D(Basis(lado, eje, lado.cross(eje)), (a + b) * 0.5)
	_cabina.add_child(m)

## La cabina del coche en primera persona: piezas sencillas hijas de la cámara.
func _cabina_3d(ver: bool) -> void:
	if not ver:
		if _cabina != null:
			_cabina.visible = false
		return
	if _cabina == null:
		_cabina = Node3D.new()
		_cabina.name = "Cabina"
		camara.add_child(_cabina)
		var oscuro := StandardMaterial3D.new()
		oscuro.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		oscuro.albedo_color = Color(0.2, 0.21, 0.23)
		oscuro.roughness = 0.85
		var gris := StandardMaterial3D.new()
		gris.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gris.albedo_color = Color(0.36, 0.37, 0.4)
		gris.roughness = 0.6
		var piel := StandardMaterial3D.new()
		piel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		piel.albedo_color = Color(0.07, 0.07, 0.08)
		piel.roughness = 0.5
		## Medidas desde los ojos (x a la derecha, y arriba, -z adelante): el
		## conductor va 0,34 m a la izquierda del centro, el coche mide 1,8 m.
		## El salpicadero: su borde de arriba queda 17 cm bajo los ojos.
		_caja_cabina(Vector3(1.8, 0.3, 0.6), Vector3(0.34, -0.32, -0.88), Vector3.ZERO, oscuro)
		_caja_cabina(Vector3(0.34, 0.2, 0.5), Vector3(0.34, -0.42, -0.5), Vector3.ZERO, gris)
		## Los pilares delanteros, del salpicadero al techo, y el borde del techo.
		_barra_cabina(Vector3(-0.52, -0.17, -0.95), Vector3(-0.47, 0.3, -0.38), 0.07, oscuro)
		_barra_cabina(Vector3(1.2, -0.17, -0.95), Vector3(1.15, 0.3, -0.38), 0.07, oscuro)
		_barra_cabina(Vector3(-0.5, 0.36, -0.38), Vector3(1.18, 0.36, -0.38), 0.04, oscuro)
		## El retrovisor, arriba al centro del parabrisas.
		_caja_cabina(Vector3(0.15, 0.045, 0.02), Vector3(0.36, 0.3, -0.48), Vector3(0, -12, 0), gris)
		## El volante: aro, buje y radios; gira con `_volante`.
		_cabina_volante = Node3D.new()
		_cabina_volante.position = Vector3(0.0, -0.3, -0.5)
		_cabina.add_child(_cabina_volante)
		var aro := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.165
		tm.outer_radius = 0.195
		tm.rings = 24
		tm.ring_segments = 8
		aro.mesh = tm
		aro.material_override = piel
		_cabina_volante.add_child(aro)
		for ang: float in [0.0, 120.0, 240.0]:
			var radio := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.025, 0.02, 0.17)
			radio.mesh = bm
			radio.material_override = gris
			radio.rotation_degrees = Vector3(0, ang, 0)
			radio.position = Vector3(sin(deg_to_rad(ang)), 0, cos(deg_to_rad(ang))) * 0.085
			_cabina_volante.add_child(radio)
		var buje := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.05
		cm.height = 0.04
		buje.mesh = cm
		buje.material_override = gris
		_cabina_volante.add_child(buje)
		## Los brazos: manga oscura y mano color piel.
		var manga := StandardMaterial3D.new()
		manga.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		manga.albedo_color = Color(0.16, 0.2, 0.3)
		var mano_m := StandardMaterial3D.new()
		mano_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mano_m.albedo_color = Color(0.8, 0.6, 0.47)
		for i in 2:
			var br := MeshInstance3D.new()
			var cm2 := CylinderMesh.new()
			cm2.top_radius = 0.034
			cm2.bottom_radius = 0.042
			cm2.height = 1.0
			cm2.radial_segments = 10
			br.mesh = cm2
			br.material_override = manga
			_cabina.add_child(br)
			_cabina_brazos.append(br)
			var mn := MeshInstance3D.new()
			var sm2 := SphereMesh.new()
			sm2.radius = 0.045
			sm2.height = 0.08
			sm2.radial_segments = 10
			sm2.rings = 6
			mn.mesh = sm2
			mn.material_override = mano_m
			mn.scale = Vector3(1.0, 0.8, 1.35)
			_cabina.add_child(mn)
			_cabina_manos.append(mn)
		## El velocímetro, en el cuadro tras el volante.
		_cabina_kmh = Label3D.new()
		_cabina_kmh.font_size = 48
		_cabina_kmh.pixel_size = 0.0012
		_cabina_kmh.modulate = Color(0.55, 0.95, 0.75)
		_cabina_kmh.outline_size = 0
		## En la consola del centro (tras el volante quedaba tapado).
		_cabina_kmh.position = Vector3(0.3, -0.13, -0.66)
		_cabina_kmh.rotation_degrees = Vector3(-35, -18, 0)
		_cabina_kmh.pixel_size = 0.0010
		_cabina_kmh.no_depth_test = false
		_cabina.add_child(_cabina_kmh)
		for h in _cabina.find_children("*", "GeometryInstance3D", true, false):
			(h as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cabina.visible = true
	## El aro mira al conductor (eje inclinado hacia atrás) y gira sobre su eje.
	_cabina_volante.basis = Basis(Vector3.RIGHT, deg_to_rad(70.0)) * Basis(Vector3.UP, _volante * 2.6)
	## Manos en el aro (giran con él) y antebrazos del hombro a la mano; el
	## cuerpo se inclina un poco hacia el lado al que giras.
	var lean := Vector3(-_volante * 0.04, 0, 0)
	for i in mini(2, _cabina_manos.size()):
		## Las manos acompañan el aro hasta ~35° y ahí resbalan (no se cruzan
		## ni bajan tras la consola en los giros fuertes).
		var giro_mano := clampf(_volante * 2.6, -0.6, 0.6)
		var base_mano := Basis(Vector3.RIGHT, deg_to_rad(70.0)) * Basis(Vector3.UP, giro_mano)
		var mano: Vector3 = _cabina_volante.position + base_mano * (_MANO_EN_ARO[i] as Vector3)
		_cabina_manos[i].position = mano
		_cabina_manos[i].basis = base_mano.scaled(Vector3(1.0, 0.8, 1.35))
		var hombro: Vector3 = (_HOMBRO[i] as Vector3) + lean
		var eje := mano - hombro
		var largo := eje.length()
		if largo < 0.01:
			continue
		var y := eje / largo
		var x := y.cross(Vector3.FORWARD)
		if x.length() < 0.01:
			x = y.cross(Vector3.RIGHT)
		x = x.normalized()
		_cabina_brazos[i].transform = Transform3D(Basis(x, y * largo, x.cross(y)), (hombro + mano) * 0.5)
	_cabina_kmh.text = "%d km/h" % int(round(absf(vel) * 3.6))

func _fov_hacia(f: float, delta: float) -> void:
	camara.fov = lerpf(camara.fov, f, clampf(delta * 3.0, 0.0, 1.0)) if delta < 1.0 else f

## El salpicadero y el volante (solo en la cámara interior): dibujos 2D sobre la
## pantalla; el volante gira con la dirección.
func _volante_ui(ver: bool = true) -> void:
	var quiero := ver and modo == "coche" and cam_coche == 2
	if not quiero:
		if _ui_volante != null:
			_ui_volante.visible = false
		return
	if _ui_volante == null:
		_ui_volante = VolanteUI.new()
		_ui_volante.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui_volante.set_anchors_preset(Control.PRESET_FULL_RECT)
		_capa.add_child(_ui_volante)
		_ui_volante.move_to_front()
	_ui_volante.visible = true
	_ui_volante.set("giro", _volante)
	_ui_volante.set("kmh", absf(vel) * 3.6)
	_ui_volante.queue_redraw()

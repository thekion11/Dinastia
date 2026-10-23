class_name CeremoniaPartido
extends "res://visor/ceremonia_partido_p1.gd"
## (Parte 2 de 2 de `ceremonia_partido.gd`.)

## Todos a su sitio de la fila (por si se saltó parte del paseo), y árbitro y
## capitanes al centro: el árbitro mirando a la tribuna principal, cada capitán
## frente a él desde su mitad.
func _preparar_sorteo() -> void:
	_quitar_rotulo()
	_lona.visible = false
	for p: Dictionary in _jugadores:
		var nd: Node3D = p["node"]
		var camino: Array = _destinos.get(nd, [])
		if not camino.is_empty():
			nd.position = camino[camino.size() - 1]
			camino.clear()
			nd.rotation.y = PI * 0.5
			_anim_de(p.get("anim"), "parado")
	for k: Dictionary in _ninos:
		if is_instance_valid(k.get("nodo")):
			(k["nodo"] as Node3D).visible = false
	_gana_local = _rng.randf() < 0.5
	_capitanes = []
	for eq in 2:
		var c := _capitan(eq == 0)
		if c.is_empty():
			continue
		var nd: Node3D = c["node"]
		var lado := 1.0 if eq == 0 else -1.0
		nd.position = Vector3(-0.1, 0, lado * 0.58)
		nd.rotation.y = PI if eq == 0 else 0.0
		_anim_de(c.get("anim"), "parado")
		_capitanes.append(c)
	if not _arbitro.is_empty():
		var na: Node3D = _arbitro["node"]
		na.position = Vector3(-0.55, 0, 0.0)
		na.rotation.y = PI * 0.5
		_anim_de(_arbitro.get("anim"), "parado")
	## La moneda: un disco dorado (algo mayor que una de verdad, para que se
	## vea en el plano medio).
	_moneda = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04
	cm.bottom_radius = 0.04
	cm.height = 0.006
	cm.radial_segments = 20
	cm.rings = 1
	_moneda.mesh = cm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.95, 0.78, 0.35)
	mm.metallic = 0.9
	mm.roughness = 0.3
	mm.emission_enabled = true
	mm.emission = Color(0.5, 0.38, 0.12)
	_moneda.material_override = mm
	_moneda.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_raiz.add_child(_moneda)
	_moneda.position = Vector3(-0.3, 1.1, 0.0)
	Sonido.toca("moneda")

func _entrar_en(fase: int) -> void:
	_fase = fase
	match fase:
		1:
			_quitar_rotulo()
			_lona.visible = true
		2:
			Sonido.toca("himno", Sonido.Bus.AMBIENTE)
			_carta = _carta_alineacion(_local, true)
		3:
			if is_instance_valid(_carta):
				_carta.queue_free()
			_carta = _carta_alineacion(_visita, false)
			Sonido.toca("aplauso", Sonido.Bus.AMBIENTE)
		4:
			if is_instance_valid(_carta):
				_carta.queue_free()
			_preparar_sorteo()

## Cada uno sigue su camino a paso de ceremonia; el niño va a su lado.
func _caminar(delta: float) -> void:
	if _fase < 1:
		return
	for p: Dictionary in _jugadores:
		var nd: Node3D = p["node"]
		var camino: Array = _destinos.get(nd, [])
		if camino.is_empty():
			continue
		var obj: Vector3 = camino[0]
		var dif := obj - nd.position
		dif.y = 0.0
		var paso := 3.5 * delta
		if dif.length() <= paso:
			nd.position = obj
			camino.pop_front()
			if camino.is_empty():
				nd.rotation.y = PI * 0.5   ## de cara a la tribuna principal (+X)
				_anim_de(p.get("anim"), "parado")
			continue
		nd.position += dif.normalized() * paso
		nd.rotation.y = rotate_toward(nd.rotation.y, atan2(dif.x, dif.z), 6.0 * delta)
	for k: Dictionary in _ninos:
		var de: Node3D = k["de"]
		var nk: Node3D = k["nodo"]
		if not is_instance_valid(de) or not is_instance_valid(nk):
			continue
		## A su derecha y un poco por delante, de la mano.
		var fwd := Vector3(sin(de.rotation.y), 0, cos(de.rotation.y))
		var der := Vector3(-fwd.z, 0, fwd.x)
		var obj := de.position + der * 0.55 + fwd * 0.25
		var antes := nk.position
		nk.position = nk.position.lerp(obj, clampf(delta * 6.0, 0.0, 1.0))
		nk.rotation.y = de.rotation.y
		_anim_de(k.get("anim"), "caminar" if antes.distance_to(nk.position) > 0.01 else "parado")

## La realización: vuelo, travelling junto a la fila que sale, y barrido lento
## de cada fila a la altura de los ojos.
func _camara(fase: int) -> void:
	match fase:
		0:
			var f := clampf(_t / T_VUELO, 0.0, 1.0)
			f = f * f * (3.0 - 2.0 * f)
			var a := lerpf(deg_to_rad(200.0), deg_to_rad(320.0), f)
			var r := lerpf(maxf(_dx, _dz) * 1.3 + 20.0, maxf(_dx, _dz) * 0.9, f)
			_cam.global_position = Vector3(cos(a) * r, lerpf(55.0, 30.0, f), sin(a) * r)
			_cam.look_at(Vector3(0, 2.0, 10.0), Vector3.UP)
		1:
			var f2 := clampf((_t - T_VUELO) / T_SALIDA, 0.0, 1.0)
			var foco := Vector3(lerpf(_x_boca, 11.0, f2), 1.4, lerpf(38.0, 8.0, f2))
			_cam.global_position = foco + Vector3(9.0, 2.6, -7.0)
			_cam.look_at(foco + Vector3(0, -0.2, 2.0), Vector3.UP)
		4:
			## Plano medio del círculo central, con un leve travelling.
			var f4 := clampf((_t - T_VUELO - T_SALIDA - T_FILA * 2.0) / T_SORTEO, 0.0, 1.0)
			_cam.fov = 38.0
			_cam.global_position = Vector3(lerpf(4.6, 3.9, f4), 1.7, lerpf(1.3, 0.7, f4))
			_cam.look_at(Vector3(0.0, 1.25, 0.0), Vector3.UP)
		2, 3:
			var lado := 1.0 if fase == 2 else -1.0
			var f3 := clampf((_t - T_VUELO - T_SALIDA - (0.0 if fase == 2 else T_FILA)) / T_FILA, 0.0, 1.0)
			var z := lado * lerpf(1.5, 13.5, f3)
			_cam.global_position = Vector3(17.0, 2.2, z + lado * 1.5)
			_cam.look_at(Vector3(11.0, 1.35, z), Vector3.UP)

## El rótulo del sorteo: escudo y «elige campo».
func _rotulo_sorteo(quien: Club) -> Control:
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(_estilo.get("fondo", Color(0.03, 0.05, 0.12, 0.88)), Tema.RADIO_GRANDE, _estilo.get("borde", Color(1, 1, 1, 0.18))))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	caja.add_child(h)
	h.add_child(_escudo(quien, 48))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	v.add_child(Tema.etiqueta(13, _estilo.get("acento", Tema.ORO), Idiomas.t("SORTEO DE CAMPO")))
	v.add_child(Tema.etiqueta(20, Tema.TEXTO, Idiomas.t("%s elige campo") % Nombres.visible(quien.nombre)))
	_ui.add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caja.offset_bottom = -54
	Animar.aparecer(caja, 0.25, 0.3)
	return caja

func _anim_gesto(ap: Variant, nombre: String) -> void:
	if ap is AnimationPlayer and is_instance_valid(ap) and (ap as AnimationPlayer).has_animation(nombre):
		(ap as AnimationPlayer).play(nombre, 0.2)
		(ap as AnimationPlayer).speed_scale = 1.0

## La moneda sube girando y cae en la mano del árbitro; luego, el apretón.
func _sorteo() -> void:
	var s := _t - (T_VUELO + T_SALIDA + T_FILA * 2.0)
	if is_instance_valid(_moneda):
		var mano := Vector3(-0.3, 1.1, 0.0)
		var u := clampf((s - 0.3) / 1.3, 0.0, 1.0)
		_moneda.position = mano + Vector3(0, 4.0 * 0.95 * u * (1.0 - u), 0)
		## Gira en el aire; al caer queda plana, de cara al cielo.
		_moneda.rotation = Vector3(u * 22.0 * (1.0 if u < 1.0 else 0.0), 0.0, 0.0)
		if s > 2.5:
			_moneda.visible = false
		if u >= 1.0 and not is_instance_valid(_carta):
			var quien := _local if _gana_local else _visita
			_carta = _rotulo_sorteo(quien)
	if s >= 2.4 and not _saludo_hecho:
		_saludo_hecho = true
		for c: Dictionary in _capitanes:
			_anim_gesto(c.get("anim"), "dar_mano")
		_anim_gesto(_arbitro.get("anim"), "dar_mano")
		## Se giran hacia el centro para el apretón.
		for c: Dictionary in _capitanes:
			var nd: Node3D = c["node"]
			nd.rotation.y = atan2(-nd.position.x, -nd.position.z)

# ---------------------------------------------------------------- el tiempo

func _process(delta: float) -> void:
	if not activa:
		return
	_t += delta
	var fase := 0
	if _t >= T_VUELO:
		fase = 1
	if _t >= T_VUELO + T_SALIDA:
		fase = 2
	if _t >= T_VUELO + T_SALIDA + T_FILA:
		fase = 3
	if _t >= T_VUELO + T_SALIDA + T_FILA * 2.0:
		fase = 4
	if _t >= T_FIN:
		terminar()
		return
	if fase != _fase:
		_entrar_en(fase)
	_caminar(delta)
	_camara(fase)
	if fase == 4:
		_sorteo()

func _unhandled_input(e: InputEvent) -> void:
	if activa and ((e is InputEventMouseButton and (e as InputEventMouseButton).pressed) or (e is InputEventKey and (e as InputEventKey).pressed)
			or (e is InputEventJoypadButton and (e as InputEventJoypadButton).pressed)):
		get_viewport().set_input_as_handled()
		terminar()

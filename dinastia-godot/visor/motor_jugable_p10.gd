extends "res://visor/motor_jugable_p9.gd"
## [Capa 10/12 de `motor_jugable.gd`] _anillo_serenidad, tanda_equipo_usuario, tanda_turno, _lado_portero_tanda, _tras_tiro_tanda, _dibujar_receptor … (+12)

## Un aro alrededor del balón mientras apuntas un penal: verde cuando es chico.
func _anillo_serenidad(ver: bool) -> void:
	if not ver:
		if is_instance_valid(_anillo):
			_anillo.visible = false
		return
	if not is_instance_valid(_anillo) and balon != null and balon.get_parent() != null:
		_anillo = MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.42
		tm.outer_radius = 0.5
		tm.rings = 40
		_anillo.mesh = tm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.no_depth_test = true
		_anillo.material_override = m
		_anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		balon.get_parent().add_child(_anillo)
	if not is_instance_valid(_anillo):
		return
	var s := serenidad()
	_anillo.visible = true
	_anillo.global_position = balon.global_position + Vector3(0, 0.02 - R, 0)
	_anillo.scale = Vector3.ONE * (0.6 + s * 1.6) * Vector3(1, 0.05, 1)
	(_anillo.material_override as StandardMaterial3D).albedo_color = Color(0.3, 1.0, 0.45, 0.9) if s < 0.22 else Color(1.0, 0.85, 0.3, 0.75)

## El equipo que manejas en la tanda (-1 = la IA tira todo).
func tanda_equipo_usuario() -> int:
	return control_equipo if control_equipo >= 0 and not autopiloto else -1

## El equipo que tira ahora.
func tanda_turno() -> int:
	if tanda.is_empty():
		return -1
	var hechos: int = (tanda["tiros"][0] as Array).size() + (tanda["tiros"][1] as Array).size()
	return (int(tanda["empieza"]) + hechos) % 2

## LA LECTURA DEL LANZADOR (M-119, 20-10): el portero de la IA se tira más al
## lado natural del pie del que patea (el diestro, a su izquierda = +X; el
## zurdo, al revés) y, según sus reflejos, a veces lee la carrera y va al lado
## bueno. Antes adivinaba 40/40/20 a ciegas.
func _lado_portero_tanda(lz: Dictionary, gk: Dictionary) -> int:
	var ref := float((gk.get("attr", {}) as Dictionary).get("ref", 0.5))
	if _rng.randf() < 0.04 + 0.12 * ref:
		var x := vel_balon.x
		return 0 if absf(x) < 0.6 else int(signf(x))
	var natural := -1 if AnimExtra.es_zurdo(String(lz.get("id", ""))) else 1
	var r := _rng.randf()
	return natural if r < 0.46 else (-natural if r < 0.82 else 0)

## Tras el golpeo (desde `_reanudar`): el tiro no cuenta como remate del
## partido y el portero se tira.
func _tras_tiro_tanda() -> void:
	var lz: Dictionary = tanda["lanzador"]
	if not _tiro_vivo.is_empty():
		var eq := 0 if bool(lz.get("es_local", true)) else 1
		tiros[eq] = maxi(int(tiros[eq]) - 1, 0)
	_tiro_vivo = {}
	apuntando = false
	cargando = false
	_anillo_serenidad(false)
	tanda["fase"] = "vuelo"
	_t_estado = 0.0
	var gk: Dictionary = tanda["portero"]
	if gk.is_empty():
		return
	## El portero de la IA adivina (40 % a cada lado, 20 % se queda); el tuyo
	## va donde dijiste.
	var tu := tanda_equipo_usuario()
	var lado: int = int(tanda["lado"])
	if not (tu >= 0 and tanda_turno() != tu) or lado == SIN_ELEGIR:
		lado = _lado_portero_tanda(lz, gk)
	tanda["lado"] = lado
	var alto := "media" if _rng.randf() < 0.6 else "baja"
	## Mirando a -Z, su izquierda es +X.
	if lado != 0:
		_anim(gk, "estirada_%s_%s" % [alto, "izq" if lado > 0 else "der"], true)
		gk["vel"] = Vector3(float(lado) * 6.5, 0, 0)
		gk["objetivo"] = TANDA_ARCO + Vector3(float(lado) * 2.2, 0, -0.3)
	else:
		_anim(gk, "atajar", true)

## Una flecha amarilla sobre el receptor elegido (córner, falta o banda).
func _dibujar_receptor() -> void:
	if _receptor_marcado.is_empty() or not is_instance_valid(_receptor_marcado.get("node")):
		if is_instance_valid(_flecha_receptor):
			_flecha_receptor.visible = false
		return
	if not is_instance_valid(_flecha_receptor) and balon != null and balon.get_parent() != null:
		_flecha_receptor = MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.36, 0.36, 0.1)
		_flecha_receptor.mesh = pm
		_flecha_receptor.rotation.x = PI
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color("ffd23f")
		m.no_depth_test = true
		_flecha_receptor.material_override = m
		balon.get_parent().add_child(_flecha_receptor)
	if is_instance_valid(_flecha_receptor):
		_flecha_receptor.visible = true
		_flecha_receptor.global_position = (_receptor_marcado["node"] as Node3D).global_position + Vector3(0, 2.4 + sin(t * 6.0) * 0.08, 0)

func _reanudar() -> void:
	if estado == "tanda":
		_tras_tiro_tanda()
		return
	_receptor_marcado = {}
	_dibujar_receptor()
	_anillo_serenidad(false)
	for q: Dictionary in jugadores:
		q.erase("ayuda_v")
	estado = "juego"
	_t_estado = 0.0
	apuntando = false
	cambio_estado.emit("juego")

## Los compañeros dentro (o cerca) del área rival, para elegir receptor.
func _receptores(p: Dictionary, lugar: Vector3, radio := 60.0) -> Array:
	var lista: Array = []
	for q: Dictionary in jugadores:
		if q == p or bool(q["por"]) or bool(q["es_local"]) != bool(p["es_local"]):
			continue
		if pos(q).distance_to(lugar) < radio:
			lista.append(q)
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return pos(a).x < pos(b).x)
	return lista

## Saque de banda manejado por ti.
func _saque_banda_usuario() -> void:
	var p := usuario
	var lugar: Vector3 = saque["lugar"]
	var d := dir_ataque(bool(p["es_local"]))
	var rs := Input.get_vector("jugar_fili_izquierda", "jugar_fili_derecha", "jugar_fili_arriba", "jugar_fili_abajo", Mando.ZONA_MUERTA)
	var mv := Mando.movimiento()
	var lista := _receptores(p, lugar, 30.0)
	if lista.is_empty():
		return
	if _receptor_i < 0 or _receptor_i >= lista.size():
		_receptor_i = 0
	if Input.is_action_just_pressed("jugar_cambiar"):
		_receptor_i = (_receptor_i + 1) % lista.size()
	## El stick derecho (o el izquierdo) apunta al compañero.
	var apunta := rs if rs.length() > 0.5 else mv
	if apunta.length() > 0.5:
		var q_dir := _companero_en_direccion(p, _a_mundo(apunta, d), true)
		var i := lista.find(q_dir)
		if i >= 0:
			_receptor_i = i
	var q: Dictionary = lista[_receptor_i]
	_receptor_marcado = q
	var hacer := ""
	if Input.is_action_just_pressed("jugar_pase"):
		hacer = "corto"
	elif Input.is_action_just_pressed("jugar_filtrado"):
		hacer = "espacio"
	elif Input.is_action_just_pressed("jugar_centro"):
		hacer = "largo"
	if hacer == "":
		return
	_anim(p, "saque_banda", true, 0.8)
	match hacer:
		"corto":
			_patear(p, pos(q) + Vector3(0, 1.0, 0), clampf(pos(q).distance_to(lugar) * 0.9 + 4.0, 7.0, 15.0), 1.0, 0.0, "saque_banda")
		"espacio":
			var hueco := pos(q) + Vector3(0, 0, d * 6.0)
			_patear(p, hueco, clampf(hueco.distance_to(lugar) * 0.8 + 5.0, 8.0, 16.0), 1.5, 0.0, "saque_banda")
		"largo":
			_patear(p, pos(q) + Vector3(0, 0.5, d * 3.0), clampf(pos(q).distance_to(lugar) * 0.55 + 7.0, 10.0, 19.0), 3.5, 0.0, "saque_banda")
	pase_a = q
	_receptor_marcado = {}
	_reanudar()

func _marcar_receptor(q: Dictionary) -> void:
	_receptor_marcado = q

## LB en córner o falta: el siguiente receptor; el apunte gira hacia él.
func _siguiente_receptor() -> void:
	var p := usuario
	var lugar: Vector3 = saque["lugar"]
	var arco := _arco_rival(p)
	var lista := _receptores(p, Vector3(0, 0, arco.z - signf(arco.z) * 9.0), 20.0)
	if lista.is_empty():
		return
	_receptor_i = (_receptor_i + 1) % lista.size()
	var q: Dictionary = lista[_receptor_i]
	var base := (arco - lugar).normalized()
	var hacia := (pos(q) - lugar)
	hacia.y = 0.0
	apunte["ang"] = clampf(-base.signed_angle_to(hacia.normalized(), Vector3.UP), -1.2, 1.2)
	apunte["fuerza"] = clampf((hacia.length() - 12.0) / 38.0, 0.2, 1.0)
	_marcar_receptor(q)
	aviso.emit("🎯 Receptor: %s" % String((q.get("jugador", {}) as Dictionary).get("nombre", "")))

## RB / LT en balón parado: llama a otro lanzador (el 2.º o el 3.º mejor
## pateador) y pasas a manejarlo a él.
func _otro_lanzador(k: int) -> void:
	var p := usuario
	var lugar: Vector3 = saque["lugar"]
	var cand: Array = []
	for q: Dictionary in jugadores:
		if bool(q["por"]) or bool(q["es_local"]) != bool(p["es_local"]):
			continue
		cand.append(q)
	cand.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["attr"]["tir"]) + float(a["attr"]["pas"]) > float(b["attr"]["tir"]) + float(b["attr"]["pas"]))
	var elegidos: Array = []
	for q: Dictionary in cand:
		if q != saque.get("lanzador", {}):
			elegidos.append(q)
	if elegidos.size() < k:
		return
	var nuevo: Dictionary = elegidos[k - 1]
	var viejo: Dictionary = saque.get("lanzador", {})
	saque["lanzador"] = nuevo
	(nuevo["node"] as Node3D).position = lugar + (lugar - _arco_rival(nuevo)).normalized() * 0.6
	if not viejo.is_empty():
		(viejo["node"] as Node3D).position = lugar + (lugar - _arco_rival(viejo)).normalized() * 2.5 + Vector3(1.5, 0, 0)
	_poner_usuario(nuevo)
	aviso.emit("%s lanzador: %s" % ["Segundo" if k == 1 else "Tercer", String((nuevo.get("jugador", {}) as Dictionary).get("nombre", ""))])

## La dirección de apunte en el campo (para la flecha de la interfaz).
func direccion_apunte() -> Vector3:
	var lugar: Vector3 = saque.get("lugar", Vector3.ZERO)
	var arco := _arco_rival(usuario) if not usuario.is_empty() else Vector3.ZERO
	var base := (arco - lugar).normalized()
	return base.rotated(Vector3.UP, -float(apunte["ang"]))

func _lanzar_usuario(fuerza: float) -> void:
	var p := usuario
	var tipo := String(saque["tipo"])
	var lugar: Vector3 = saque["lugar"]
	if tipo == "penal":
		## LB + B: panenka (bombeada al centro); RB + B: colocado con rosca.
		if _mods_carga == "vaselina":
			_mod_tiro = "vaselina"
			_tirar(p, Vector2(0, 0.2), 0.35)
			aviso.emit("🎩 ¡A lo Panenka!")
		else:
			_mod_tiro = "rosca" if _mods_carga == "rosca" else ""
			## En la tanda todos tiran al arco de +Z.
			var d_ap := 1.0 if estado == "tanda" else dir_ataque(bool(p["es_local"]))
			_tirar(p, Vector2(float(apunte["x"]) * d_ap * -1.0, float(apunte["y"]) - 0.4), fuerza)
		_mod_tiro = ""
		_mods_carga = ""
	else:
		var dir := direccion_apunte()
		var dist := 12.0 + fuerza * 38.0
		var destino := lugar + dir * dist
		destino.y = float(apunte["loft"]) * 2.0
		var loft := float(apunte["loft"]) * 7.0
		var efecto_saque := float(apunte["ang"]) * -10.0 + float(apunte.get("efecto", 0.0)) * 9.0
		_patear(p, destino, 12.0 + fuerza * 18.0, loft, efecto_saque, "patear" if fuerza > 0.6 else "pase")
		if tipo == "falta" and Vector2(lugar.x, lugar.z - _arco_rival(p).z).length() < 32.0:
			tiros[0 if bool(p["es_local"]) else 1] += 1
			stats["tiros"] += 1
		pase_a = _companero_cerca(p, destino)
	_reanudar()

# ---------------------------------------------------------------- tú

## Lanzar tú: el stick mueve la dirección (córner/falta) o el punto del arco
## (penal); arriba/abajo la altura; mantener TIRO carga la fuerza y soltar
## patea. PASE lanza a ras, sin cargar.
func _apuntar_usuario(delta: float) -> void:
	var tipo := String(saque["tipo"])
	var mv := Mando.movimiento()
	_anillo_serenidad(tipo == "penal")
	_dibujar_receptor()
	## SAQUE DE BANDA (FC 26): A en corto al elegido, Y al espacio, X largo;
	## LB cambia de receptor y el stick derecho apunta.
	if tipo == "banda":
		_saque_banda_usuario()
		return
	if tipo in ["corner", "falta"]:
		## LB: el receptor dentro del área (el apunte va hacia él).
		if Input.is_action_just_pressed("jugar_cambiar"):
			_siguiente_receptor()
		## RB / LT: segundo y tercer lanzador (jugada ensayada).
		if Input.is_action_just_pressed("jugar_mod"):
			_otro_lanzador(1)
			return
		if Input.is_action_just_pressed("jugar_regate"):
			_otro_lanzador(2)
			return
	if tipo == "penal":
		apunte["x"] = clampf(float(apunte["x"]) + mv.x * delta * 1.4, -1.0, 1.0)
		apunte["y"] = clampf(float(apunte["y"]) - mv.y * delta * 1.2, 0.0, 1.0)
	else:
		apunte["ang"] = clampf(float(apunte["ang"]) + mv.x * delta * 1.2, -1.2, 1.2)
		apunte["loft"] = clampf(float(apunte["loft"]) - mv.y * delta * 0.8, 0.0, 1.0)
	## Stick derecho: el efecto (curva) del lanzamiento, como en FC.
	var rs := Input.get_vector("jugar_fili_izquierda", "jugar_fili_derecha", "jugar_fili_arriba", "jugar_fili_abajo", Mando.ZONA_MUERTA)
	if absf(rs.x) > 0.2:
		apunte["efecto"] = clampf(float(apunte.get("efecto", 0.0)) + rs.x * delta * 1.5, -1.0, 1.0)
	if Input.is_action_pressed("jugar_tiro"):
		if not cargando:
			_mods_carga = ""
		apunte["fuerza"] = minf(1.0, float(apunte["fuerza"]) + delta * 0.9)
		cargando = true
		if Input.is_action_pressed("jugar_cambiar"):
			_mods_carga = "vaselina"
		elif Input.is_action_pressed("jugar_mod"):
			_mods_carga = "rosca"
	elif cargando:
		cargando = false
		## Penal: cuanto más chico el círculo de serenidad, más preciso.
		if tipo == "penal":
			_error_extra = lerpf(0.4, 1.7, serenidad())
		_lanzar_usuario(float(apunte["fuerza"]))
		_error_extra = 1.0
	elif Input.is_action_just_pressed("jugar_pase"):
		_lanzar_usuario(0.45)

func _ritmo_de_saque(lanzador: Dictionary) -> float:
	if lanzador.is_empty() or minuto() < 75 or sin_gestion_tiempo:
		return 1.0
	var eq := 0 if bool(lanzador["es_local"]) else 1
	if eq == control_equipo:
		return 1.0
	var dif := int(goles[eq]) - int(goles[1 - eq])
	return 2.2 if dif > 0 else (0.6 if dif < 0 else 1.0)

## ¿Están todos a menos de 3 m de su sitio del saque?
func _colocados() -> bool:
	for p: Dictionary in jugadores:
		if p.has("objetivo") and pos(p).distance_to(p["objetivo"] as Vector3) > 3.0:
			return false
	return true

func _ejecutar_saque_ia(p: Dictionary, tipo: String, lugar: Vector3) -> void:
	var arco := _arco_rival(p)
	match tipo:
		"corner":
			## Todo en el sentido del ataque (antes el mismo giro absoluto daba
			## córners cerrados a un equipo y abiertos al otro).
			var sa := signf(arco.z)
			var destino := Vector3(_rng.randf_range(-3, 4) * -sa, 1.7, arco.z - sa * _rng.randf_range(5, 9))
			_ctx_golpeo = "centro"
			_patear(p, destino, 18.0, 0.0, -signf(lugar.x) * 8.0 * -sa, "pase")
			pase_a = _companero_cerca(p, destino)
		"penal":
			## Algún penal se va fuera o al palo (antes el apunte nunca salía del arco).
			_tirar(p, Vector2(_rng.randf_range(-1.06, 1.06), _rng.randf_range(-0.3, 0.45)), 0.7)
		"falta":
			var dist := Vector2(lugar.x - arco.x, lugar.z - arco.z).length()
			if dist < 30.0:
				_tirar(p, Vector2(_rng.randf_range(-0.9, 0.9), 0.5), 0.75)
			else:
				var mejor := _mejor_pase(p)
				if not mejor.is_empty():
					_pasar_a(p, mejor, dist > 35.0)
				else:
					_patear(p, arco * 0.7, 20.0, 4.0)
		"puerta":
			## Saque de puerta: en corto a un central si está libre; si no, a
			## media cancha, para que lo peleen.
			var corto := _mejor_pase(p)
			if not corto.is_empty() and pos(corto).distance_to(pos(p)) < 30.0 and _rng.randf() < 0.6:
				_pasar_a(p, corto)
			else:
				var lejos := Vector3(_rng.randf_range(-16, 16), 0, dir_ataque(bool(p["es_local"])) * 3.0)
				_patear(p, lejos, 19.0, 3.5, 0.0, "patear")
		_:
			var m := _mejor_pase(p)
			if not m.is_empty():
				_pasar_a(p, m)
				if tipo == "banda":
					_anim(p, AnimExtra.variante(p["anim"], "saque_banda", String(p.get("id", "")), _rng), true)
			else:
				_patear(p, pos(p) + Vector3(0, 0, dir_ataque(bool(p["es_local"])) * 8.0), 10.0)
	_reanudar()

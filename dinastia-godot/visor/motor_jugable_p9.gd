extends "res://visor/motor_jugable_p8.gd"
## [Capa 9/12 de `motor_jugable.gd`] _filigrana, _pase_manual, _centro_usuario, _segundo_presionador, _control_usuario, _fuera_del_area … (+3)

## Una filigrana: si el jugador no tiene las estrellas, le sale mal y el balón
## se le va; si las tiene, gesto, movimiento del balón y, según su regate
## contra la defensa del rival más cercano, el rival se come el amago.
func _filigrana(p: Dictionary, id: String, lado: float) -> void:
	var f: Array = ControlFC.FILIGRANAS.get(id, [])
	if f.is_empty():
		return
	var n: Node3D = p["node"]
	var fwd := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
	var der := Vector3(-fwd.z, 0, fwd.x)
	var reg := float(p["attr"]["reg"])
	var mis := ControlFC.estrellas(reg)
	var necesita := int(f[1])
	var ap: AnimationPlayer = p["anim"]
	var nom := String(f[4])
	if is_instance_valid(ap) and lado < 0.0 and ap.has_animation(nom + "_espejo"):
		nom += "_espejo"
	_anim(p, nom, true, 0.9)
	p["regate_hasta"] = t + 0.9
	if necesita > mis:
		## Le queda grande: el balón se le escapa un par de metros.
		filigrana.emit(String(f[0]), necesita, false)
		aviso.emit("✖ %s (necesita %d★)" % [String(f[0]), necesita])
		poseedor = {}
		ultimo_toque = p
		p["enfriar"] = 0.35
		vel_balon = (fwd + der * _rng.randf_range(-0.8, 0.8)).normalized() * 4.5
		return
	filigrana.emit(String(f[0]), necesita, true)
	var sp := (p["vel"] as Vector3).length()
	match String(f[5]):
		"lateral", "lateral_lento":
			var fuerza := 3.2 if String(f[5]) == "lateral" else 2.0
			p["vel"] = der * lado * fuerza + fwd * sp * 0.5
			balon.position = n.position + (der * lado * 0.7 + fwd * 0.45) + Vector3(0, R, 0)
			vel_balon = der * lado * fuerza + fwd * sp * 0.5
		"giro":
			var nuevo := der * lado
			_mirar(p, atan2(nuevo.x, nuevo.z), 0.3)
			p["vel"] = nuevo * 2.5
			balon.position = n.position + nuevo * 0.6 + Vector3(0, R, 0)
			vel_balon = nuevo * 3.0
		"giro_atras":
			_mirar(p, atan2(-fwd.x, -fwd.z), 0.35)
			p["vel"] = -fwd * 1.5
			balon.position = n.position - fwd * 0.6 + Vector3(0, R, 0)
			vel_balon = -fwd * 2.5
		"arranque":
			p["vel"] = fwd * (sp + 2.0)
			p["correr"] = true
			poseedor = {}
			ultimo_toque = p
			vel_balon = fwd * 7.5
		"sombrero":
			## Por encima del rival: el balón vuela y él lo persigue.
			poseedor = {}
			ultimo_toque = p
			balon.position = n.position + fwd * 0.4 + Vector3(0, 0.4, 0)
			vel_balon = fwd * 5.5 + Vector3(0, 5.0, 0)
			p["correr"] = true
		"amago":
			pass
	## ¿Se lo come el rival más cercano?
	var r := _rival_mas_cercano(p)
	if not r.is_empty() and pos(r).distance_to(pos(p)) < 4.0:
		var engano := clampf(0.35 + (reg - float(r["attr"]["def"])) * 0.9 + float(mis - necesita) * 0.05, 0.1, 0.88)
		if _rng.randf() < engano:
			r["enfriar"] = 0.8
			## Se tira hacia el lado equivocado (con inercia: antes saltaba 0,7 m).
			r["vel"] = (r["vel"] as Vector3) * 0.3 - der * lado * 2.0
			_empujar(r, -der * lado, 3.5, 0.6, 0.6)
			_anim(r, "falta_barrida" if _rng.randf() < 0.3 else "marcar", true, 0.6)
			aviso.emit("✨ %s" % String(f[0]))

## El pase manual: al punto, raso o por arriba, sin elegir receptor.
func _pase_manual(p: Dictionary, dir: Vector3, dist: float, por_arriba: bool) -> void:
	var destino := pos(p) + dir.normalized() * dist
	destino.x = clampf(destino.x, -ANCHO + 0.5, ANCHO - 0.5)
	destino.z = clampf(destino.z, -LARGO + 0.5, LARGO - 0.5)
	if por_arriba:
		_patear(p, destino, clampf(dist * 0.45 + 6.0, 10.0, 19.0), 2.0, 0.0, "pase")
	else:
		_patear(p, destino, clampf(velocidad_para(dist, 4.0), 7.0, 24.0), 0.0, 0.0, "pase")
	pase_a = _companero_cerca(p, destino)
	_pase_eq = 0 if bool(p["es_local"]) else 1
	pases[_pase_eq] += 1
	stats["pases"] += 1
	_pase_usuario_vivo = true
	_pase_usuario_de = usuario

## Un centro: normal, bombeado (LB) o tenso y raso (RB).
func _centro_usuario(p: Dictionary, arco: Vector3, d: float, lb: bool, rb: bool) -> void:
	var destino := Vector3(_rng.randf_range(-3, 3), 1.6, arco.z - d * 7.0)
	var vh := 17.0
	var efecto := -signf(pos(p).x) * 6.0 * -d
	if lb:
		destino.y = 2.2
		destino.z = arco.z - d * 9.0
		vh = 14.0
		_patear(p, destino, vh, 4.5, efecto * 0.6, "pase")
	elif rb:
		destino = Vector3(_rng.randf_range(-2, 2), 0.3, arco.z - d * 6.0)
		_patear(p, destino, 23.0, 0.0, efecto * 0.4, "pase")
	else:
		_patear(p, destino, vh, 0.0, efecto, "pase")
	_ctx_golpeo = "centro"
	pase_a = _companero_cerca(p, destino)
	stats["pases"] += 1
	_pase_usuario_vivo = true
	_pase_usuario_de = usuario

## El compañero que sale a presionar con RB: el más cercano al rival.
func _segundo_presionador(p: Dictionary, menos: Dictionary = {}) -> Dictionary:
	var mejor: Dictionary = {}
	if poseedor.is_empty():
		return mejor
	var md := 999.0
	for q: Dictionary in jugadores:
		if q == p or q == menos or bool(q["por"]) or bool(q["es_local"]) != bool(p["es_local"]):
			continue
		var dd := pos(q).distance_to(pos(poseedor))
		if dd < md:
			md = dd
			mejor = q
	return mejor

## Los controles durante el juego, como en FC 26 (Configuración Clásica): A
## pase, B tiro, X centro, Y al hueco, RB y LB modificadores, RT sprint, LT
## proteger o bregar, stick derecho filigranas y cambio manual, cruceta tácticas
## rápidas. Todas las combinaciones del manual están en `ControlFC`.
func _control_usuario(delta: float) -> void:
	if usuario.is_empty() or autopiloto:
		return
	var p := usuario
	var n: Node3D = p["node"]
	var d := dir_ataque(bool(p["es_local"]))
	var mv := Mando.movimiento()
	## Con la cámara detrás del jugador mirando al arco rival: arriba en la
	## pantalla es hacia el arco, la derecha de la pantalla es -X al atacar +Z.
	var mundo := _a_mundo(mv, d)
	var lb := Input.is_action_pressed("jugar_cambiar")
	var rb := Input.is_action_pressed("jugar_mod")
	var lt := Input.is_action_pressed("jugar_regate")
	var sprint := Input.is_action_pressed("jugar_sprint")
	p["correr"] = sprint
	p["freno"] = 1.0
	p["protege"] = false
	p["toque_corto"] = false
	p["giro_firme"] = false
	if mundo.length() > 0.1:
		p["objetivo"] = pos(p) + mundo.normalized() * 3.0
		p["manual"] = mundo.normalized()
	else:
		p["objetivo"] = pos(p)
		p["manual"] = Vector3.ZERO
	_tacticas_rapidas()
	_seguir_pared()
	_seguir_portero_mandado()
	## L3 + R3 a la vez: bloquear (o soltar) al jugador que manejas. Se cambia
	## al PULSAR la pareja (flanco), no en cada fotograma que siga pulsada.
	var pareja := Input.is_action_pressed("jugar_pedir") and Input.is_action_pressed("jugar_sombrero")
	if pareja and not _pareja_bloqueo:
		bloqueo = not bloqueo
		aviso.emit("🔒 Jugador bloqueado" if bloqueo else "🔓 Bloqueo quitado")
	_pareja_bloqueo = pareja
	if pareja:
		return
	var con_balon := poseedor == p
	var fwd := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
	## El stick derecho en el plano del jugador (x a su derecha, y adelante).
	var rs := Input.get_vector("jugar_fili_izquierda", "jugar_fili_derecha", "jugar_fili_arriba", "jugar_fili_abajo", Mando.ZONA_MUERTA)
	var rs_mundo := _a_mundo(rs, d)
	var der := Vector3(-fwd.z, 0, fwd.x)
	var rel := Vector2(rs_mundo.dot(der), rs_mundo.dot(fwd))
	if con_balon:
		var dir_mira := mundo.normalized() if mundo.length() > 0.1 else fwd
		## EL PORTERO CON EL BALÓN EN LAS MANOS: X saque largo (de volea),
		## A pase corto con la mano.
		if bool(p["por"]):
			if Input.is_action_just_pressed("jugar_centro"):
				var lejos := pos(p) + Vector3(-mv.x * d * 12.0, 0, d * 46.0)
				lejos.x = clampf(lejos.x, -ANCHO + 4.0, ANCHO - 4.0)
				_patear(p, lejos, 22.0, 6.0, 0.0, "patear")
				return
			if Input.is_action_just_pressed("jugar_pase"):
				var qm := _companero_en_direccion(p, dir_mira)
				if not qm.is_empty():
					_pasar_a(p, qm)
					_anim(p, "saque_banda", true, 0.6)
				return
		## PASE ELEGANTE (LT + A o X): de tacón, rabona o exterior. Bonito y
		## algo menos preciso.
		if lt and (Input.is_action_just_pressed("jugar_pase") or Input.is_action_just_pressed("jugar_centro")):
			var largo_e := Input.is_action_just_pressed("jugar_centro")
			var qe := _companero_en_direccion(p, dir_mira)
			if not qe.is_empty():
				_error_extra = 1.35
				_pasar_a(p, qe, largo_e)
				_error_extra = 1.0
				var ops: Array = ["taconazo", "pase_rabona", "pase_exterior"] if not largo_e else ["pase_rabona", "trivela"]
				_anim(p, String(ops[_rng.randi() % ops.size()]), true)
				aviso.emit("🎩 Pase elegante")
			return
		## Mantener RB: regate técnico; LB: regate ágil; LT: proteger; RB + LT:
		## cambios de dirección firmes.
		if lt and rb:
			p["giro_firme"] = true
			p["freno"] = 0.75
		elif lt:
			p["protege"] = true
			p["freno"] = 0.55
		elif (rb or lb) and not cargando and mundo.length() > 0.1:
			p["toque_corto"] = true
			p["freno"] = 0.8 if rb else 0.9
		## Filigranas del stick derecho (y R3, y LB+RB atrás).
		var fil := _gestos.leer(rel, t, lb, lt, rb, sprint) if float(p.get("gesto_hasta", 0.0)) < t else {}
		if Input.is_action_just_pressed("jugar_sombrero"):
			fil = {"id": "sombrero_corto", "lado": 1.0}
		if lb and rb and mundo.length() > 0.5 and mundo.normalized().dot(fwd) < -0.6 and float(p.get("gesto_hasta", 0.0)) < t:
			fil = {"id": "arrastre", "lado": 1.0}
		if not fil.is_empty():
			_filigrana(p, String(fil["id"]), float(fil["lado"]))
			return
		## El tiro: se carga manteniendo y sale al soltar; los modificadores
		## valen si se pulsan en algún momento de la carga.
		if Input.is_action_pressed("jugar_tiro"):
			if not cargando:
				_mods_carga = ""
			carga = minf(1.0, carga + delta * 1.1)
			cargando = true
			if lb and rb:
				_mods_carga = "potente"
			elif rb and _mods_carga == "":
				_mods_carga = "rosca"
			elif lb and _mods_carga == "":
				_mods_carga = "vaselina"
			## AMAGO DE TIRO: con la carga en marcha, Pase o Centro lo cancela.
			if Input.is_action_just_pressed("jugar_pase") or Input.is_action_just_pressed("jugar_centro"):
				cargando = false
				carga = 0.0
				_filigrana(p, "amago_rabona" if lt else "amago_tiro", 1.0)
			return
		elif cargando:
			cargando = false
			var ap_tiro := Vector2(-mv.x * d, -mv.y * 0.5)
			if Mando.ayuda("tiro") == "asistido" and _mods_carga != "potente":
				## Asistido: al palo largo, abajo, con un toque del stick.
				## (`_tirar` recibe la X del mundo: el palo largo es el del lado contrario.)
				var largo := -signf(pos(p).x + 0.01)
				ap_tiro = Vector2(clampf(largo * 0.75 + ap_tiro.x * 0.35, -1.0, 1.0), -0.35 + ap_tiro.y * 0.3)
			else:
				_manual_tiro = true
			_mod_tiro = _mods_carga
			if _mods_carga == "potente":
				lento = 0.5
			_tirar(p, ap_tiro, carga)
			_mod_tiro = ""
			_manual_tiro = false
			carga = 0.0
			return
		if Input.is_action_just_pressed("jugar_pase"):
			## La devolución de la pared: el que la pidió corre al hueco.
			if not _pared.is_empty() and t < float(_pared["hasta"]) and _pared["de"] != p and not lb:
				var de: Dictionary = _pared["de"]
				_pared = {}
				_pasar_a(p, de, false, true)
				aviso.emit("🔁 ¡Pared!")
			elif Mando.ayuda("pase") == "manual" and not lb:
				## PASE MANUAL: al punto exacto hacia donde apuntas (12 m), sin
				## buscar compañero; el que esté cerca corre a por él.
				_pase_manual(p, dir_mira, 16.0 if rb else 12.0, false)
			else:
				var q := _companero_en_direccion(p, dir_mira)
				if not q.is_empty():
					_pasar_a(p, q, false, false, rb)
					if lb:
						## LB + A: PARED. El que la da arranca al espacio y la
						## pide de vuelta (3,5 s para devolverla con Pase).
						_pared = {"de": p, "hasta": t + 3.5}
		elif Input.is_action_just_pressed("jugar_filtrado"):
			var q2 := _companero_en_direccion(p, mundo if mundo.length() > 0.1 else Vector3(0, 0, d))
			if not q2.is_empty():
				## LB + Y bombeado por encima de la defensa; RB + Y tenso.
				_pasar_a(p, q2, lb, true, rb)
		elif Input.is_action_just_pressed("jugar_pase_largo") and Mando.ayuda("pase") == "manual":
			_pase_manual(p, dir_mira, 28.0, true)
		elif Input.is_action_just_pressed("jugar_pase_largo"):
			var q3 := _companero_en_direccion(p, mundo if mundo.length() > 0.1 else Vector3(0, 0, d))
			if not q3.is_empty():
				_pasar_a(p, q3, true)
		elif Input.is_action_just_pressed("jugar_centro"):
			var arco := _arco_rival(p)
			## En tres cuartos de cancha rival es un centro; antes, un pase largo.
			if absf(arco.z - pos(p).z) < 38.0:
				_centro_usuario(p, arco, d, lb, rb)
			else:
				var q4 := _companero_en_direccion(p, mundo if mundo.length() > 0.1 else Vector3(0, 0, d))
				if not q4.is_empty():
					_pasar_a(p, q4, true, false, rb)
	else:
		cargando = false
		carga = 0.0
		if _seguir_barrida(p):
			return
		var rival_con_balon := not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"])
		## LT: bregar (jockey), de cara al balón y más despacio; con RT, en carrera.
		if lt:
			p["freno"] = 0.85 if sprint else 0.6
			p["jockey"] = true
		else:
			p["jockey"] = false
		## Stick derecho sin balón: cambio manual al compañero hacia donde apuntas.
		if rs_mundo.length() > 0.8 and t > _cambio_rs_hasta:
			_cambio_rs_hasta = t + 0.45
			var elegido := _companero_en_direccion(p, rs_mundo.normalized(), true)
			if not elegido.is_empty():
				_poner_usuario(elegido)
				_manual_hasta = t + 1.5
				return
		## RB + A: falta táctica (agarrón): corta la contra con amarilla segura.
		if rb and Input.is_action_just_pressed("jugar_pase") and rival_con_balon and pos(poseedor).distance_to(pos(p)) < 2.4:
			_anim(p, "falta_empujon", true)
			_falta_tactica = true
			_falta(p, poseedor, 0.25, "", "agarron")
			_falta_tactica = false
			return
		## A mantenido: CONTENER. Se pone entre el rival y su arco, a metro y
		## medio, sin tirarse (antes era correr a por él como un loco).
		if Input.is_action_pressed("jugar_pase") and rival_con_balon and not rb:
			var arco_p := _arco_propio(p)
			var rp := pos(poseedor)
			p["objetivo"] = rp + (arco_p - rp).normalized() * 1.4
			p["correr"] = rp.distance_to(pos(p)) > 4.0
			p["jockey"] = true
		## RB mantenido: el compañero más cercano va a presionar al que la lleva.
		## Doble toque y mantener: van DOS (el segundo tapa al receptor más
		## cercano).
		if Input.is_action_just_pressed("jugar_mod"):
			_presion_doble = t - _rb_ultimo < 0.3
			_rb_ultimo = t
		if rb and rival_con_balon:
			var ayuda := _segundo_presionador(p)
			if not ayuda.is_empty():
				ayuda["objetivo"] = pos(poseedor)
				ayuda["correr"] = true
				if _presion_doble:
					var receptor := _rival_mas_cercano(poseedor)
					var tercero := _segundo_presionador(p, ayuda)
					if not receptor.is_empty() and not tercero.is_empty():
						tercero["objetivo"] = pos(receptor).lerp(pos(poseedor), 0.35)
						tercero["correr"] = true
		elif not rb:
			_presion_doble = false
		## R3 mantenido + stick izquierdo: mueves al PORTERO a mano.
		if Input.is_action_pressed("jugar_sombrero"):
			var gk_m := _mi_portero(p)
			if not gk_m.is_empty() and mundo.length() > 0.1:
				gk_m["objetivo"] = pos(gk_m) + mundo.normalized() * 2.0
				gk_m["mandado_hasta"] = t + 0.15
				p["objetivo"] = pos(p)
				p["manual"] = Vector3.ZERO
			return
		## Y: mantener = sale el portero; doble toque = se va al palo largo.
		if Input.is_action_just_pressed("jugar_filtrado"):
			if t - _y_ultimo < 0.3:
				_palo_largo_hasta = t + 3.0
				aviso.emit("🧤 Portero al palo largo")
			_y_ultimo = t
		if Input.is_action_pressed("jugar_filtrado") and t >= _palo_largo_hasta and (rival_con_balon or poseedor.is_empty()):
			for gk: Dictionary in jugadores:
				if bool(gk["por"]) and bool(gk["es_local"]) == bool(p["es_local"]) and gk != p:
					gk["objetivo"] = balon.position
					gk["correr"] = true
		if Input.is_action_just_pressed("jugar_tiro") and float(p["enfriar"]) <= 0.0:
			if rival_con_balon and pos(poseedor).distance_to(pos(p)) < 1.8:
				_entrada(p, false)
			elif poseedor.is_empty() and balon.position.distance_to(pos(p)) < 1.6:
				## Despeje / remate de primera.
				var arco2 := _arco_rival(p)
				if absf(arco2.z - pos(p).z) < 25.0:
					## De primera: al palo largo y abajo, corregido con el stick
					## (antes iba siempre al centro, a las manos del portero).
					var largo2 := -signf(pos(p).x + 0.01)
					_tirar(p, Vector2(clampf(largo2 * 0.75 - mv.x * d * 0.35, -1.0, 1.0), -0.35), 0.8)
				else:
					_patear(p, pos(p) + Vector3(0, 0, d * 25.0), 22.0, 4.0, 0.0, "patear")
		if Input.is_action_just_pressed("jugar_centro") and float(p["enfriar"]) <= 0.0:
			## Barrida: más alcance, más riesgo. Se lanza al suelo hacia donde va
			## el rival y la entrada se decide al llegar (`_seguir_barrida`); antes
			## saltaba 1,6 m en un fotograma y la entrada se resolvía a distancia.
			if rival_con_balon and pos(poseedor).distance_to(pos(p)) < 3.2:
				_lanzar_barrida(p)
			else:
				_anim(p, "falta_barrida", true)
				p["enfriar"] = 1.2
		if Input.is_action_just_pressed("jugar_pedir"):
			pedido_hasta = t + 2.5
			aviso.emit("🙋 ¡Pide el balón!")
			_anim(p, "pedir_balon", true)

func _fuera_del_area(p: Dictionary) -> Vector3:
	var o := _forma(p, false)
	var lugar: Vector3 = saque["lugar"]
	var arco_z := signf(lugar.z) * LARGO
	if absf(o.z - arco_z) < AREA_Z + 1.0:
		o.z = arco_z - signf(arco_z) * (AREA_Z + 2.0)
	return o

## Córner y falta: los que atacan entran al área (primer palo, segundo palo,
## punto de penal, frontal) y los que defienden los marcan; en las faltas
## cercanas, cuatro hacen barrera a 9,15 m.
func _pos_balon_parado(p: Dictionary, lugar: Vector3, saca_local: bool) -> Vector3:
	var ataca := bool(p["es_local"]) == saca_local
	var arco_z := LARGO * dir_ataque(saca_local)
	## Las x se escriben para atacar hacia -Z y se reflejan para +Z (como el
	## catálogo de jugadas): los dos equipos ocupan el área igual.
	var ex := -signf(arco_z)
	var zonas := [Vector3(-2.5 * ex, 0, arco_z - signf(arco_z) * 5.0), Vector3(3.0 * ex, 0, arco_z - signf(arco_z) * 6.5),
		Vector3(0, 0, arco_z - signf(arco_z) * 11.0), Vector3(-6.0 * ex, 0, arco_z - signf(arco_z) * 9.0),
		Vector3(6.5 * ex, 0, arco_z - signf(arco_z) * 10.0), Vector3(0, 0, arco_z - signf(arco_z) * 18.0)]
	var i := absi(String(p.get("id", "")).hash()) % zonas.size()
	if ataca:
		if _rol(p) in ["DFC", "DC", "ED", "EI", "MC"]:
			return zonas[i]
		return _forma(p, true)
	## Defensores: barrera en las faltas cercanas.
	var dist_arco := Vector2(lugar.x, lugar.z - arco_z).length()
	if String(saque["tipo"]) == "falta" and dist_arco < 32.0 and _rol(p) in ["DC", "ED", "EI", "MC"]:
		var hacia := (Vector3(0, 0, arco_z) - lugar).normalized()
		var lado := Vector3(hacia.z, 0, -hacia.x)
		var k := float(i % 4) - 1.5
		return lugar + hacia * 9.15 + lado * k * 0.7
	return zonas[i] + Vector3(0.8 * ex, 0, 0)

func _ia_portero_saque(p: Dictionary) -> Vector3:
	var arco := _arco_propio(p)
	return arco + Vector3(0, 0, dir_ataque(bool(p["es_local"])) * 0.8)

## EL CÍRCULO DE SERENIDAD del penal: late entre grande (1) y chico (0).
func serenidad() -> float:
	return 0.5 + 0.5 * cos(_t_estado * 3.4)

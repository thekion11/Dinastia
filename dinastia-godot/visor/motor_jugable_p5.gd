extends "res://visor/motor_jugable_p5_p1.gd"
## (Parte 2 de 2 de `motor_jugable_p5.gd`.)

## La foto del fuera de juego al patear `p`. En saque de banda, córner y saque
## de puerta no hay fuera de juego (regla 11).
func _foto_offside(p: Dictionary) -> void:
	_offside = {}
	_margenes_pase = {}
	if estado == "saque" and String(saque.get("tipo", "")) in ["banda", "corner", "puerta"]:
		return
	var local := bool(p["es_local"])
	var d := dir_ataque(local)
	## El penúltimo rival (el portero cuenta): la línea del fuera de juego.
	var prof: Array = []
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != local:
			prof.append(pos(q).z * d)
	if prof.size() < 2:
		return
	prof.sort()
	var penultimo: float = prof[prof.size() - 2]
	var balon_prof := balon.position.z * d
	var ids := {}
	_margenes_pase = {"local": local, "m": {}, "z": {}, "linea": maxf(balon_prof, penultimo) * d}
	for q: Dictionary in jugadores:
		if q == p or bool(q["es_local"]) != local:
			continue
		var z := pos(q).z * d
		if z > 0.0:
			_margenes_pase["m"][String(q.get("id", ""))] = z - maxf(balon_prof, penultimo)
			_margenes_pase["z"][String(q.get("id", ""))] = pos(q).z
		## En campo rival, por delante del balón y del penúltimo (con 30 cm de
		## tolerancia: la línea la marca el cuerpo, no los pies).
		if z > 0.0 and z > balon_prof + 0.3 and z > penultimo + 0.3:
			ids[String(q.get("id", ""))] = true
	if not ids.is_empty():
		_offside = {"local": local, "ids": ids, "de": String(p.get("slot_code", "")), "anim": _ultima_anim, "t": t,
			"por": bool(p["por"]), "z": pos(p).z * d}

## EL GESTO QUE TOCA (13-10-2026). Hay 333 animaciones de futbolista y el motor
## usaba un puñado, y los golpeos se sorteaban a ciegas (un pase corto podía
## salir con gesto de rabona). Aquí se elige por la jugada: tiro colocado,
## cañonazo, rosca, de primera, volea o en carrera; pase interior, al pie,
## bombeado, largo, filtrado, atrás o de primera; centro, despeje, saque de
## banda, cabezazo de pase o de remate. Y el zurdo, con la zurda (espejo).
func _golpeo_anim(p: Dictionary, ap: AnimationPlayer, anim: String, destino: Vector3, desde: Vector3, vh: float, loft: float, efecto: float) -> String:
	var d := dir_ataque(bool(p["es_local"]))
	var dist := Vector2(destino.x - desde.x, destino.z - desde.z).length()
	var de_primera := t - float(p.get("tomo_en", -9.0)) < 0.35
	var en_aire := desde.y > 0.45
	var sp := (p["vel"] as Vector3).length()
	var ops: Array = []
	match _ctx_golpeo:
		"tiro":
			if en_aire:
				ops = ["volea", "media_volea"] if desde.y < 1.2 else ["tijera", "chilena"]
			elif de_primera:
				ops = ["tiro_de_primera"]
			elif absf(efecto) > 2.2:
				ops = ["tiro_rosca", "trivela"]
			elif vh > 30.0:
				ops = ["tiro_canonazo", "tiro_empeine", "tiro_seco"]
			elif sp > 5.0:
				ops = ["tiro_carrera"]
			else:
				ops = ["tiro_colocado", "tiro_rastron", "tiro_puntera"]
		"filtrado":
			ops = ["pase_filtrado"]
		"centro":
			ops = ["centro_raso"] if destino.y < 0.6 else (["centro_rosca", "centro"] if absf(efecto) > 3.0 else ["centro"])
		"despeje":
			ops = ["patear", "pase_largo"]
		"banda":
			ops = ["saque_banda"]
		"mano":
			ops = ["saque_mano"]
		_:
			if anim == "cabezazo":
				ops = ["cabezazo_potente", "cabezazo_picado"] if vh > 15.0 else ["pase_cabeza", "cabezazo"]
			elif en_aire and anim == "pase":
				ops = ["pase_pecho"] if desde.y > 1.0 else ["media_volea"]
			elif anim == "pase":
				var atras := (destino.z - desde.z) * d < -3.0
				if sp > 4.5 and loft <= 0.0 and not de_primera and not atras and ap.has_animation("pase_carrera"):
					ops = ["pase_carrera"]   ## pasando a la carrera, el de League-Soccer (01-11)
				elif loft > 0.0:
					ops = ["pase_largo", "pase_bombeado"] if dist > 28.0 else ["pase_bombeado"]
				elif de_primera:
					ops = ["pase_primera"]
				elif atras:
					ops = ["pase_atras"]
				elif dist < 13.0:
					ops = ["pase_interior", "pase"]
				elif absf(destino.x - desde.x) > absf(destino.z - desde.z) * 1.6:
					ops = ["pase_lateral", "pase_cruzado"]
				else:
					ops = ["pase_empeine", "pase", "pase_exterior"]
			else:
				ops = [anim]
	var vivos: Array = ops.filter(func(n: String) -> bool: return ap.has_animation(n))
	## (16-11, M6-21) El sorteo del gesto no gasta el `_rng` del motor: si no, el partido con la misma semilla dependía de qué clips había cargados.
	var nombre := String(vivos[absi(hash(String(p.get("id", "")) + ":" + str(_n_patada))) % vivos.size()]) if not vivos.is_empty() else anim
	if AnimExtra.es_zurdo(String(p.get("id", ""))) and ap.has_animation(nombre + "_espejo"):
		nombre += "_espejo"
	return nombre

## (16-11, informe M6-06) La ley con que rueda el balón suelto, para quien lo PREDICE: aquí la de siempre; `MotorLeague` las cambia
## por la de League cuando es su física la que mueve el balón (C4). Ver `visor/ley_balon.gd`.
func _velocidad_pase(dist: float, sobra: float) -> float:
	return LeyBalon.velocidad_siempre(dist, sobra)

## (16-11, H1 A1.2) El PASE MANUAL raso (`_pase_manual`), con la ley que mueve el balón: aquí la de siempre y su sobra de 4 m
## de antes (el motor de siempre no cambia); `MotorLeague` usa la de League (antes C4 lo pedía con esta y un 12 m rodaba 8,3).
func _velocidad_pase_manual(dist: float) -> float:
	return LeyBalon.velocidad_siempre(dist, 4.0)

## El raso más largo que llega con la fuerza máxima de un pase; más lejos, por arriba.
func _raso_max() -> float:
	return 36.0

## Cuánto más rápido hay que lanzar para que el aire no lo deje corto (ver `compensa_arrastre`).
func _compensa_aire(vh: float, tv: float) -> float:
	return 1.0 / (1.0 - minf(ARRASTRE_CUAD * vh * tv, 0.2))

## (16-11, informe M6-10) El portero solo es intocable y lleva el balón «en la mano» dentro de su área; fuera, conduce como uno más.
func _portero_intocable(p: Dictionary) -> bool:
	return bool(p["por"]) and _en_su_area(p, pos(p))

# ---------------------------------------------------------------- animación de los 22 en C++

## (16-11, paso a C++, orden del dueño «50/60 % del tiempo de CPU en C++») `animar_jugadores` decide y pone la animación de los 22 en una llamada; los casos raros
## (el que se levanta y el parado que quizá está fundido) los hace `_animar_uno` como siempre. Equivale al bucle de `super` porque cada jugador solo toca lo suyo.
## Con `comparar_anim` (pruebas) se comparan las decisiones con `_anim_decidir_gd` y el estado que deja con `_anim_esperado_gd`.
const ANIMS_NAT := ["parado", "trotar", "correr", "conducir", "trotar_atras", "marcar", "portero_listo", "portero_lateral_der", "portero_lateral_izq", "cansado"]
static var anim_gd := false
static var comparar_anim := false
static var anim_comparados := 0
static var anim_distintos := 0

## ¿Pasa `_anim` por las capas de League (`LeagueAcciones.ocupado`, `LeagueLocomocion.bloquea`, `igualar`)? Lo sobrescribe `MotorLeague`.
func _anim_league() -> bool:
	return false

func _mover_jugadores(delta: float) -> void:
	var nat := Nativo.obj()
	if nat == null or anim_gd or not nat.has_method("animar_jugadores"):
		super(delta)
		return
	var res := _mover_fisica(delta, balon.position)
	var pid: Variant = poseedor.get("id") if not poseedor.is_empty() else null
	var esperado: Array = []
	if comparar_anim:
		anim_comparados += 1
		var dec_c: PackedFloat64Array = nat.animar_jugadores(jugadores, res, t, pid, cansancio_real, _anim_league(), false)
		var dec_g := _anim_decidir_gd(res)
		if var_to_bytes(dec_c) != var_to_bytes(dec_g):
			anim_distintos += 1
		for i in jugadores.size():
			esperado.append(_anim_esperado_gd(jugadores[i], int(dec_g[i * 2])))
	var d: PackedFloat64Array = nat.animar_jugadores(jugadores, res, t, pid, cansancio_real, _anim_league(), true)
	for i in jugadores.size():
		if is_equal_approx(d[i * 2], -2.0):
			_animar_uno(i, res)
		elif comparar_anim and d[i * 2] >= 0.0:
			var p: Dictionary = jugadores[i]
			if esperado[i] != [String(p.get("anim_actual", "")), String(p.get("ls_pedido", "")), p.has("ls_tiempo_de")]:
				anim_distintos += 1

## Gemela de las decisiones de `animar_jugadores`: [código, escala] por jugador (−1 = no se toca, −2 = `_animar_uno`).
func _anim_decidir_gd(res: PackedFloat64Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(jugadores.size() * 2)
	for idx in jugadores.size():
		out[idx * 2] = -1.0
		out[idx * 2 + 1] = -1.0
		var p: Dictionary = jugadores[idx]
		if is_zero_approx(res[idx * 4]):
			continue
		if float(p.get("levantar_en", 0.0)) > 0.0:
			out[idx * 2] = -2.0
			continue
		if float(p.get("gesto_hasta", 0.0)) > t:
			continue
		var sp := res[idx * 4 + 1]
		var anim := CicloCarrera.ciclo(sp, String(p.get("anim_actual", "")))   ## (17-11) igual que `animar_jugadores` (C++)
		if poseedor == p and sp >= 0.5 and sp < 6.5:
			anim = "conducir"
		elif res[idx * 4 + 2] > 0.5:
			anim = "trotar_atras"
		elif bool(p.get("jockey", false)) and poseedor != p and sp < 4.5:
			anim = "marcar"
		elif sp < 0.5 and bool(p["por"]) and res[idx * 4 + 3] < 32.0:
			anim = "portero_listo"
		elif bool(p["por"]) and poseedor != p and sp >= 0.5 and sp < 6.0:
			var n: Node3D = p["node"]
			var vel: Vector3 = p["vel"]
			var fr := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
			var lat := vel.dot(Vector3(-fr.z, 0, fr.x))
			var fon := vel.dot(fr)
			if absf(lat) >= absf(fon) * 0.8:
				anim = "portero_lateral_der" if lat > 0.0 else "portero_lateral_izq"
			elif fon < 0.0:
				anim = "trotar_atras"
		elif sp < 0.5 and cansancio_real:
			out[idx * 2] = -2.0
			continue
		out[idx * 2] = float(ANIMS_NAT.find(anim))
		out[idx * 2 + 1] = CicloCarrera.escala(anim, sp)
	return out

## Lo que dejaría `_anim(p, nombre, false)` en el jugador: [anim_actual, ls_pedido, ¿sigue ls_tiempo_de?].
func _anim_esperado_gd(p: Dictionary, codigo: int) -> Array:
	var r := [String(p.get("anim_actual", "")), String(p.get("ls_pedido", "")), p.has("ls_tiempo_de")]
	if codigo < 0:
		return r
	var nombre: String = ANIMS_NAT[codigo]
	if _anim_league():
		if p.has("ls_propio_hasta"):
			return r
		if not (float(p.get("ls_trans_hasta", 0.0)) <= t and is_zero_approx(float(p.get("ls_cuerpo", 0.0)))):
			r[1] = nombre
			return r
		r[2] = false
	var ap: AnimationPlayer = p.get("anim")
	if r[0] != nombre and is_instance_valid(ap) and ap.has_animation(nombre):
		r[0] = nombre
	return r

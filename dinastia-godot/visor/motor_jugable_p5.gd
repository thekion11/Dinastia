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
	var nombre := String(vivos[_rng.randi() % vivos.size()]) if not vivos.is_empty() else anim
	if AnimExtra.es_zurdo(String(p.get("id", ""))) and ap.has_animation(nombre + "_espejo"):
		nombre += "_espejo"
	return nombre

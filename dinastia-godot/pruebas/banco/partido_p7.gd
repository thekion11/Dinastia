extends "res://pruebas/banco/partido_p6.gd"
## [Capa 7/8 de `partido.gd`] _probar_dorsales_anim
## (17-11, punto 7 de `docs/04_auditorias/COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md`) El dorsal y el apellido de la espalda
## (`DisenosKit`, `visor/dorsal_q.gdshaderinc`) y la animación más natural (`CicloCarrera`, `InerciaCuerpo`): lo comprobable sin
## pantalla. Lo visual se revisa con `pruebas/captura_dorsales_anim.tscn` (fotos en `docs/04_auditorias/capturas_dorsales_anim_2026-11-17/`).

func _probar_dorsales_anim() -> void:
	_titulo("PARTIDO: DORSAL Y NOMBRE EN LA ESPALDA, CARRERA SIN PATINAR E INERCIA (SOLO VISUAL)")
	_dq_letras_y_ribete()
	_dq_ciclo_carrera()
	_dq_trote_cmu()
	_dq_inercia_curva()
	_dq_inercia_partido()

func _dq_letras_y_ribete() -> void:
	var l := DisenosKit.letras_nombre("  Muñoz-Peña ")
	_comprobar(Array(l) == [13, 21, 14, 15, 26, 28, 16, 5, 14, 1, 0, 0] and DisenosKit.largo_nombre(l) == 10,
		"dorsal: «Muñoz-Peña» pasa a MUNOZ-PENA en la fuente de 5 × 7 (%s)" % str(l))
	var l2 := DisenosKit.letras_nombre("O'Brien Çakır van der Saar")
	_comprobar(l2.size() == DisenosKit.NOMBRE_MAX and l2[1] == 29 and l2[8] == 3,
		"dorsal: el apóstrofo, la Ç y los nombres de más de 12 letras (se cortan) (%s)" % str(l2))
	_comprobar(DisenosKit.apellido_espalda("Lionel Andrés Messina") == "Messina" and DisenosKit.apellido_espalda("") == "",
		"dorsal: a la espalda va el apellido (la última palabra), como en el rótulo del partido")
	## Contraste: blanco sobre azul marino se lee solo; blanco sobre blanco y rojo sobre rayas rojas llevan ribete.
	var solo := DisenosKit.ribete_numero(Color.WHITE, [Color("0b1f4d")])
	var blanco := DisenosKit.ribete_numero(Color.WHITE, [Color("f4f4f4")])
	var rayas := DisenosKit.ribete_numero(Color("c8102e"), [Color.WHITE, Color("c8102e")])
	_comprobar(solo.a == 0.0 and blanco.a > 0.06 and blanco.get_luminance() < 0.2 and rayas.a > 0.06 and rayas.get_luminance() > 0.8,
		"dorsal: ribete solo cuando hace falta (marino %.3f, blanco sobre blanco %.3f oscuro, rojo sobre rayas rojas %.3f claro)" % [solo.a, blanco.a, rayas.a])
	var u := DisenosKit.uniforms({"dis": "liso", "cols": ["ffd600", "0b1f4d"], "num": "0b1f4d"}, 9, "Gómez")
	var u0 := DisenosKit.uniforms({"dis": "liso", "cols": ["ffd600", "0b1f4d"], "num": "0b1f4d"}, 0, "Gómez")
	_comprobar(int(u["nombre_n"]) == 5 and int(u0["nombre_n"]) == 0 and u.has("color_num_borde"),
		"dorsal: el shader recibe el apellido (5 letras) y, sin dorsal, nada en la espalda")

## La carrera: histéresis entre trotar y correr y la zancada que va con el cuerpo en todo el tramo de cada ciclo.
func _dq_ciclo_carrera() -> void:
	var hist := CicloCarrera.ciclo(5.0, "trotar") == "trotar" and CicloCarrera.ciclo(5.0, "correr") == "correr" \
		and CicloCarrera.ciclo(4.4, "correr") == "trotar" and CicloCarrera.ciclo(5.3, "trotar") == "correr" and CicloCarrera.ciclo(0.3, "correr") == "parado"
	_comprobar(hist, "carrera: de trotar a correr a 5,2 m/s y de vuelta por debajo de 4,5 (sin cambiar de ciclo cada fotograma)")
	## Velocidad que sube de 0,5 a 9,5 m/s y vuelve: lo que patina el pie, con la escala de antes (0,7-1,4) y la de ahora.
	var peor_antes := 0.0
	var peor := 0.0
	var cambios := 0
	var actual := "parado"
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for i in 400:
		var sp := 0.5 + 9.0 * (1.0 - absf(float(i) / 200.0 - 1.0)) + rng.randf_range(-0.15, 0.15)
		var c := CicloCarrera.ciclo(sp, actual)
		if c != actual:
			cambios += 1
		actual = c
		var viejo := "parado" if sp < 0.5 else ("trotar" if sp < 5.2 else "correr")
		if viejo != "parado":
			var v0: float = CicloCarrera.CICLO[viejo][0]
			peor_antes = maxf(peor_antes, absf(sp - v0 * clampf(sp / v0, 0.7, 1.4)))
		if sp >= 2.0 and sp <= 10.0:
			peor = maxf(peor, CicloCarrera.patina(c, sp))
	_comprobar(peor < 0.05 and peor_antes > 0.4, "carrera: entre 2 y 10 m/s el pie no patina (%.2f m/s; antes hasta %.2f)" % [peor, peor_antes])
	_comprobar(cambios <= 6, "carrera: con la velocidad temblando ±0,15 m/s, solo %d cambios de ciclo en una subida y bajada" % cambios)

## EL TROTE DE CAPTURA REAL (`TroteCmu`): repartido por jugador, cada clip sin patinar en todo su tramo (con sus umbrales) y, en el
## cuerpo de verdad, con el pie de apoyo a la velocidad de la tabla y apoyado en el césped (la retarget de CMU flotaba 5-21 cm).
func _dq_trote_cmu() -> void:
	var usados := {}
	var originales := 0
	for i in 22:
		var b := TroteCmu.base_de("jug_%d_%d" % [i, i * 37])
		if b == "":
			originales += 1
		else:
			usados[b] = true
	_comprobar(usados.size() >= 10 and originales >= 1 and originales <= 8 and TroteCmu.base_de("x7") == TroteCmu.base_de("x7"),
		"trote CMU: 22 jugadores, %d trotes distintos y %d con el de siempre (siempre el mismo para cada uno)" % [usados.size(), originales])
	var peor := 0.0
	var peor_hi := 0.0
	var cambios_max := 0
	for base: String in TroteCmu.CLIPS:
		var v := float(TroteCmu.CLIPS[base][0])
		var p := {"trote_cmu": [TroteCmu.PREFIJO + base, v, TroteCmu.umbral_correr(v)]}
		var actual := "parado"
		var cambios := 0
		var rng := RandomNumberGenerator.new()
		rng.seed = 23
		for i in 400:
			var sp := 0.5 + 9.0 * (1.0 - absf(float(i) / 200.0 - 1.0)) + rng.randf_range(-0.15, 0.15)
			var c := CicloCarrera.ciclo_jugador(p, sp, actual)
			cambios += 1 if c != actual else 0
			actual = c
			if sp >= 2.0 and sp <= 10.0:
				peor = maxf(peor, CicloCarrera.patina_jugador(p, c, sp))
			if c == "trotar":
				peor_hi = maxf(peor_hi, CicloCarrera.escala_jugador(p, c, sp))
		cambios_max = maxi(cambios_max, cambios)
	## (×1,45 como regla; el más lento, 3,11 m/s, llega a ×1,48 porque nadie pasa a correr antes de 4,6 m/s)
	_comprobar(peor < 0.05 and peor_hi <= TroteCmu.A_CORRER_MIN / 3.1 and cambios_max <= 6,
		"trote CMU: los 24 clips, entre 2 y 10 m/s el pie no patina (%.2f m/s), la mocap no pasa de ×%.2f y ≤ %d cambios de ciclo" % [peor, peor_hi, cambios_max])
	var raiz := Node3D.new()
	add_child(raiz)
	var d := FutbolistaQ.crear(1.8, "male")
	raiz.add_child(d["nodo"])
	FutbolistaQ.terminar(d, true)
	var dv := 0.0
	var suelo := 0.0
	var en_fase := 0
	for base: String in TroteCmu.CLIPS:
		var clave := TroteCmu.PREFIJO + base
		if not TroteCmu.asegurar(d["anim"], d["esqueleto"], base, clave):
			continue
		var m := AnimPasos.medir((d["anim"] as AnimationPlayer).get_animation(clave), d["esqueleto"])
		dv = maxf(dv, absf(float(m["vel"]) - float(TroteCmu.CLIPS[base][0])))
		suelo = maxf(suelo, absf(float(m["suelo"])))
		en_fase += 1 if AnimPasos.fases.has(clave) and (d["anim"] as AnimationPlayer).get_animation(clave).loop_mode == Animation.LOOP_LINEAR else 0
	_comprobar(dv < 0.05 and suelo < 0.01 and en_fase == TroteCmu.CLIPS.size(),
		"trote CMU: en el cuerpo real, el pie de apoyo a la velocidad de la tabla (±%.2f m/s), en el césped (%.3f m) y los %d en bucle y con su fase" % [dv, suelo, en_fase])
	raiz.queue_free()

## Un cuerpo que corre en círculo a 6 m/s (radio 8 m): se ladea hacia dentro, sin pasar del tope; en recta, derecho.
func _dq_inercia_curva() -> void:
	var raiz := Node3D.new()
	add_child(raiz)
	var cuerpo := Node3D.new()
	raiz.add_child(cuerpo)
	var iner := InerciaCuerpo.new()
	iner.cuerpo = cuerpo
	var dt := 1.0 / 30.0
	var w := 6.0 / 8.0
	for i in 90:
		var a := w * dt * float(i)
		cuerpo.global_position = Vector3(8.0 * cos(a), 0.0, 8.0 * sin(a))
		cuerpo.rotation.y = atan2(-sin(a), cos(a))   ## mira hacia donde va (tangente)
		iner.seguir(dt, Vector3.INF, true)
	var centro := -cuerpo.global_position.normalized()
	var hacia_dentro := iner.inclina.normalized().dot(centro)
	_comprobar(hacia_dentro > 0.9 and iner.inclina.length() <= InerciaCuerpo.LADEO_MAX + 0.01 and iner.inclina.length() > 0.15,
		"inercia: en la curva se ladea hacia dentro (%.2f) %.1f° (tope 13°)" % [hacia_dentro, rad_to_deg(atan(iner.inclina.length()))])
	for i in 60:
		cuerpo.global_position += Vector3(0, 0, 6.0 * dt)
		cuerpo.rotation.y = 0.0
		iner.seguir(dt, Vector3.INF, true)
	_comprobar(iner.inclina.length() < 0.02 and absf(iner.torso) < 0.02, "inercia: a velocidad constante en recta va derecho (%.3f)" % iner.inclina.length())
	iner.free()
	raiz.queue_free()

## En un partido: la inercia se monta en ALTA, se mueve en los cercanos, NO cambia la huella del motor y no existe en las bajas.
func _dq_inercia_partido() -> void:
	var cal := Calidad.elegida
	var ligero := Calidad.partido_ligero
	var antes := InerciaCuerpo.encendida
	var huellas: Array[String] = []
	var activos := 0
	var max_lean := 0.0
	var max_torso := 0.0
	var pelvis_mueve := false
	var trote_antes := TroteCmu.encendida
	var con_trote := {}
	var trotando_cmu := 0
	for con: bool in [false, true]:
		InerciaCuerpo.encendida = con
		TroteCmu.encendida = con
		Calidad.elegida = Calidad.ALTA
		Calidad.partido_ligero = false
		var raiz := Node3D.new()
		add_child(raiz)
		var mo := _motor_c6(raiz, "combinado_c4", ["KOR", "FRA"], 6)
		MiradaBalon.poner(mo.jugadores, mo.balon, mo)
		var ac: AnimacionCercana = mo.get_node_or_null("AnimacionCercana")
		for i in 360:
			mo.paso(1.0 / 30.0)
			if ac != null:
				ac.actualizar(1.0 / 30.0, mo.balon.global_position + Vector3(0, 12, -18))
			if not con:
				continue
			for p: Dictionary in mo.jugadores:
				var tc: Array = p.get("trote_cmu", [])
				if not tc.is_empty():
					if i == 0:
						con_trote[String(tc[0])] = int(con_trote.get(String(tc[0]), 0)) + 1
					if p.get("anim_actual") == "trotar" and String((p["anim"] as AnimationPlayer).current_animation) == String(tc[0]):
						trotando_cmu += 1
				var esq := FutbolistaQ.esqueleto_de(p["node"])
				var iner: InerciaCuerpo = esq.get_node_or_null("InerciaCuerpo") if esq != null else null
				if iner == null or not iner.active:
					continue
				activos += 1
				max_lean = maxf(max_lean, iner.inclina.length())
				max_torso = maxf(max_torso, absf(iner.torso))
				if not pelvis_mueve and i > 120 and iner.inclina.length() > 0.08 and iner.peso > 0.9:
					pelvis_mueve = _pelvis_se_inclina(esq, iner)
		huellas.append(_huella_h1(mo))
		raiz.queue_free()
	InerciaCuerpo.encendida = antes
	TroteCmu.encendida = trote_antes
	_comprobar(huellas[0] == huellas[1], "inercia y trote CMU: con el ladeo, el torso y el trote de cada uno la huella del motor no cambia (%s = %s)" % [huellas[0], huellas[1]])
	var n_trote := 0
	for k: String in con_trote:
		n_trote += int(con_trote[k])
	_comprobar(con_trote.size() >= 6 and n_trote >= 12 and trotando_cmu > 300,
		"trote CMU: en el partido %d jugadores con %d trotes distintos, y trotan con el suyo (%d pasos·jugador)" % [n_trote, con_trote.size(), trotando_cmu])
	_comprobar(activos > 500 and max_lean > 0.05 and max_lean <= Vector2(InerciaCuerpo.LADEO_MAX, InerciaCuerpo.CABECEO_MAX).length() + 0.01 and max_torso > 0.05 and max_torso <= InerciaCuerpo.TORSO_MAX + 0.01,
		"inercia: activa en los cercanos (%d pasos·jugador), ladeo máx. %.1f° (tope 13° de lado y 9° de frente), torso máx. %.1f°" % [activos, rad_to_deg(atan(max_lean)), rad_to_deg(max_torso)])
	_comprobar(pelvis_mueve, "inercia: el modificador inclina de verdad la pelvis del esqueleto")
	Calidad.elegida = Calidad.ULTRA_BAJA
	var raiz2 := Node3D.new()
	add_child(raiz2)
	var mo2 := _motor_c6(raiz2, "combinado_c4", ["NGA", "URU"], 3)
	MiradaBalon.poner(mo2.jugadores, mo2.balon, mo2)
	var n_iner := 0
	for p: Dictionary in mo2.jugadores:
		var esq := FutbolistaQ.esqueleto_de(p["node"])
		n_iner += esq.find_children("*", "InerciaCuerpo", false, false).size() if esq != null else 0
		n_iner += 0 if (p.get("trote_cmu", []) as Array).is_empty() else 1
	_comprobar(n_iner == 0, "inercia y trote CMU: en ULTRA BAJA no se montan en nadie (%d)" % n_iner)
	raiz2.queue_free()
	Calidad.elegida = cal
	Calidad.partido_ligero = ligero

## Corre el modificador a mano (en el banco no hay fotogramas): el eje de la pelvis se aparta de la vertical.
func _pelvis_se_inclina(esq: Skeleton3D, iner: InerciaCuerpo) -> bool:
	var ip := esq.find_bone("pelvis")
	esq.reset_bone_poses()
	var antes := esq.get_bone_global_pose(ip).basis
	iner._process_modification()
	var despues := esq.get_bone_global_pose(ip).basis
	return antes.get_rotation_quaternion().angle_to(despues.get_rotation_quaternion()) > 0.03

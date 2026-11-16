extends "res://pruebas/banco/partido_p5.gd"
## [Capa 6/7 de `partido.gd`] _probar_frontera_mitad, _probar_entrada_por_pasos, _probar_arreglos_motor_c6
## (16-11) Las pruebas de los arreglos del capítulo 6 del informe AAA (fallos del motor del partido) y de su revisión
## independiente (anexo A): el cambio de mitad con el MISMO motor, la entrada a 30 y 120 FPS y el reglamento.

## Un motor `cual` listo con dos clubes de países distintos (nunca un solo club en las pruebas).
func _motor_c6(raiz: Node3D, cual: String, paises: Array, semilla: int) -> MotorJugable:
	var mu := Mundo.new()
	var ps: Array[String] = []
	ps.assign(paises)
	mu.generar(ps, semilla)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var a: Club = mu.ligas[0].clubes[semilla % 4]
	var b: Club = mu.ligas[mu.ligas.size() - 1].clubes[(semilla + 2) % 4]
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var mo := MotorFabrica.crear(cual)
	raiz.add_child(mo)
	mo.set_physics_process(false)
	mo.autopiloto = true
	var bola := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	mo.preparar(lista, bola, "", semilla)
	return mo

## El plazo más lejano en el futuro (s) de todo el estado del motor: jugadores («*_hasta», «*_en», «*_desde»), relojes
## de la capa 1, diccionarios del motor y metadatos de los módulos (presión por zona, carreras, pared, ventaja…).
func _plazo_mas_lejano(m: MotorJugable) -> Array:
	var peor := -INF
	var donde := ""
	for p: Dictionary in m.jugadores:
		for k: Variant in p.keys():
			var ks := String(k)
			if p[k] is float and (ks.ends_with("_hasta") or ks.ends_with("_en") or ks.ends_with("_desde") or MotorJugable._CLAVES_T.has(ks)) and float(p[k]) - m.t > peor:
				peor = float(p[k]) - m.t
				donde = "%s.%s" % [String(p.get("slot_code", "")), ks]
	for nombre: String in MotorJugable._RELOJES + ["_decision_en"]:
		var v: Variant = m.get(nombre)
		for x: Variant in (v if v is Array else [v]):
			if x is float and float(x) - m.t > peor and not nombre.ends_with("_desde") and nombre != "_rb_ultimo" and nombre != "_y_ultimo" and nombre != "_presion_doble":
				peor = float(x) - m.t
				donde = nombre
	for nombre: StringName in m.get_meta_list():
		var v: Variant = m.get_meta(nombre)
		var dics: Array = [v] if v is Dictionary else []
		if v is Dictionary:
			for sub: Variant in (v as Dictionary).values():
				if sub is Dictionary:
					dics.append(sub)
		for d: Dictionary in dics:
			for k: Variant in d.keys():
				if d[k] is float and (String(nombre) == "zona_hasta" or String(k) in ["hasta", "libre", "t"]) and float(d[k]) - m.t > peor:
					peor = float(d[k]) - m.t
					donde = "%s.%s" % [nombre, k]
	return [peor, donde]

## M6-02/03/08/09 y anexo A: un partido con el MISMO motor (dos mitades y prórroga). En el último paso de cada parte se
## ponen plazos de los que el cambio de mitad dejaba vivos (mirar, levantarse, presión por zona, carrera al espacio,
## centro de C4, ventaja); al empezar la siguiente ninguno puede quedar más de 10 s en el futuro.
func _probar_frontera_mitad() -> void:
	_titulo("PARTIDO: FRONTERA DE MITAD (MISMO MOTOR, DOS MITADES Y PRÓRROGA)")
	for caso: Array in [["combinado_c4", ["ARG", "ITA"], 7], ["siempre", ["BRA", "ESP"], 12]]:
		var raiz := Node3D.new()
		add_child(raiz)
		var mo := _motor_c6(raiz, String(caso[0]), caso[1], int(caso[2]))
		mo.duracion_mitad = 30.0
		mo.eliminatoria = true
		mo.anadido = [0.0, 0.0, 0.0, 0.0]
		var mitad := mo.mitad
		var revisadas := 0
		var malas: Array = []
		for i in 12000:
			if mo.estado == "fin" or mo.estado == "tanda":
				break
			if mo.mitad == 2 and mo.estado == "juego":
				mo.goles = [1, 1]   ## empate: hay prórroga
			if mo.estado == "juego" and mo.t >= mo.dur_mitad() - 1.0 / 30.0 - 0.0001 and mo.t < mo.dur_mitad():
				var p: Dictionary = mo.jugadores[3 + mo.mitad]
				p["mirar_hasta"] = mo.t + 0.35
				p["mirar"] = 1.0
				p["levanta_hasta"] = mo.t + 3.4
				p["levantar_en"] = mo.t + 1.6
				mo.set_meta("zona_hasta", {true: mo.t + 3.0, false: mo.t + 4.0})
				mo.set_meta("_carrera_l", {"id": String(p["id"]), "hasta": mo.t + 5.0, "libre": mo.t + 6.0, "x": 0.0})
				mo.set_meta("_t_centro", mo.t)
				mo.set_meta("ventaja", {"t": mo.t, "te": 0.0, "lugar": Vector3.ZERO, "local": true, "nombre": ""})
			mo.paso(1.0 / 30.0)
			if mo.mitad != mitad:
				mitad = mo.mitad
				revisadas += 1
				var r := _plazo_mas_lejano(mo)
				if float(r[0]) > 10.0:
					malas.append("mitad %d: %s a %.1f s" % [mitad, String(r[1]), float(r[0])])
				var zona: Dictionary = mo.get_meta("zona_hasta", {})
				if float(zona.get(false, -99.0)) - mo.t > 10.0:
					malas.append("zona_hasta")
		_comprobar(revisadas == 3 and malas.is_empty(), "%s: al empezar el 2.º tiempo y las dos partes de la prórroga ningún plazo queda > 10 s en el futuro (%d revisadas; %s)" % [caso[0], revisadas, str(malas)])
		raiz.queue_free()

## M6-01 (y su revisión): el estadio avanza el motor a pasos de 1/60 s desde `_process`. Una pulsación tiene que valer
## EXACTAMENTE una vez a 30 FPS (2 pasos por fotograma) y a 120 FPS (la mitad de los fotogramas sin paso), y lo pulsado
## con el partido en pausa no se dispara al reanudar. Se reproduce el bucle de `VistaEstadio._paso_motor`.
func _probar_entrada_por_pasos() -> void:
	_titulo("PARTIDO: ENTRADA POR PASOS A 30 Y 120 FPS")
	Mando.registrar()
	const DT := 1.0 / 60.0
	for caso: Array in [[30.0, 1.0], [120.0, 1.0], [45.0, 1.0], [60.0, 0.0]]:
		var fps: float = caso[0]
		var mult: float = caso[1]
		Mando.pasos_activar(true)
		var acum := 0.0
		var vistas := 0
		for f in 24:
			## (`Mando.pasos_fotograma` no se llama: el banco corre en UN fotograma del motor y el `Input` de otras secciones
			## seguiría «recién pulsado»; la pulsación del fotograma se inyecta, que es lo que haría `pasos_fotograma`.)
			if f == 4:
				Mando.pasos_inyectar(&"jugar_cambiar")   ## a 120 FPS cae en un fotograma sin paso: la ve el paso siguiente
			if mult <= 0.0:
				Mando.pasos_consumir()
			acum = minf(acum + mult / fps, DT * 16.0)
			while acum >= DT:
				if Mando.pulsado(&"jugar_cambiar"):
					vistas += 1
				Mando.pasos_consumir()
				acum -= DT
		var esperado := 0 if mult <= 0.0 else 1
		_comprobar(vistas == esperado, "a %d FPS%s la pulsación vale %d vez/veces (%d)" % [int(fps), " en pausa" if mult <= 0.0 else "", esperado, vistas])
	## Tras la pausa, al reanudar no aparece lo pulsado entonces.
	Mando.pasos_inyectar(&"jugar_pase")
	Mando.pasos_consumir()
	_comprobar(not Mando.pulsado(&"jugar_pase"), "lo pulsado en pausa (o en la repetición) no se dispara al reanudar")
	Mando.pasos_activar(false)

## Reglamento, física del balón de C4 y portero (M6-06, 07, 10, 13, 15, 17-20, 22, 24-26; F-01).
func _probar_arreglos_motor_c6() -> void:
	_titulo("PARTIDO: ARREGLOS DEL CAPÍTULO 6 (BALÓN DE C4, REGLAMENTO, PORTERO)")
	var raiz := Node3D.new()
	add_child(raiz)
	var c4 := _motor_c6(raiz, "combinado_c4", ["FRA", "MEX"], 5)
	var bola: Node3D = c4.balon
	## M6-06: el pase raso de N m llega a N m con la física que lo mueve (antes 12 → 8 m).
	var rueda := func(v0: float) -> float:
		c4.poseedor = {}
		c4.estado = "saque"
		bola.position = Vector3(0, 0.11, -45.0)
		c4.vel_balon = Vector3(0, 0, v0)
		c4.giro_balon = Vector3.ZERO
		for i in 900:
			c4._mover_balon(1.0 / 60.0)
			if c4.vel_balon.length() < 0.05:
				break
		return bola.position.z + 45.0
	var cortos: Array = []
	for n: float in [8.0, 12.0, 16.0, 20.0]:
		var vu := clampf(c4._velocidad_pase(n, 4.0), 7.0, 24.0)
		var x: float = rueda.call(vu)
		if x < n or x > n + 4.0:
			cortos.append("%d m→%.1f" % [int(n), x])
	_comprobar(cortos.is_empty() and c4._raso_max() > 20.0 and c4._raso_max() < 26.0, "C4: el pase manual de 8-20 m llega y muere a menos de 4 m del destino (%s); más de %.1f m va por arriba" % [str(cortos), c4._raso_max()])
	_comprobar(is_equal_approx(MotorJugable.velocidad_para(20.0), LeyBalon.velocidad_siempre(20.0)), "el motor de siempre pide sus pases con su ley de siempre")
	## M6-07: el clima llega al balón suelto de League.
	var seco: float = rueda.call(14.0)
	GestoTecnico.fijar_clima(c4, "nieve")
	var nieve: float = rueda.call(14.0)
	GestoTecnico.fijar_clima(c4, "lluvia")
	var lluvia: float = rueda.call(14.0)
	GestoTecnico.fijar_clima(c4, "")
	_comprobar(nieve < seco - 1.0 and lluvia > seco + 0.5, "C4: con nieve el balón suelto rueda menos y con lluvia más (%.1f / %.1f / %.1f m)" % [nieve, seco, lluvia])
	## M6-24: el combinado elige sus piezas del balón por gancho (sin vaciar `equipos` ni apagar `fase3`).
	var f3 := MotorLeague.fase3
	var vistos: Array = []
	c4.gol.connect(func(_l: bool, _a: String, _s: String) -> void: vistos.append([(c4 as MotorLeague).equipos.size(), MotorLeague.fase3]))
	c4.estado = "juego"
	c4.poseedor = {}
	bola.position = Vector3(0, 0.5, c4.LARGO - 0.3)
	c4.vel_balon = Vector3(0, 0, 12.0)
	for i in 4:
		if c4.estado == "juego":
			c4._mover_balon(1.0 / 60.0)
	_comprobar(not vistos.is_empty() and int(vistos[0][0]) == 2 and bool(vistos[0][1]) == f3, "C4: durante un gol los oyentes ven las piezas reales (%s)" % str(vistos))
	## M6-19: gol con la pelota entera.
	var mo := c4
	mo.estado = "juego"
	var g0: int = mo.goles[0] + mo.goles[1]
	bola.position = Vector3(0, 0.5, mo.LARGO + 0.05)
	mo._palos_y_lineas(Vector3(0, 0.5, mo.LARGO - 0.2))
	mo.estado = "juego"
	var medio: int = mo.goles[0] + mo.goles[1]
	bola.position = Vector3(0, 0.5, mo.LARGO + 0.15)
	mo._palos_y_lineas(Vector3(0, 0.5, mo.LARGO + 0.05))
	_comprobar(medio == g0 and mo.goles[0] + mo.goles[1] == g0 + 1, "el gol vale cuando la pelota ENTERA cruza la línea (a 5 cm no; a 15 cm sí)")
	## M6-15: la falta del usuario solo es tiro si va a puerta.
	var lz: Dictionary = mo.jugadores[9]
	var arco := mo._arco_rival(lz)
	var lugar := Vector3(18.0, 0.11, arco.z - signf(arco.z) * 24.0)
	_comprobar(MotorReglas.va_a_puerta(mo, lz, lugar, (arco - lugar).normalized(), 40.0) and not MotorReglas.va_a_puerta(mo, lz, lugar, (Vector3(-2, 0, arco.z - signf(arco.z) * 8.0) - lugar).normalized(), 20.0), "la falta lateral al área no es tiro; la que va a la portería sí")
	## M6-17: tanda igualada y portero de urgencia.
	var ig := MotorReglas.igualar_tanda([[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]])
	_comprobar((ig[0] as Array).size() == 10 and (ig[1] as Array).size() == 10 and not MotorReglas.portero_de_urgencia([{"id": "a"}, {"id": "b"}]).is_empty(), "la tanda se tira con los mismos lanzadores por equipo y sin portero ataja uno de campo")
	## M6-20: doble toque del que saca.
	mo.estado = "saque"
	MotorReglas.marcar_ejecutor(mo, lz)
	mo.estado = "juego"
	mo.ultimo_toque = lz
	var pito := MotorReglas.doble_toque(mo, lz)
	_comprobar(pito and mo.estado == "saque" and String(mo.saque.get("tipo", "")) == "falta" and bool(mo.saque["local"]) != bool(lz["es_local"]), "el que saca y vuelve a tocar sin que lo toque otro: libre indirecto")
	mo.estado = "saque"
	MotorReglas.marcar_ejecutor(mo, lz)
	mo.estado = "juego"
	mo.ultimo_toque = mo.jugadores[15]
	_comprobar(not MotorReglas.doble_toque(mo, lz) and not mo.has_meta("_ejecutor_saque"), "si lo tocó otro antes, no hay doble toque")
	## M6-10: el portero, tocable fuera del área.
	var gk: Dictionary = {}
	for q: Dictionary in mo.jugadores:
		if bool(q["por"]) and bool(q["es_local"]):
			gk = q
	(gk["node"] as Node3D).position = mo._arco_propio(gk) + Vector3(0, 0, mo.dir_ataque(true) * 6.0)
	var dentro := mo._portero_intocable(gk)
	(gk["node"] as Node3D).position = mo._arco_propio(gk) + Vector3(0, 0, mo.dir_ataque(true) * 30.0)
	mo.poseedor = gk
	gk["contacto_hasta"] = 0.0
	gk["gesto_hasta"] = 0.0
	_comprobar(dentro and not mo._portero_intocable(gk) and mo._libre_para_duelo(gk), "el portero es intocable en su área; fuera de ella, un jugador más (entradas y duelos)")
	## M6-13: el que sale no deja referencias.
	var sale: Dictionary = mo.jugadores[7]
	var entra := {"id": "suplente_prueba"}
	mo.pase_a = sale
	mo.ultimo_toque = sale
	mo.saque = {"tipo": "banda", "lanzador": sale}
	MotorReglas.limpiar_sale(mo, sale, entra)
	_comprobar(mo.pase_a.is_empty() and is_same(mo.ultimo_toque, entra) and is_same(mo.saque["lanzador"], entra), "el cambio no deja pases, toques ni saques apuntando al que sale")
	## M6-26 y M6-22: tumbado no se cabecea; con el balón en la mano del portero no hay disputa.
	mo.estado = "juego"
	mo.poseedor = {}
	var cab: Dictionary = mo.jugadores[10]
	for q: Dictionary in mo.jugadores:
		q["enfriar"] = 1.0
	cab["enfriar"] = 0.0
	cab["levanta_hasta"] = mo.t + 3.0
	bola.position = mo.pos(cab) + Vector3(0, 1.9, 0)
	mo.vel_balon = Vector3.ZERO
	var toques: int = mo._n_patada
	mo._disputas(0.0)
	cab["levanta_hasta"] = 0.0
	_comprobar(mo._n_patada == toques, "un jugador en el suelo no cabecea")
	mo._en_mano = {"p": gk, "hasta": mo.t + 0.4, "vel": Vector3.ZERO}
	cab["enfriar"] = 0.0
	bola.position = mo.pos(cab) + Vector3(0, 0.5, 0)
	mo._disputas(0.0)
	_comprobar(mo.poseedor.is_empty() and mo._n_patada == toques, "con el balón en la mano del portero (saque de mano) nadie lo disputa")
	mo._en_mano = {}
	MotorLeague.fase3 = f3
	raiz.queue_free()

## Huella del motor (como `pruebas/igualdad_motor.gd`): balón, los 22 (con su giro), goles, tiros, estado y estadísticas.
func _huella_h1(m: MotorJugable) -> String:
	var s := PackedStringArray()
	s.append("%.3f,%.3f,%.3f" % [m.balon.position.x, m.balon.position.y, m.balon.position.z])
	for p: Dictionary in m.jugadores:
		var q := (p["node"] as Node3D).position
		s.append("%.3f,%.3f,%.3f,%.3f" % [q.x, q.y, q.z, (p["node"] as Node3D).rotation.y])
	s.append(str(m.goles) + str(m.tiros) + m.estado + str(m.stats))
	return str(hash("|".join(s)))

## H1 del informe AAA (16-11): el pie al balón y la cabeza al balón (`AnimacionCercana`, `PieBalonIK`) son SOLO visuales: con
## ellos encendidos y actualizándose cada paso, la huella del motor es la misma; en las calidades bajas y con «Partido ligero»
## no se monta nada y la mirada queda apagada (sin coste).
func _probar_h1_animacion() -> void:
	_titulo("PARTIDO: H1 ANIMACIÓN (PIE Y CABEZA AL BALÓN SIN TOCAR EL MOTOR; NADA EN LAS CALIDADES BAJAS)")
	var cal := Calidad.elegida
	var ligero := Calidad.partido_ligero
	var huellas: Array[String] = []
	var con_pie := 0
	var con_mira := 0
	var acerca := false
	for con_ik: bool in [false, true]:
		Calidad.elegida = Calidad.ALTA
		Calidad.partido_ligero = false
		var raiz := Node3D.new()
		add_child(raiz)
		var mo := _motor_c6(raiz, "combinado_c4", ["MEX", "ITA"], 9)
		MiradaBalon.poner(mo.jugadores, mo.balon, mo if con_ik else null)
		var ac: AnimacionCercana = mo.get_node_or_null("AnimacionCercana")
		if con_ik:
			_comprobar(ac != null, "H1: con calidad ALTA se monta `AnimacionCercana`")
		for i in 900:
			mo.paso(1.0 / 30.0)
			if ac == null:
				continue
			ac.actualizar(1.0 / 30.0, mo.balon.global_position + Vector3(0, 12, -18))
			for p: Dictionary in mo.jugadores:
				var esq := FutbolistaQ.esqueleto_de(p["node"])
				var pie: PieBalonIK = esq.get_node_or_null("PieBalonIK") if esq != null else null
				var mira: LookAtModifier3D = esq.get_node_or_null("MiradaBalon") if esq != null else null
				if pie != null and pie.active and pie.peso > 0.3:
					con_pie += 1
					if not acerca and i > 300:
						acerca = _pie_se_acerca(esq, pie)
				if mira != null and mira.active:
					con_mira += 1
		huellas.append(_huella_h1(mo))
		raiz.queue_free()
	_comprobar(huellas[0] == huellas[1], "H1: con el pie y la cabeza al balón la huella del motor no cambia (%s = %s)" % [huellas[0], huellas[1]])
	_comprobar(con_pie > 20 and con_mira > 900, "H1: el pie se activa en el que toca (%d pasos·jugador) y la cabeza en los cercanos (%d)" % [con_pie, con_mira])
	_comprobar(acerca, "H1: el IK de dos huesos acerca el tobillo al objetivo junto al balón")
	## Calidades bajas y «Partido ligero»: nada montado y la mirada apagada.
	for caso: Array in [[Calidad.ULTRA_BAJA, false], [Calidad.MEDIA_BAJA, false], [Calidad.ULTRA_ALTA, true]]:
		Calidad.elegida = int(caso[0])
		Calidad.partido_ligero = bool(caso[1])
		var raiz := Node3D.new()
		add_child(raiz)
		var mo := _motor_c6(raiz, "combinado_c4", ["JPN", "NGA"], 4)
		MiradaBalon.poner(mo.jugadores, mo.balon, mo)
		var pies := 0
		var miras := 0
		for p: Dictionary in mo.jugadores:
			var esq := FutbolistaQ.esqueleto_de(p["node"])
			pies += esq.find_children("*", "PieBalonIK", false, false).size()
			var mira: LookAtModifier3D = esq.get_node_or_null("MiradaBalon")
			if mira != null and mira.active:
				miras += 1
		_comprobar(mo.get_node_or_null("AnimacionCercana") == null and pies == 0 and miras == 0,
			"H1: en calidad %d (ligero %s) ni pie ni mirada (%d pies, %d miradas activas)" % [int(caso[0]), str(caso[1]), pies, miras])
		raiz.queue_free()
	Calidad.elegida = cal
	Calidad.partido_ligero = ligero

## Corre el modificador a mano (en el banco no hay fotogramas): el tobillo del pie del toque queda más cerca de su objetivo.
func _pie_se_acerca(esq: Skeleton3D, pie: PieBalonIK) -> bool:
	var lado := pie._pie_cercano(esq, esq.global_transform)
	var i3 := esq.find_bone("foot_" + lado)
	var bp := pie.balon.global_position
	var hacia := pie.cuerpo.global_position - bp
	hacia.y = 0.0
	var antes := esq.global_transform * esq.get_bone_global_pose(i3).origin
	var obj := bp + hacia.normalized() * (PieBalonIK.RADIO_BALON + PieBalonIK.SEPARACION)
	obj.y = maxf(antes.y, bp.y - PieBalonIK.RADIO_BALON * 0.5)
	if obj.distance_to(antes) > PieBalonIK.ALCANCE or obj.distance_to(antes) < 0.03:
		return false
	pie.lado = lado
	var peso := pie.peso
	pie.peso = 1.0
	pie._process_modification()
	pie.peso = peso
	var despues := esq.global_transform * esq.get_bone_global_pose(i3).origin
	return despues.distance_to(obj) < antes.distance_to(obj) * 0.6

extends "res://pruebas/banco/partido_p3_p1.gd"
## (Parte 2 de 2 de `partido_p3.gd`.)

## TIRO POR LÍNEA LIMPIA (03-11-2026, IA F6, `MotorTiroLimpio`): apunta al punto del arco que ni el portero ni un defensa tapan.
func _probar_tiro_limpio() -> void:
	_titulo("TIRO POR PROBABILIDAD DE LÍNEA LIMPIA")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var tirador: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))[0]
	var arco := motor._arco_rival(tirador)
	var d := signf(arco.z)
	var rivales: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]))
	var por: Dictionary = rivales.filter(func(p: Dictionary) -> bool: return bool(p["por"]))[0]
	var campo: Array = rivales.filter(func(p: Dictionary) -> bool: return not bool(p["por"]))
	for i in campo.size():
		(campo[i]["node"] as Node3D).position = Vector3(-30.0 + i * 5.0, 0, -d * 30.0)
	(tirador["node"] as Node3D).position = Vector3(0, 0, arco.z - d * 16.0)
	## Portero en el palo izquierdo (x negativo) y un defensa tapando el centro.
	(por["node"] as Node3D).position = Vector3(-2.6, 0, arco.z - d * 0.5)
	(campo[0]["node"] as Node3D).position = Vector3(0, 0, arco.z - d * 8.0)
	var izq := MotorTiroLimpio.limpieza(motor, tirador, -0.82)
	var cen := MotorTiroLimpio.limpieza(motor, tirador, 0.0)
	var der := MotorTiroLimpio.limpieza(motor, tirador, 0.82)
	_comprobar(der > izq and der > cen, "el palo libre (%.2f) es más limpio que el del portero (%.2f) y que el centro tapado (%.2f)" % [der, izq, cen])
	_comprobar(cen < 0.5, "con un defensa en la línea el centro queda tapado (%.2f)" % cen)
	var elegido := 0
	for i in 20:
		var mj := MotorTiroLimpio.mejor(motor, tirador)
		if float(mj[0]) > 0.5:
			elegido += 1
	_comprobar(elegido >= 18, "apunta al palo libre %d de 20 veces" % elegido)
	_comprobar(MotorTiroLimpio.factor_ganas(1.0) > MotorTiroLimpio.factor_ganas(0.0), "limpia da más ganas que tapada")
	(r[1] as Node3D).queue_free()

## ANTICIPACIÓN DEL PORTERO (03-11-2026, IA F7, `MotorParada.destino`): con la parada decidida se desliza hacia el cruce, sin pasarse.
func _probar_portero_anticipa() -> void:
	_titulo("EL PORTERO SE ANTICIPA AL CRUCE")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var gk: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["por"]))[0]
	(gk["node"] as Node3D).position = Vector3(0.0, 0, 50.0)
	_comprobar(MotorParada.destino(motor, gk) == Vector3.INF, "sin parada pendiente no se mueve")
	gk["parada_pend"] = {"cruce": Vector3(3.0, 1.0, 52.0), "estirada": true, "n": 0}
	var d := MotorParada.destino(motor, gk)
	_comprobar(d.x > 0.5 and d.x <= MotorParada.DESLIZA + 0.01, "se desliza hacia el cruce sin pasarse (%.2f m)" % d.x)
	_comprobar(absf(d.z - 50.0) < 0.01, "no se adelanta ni retrocede")
	gk["parada_pend"] = {"cruce": Vector3(0.3, 1.0, 52.0), "estirada": false, "n": 0}
	var d2 := MotorParada.destino(motor, gk)
	_comprobar(absf(d2.x - 0.3) < 0.01, "si el tiro va casi a él, se pone en la línea (%.2f)" % d2.x)
	(r[1] as Node3D).queue_free()

## LA IMAGEN MENTAL (03-11-2026, IA F8, `MotorMente`): la CPU de nivel bajo ve a los rivales donde estaban hace un rato.
func _probar_imagen_mental() -> void:
	_titulo("LA IMAGEN MENTAL DE LA CPU")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	motor.control_equipo = 0   ## el usuario lleva al local; la CPU es la visita
	var local: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))[0]
	var cpu: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))[0]
	var nodo := local["node"] as Node3D
	motor.dificultad_cpu = "practicante"
	motor.t = 10.0
	nodo.position = Vector3(0, 0, 0)
	MotorMente.actualizar(motor)
	motor.t = 10.2
	nodo.position = Vector3(5, 0, 0)
	MotorMente.actualizar(motor)
	motor.t = 10.6
	nodo.position = Vector3(10, 0, 0)
	MotorMente.actualizar(motor)
	_comprobar(absf(MotorMente.retardo(motor, cpu) - 0.5) < 0.001, "el Practicante ve con 0,5 s de retardo")
	var visto := MotorMente.pos_vista(motor, cpu, local)
	_comprobar(visto.x < 5.1, "la CPU de Practicante ve al rival en x=%.1f, no en x=10" % visto.x)
	_comprobar(MotorMente.retardo(motor, local) == 0.0 and MotorMente.pos_vista(motor, local, cpu) == motor.pos(cpu), "el equipo del usuario ve el presente")
	motor.dificultad_cpu = "debutante"
	_comprobar(MotorMente.retardo(motor, cpu) == 0.0 and absf(MotorMente.pos_vista(motor, cpu, local).x - 10.0) < 0.01, "el Debutante lo ve en el presente (calibración de siempre)")
	motor.dificultad_cpu = "ultimate"
	local["vel"] = Vector3(4.0, 0, 0)
	_comprobar(MotorMente.retardo(motor, cpu) < 0.0, "Ultimate se adelanta (retardo negativo)")
	_comprobar(absf(MotorMente.pos_vista(motor, cpu, local).x - (10.0 + 4.0 * 0.3)) < 0.01, "Ultimate ve al rival donde ESTARÁ (x=%.1f)" % MotorMente.pos_vista(motor, cpu, local).x)
	motor.dificultad_cpu = "semiprofesional"
	_comprobar(MotorMente.retardo(motor, cpu) == 0.0, "Semiprofesional ve el presente")
	(r[1] as Node3D).queue_free()

## ROLES DINÁMICOS (03-11-2026, IA F2, `MotorRoles`): si dos laterales se cruzan de banda, intercambian el puesto; el húngaro es óptimo.
func _probar_roles_dinamicos() -> void:
	_titulo("ROLES DINÁMICOS CON EL ALGORITMO HÚNGARO")
	## El húngaro solo: la matriz 3×3 clásica.
	var c := [[4.0, 1.0, 3.0], [2.0, 0.0, 5.0], [3.0, 2.0, 2.0]]
	var a := MotorRoles.hungaro(c)
	var coste := float(c[0][a[0]]) + float(c[1][a[1]]) + float(c[2][a[2]])
	_comprobar(absf(coste - 5.0) < 0.001, "el húngaro halla el coste mínimo 5 (halló %.1f)" % coste)
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var ld: Dictionary = {}
	var li: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if bool(p["es_local"]):
			if motor._rol(p) == "LD" and ld.is_empty():
				ld = p
			elif motor._rol(p) == "LI" and li.is_empty():
				li = p
	if ld.is_empty() or li.is_empty():
		_comprobar(false, "la formación de prueba tiene LD y LI")
		(r[1] as Node3D).queue_free()
		return
	## En su sitio: cada uno su puesto.
	(ld["node"] as Node3D).position = ld["base_pos"]
	(li["node"] as Node3D).position = li["base_pos"]
	motor.t = 20.0
	_comprobar(MotorRoles.base(motor, ld) == ld["base_pos"] and MotorRoles.base(motor, li) == li["base_pos"], "en su sitio, cada uno conserva su puesto")
	## Cruzados de banda (mucho): intercambian.
	(ld["node"] as Node3D).position = li["base_pos"]
	(li["node"] as Node3D).position = ld["base_pos"]
	motor.t = 21.0
	_comprobar(MotorRoles.base(motor, ld) == li["base_pos"] and MotorRoles.base(motor, li) == ld["base_pos"], "cruzados de banda, intercambian el puesto")
	## Histéresis: un pequeño desplazamiento no devuelve el puesto al instante.
	(ld["node"] as Node3D).position = (li["base_pos"] as Vector3) + Vector3(-1.0, 0, 0)
	motor.t = 21.6
	_comprobar(MotorRoles.base(motor, ld) == li["base_pos"], "con el reparto vigente y casi sin mejora, no parpadea")
	(r[1] as Node3D).queue_free()

## APOYO POR CAMPO DE FUERZAS (03-11-2026, IA F3, `MotorApoyo`): anillo de pase, repulsión de compañeros y salida de la línea tapada.
func _probar_apoyo_fuerzas() -> void:
	_titulo("APOYO POR CAMPO DE FUERZAS")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var locales: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]))
	for q: Dictionary in motor.jugadores:
		(q["node"] as Node3D).position = Vector3(-55.0 + randf() * 2.0, 0, 90.0)
	var c: Dictionary = locales[0]
	var p: Dictionary = locales[1]
	var otro: Dictionary = locales[2]
	var nc := c["node"] as Node3D
	var np := p["node"] as Node3D
	nc.position = Vector3(0, 0, 0)
	## 1) Muy lejos del anillo: lo atrae hacia el portador.
	np.position = Vector3(16.0, 0, 0)
	var f1 := MotorApoyo.fuerza(motor, p, c)
	_comprobar(f1.x < 0.0, "a 16 m del portador, el anillo lo acerca (fuerza x %.1f)" % f1.x)
	## 2) Pegado al portador: lo aparta.
	np.position = Vector3(4.0, 0, 0)
	var f2 := MotorApoyo.fuerza(motor, p, c)
	_comprobar(f2.x > 0.0, "a 4 m del portador, lo aparta (fuerza x %.1f)" % f2.x)
	## 3) Un compañero encima: se repelen.
	np.position = Vector3(12.0, 0, 0)
	var f_solo := MotorApoyo.fuerza(motor, p, c)
	(otro["node"] as Node3D).position = Vector3(12.0, 0, 3.0)
	var f_comp := MotorApoyo.fuerza(motor, p, c)
	_comprobar(f_comp.z < f_solo.z - 1.0, "con un compañero a 3 m (por +z), se aparta hacia -z (%.1f frente a %.1f)" % [f_comp.z, f_solo.z])
	(otro["node"] as Node3D).position = Vector3(-55.0, 0, 90.0)
	## 4) Rival en la línea de pase: sale al lado libre.
	var rival: Dictionary = vis.filter(func(q: Dictionary) -> bool: return not bool(q["por"]))[0]
	(rival["node"] as Node3D).position = Vector3(6.0, 0, 0.4)
	var f_t := MotorApoyo.fuerza(motor, p, c)
	_comprobar(absf(f_t.z) > absf(f_solo.z) + 1.0, "con la línea tapada se desvía hacia un lado (|z| %.1f frente a %.1f)" % [absf(f_t.z), absf(f_solo.z)])
	(rival["node"] as Node3D).position = Vector3(-55.0, 0, 90.0)
	## 5) Fuera de alcance: no cambia su puesto. Tope de la fuerza.
	np.position = Vector3(30.0, 0, 0)
	_comprobar(MotorApoyo.punto(motor, p, c, Vector3(30, 0, 0)) == Vector3(30, 0, 0), "a más de 18 m no interviene")
	(otro["node"] as Node3D).position = Vector3(12.0, 0, 0.5)
	np.position = Vector3(12.0, 0, 0)
	_comprobar(MotorApoyo.fuerza(motor, p, c).length() <= MotorApoyo.TOPE + 0.01, "la fuerza nunca pasa del tope")
	(r[1] as Node3D).queue_free()

## ANCLA Y ENJAMBRE (03-11-2026, vídeo del dueño): nadie se aleja de su puesto más de su radio, y los pegados al balón no se marcan al hombre.
func _probar_ancla_enjambre() -> void:
	_titulo("ANCLA A LA POSICIÓN BASE Y SIN ENJAMBRE")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var locales: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var def: Dictionary = locales.filter(func(p: Dictionary) -> bool: return motor._rol(p) == "DFC")[0]
	var base: Vector3 = MotorRoles.base(motor, def)
	var lejos := MotorAncla.limitar(motor, def, base + Vector3(40.0, 0, 0))
	_comprobar(absf(Vector2(lejos.x - base.x, lejos.z - base.z).length() - MotorAncla.radio(motor, def)) < 0.01, "un objetivo a 40 m de su puesto se recorta al radio (%.1f m)" % Vector2(lejos.x - base.x, lejos.z - base.z).length())
	var cerca := base + Vector3(6.0, 0, 3.0)
	_comprobar(MotorAncla.limitar(motor, def, cerca) == cerca, "un objetivo cercano no se toca")
	var delantero: Variant = locales.filter(func(p: Dictionary) -> bool: return motor._rol(p) == "DC")
	if not (delantero as Array).is_empty():
		_comprobar(MotorAncla.radio(motor, def) < MotorAncla.radio(motor, delantero[0]), "la defensa tiene menos radio que el delantero")
	## Sin enjambre: un rival pegado al balón no entra entre los marcados al hombre.
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))
	var arco := motor._arco_propio(def)
	var hacia := (Vector3.ZERO - arco).normalized()
	for i in vis.size():
		(vis[i]["node"] as Node3D).position = Vector3(-30.0 + i * 5.0, 0, -arco.z * 0.9)
	var balon := arco + hacia * 30.0
	motor.balon.position = Vector3(balon.x, 0.11, balon.z)
	(vis[0]["node"] as Node3D).position = balon + Vector3(4.0, 0, 0)       ## pegado al balón
	(vis[1]["node"] as Node3D).position = arco + hacia * 14.0 + Vector3(-8.0, 0, 0)   ## libre y cerca del arco
	motor.poseedor = {}
	motor.t += 1.0
	var mapa := MotorMarcaje.reparto(motor, true)
	_comprobar(not mapa.has(String(vis[0]["id"])), "el rival pegado al balón (4 m) no se marca al hombre: lo cubre la presión")
	_comprobar(mapa.has(String(vis[1]["id"])), "el libre cerca del arco sí tiene marcador")
	(r[1] as Node3D).queue_free()

## EL MAPA DE REGIONES NUMERADAS (03-11-2026, `MotorRegiones`): número de región, centro y ocupación (nadie comparte región).
func _probar_regiones() -> void:
	_titulo("MAPA DE REGIONES NUMERADAS Y OCUPACIÓN")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var ok := true
	for n in MotorRegiones.COLS * MotorRegiones.FILAS:
		var c := MotorRegiones.centro(motor, n)
		ok = ok and MotorRegiones.numero(motor, c.x, c.z) == n
	_comprobar(ok, "el centro de cada una de las %d regiones vuelve a su número" % (MotorRegiones.COLS * MotorRegiones.FILAS))
	_comprobar(MotorRegiones.numero(motor, -999.0, -999.0) == 0 and MotorRegiones.numero(motor, 999.0, 999.0) == MotorRegiones.COLS * MotorRegiones.FILAS - 1, "fuera del campo se recorta a la región de la esquina")
	var locales: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	motor.t += 1.0
	var punto := MotorRegiones.centro(motor, 17) + Vector3(1.0, 0, 1.0)
	var a := MotorRegiones.libre(motor, locales[0], punto)
	var b := MotorRegiones.libre(motor, locales[1], punto)
	var c := MotorRegiones.libre(motor, locales[2], punto)
	_comprobar(a == punto, "el primero se queda con su región")
	var rb := MotorRegiones.numero(motor, b.x, b.z)
	var rc := MotorRegiones.numero(motor, c.x, c.z)
	_comprobar(rb != 17 and rc != 17 and rb != rc, "el segundo y el tercero van a regiones distintas y libres (%d y %d)" % [rb, rc])
	_comprobar(MotorRegiones.libre(motor, locales[0], punto) == punto, "el dueño de la región la conserva en el mismo fotograma")
	motor.t += 0.5
	_comprobar(MotorRegiones.libre(motor, locales[1], punto) == punto, "en el fotograma siguiente la ocupación se reinicia")
	(r[1] as Node3D).queue_free()

## ADAPTABILIDAD, HABILIDADES, FORMACIÓN Y ENTORNO (03-11-2026, `MotorAdaptacion`): lado fuerte del rival y radio de acción por jugador.
func _probar_adaptacion() -> void:
	_titulo("ADAPTACIÓN AL RIVAL, HABILIDADES Y ENTORNO")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var locales: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))
	_comprobar(MotorAdaptacion.desvio_x(motor, true, false) == 0.0, "al principio no se desplaza (aún no sabe por dónde ataca el rival)")
	motor.poseedor = vis[0]
	motor.balon.position = Vector3(25.0, 0.11, 10.0)
	for i in 700:
		MotorAdaptacion.actualizar(motor, 0.1)
	var d := MotorAdaptacion.desvio_x(motor, true, false)
	_comprobar(d > 1.5 and d <= MotorAdaptacion.TOPE_LADO, "tras 70 s con el rival atacando por la derecha, el bloque se corre hacia ese lado (%.1f m)" % d)
	_comprobar(MotorAdaptacion.desvio_x(motor, false, true) == 0.0, "el equipo que ataca no se desplaza")
	_comprobar(MotorAdaptacion.desvio_x(motor, true, true) == 0.0, "con la posesión propia tampoco")
	## Habilidades: un jugador veloz y fuerte tiene más radio que uno lento y débil.
	var p: Dictionary = locales[1]
	var attr_viejo: Dictionary = (p["attr"] as Dictionary).duplicate()
	p["attr"]["rit"] = 1.0
	p["attr"]["fis"] = 1.0
	var rapido := MotorAdaptacion.escala_radio(motor, p)
	p["attr"]["rit"] = 0.15
	p["attr"]["fis"] = 0.15
	var lento := MotorAdaptacion.escala_radio(motor, p)
	p["attr"] = attr_viejo
	_comprobar(rapido > lento + 0.2, "el rápido y fuerte llega más lejos (%.2f frente a %.2f)" % [rapido, lento])
	## Formación: el carrilero tiene más radio.
	var q: Dictionary = locales[2]
	var slot_viejo: Variant = q.get("slot_code", "")
	q["slot_code"] = "LD"
	var normal := MotorAdaptacion.escala_radio(motor, q)
	q["slot_code"] = "CAD"
	var carrilero := MotorAdaptacion.escala_radio(motor, q)
	q["slot_code"] = slot_viejo
	_comprobar(absf(carrilero / normal - 1.3) < 0.01, "el carrilero (CAD) tiene 1,3× de radio (%.2f)" % (carrilero / normal))
	## Entorno: la lluvia junta al bloque.
	motor.clima = ""
	var seco := MotorAdaptacion.escala_radio(motor, p)
	motor.clima = "lluvia"
	var lluvia := MotorAdaptacion.escala_radio(motor, p)
	motor.clima = ""
	_comprobar(absf(lluvia / seco - 0.9) < 0.01, "con lluvia el radio baja un 10 % (%.2f)" % (lluvia / seco))
	(r[1] as Node3D).queue_free()

## LA DEFENSA NO VE UN BALÓN VIEJO (03-11-2026, `MotorColocacion`): con el rival atacando el balón «lento» va casi en directo y el sesgo cae rápido.
func _probar_colocacion_defensa() -> void:
	_titulo("COLOCACIÓN: LA DEFENSA SIGUE AL BALÓN EN DIRECTO")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var loc: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))
	for q: Dictionary in motor.jugadores:
		(q["node"] as Node3D).position = Vector3(-30.0, 0, -40.0)
	motor.poseedor = loc[0]
	motor.balon.position = Vector3(0, 0.11, 0)
	for i in 100:
		MotorColocacion.actualizar(motor, 0.1)
	_comprobar(MotorColocacion.sesgo(motor, true) > 0.9, "el equipo con balón tiene sesgo de posesión alto")
	## El rival roba el balón y sube rápido.
	motor.poseedor = vis[0]
	motor.balon.position = Vector3(0, 0.11, 30.0)
	for i in 10:
		MotorColocacion.actualizar(motor, 0.1)
	_comprobar(MotorColocacion.sesgo(motor, true) < 0.5, "al perder el balón el sesgo cae en 1 s (%.2f)" % MotorColocacion.sesgo(motor, true))
	var z := MotorColocacion.balon_lento(motor, true).z
	_comprobar(z > 22.0, "y el balón que ve el que defiende va casi en directo: %.1f de 30 m en 1 s" % z)
	(r[1] as Node3D).queue_free()

## EL PORTERO SE DESLIZA MIENTRAS ESPERA (03-11-2026, F7 corregida): con la parada pendiente, `_ia_portero` devuelve el punto de deslizamiento en TODOS los fotogramas.
func _probar_portero_desliza_pendiente() -> void:
	_titulo("EL PORTERO SE DESLIZA TODO EL TIEMPO QUE ESPERA LA PARADA")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var gk: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["por"]) and bool(p["es_local"]))[0]
	var arco := motor._arco_propio(gk)
	(gk["node"] as Node3D).position = Vector3(0.0, 0, arco.z - signf(arco.z) * 1.0)
	motor.poseedor = {}
	motor.estado = "juego"
	var sg := signf(arco.z)
	motor.balon.position = Vector3(0, 1.0, arco.z - sg * 30.0)
	motor.vel_balon = Vector3(0, 0, sg * 20.0)   ## el tiro viene hacia el arco: la parada sigue pendiente (1,5 s)
	gk["_patada_vista"] = motor._n_patada           ## ya decidió: no vuelve a decidir
	gk["parada_pend"] = {"cruce": Vector3(3.0, 1.0, arco.z), "estirada": true, "n": motor._n_patada}
	var d1 := motor._ia_portero(gk)
	_comprobar(d1.x > 0.5, "con la parada pendiente se desliza hacia el cruce en este fotograma (%.2f m)" % d1.x)
	var d2 := motor._ia_portero(gk)
	_comprobar(d2.x > 0.5, "y también en el siguiente (%.2f m)" % d2.x)
	gk.erase("parada_pend")
	_comprobar(absf(motor._ia_portero(gk).x) < d1.x, "sin parada pendiente vuelve a su colocación")
	(r[1] as Node3D).queue_free()

## EL TIRO FALLIDO (03-11-2026, ciclo 7, `MotorTiroLimpio.fallar`, bandera TIRO_REAL): más distancia y presión = más fallos; apagado no cambia el destino.
func _probar_tiro_fallido() -> void:
	_titulo("TIRO FALLIDO Y BLOQUEADO (TIRO_REAL)")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var tirador: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))[0]
	for q: Dictionary in motor.jugadores:
		if q != tirador:
			(q["node"] as Node3D).position = Vector3(-33.0, 0, -45.0)
	var arco := motor._arco_rival(tirador)
	(tirador["node"] as Node3D).position = Vector3(0, 0, arco.z - signf(arco.z) * 14.0)
	var destino := Vector3(2.0, 0.8, arco.z)
	var antes := MotorTiroLimpio._real
	MotorTiroLimpio._real = false
	_comprobar(MotorTiroLimpio.fallar(motor, tirador, destino, 14.0, 5.0) == destino, "con la bandera apagada el destino no cambia")
	_comprobar(MotorTiroLimpio.alcance(30.0) == 30.0, "con la bandera apagada el alcance de tiro no cambia")
	_comprobar(MotorTiroLimpio.bono_area(10.0) == 0.0, "con la bandera apagada no hay bono de área")
	_comprobar(MotorPaseMejora.RIESGO_K == 1.0 or OS.get_environment("PMOT_RIESGO") != "", "el peso del riesgo del pase es 1,0 por defecto")
	_comprobar(MotorPaseMejora.VEL_K == 1.2 or OS.get_environment("PMOT_VEL") != "", "la velocidad del pase raso es 1,2 por defecto")
	_comprobar(MotorPaseMejora.DIST_K == 0.02 or OS.get_environment("PMOT_DIST") != "", "la penalización por distancia del pase es 0,02 por defecto")
	_comprobar((MotorDuelo.K == 1.0 and MotorDuelo.ENF == 1.0) or OS.get_environment("ENTRADA_K") != "" or OS.get_environment("ENTRADA_ENF") != "", "las perillas de la entrada son neutras (1,0) por defecto")
	MotorTiroLimpio._real = true
	_comprobar(absf(MotorTiroLimpio.alcance(30.0) - 30.0 * MotorTiroLimpio.ALCANCE_K) < 0.001 and MotorTiroLimpio.ALCANCE_K > 1.0, "con la bandera encendida el alcance de tiro crece")
	_comprobar(MotorTiroLimpio.bono_area(10.0) > 0.0 and MotorTiroLimpio.bono_area(30.0) == 0.0, "encendida, el bono solo vale dentro del área")
	var cerca := MotorTiroLimpio.probabilidad_fallo(motor, tirador, destino, 8.0, 5.0)
	var lejos := MotorTiroLimpio.probabilidad_fallo(motor, tirador, destino, 28.0, 5.0)
	var apretado := MotorTiroLimpio.probabilidad_fallo(motor, tirador, destino, 8.0, 1.0)
	_comprobar(lejos > cerca + 0.15, "más lejos, más fallos (%.2f a 28 m frente a %.2f a 8 m)" % [lejos, cerca])
	_comprobar(apretado > cerca + 0.1, "con un rival encima, más fallos (%.2f frente a %.2f)" % [apretado, cerca])
	## Un defensa en la línea de tiro bloquea.
	var libre := MotorTiroLimpio.probabilidad_fallo(motor, tirador, destino, 14.0, 5.0)
	var rival: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))[0]
	(rival["node"] as Node3D).position = Vector3(1.0, 0, arco.z - signf(arco.z) * 7.0)
	var tapado := MotorTiroLimpio.probabilidad_fallo(motor, tirador, destino, 14.0, 5.0)
	_comprobar(tapado > libre + 0.1, "un defensa en la línea sube el fallo (%.2f frente a %.2f)" % [tapado, libre])
	## Los fallos salen de los palos o por encima: ninguno cae dentro del arco.
	var dentro := 0
	for i in 200:
		var d := MotorTiroLimpio.fallar(motor, tirador, destino, 28.0, 1.0)
		if d != destino and absf(d.x) < motor.PALO and d.y < motor.LARGUERO:
			dentro += 1
	_comprobar(dentro == 0, "un tiro fallido nunca queda dentro del arco (%d de 200)" % dentro)
	var modo_antes := motor._mod_tiro
	motor._mod_tiro = "raso"
	var altos := 0
	for i in 200:
		if MotorTiroLimpio.fallar(motor, tirador, Vector3(2.0, 0.3, arco.z), 28.0, 1.0).y > 0.8:
			altos += 1
	motor._mod_tiro = modo_antes
	_comprobar(altos == 0, "un tiro raso fallido nunca sube por encima de 0,8 m (%d de 200)" % altos)
	MotorTiroLimpio._real = antes
	(r[1] as Node3D).queue_free()

## LA TRAZA DE POSESIONES (03-11-2026, ciclo 9, `MotorTraza`): cuenta dónde y por qué se pierde la posesión y cuántas veces se entra al área; no decide nada.
func _probar_traza() -> void:
	_titulo("TRAZA DE POSESIONES Y ENTRADAS AL ÁREA")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var loc: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))[0]
	var vis: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))[0]
	motor.diag = {}
	motor._t_estado = 10.0   ## no es una reanudación reciente
	var d := motor.dir_ataque(true)
	var arco_z := motor.LARGO * d
	motor.balon.position = Vector3(0, 0.11, 0)
	motor._pase_eq = -1
	MotorTraza.tomar(motor, loc)
	_comprobar(int(motor.diag.get("traza_posesiones", 0)) == 1, "la primera posesión se cuenta")
	_comprobar(MotorTraza.zona(motor, 0) == "medio", "el centro del campo es «medio» (%s)" % MotorTraza.zona(motor, 0))
	motor.balon.position = Vector3(0, 0.11, arco_z - d * 8.0)
	_comprobar(MotorTraza.zona(motor, 0) == "area" and MotorTraza.zona(motor, 1) == "propio", "a 8 m del arco rival es «area» para el local y «propio» para la visita")
	MotorTraza.paso(motor)
	MotorTraza.paso(motor)
	_comprobar(int(motor.diag.get("traza_entrada_area", 0)) == 1, "una entrada al área cuenta una sola vez aunque el balón siga dentro")
	## El rival corta un pase del local dentro del área.
	motor._pase_eq = 0
	MotorTraza.tomar(motor, vis)
	_comprobar(int(motor.diag.get("traza_perdida_area_pase_otro", 0)) == 1, "pase cortado dentro del área (sin clasificar): «perdida_area_pase_otro»")
	## La visita pierde el balón en un duelo en el medio campo.
	motor.balon.position = Vector3(0, 0.11, 0)
	motor._pase_eq = -1
	MotorTraza.tomar(motor, loc)
	_comprobar(int(motor.diag.get("traza_perdida_medio_suelto_control_ajeno_t2", 0)) == 1, "balón suelto sin dueño reciente recogido en el medio campo: «perdida_medio_suelto_control_ajeno_t2»")
	## Sale del área y vuelve a entrar: segunda entrada.
	MotorTraza.paso(motor)
	motor.balon.position = Vector3(0, 0.11, arco_z - d * 8.0)
	MotorTraza.paso(motor)
	_comprobar(int(motor.diag.get("traza_entrada_area", 0)) == 2, "salir y volver a entrar cuenta otra entrada")
	(r[1] as Node3D).queue_free()

## LA DESCARGA BAJO PRESIÓN (03-11-2026, ciclo 9, `MotorDescarga`, bandera PASE_DESCARGA): con un rival encima decide ya; apagado no cambia nada.
func _probar_descarga() -> void:
	_titulo("DESCARGA BAJO PRESIÓN")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var p: Dictionary = motor.jugadores.filter(func(q: Dictionary) -> bool: return bool(q["es_local"]) and not bool(q["por"]))[0]
	var antes := MotorDescarga._on
	MotorDescarga._on = false
	_comprobar(not MotorDescarga.urge(motor, p, 1.0) and MotorDescarga.holgura(0.5) == 0.5, "apagada no urge ni cambia la espera")
	MotorDescarga._on = true
	motor.t = 50.0
	p["tomo_en"] = 40.0
	_comprobar(MotorDescarga.urge(motor, p, 1.5), "con un rival a 1,5 m, decide ya")
	_comprobar(not MotorDescarga.urge(motor, p, 1.5), "pero no dos veces seguidas (pausa mínima)")
	motor.t += MotorDescarga.PAUSA + 0.05
	_comprobar(not MotorDescarga.urge(motor, p, 4.0), "con el rival lejos (4 m) no urge")
	_comprobar(MotorDescarga.urge(motor, p, 1.5), "pasada la pausa vuelve a poder")
	motor.t += 1.0
	p["tomo_en"] = motor.t - 0.1
	_comprobar(not MotorDescarga.urge(motor, p, 1.5), "recién recibido el balón (0,1 s) no decide aún")
	_comprobar(MotorDescarga.holgura(0.5) == MotorDescarga.HOLGURA and MotorDescarga.holgura(1.0) == 1.0, "la espera con presión baja a %.2f y sin presión no cambia" % MotorDescarga.HOLGURA)
	MotorDescarga._on = antes
	(r[1] as Node3D).queue_free()

## (12-11) EL ADELANTO DEL PASE EN C4 (`MejorasC4Adelanto`): si un rival llega antes al punto adelantado, la mitad o al pie.
func _probar_adelanto_c4() -> void:
	_titulo("C4: EL ADELANTO DEL PASE")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var q: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))[0]
	for p: Dictionary in motor.jugadores:
		(p["node"] as Node3D).position = Vector3(40.0, 0, 0) if bool(p["es_local"]) != bool(q["es_local"]) else Vector3(-30.0, 0, 0)
	(q["node"] as Node3D).position = Vector3(0, 0, 10.0)
	motor.balon.position = Vector3(0, 0, -5.0); var base := Vector3(0, 0, 6.0)
	var antes := MejorasC4Adelanto.ACTIVO; MejorasC4Adelanto.ACTIVO = false
	_comprobar(MejorasC4Adelanto.guia(motor, q, base) == base, "con la bandera apagada no cambia nada")
	MejorasC4Adelanto.ACTIVO = true; _comprobar(MejorasC4Adelanto.guia(motor, q, base) == base, "sin rival cerca del punto se adelanta entero")
	var rival: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) != bool(q["es_local"]))[0]
	(rival["node"] as Node3D).position = Vector3(0, 0, 23.0)   ## llega antes a 16 m, no a 13 m
	_comprobar(MejorasC4Adelanto.guia(motor, q, base) == base * 0.5, "con un rival en el punto, la mitad del adelanto")
	(rival["node"] as Node3D).position = Vector3(0.5, 0, 12.5)
	_comprobar(MejorasC4Adelanto.guia(motor, q, base) == Vector3.ZERO, "con el rival también a mitad de camino, al pie")
	MejorasC4Adelanto.ACTIVO = antes
	(r[1] as Node3D).queue_free()

class_name MovimientoMotor
## (16-11, M6-12) Movimiento de los 22 en GDScript: gemela de `mover_jugadores_fisica` (nativo/src/mover_nativo.cpp), sacada de
## `motor_jugable_p5.gd` para que esa capa no pase de 450 líneas. Misma aritmética, mismo orden: `pruebas/probar_nativo.tscn` compara bytes.

## `lim` = [A_MAX, ANCHO, LARGO, GIRO_RAPIDO] del motor (los mismos que recibe la gemela C++).
static func mover_gd(m: Object, delta: float, bpos: Vector3, lim: PackedFloat64Array) -> PackedFloat64Array:
	var jugadores: Array = m.jugadores
	var t: float = m.t
	var poseedor: Dictionary = m.poseedor
	var A_MAX: float = lim[0]
	var ANCHO: float = lim[1]
	var LARGO: float = lim[2]
	var GIRO_RAPIDO: float = lim[3]
	var salida := PackedFloat64Array()
	salida.resize(jugadores.size() * 4)
	var idx := -1
	for p: Dictionary in jugadores:
		idx += 1
		var n: Node3D = p["node"]
		if not is_instance_valid(n) or not p.has("objetivo"):
			continue
		salida[idx * 4] = 1.0
		var np: Vector3 = n.position   ## (13-11, rendimiento) una lectura y una escritura de la posición del nodo por jugador y paso (antes 5-9 llamadas nativas)
		var obj: Vector3 = p["objetivo"] if float(p.get("levanta_hasta", 0.0)) <= t else np   ## en el suelo tras la barrida (31-10)
		obj.y = 0.0
		var dif := obj - Vector3(np.x, 0, np.z)
		var dist := dif.length()
		var rit := float(p["attr"]["rit"])
		## La velocidad pesa más (13-10-2026): de ~6,7 m/s a ~8,3 m/s según el ritmo.
		var tope := (4.4 + rit * 4.2) * (1.0 if bool(p.get("correr", false)) else 0.62) * (0.7 + 0.3 * float(p["aguante"]))
		if poseedor == p:
			tope *= 0.88
		## Regate técnico, proteger o bregar: más despacio (lo pone el control).
		tope *= float(p.get("freno", 1.0))
		## Tras un choque o con un rival agarrándolo, va más despacio un rato.
		if float(p.get("freno_duelo_hasta", 0.0)) > t:
			tope *= float(p.get("freno_duelo", 1.0))
		var deseada := Vector3.ZERO
		if dist > 0.25:
			deseada = dif / dist * minf(tope, dist * 2.5)
		var vel: Vector3 = p["vel"]
		## INERCIA DE VERDAD (14-10-2026): antes la velocidad saltaba a la
		## nueva dirección en dos décimas, como un patinador. Ahora el rumbo
		## gira con un tope que baja con la velocidad (a toda carrera se abre
		## la curva) y, si el giro es grande, primero frena; frena (11 m/s²)
		## más rápido de lo que acelera (6 m/s², 8 con buen ritmo).
		var sp0 := vel.length()
		var sp_des := deseada.length()
		if sp0 > 0.6 and sp_des > 0.1:
			var dir0 := vel / sp0
			var dir1 := deseada / sp_des
			var ang := dir0.signed_angle_to(dir1, Vector3.UP)
			var giro_rad := lerpf(9.0, 2.6, clampf(sp0 / 8.0, 0.0, 1.0))
			## RB + LT: cambios de dirección firmes (gira cerrado sin frenar tanto).
			if bool(p.get("giro_firme", false)):
				giro_rad *= 2.4
			var giro_max := giro_rad * delta
			var dir := dir0.rotated(Vector3.UP, clampf(ang, -giro_max, giro_max))
			## Giro brusco: se frena para girar (cambio de dirección real).
			var objetivo_sp := sp_des * (1.0 - 0.6 * clampf((absf(ang) - 0.5) / 2.0, 0.0, 1.0))
			var acel := (6.0 + rit * 2.0) if objetivo_sp > sp0 else 11.0
			vel = dir * move_toward(sp0, objetivo_sp, acel * delta)
		else:
			vel = vel.move_toward(deseada, (6.0 + rit * 2.0) * delta if sp_des > sp0 else 11.0 * delta)
		## TOPE DE ACELERACIÓN TOTAL (19-10-2026): frenar, girar y arrancar a la
		## vez no pasa de A_MAX m/s² (más con giro firme), lo que aguanta un
		## cuerpo en un recorte. Antes la suma llegaba a 25-30 (tirones en la
		## sonda). Con 14 el juego se quedaba sin chispa (la mitad de goles).
		var a_max := (A_MAX * 1.35 if bool(p.get("giro_firme", false)) else A_MAX) * delta
		var dv: Vector3 = vel - (p["vel"] as Vector3)
		if dv.length() > a_max:
			vel = (p["vel"] as Vector3) + dv.normalized() * a_max
		p["vel"] = vel
		np += vel * delta
		## EL EMPUJÓN DEL DUELO: un desplazamiento lateral que sube en una
		## décima y se apaga solo (sin saltos: tope de 22 m/s²).
		var emp_obj: Vector3 = p.get("empujon_obj", Vector3.ZERO)
		var emp: Vector3 = p.get("empujon", Vector3.ZERO)
		if emp_obj != Vector3.ZERO or emp != Vector3.ZERO:
			emp = emp.move_toward(emp_obj, 22.0 * delta)
			p["empujon_obj"] = emp_obj * exp(-7.0 * delta) if emp_obj.length() > 0.05 else Vector3.ZERO
			p["empujon"] = emp if emp.length() > 0.02 or emp_obj != Vector3.ZERO else Vector3.ZERO
			np += emp * delta
		np = Vector3(clampf(np.x, -ANCHO - 2.0, ANCHO + 2.0), np.y, clampf(np.z, -LARGO - 2.0, LARGO + 2.0))
		n.position = np
		var sp := vel.length()
		## RECORRER HACIA ATRÁS (13-10-2026): el defensa que se repliega cerca
		## de la jugada no da la espalda al balón; retrocede mirándolo.
		var hacia_b := bpos - np
		hacia_b.y = 0.0
		var atras := false
		var giro_antes := n.rotation.y
		var corre_recto := false
		if float(p.get("mirar_hasta", 0.0)) > t:
			## Un giro mandado (golpeo, filigrana): manda sobre todo lo demás.
			n.rotation.y = rotate_toward(n.rotation.y, float(p["mirar"]), GIRO_RAPIDO * delta)
		elif sp > 0.5 and sp < 4.2 and poseedor != p and not bool(p["por"]) and hacia_b.length() < 18.0 \
				and not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]) \
				and vel.normalized().dot(hacia_b.normalized()) < -0.35:
			atras = true
			n.rotation.y = rotate_toward(n.rotation.y, atan2(hacia_b.x, hacia_b.z), 7.0 * delta)
		elif (bool(p["por"]) or bool(p.get("jockey", false))) and poseedor != p and sp < 6.0 and hacia_b.length() > 0.5:
			## El portero no da la espalda al balón: se mueve de lado o atrás.
			n.rotation.y = rotate_toward(n.rotation.y, atan2(hacia_b.x, hacia_b.z), 8.0 * delta)
		elif sp > 0.4:
			n.rotation.y = rotate_toward(n.rotation.y, atan2(vel.x, vel.z), 9.0 * delta)
			corre_recto = true
		elif poseedor != p:
			var hacia := bpos - np
			n.rotation.y = rotate_toward(n.rotation.y, atan2(hacia.x, hacia.z), 4.0 * delta)
		## Al girar corriendo de frente, el cuerpo se inclina hacia dentro de la curva (31-10, §2.2e P2); de lado o atrás, no.
		if delta > 0.0:
			n.rotation.z = MovimientoNatural.inclinacion(n.rotation.z, angle_difference(giro_antes, n.rotation.y) / delta if corre_recto else 0.0, sp, delta)
			n.rotation.x = MovimientoNatural.cabeceo(n.rotation.x, (sp - float(p.get("sp_antes", sp))) / delta if corre_recto else 0.0, delta)
			p["sp_antes"] = sp
		## Aguante: el sprint cansa, andar recupera.
		if bool(p.get("correr", false)) and sp > 5.0:
			## Presionar arriba cansa: el equipo de presión alta se funde antes
			## (el precio de la pizarra ofensiva, que se nota con el cansancio real).
			var coste := 1.0 + 0.35 * float(m._tac(bool(p["es_local"]), "presion") - 1) + 0.15 * float(m._tac(bool(p["es_local"]), "ritmo") - 1)
			p["aguante"] = maxf(0.2, float(p["aguante"]) - delta * 0.012 * (1.4 - float(p["attr"]["fis"])) * coste)
		else:
			p["aguante"] = minf(1.0, float(p["aguante"]) + delta * 0.006)
		salida[idx * 4 + 1] = sp
		salida[idx * 4 + 2] = 1.0 if atras else 0.0
		salida[idx * 4 + 3] = hacia_b.length()
	return salida

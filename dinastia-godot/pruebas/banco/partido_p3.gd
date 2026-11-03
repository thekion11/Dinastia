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

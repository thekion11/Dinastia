extends "res://pruebas/banco/varios_p10.gd"
## [Capa de `varios_p11_p1.gd`, 21-11 refactor de forma] Secciones de PARTIDO: NÚCLEO DE LEAGUE-SOCCER.
## Cada bloque es independiente (no comparte estado); el orden de las comprobaciones y los textos son los de antes.


## NÚCLEO, parte 1: velocidades cuantizadas, mentalidad por puesto, pase con rivales, espacio libre y ventaja.
func _lg_nucleo_pases() -> void:
	_comprobar(is_zero_approx(LeagueNucleo.rango_velocidad(1.0)) and is_equal_approx(LeagueNucleo.rango_velocidad(3.0), 3.5) and is_equal_approx(LeagueNucleo.rango_velocidad(5.0), 5.0) and is_equal_approx(LeagueNucleo.rango_velocidad(7.0), 8.0), "velocidades cuantizadas como `velocitystate.hpp` (0 · 3,5 · 5 · 8)")
	_comprobar(is_zero_approx(LeagueNucleo.mentalidad("DFC")) and is_equal_approx(LeagueNucleo.mentalidad("LD"), 0.25) and is_equal_approx(LeagueNucleo.mentalidad("MC"), 0.5) and is_equal_approx(LeagueNucleo.mentalidad("DC"), 1.0), "mentalidad por puesto (AI_GetMindSet)")
	var libre := LeagueNucleo.odds_pase(Vector2.ZERO, Vector2(20, 0), LeagueNucleo.CORTO, [])
	var tapado := LeagueNucleo.odds_pase(Vector2.ZERO, Vector2(20, 0), LeagueNucleo.CORTO, [[Vector2(10, 0.5), Vector2.ZERO, false]])
	_comprobar(is_equal_approx(libre, 1.0) and tapado < 0.2, "pase sin rivales = 1; con un rival en la línea casi 0 (%.2f)" % tapado)
	_comprobar(is_equal_approx(LeagueNucleo.odds_pase(Vector2.ZERO, Vector2(20, 0), LeagueNucleo.ALTO, []), 0.6), "el pase alto paga 0,4 de castigo fijo (L: «don't prefer high passing»)")
	_comprobar(is_equal_approx(LeagueNucleo.espacio_libre(Vector2.ZERO, [], 5.0, 0.5), 1.0) and LeagueNucleo.espacio_libre(Vector2.ZERO, [[Vector2(1, 0), Vector2.ZERO, false], [Vector2(-1, 0), Vector2.ZERO, false], [Vector2(0, 1), Vector2.ZERO, false]], 5.0, 0.5) < 0.1, "espacio libre: 1 sin rivales, ~0 rodeado")
	_comprobar(LeagueReglas.ventaja(1000.0, 0.0, true) == 1 and LeagueReglas.ventaja(500.0, 0.0, true) == 0 and LeagueReglas.ventaja(4000.0, 0.0, false) == 2, "ventaja: vuelve a la falta tras 0,6 s si se pierde; jugada a los 3,5 s")


## NÚCLEO, parte 2: la física del balón (raso y botando) y la decisión del delantero solo frente al arco.
func _lg_balon_decision() -> void:
	var cfg := LeagueNucleo.config_balon()
	var r := LeagueNucleo.fuerzas_balon(Vector3(0, 0.11, 0), Vector3(10, 0, 0), cfg, 0.01)
	_comprobar((r[1] as Vector3).x < 10.0 and (r[1] as Vector3).x > 9.9 and is_equal_approx((r[0] as Vector3).y, 0.11), "el balón raso frena por el césped sin hundirse (%.4f m/s)" % (r[1] as Vector3).x)
	var bote := LeagueNucleo.fuerzas_balon(Vector3(0, 0.05, 0), Vector3(0, -5, 0), cfg, 0.01)
	_comprobar(absf((bote[1] as Vector3).y - ((5.0 + 9.81 * 0.01) * 0.64 - 0.05)) < 0.02, "bota con 0,64 del impacto (con la gravedad del paso) menos 0,05 (%.2f)" % (bote[1] as Vector3).y)
	var dec := LeagueNucleo.decidir({"pos": Vector2(-40, 0), "mov": Vector2.ZERO, "lado": 1.0, "puesto": "DC", "tec_pase": 0.7, "tec_tiro": 0.8, "posee_ms": 500.0,
		"sit": LeagueNucleo.situacion(Vector2(-40, 0), Vector2.ZERO, 1.0, [])}, [], [], Vector2.ZERO, 1.0, RandomNumberGenerator.new())
	_comprobar(String(dec["accion"]) == "tiro", "solo y a 12 m del arco rival, el delantero tira (%s)" % dec["accion"])
	_comprobar(is_equal_approx(LeagueNucleo.trampa_offside(-49.0, -1.0, -40.0), -40.0) and absf(LeagueNucleo.trampa_offside(-39.0, -1.0, -40.0) - -38.5) < 0.01 and is_equal_approx(LeagueNucleo.trampa_offside(-20.0, -1.0, -40.0), -20.0), "la trampa del fuera de juego sube a los de atrás hasta la línea y comprime los 2 m de delante")


## IA SIN BALÓN (fase 3): estrategias por puesto, sesgos, defensa, marcajes y pereza.
func _lg_sin_balon() -> void:
	## Fase 3 (IA sin balón): fórmulas de las estrategias por puesto contra el original.
	_comprobar(LeagueSinBalon.grupo("DFC") == "def" and LeagueSinBalon.grupo("MC") == "med" and LeagueSinBalon.grupo("DC") == "ata", "estrategia por puesto (defensa, medio, ataque)")
	_comprobar(is_zero_approx(LeagueSinBalon.sesgo_estatico("def", 5.0)) and LeagueSinBalon.sesgo_estatico("def", 40.0) > 0.95, "con la acción cerca se intercambian puestos; lejos, cada uno a su casilla")
	_comprobar(is_zero_approx(LeagueSinBalon.sesgo_ataque("ata", 0.5, 1.0)) and is_equal_approx(LeagueSinBalon.sesgo_ataque("ata", 1.5, 1.0), 1.0), "el apoyo ofensivo crece con la posesión que se desvanece")
	var dp := LeagueSinBalon.posicion_defensa(Vector2(-20, 0), Vector2.ZERO, Vector2(-30, 0), -1.0)
	_comprobar(dp.x < -20.0 and dp.x > -30.0 and absf(dp.y) < 0.01, "el defensor intercepta al rival en su línea hacia el arco (%.1f, %.1f)" % [dp.x, dp.y])
	_comprobar(LeagueSinBalon.necesita_defender(-1.0, Vector2(-30, 0), Vector2(-30, 5)) and not LeagueSinBalon.necesita_defender(-1.0, Vector2(-30, 0), Vector2(-20, 1)), "solo se mueve si el rival le gana el lado (NeedDefendingMovement)")
	var mc := LeagueSinBalon.marcajes([["a", Vector2(-40, 0), Vector2.ZERO, false], ["b", Vector2(-10, 20), Vector2.ZERO, false], ["g", Vector2(-50, 0), Vector2.ZERO, true]], [["x", Vector2(-38, 1), Vector2.ZERO, false, false]], -1.0, Vector2.ZERO)
	_comprobar(mc.get("a", "") == "x" and not mc.has("g"), "marca al hombre el más cercano y bien colocado, nunca el portero")
	_comprobar(is_equal_approx(LeagueSinBalon.velocidad_perezosa(8.0, 1.0, 5.0, 0.5, 0.5, 0.0, 0.5), 8.0) and LeagueSinBalon.velocidad_perezosa(8.0, 1.0, 60.0, 0.5, 0.5, 0.0, 0.5) < 8.0, "pereza: cerca de la acción corre a tope; lejos, afloja")
	_comprobar(LeagueReglas.empezar_presion_zona(1.0, 0.2, 8.0) and not LeagueReglas.empezar_presion_zona(0.0, 1.0, 1.0), "presión de zona al perder el balón según la palanca")


## TOQUES (fase 4a): el catálogo de toques y el filtro de alcance y radio.
func _lg_toques() -> void:
	## Fase 4a: el catálogo de toques (de las animaciones originales) y el filtro de alcance.
	var cat := LeagueToques.catalogo()
	_comprobar(cat.has("interfere") and cat.has("shot") and (cat["shot"]["sprint"] as Array).size() > 0, "catálogo de toques cargado (%d tipos)" % cat.size())
	var cerca := PackedVector3Array()
	var lejos := PackedVector3Array()
	for k in 71:
		cerca.append(Vector3(1.0, 0.0, 0.11))
		lejos.append(Vector3(9.0, 0.0, 0.11))
	_comprobar(not LeagueToques.alcanza("interfere", Vector2.ZERO, Vector2(1, 0), 0.0, cerca).is_empty() and LeagueToques.alcanza("interfere", Vector2.ZERO, Vector2(1, 0), 0.0, lejos).is_empty(), "interferir alcanza un balón a 1 m delante y no uno a 9 m")
	_comprobar(LeagueToques.radio("interfere", 24, 0.0) > LeagueToques.radio("sliding", 24, 0.0) and LeagueToques.clase(7.0) == 3, "radio por tipo (interferir > barrida) y clases de velocidad")


## EL MOTOR: la variante juega 20 s de partido con dos clubes de países distintos, y la bandera
## no cambia el motor de siempre.
func _lg_motor_juega() -> void:
	## La variante juega 20 s de partido con dos clubes de países distintos y la bandera no cambia el motor de siempre.
	var m := Mundo.new()
	m.generar(["ARG", "ESP"], 99)
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var a: Club = m.ligas[0].clubes[2]
	var b: Club = m.ligas[m.ligas.size() - 1].clubes[5]
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ml := MotorLeague.new()
	raiz.add_child(ml)
	ml.set_physics_process(false)
	ml.autopiloto = true
	ml.preparar(lista, StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0)), "", 5)
	for i in 600:
		ml.paso(1.0 / 30.0)
	var decisiones := 0
	for k: String in ml.cuenta:
		decisiones += int(ml.cuenta[k])
	_comprobar(ml.estado != "fin" and decisiones > 0 and (ml.equipos[0] as LeagueEquipo).balon_hist.size() == LeagueEquipo.HISTORIA, "MotorLeague juega (%s - %s): %d decisiones de League en 20 s" % [a.pais, b.pais, decisiones])
	_comprobar(MotorLeague.crear() is MotorLeague == MotorLeague.activo, "la bandera elige el motor (apagada = el de siempre)")
	raiz.queue_free()

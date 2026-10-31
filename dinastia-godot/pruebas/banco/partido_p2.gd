extends "res://pruebas/banco/partido_p1.gd"
## [Capa 2/6 de `partido.gd`] _probar_tactica_en_movimiento, _motor_de_prueba, _probar_dificultad_cpu, _probar_faltas_puntos


## COMPARAR TACTICAS DE VERDAD (17-9-2026), sin necesitar pantalla: llama
## `_objetivo_jugador()` directo -el mismo metodo que usa `MatchPlayback._mover()`
## para cada uno de los 22, cada fotograma- con la MISMA ranura de formacion y
## la MISMA pelota, cambiando solo la `Tactica`. Si dos tacticas de verdad se
## sienten distinto jugando, tienen que devolver puntos distintos aqui -es la
## unica forma de "comparar visualmente" que tengo sin ojos.
func _probar_tactica_en_movimiento() -> void:
	_titulo("TACTICA EN EL MOVIMIENTO 3D (nivel FC 26)")
	var mp := MatchPlayback.new()
	mp.fase = "ataqueLocal"  # el equipo local ataca -hacia Z negativo, dir_ataque=-1

	var t_ofensiva := Tactica.new()
	t_ofensiva.mentalidad = Tactica.Mentalidad.OFENSIVA
	t_ofensiva.linea = Tactica.Nivel.ALTO
	t_ofensiva.amplitud = Tactica.Nivel.ALTO

	var t_defensiva := Tactica.new()
	t_defensiva.mentalidad = Tactica.Mentalidad.DEFENSIVA
	t_defensiva.linea = Tactica.Nivel.BAJO
	t_defensiva.amplitud = Tactica.Nivel.BAJO

	## Mismo jugador (misma ranura de formacion `base`), misma pelota -delta
	## grande y reaccion casi nula para que el empuje ya haya llegado del todo
	## a su objetivo, sin que la inercia de la ronda 2 tape la comparacion.
	var base := Vector3(20.0, 0, 0.0)
	var bola := Vector3(0, 0.11, -20.0)

	mp.local_tactica = t_ofensiva
	var obj_of: Vector3 = mp._objetivo_jugador(base, bola, true, {"_reaccion": 0.01}, 5.0)

	mp.local_tactica = t_defensiva
	var obj_def: Vector3 = mp._objetivo_jugador(base, bola, true, {"_reaccion": 0.01}, 5.0)

	_linea("  ofensiva+linea alta: (x=%.1f, z=%.1f)   defensiva+linea baja: (x=%.1f, z=%.1f)" % [
		obj_of.x, obj_of.z, obj_def.x, obj_def.z])
	_comprobar(obj_of.z < obj_def.z - 3.0,
		"ofensiva+linea alta empuja el bloque medible mas arriba que defensiva+linea baja (diferencia real, no cosmetica)")
	_comprobar(absf(obj_of.x) > absf(obj_def.x),
		"amplitud alta separa mas del centro que amplitud baja")

	## MARCA AL HOMBRE: un defensor con la casilla activa tiene que terminar
	## MAS CERCA del rival marcado que el mismo defensor con marca por zonas.
	var t_zonal := Tactica.new()
	var t_marca := Tactica.new()
	t_marca.marca_al_hombre = true
	## `_rival_mas_cercano()` necesita `yo["node"]` de verdad -en un partido
	## real todo jugador lo trae (lo pone `PlayerSpawner`), pero en esta
	## prueba hay que armarlo a mano. Sin este nodo, el primer intento de esta
	## prueba fallaba con un error real de "node" faltante -detectado
	## revisando el `.err.txt`, no confiando en que "0 fallos" bastara.
	var yo_nodo := Node3D.new()
	yo_nodo.position = base
	add_child(yo_nodo)
	var yo := {"_reaccion": 0.01, "slot_code": "DFC", "node": yo_nodo, "es_local": true, "arbitro": false}
	var rival_nodo := Node3D.new()
	rival_nodo.position = Vector3(-15.0, 0, 30.0)  # lejos de la ranura de formacion del marcador
	add_child(rival_nodo)
	var rival := {"node": rival_nodo, "es_local": false, "slot_code": "DC", "arbitro": false}
	mp.players = [rival]
	mp.fase = "ataqueVisita"  # el local defiende -condicion para que la marca se active

	mp.local_tactica = t_zonal
	var obj_zonal: Vector3 = mp._objetivo_jugador(base, bola, true, yo.duplicate(), 5.0)
	mp.local_tactica = t_marca
	var obj_marca: Vector3 = mp._objetivo_jugador(base, bola, true, yo.duplicate(), 5.0)

	var d_zonal := obj_zonal.distance_to(rival_nodo.position)
	var d_marca := obj_marca.distance_to(rival_nodo.position)
	_linea("  distancia al rival marcado -> zonal: %.1f m   marca al hombre: %.1f m" % [d_zonal, d_marca])
	_comprobar(d_marca < d_zonal - 3.0,
		"con marca al hombre activa, el defensor termina medible mas cerca del rival que en zona")
	rival_nodo.queue_free()
	yo_nodo.queue_free()

	## FUERA DE JUEGO: un defensor con la trampa activa tiene que quedar mas
	## adelantado (mas cerca de la mitad de cancha rival) que sin ella, en la
	## MISMA fase de defender.
	mp.players = []
	var t_sin_trampa := Tactica.new()
	var t_con_trampa := Tactica.new()
	t_con_trampa.fuera_de_juego = true
	var def_p := {"_reaccion": 0.01, "slot_code": "DFC"}
	mp.local_tactica = t_sin_trampa
	var obj_sin_trampa: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	mp.local_tactica = t_con_trampa
	var obj_con_trampa: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	_linea("  linea sin trampa: z=%.1f   con trampa de fuera de juego: z=%.1f" % [obj_sin_trampa.z, obj_con_trampa.z])
	_comprobar(obj_con_trampa.z < obj_sin_trampa.z - 2.0,
		"la trampa del fuera de juego sube medible la linea del defensor (local ataca a Z negativo)")

	## SALIDA CORTA: con el equipo en fase de ataque, un central tiene que
	## separarse mas del centro (mas ancho) si el club arma desde atras.
	var t_sin_salida := Tactica.new()
	var t_con_salida := Tactica.new()
	t_con_salida.salida_corta = true
	mp.fase = "ataqueLocal"  # el local ataca -este defensor SI tiene la pelota
	mp.local_tactica = t_sin_salida
	var obj_sin_salida: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	mp.local_tactica = t_con_salida
	var obj_con_salida: Vector3 = mp._objetivo_jugador(base, bola, true, def_p.duplicate(), 5.0)
	_linea("  ancho sin salida corta: x=%.1f   con salida corta: x=%.1f" % [obj_sin_salida.x, obj_con_salida.x])
	_comprobar(absf(obj_con_salida.x) > absf(obj_sin_salida.x) + 1.5,
		"la salida corta separa medible al central del centro cuando su equipo ataca")

	## RITMO: en igualdad de todo lo demas, un equipo de ritmo alto tiene que
	## desplazarse mas en UN MISMO paso de tiempo que uno de ritmo bajo -se
	## prueba con `_mover()` de verdad, no repitiendo la formula a mano.
	var nodo_alto := Node3D.new()
	nodo_alto.position = Vector3(20.0, 0, 20.0)
	add_child(nodo_alto)
	var nodo_bajo := Node3D.new()
	nodo_bajo.position = Vector3(20.0, 0, -20.0)
	add_child(nodo_bajo)
	var t_ritmo_alto := Tactica.new()
	t_ritmo_alto.ritmo = Tactica.Nivel.ALTO
	var t_ritmo_bajo := Tactica.new()
	t_ritmo_bajo.ritmo = Tactica.Nivel.BAJO
	var mp2 := MatchPlayback.new()
	mp2.fase = "ataqueVisita"  # el local (estos dos jugadores) defiende
	mp2.local_tactica = t_ritmo_alto
	mp2.players = [{"node": nodo_alto, "anim": null, "es_local": true, "base_pos": Vector3(0, 0, 20.0), "id": "ra"}]
	mp2.ball = null
	mp2._mover(1.0)
	var mp3 := MatchPlayback.new()
	mp3.fase = "ataqueVisita"
	mp3.local_tactica = t_ritmo_bajo
	mp3.players = [{"node": nodo_bajo, "anim": null, "es_local": true, "base_pos": Vector3(0, 0, -20.0), "id": "rb"}]
	mp3.ball = null
	mp3._mover(1.0)
	var recorrido_alto := nodo_alto.position.distance_to(Vector3(20.0, 0, 20.0))
	var recorrido_bajo := nodo_bajo.position.distance_to(Vector3(20.0, 0, -20.0))
	_linea("  recorrido en 1s -> ritmo alto: %.2f m   ritmo bajo: %.2f m" % [recorrido_alto, recorrido_bajo])
	_comprobar(recorrido_alto > recorrido_bajo,
		"un equipo de ritmo alto se mueve medible mas rapido que uno de ritmo bajo, mismo tiempo")
	nodo_alto.queue_free()
	nodo_bajo.queue_free()

	## JUGADA DE GOL (primera "jugada prehecha" real, 18-9-2026): el asistidor
	## de un gol tiene que dejar de ser ajeno a su propio pase -acercarse
	## medible al destino que le calcula `_jugada_gol()`, no seguir clavado en
	## su ranura de formacion como si el pase lo hubiera dado otro-. Se prueba
	## por `suceso()`, la puerta real que usa el partido en vivo (no llamando a
	## `_jugada_gol()` a mano), para que la prueba cubra tambien el disparo del
	## evento real y no solo la funcion aislada.
	var nodo_rematador := Node3D.new()
	nodo_rematador.position = Vector3(0.0, 0, -40.0)
	add_child(nodo_rematador)
	var nodo_asistidor := Node3D.new()
	nodo_asistidor.position = Vector3(15.0, 0, -10.0)  # lejos del area al momento del gol
	add_child(nodo_asistidor)

	var mp4 := MatchPlayback.new()
	mp4.fase = "medio"
	var p_rematador := {"id": "goleador", "node": nodo_rematador, "anim": null, "es_local": true,
		"base_pos": Vector3(0, 0, -40.0), "slot_code": "DC", "arbitro": false}
	var p_asistidor := {"id": "asistidor", "node": nodo_asistidor, "anim": null, "es_local": true,
		"base_pos": Vector3(15.0, 0, -10.0), "slot_code": "MC", "arbitro": false}
	mp4.players = [p_rematador, p_asistidor]
	mp4.players_by_id = {"goleador": p_rematador, "asistidor": p_asistidor}
	mp4.suceso({"min": 10, "t": "golMi", "equipo": "local", "tx": "gol de prueba",
		"jugadorId": "goleador", "asistidorId": "asistidor"})

	_comprobar(float(mp4._guion_hasta.get("asistidor", -1.0)) > mp4.elapsed,
		"tras el gol, el asistidor tiene una jugada con guion activa (no vuelve de inmediato al reparto por zona)")

	var destino_guion: Vector3 = mp4._guion_destino.get("asistidor", Vector3.ZERO)
	var d_inicial := nodo_asistidor.position.distance_to(destino_guion)
	for i in 20:
		mp4._mover(0.1)
	var d_final := nodo_asistidor.position.distance_to(destino_guion)
	_linea("  asistidor -> destino de la jugada: antes %.1f m   despues de 2s %.1f m" % [d_inicial, d_final])
	_comprobar(d_final < d_inicial - 3.0,
		"el asistidor se mueve medible hacia el destino de la jugada de gol, no se queda en su ranura de formacion")

	nodo_rematador.queue_free()
	nodo_asistidor.queue_free()

	## APOYO CERCANO (18-9-2026): sin ninguna jugada con guion activa, el
	## compañero MAS CERCANO al balón tiene que moverse medible hacia una
	## posición de apoyo -no quedarse en su ranura de formación como el resto-,
	## mientras que un compañero lejano SIGUE en reparto de zona normal. Es la
	## pieza que pidió el usuario: movimiento con sentido sin depender de una
	## jugada prehecha.
	var nodo_cercano := Node3D.new()
	nodo_cercano.position = Vector3(10.0, 0, -15.0)  # a unos pocos metros del balon
	add_child(nodo_cercano)
	var nodo_lejano := Node3D.new()
	nodo_lejano.position = Vector3(-25.0, 0, 30.0)  # lejos del balon, del otro lado
	add_child(nodo_lejano)
	var mp5 := MatchPlayback.new()
	mp5.fase = "ataqueLocal"  # el local ataca -condicion para que el apoyo se active
	var bola_apoyo := Vector3(12.0, 0.11, -18.0)
	var p_cercano := {"id": "cerca", "node": nodo_cercano, "anim": null, "es_local": true,
		"base_pos": Vector3(10.0, 0, -15.0), "slot_code": "MC", "arbitro": false, "_reaccion": 0.01}
	var p_lejano := {"id": "lejos", "node": nodo_lejano, "anim": null, "es_local": true,
		"base_pos": Vector3(-25.0, 0, 30.0), "slot_code": "MC", "arbitro": false, "_reaccion": 0.01}
	mp5.players = [p_cercano, p_lejano]
	mp5.ball = null

	var obj_cercano: Vector3 = mp5._objetivo_jugador(p_cercano["base_pos"], bola_apoyo, true, p_cercano, 5.0)
	var obj_lejano: Vector3 = mp5._objetivo_jugador(p_lejano["base_pos"], bola_apoyo, true, p_lejano, 5.0)
	var d_cercano_balon := obj_cercano.distance_to(bola_apoyo)
	var d_lejano_balon := obj_lejano.distance_to(bola_apoyo)
	_linea("  apoyo -> objetivo del cercano a %.1f m del balon   objetivo del lejano a %.1f m del balon" % [
		d_cercano_balon, d_lejano_balon])
	_comprobar(d_cercano_balon < 8.0,
		"el companero mas cercano al balon termina medible cerca de el (posicion de apoyo)")
	_comprobar(d_cercano_balon < d_lejano_balon - 10.0,
		"el companero mas cercano al balon queda medible mas cerca de el que el companero lejano -el apoyo no arrastra a todos por igual")

	nodo_cercano.queue_free()
	nodo_lejano.queue_free()

## FÍSICA DEL MOTOR SIN PANTALLA (20-10-2026): 40 s de juego con el motor real,
## medidos como la sonda de física (cada 1/30 s, dos pasos de 1/60). Guarda lo
## arreglado el 19-10: nadie a más de 10,5 m/s, ningún giro de más de 720°/s,
## casi ningún tirón > 25 m/s² y el balón sin saltos en juego.
## Un motor real sin pantalla con dos equipos de la liga chilena, para las
## pruebas del partido (mini bancos). Devuelve [motor, raíz, balón].
func _motor_de_prueba(semilla := 7) -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.preparar(lista, ball, "", semilla)
	return [motor, raiz, ball]

## DIFICULTAD DE LA CPU (20-10-2026): solo toca al equipo de la CPU, y
## «profesional» deja el motor como siempre.
func _probar_dificultad_cpu() -> void:
	_titulo("DIFICULTAD DE LA CPU")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	var cpu: Dictionary = {}
	var mio: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if not bool(p["por"]):
			if bool(p["es_local"]) and mio.is_empty():
				mio = p
			elif not bool(p["es_local"]) and cpu.is_empty():
				cpu = p
	var puro := float(cpu["attr_puro"]["pas"])
	_comprobar(motor.equipo_cpu() == -1 and is_equal_approx(float(cpu["attr"]["pas"]), puro), "sin nadie al mando no hay CPU que ajustar")
	motor.control_equipo = 0
	motor.fijar_dificultad("ultimate")
	_comprobar(motor.equipo_cpu() == 1, "manejando al local, la CPU es la visita")
	_comprobar(float(cpu["attr"]["pas"]) > puro, "en Ultimate la CPU pasa mejor (%.2f > %.2f)" % [float(cpu["attr"]["pas"]), puro])
	_comprobar(is_equal_approx(float(mio["attr"]["pas"]), float(mio["attr_puro"]["pas"])), "y tus jugadores no cambian")
	_comprobar(motor._tac(false, "presion") == 2, "y presiona más")
	motor.fijar_dificultad("practicante")
	_comprobar(float(cpu["attr"]["pas"]) < puro and motor._tac(false, "presion") == 0, "en Practicante, peor y presiona menos")
	motor.fijar_dificultad("debutante")
	_comprobar(is_equal_approx(float(cpu["attr"]["pas"]), puro) and motor._tac(false, "presion") == 1 and motor.ORDEN_DIFICULTAD.size() == 8, "Debutante = el motor de siempre (de 8 categorías)")
	## M-098: la cabeza sigue al balón (un modificador por jugador).
	_comprobar(MiradaBalon.poner(motor.jugadores, motor.balon) == motor.jugadores.size()
		and MiradaBalon.poner(motor.jugadores, motor.balon) == 0, "M-098: un LookAt en la cabeza de cada jugador, sin duplicar")
	## M-073: el capitán (y solo él) lleva el brazalete.
	var con_brazalete := [0, 0]
	var capitan_en_once := [false, false]
	for p: Dictionary in motor.jugadores:
		var eq := 0 if bool(p["es_local"]) else 1
		if bool((p.get("jugador", {}) as Dictionary).get("capitan", false)):
			capitan_en_once[eq] = true
		var lleva := false
		for mi in (p["node"] as Node).find_children("*", "MeshInstance3D", true, false):
			for k in (mi as MeshInstance3D).get_surface_override_material_count():
				var mt := (mi as MeshInstance3D).get_surface_override_material(k)
				if mt is ShaderMaterial and (mt as ShaderMaterial).get_shader_parameter("acc_brazalete") is Color \
						and ((mt as ShaderMaterial).get_shader_parameter("acc_brazalete") as Color).a > 0.5:
					lleva = true
		if lleva:
			con_brazalete[eq] += 1
	_comprobar(con_brazalete[0] == (1 if capitan_en_once[0] else 0) and con_brazalete[1] == (1 if capitan_en_once[1] else 0),
		"M-073: brazalete solo en el capitán (%s; capitán en el once %s)" % [str(con_brazalete), str(capitan_en_once)])
	_comprobar(capitan_en_once == [true, true], "M-073: cada equipo sale con un capitán (o el que hereda la cinta)")
	## M-127: gestión del tiempo al final (el que gana tarda, el que pierde corre).
	motor.control_equipo = -1
	motor.mitad = 2
	motor.t = motor.dur_mitad() * 0.85
	motor.goles = [1, 0]
	var loc_p: Dictionary = {}
	var vis_p: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if bool(p["es_local"]) and loc_p.is_empty():
			loc_p = p
		elif not bool(p["es_local"]) and vis_p.is_empty():
			vis_p = p
	_comprobar(motor.minuto() >= 75 and motor._ritmo_de_saque(loc_p) > 1.0 and motor._ritmo_de_saque(vis_p) < 1.0,
		"M-127: al %d' el que gana se toma su tiempo y el que pierde saca rápido" % motor.minuto())
	motor.control_equipo = 0
	_comprobar(is_equal_approx(motor._ritmo_de_saque(loc_p), 1.0), "M-127: el equipo del usuario no pierde tiempo solo")
	## M-119: en la tanda el portero se tira más al lado natural del pie del que patea.
	var cuenta := {-1: 0, 0: 0, 1: 0}
	motor.vel_balon = Vector3.ZERO
	for _i in 600:
		cuenta[motor._lado_portero_tanda(loc_p, vis_p)] += 1
	var nat := -1 if AnimExtra.es_zurdo(String(loc_p.get("id", ""))) else 1
	_comprobar(int(cuenta[nat]) > int(cuenta[-nat]) and int(cuenta[0]) > 0, "M-119: el portero lee el pie del lanzador (%s, natural %d)" % [str(cuenta), nat])
	raiz.queue_free()

## FALTAS POR PUNTOS (20-10-2026, vídeo del dueño): jugadas preparadas.
func _probar_faltas_puntos() -> void:
	_titulo("FALTAS POR PUNTOS")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	var loc: Array = []
	var vis: Array = []
	for p: Dictionary in motor.jugadores:
		if bool(p["por"]):
			continue
		(loc if bool(p["es_local"]) else vis).append(p)
	var atacante: Dictionary = loc[0]
	var defensa: Dictionary = vis[0]
	var arco := motor._arco_rival(atacante)
	var d := signf(arco.z)
	## Todos los demás lejos, a la espalda del atacante (no tapan el arco).
	for i in range(1, loc.size()):
		(loc[i]["node"] as Node3D).position = Vector3(-30 + i * 3, 0, -d * 45.0)
	for i in range(1, vis.size()):
		(vis[i]["node"] as Node3D).position = Vector3(-30 + i * 3, 0, -d * 48.0)
	## 1) Mano a mano: el 9 corre hacia el arco a 20 m; el último defensa llega
	## por detrás, lanzado, en plancha → roja directa.
	(atacante["node"] as Node3D).position = Vector3(0, 0, arco.z - d * 20.0)
	atacante["vel"] = Vector3(0, 0, d * 7.0)
	(defensa["node"] as Node3D).position = Vector3(0, 0, arco.z - d * 21.5)
	defensa["vel"] = Vector3(0, 0, d * 7.5)
	var pf := motor.puntos_falta(defensa, atacante, "deslizante")
	_comprobar((pf["factores"] as Array).has("por_detras") and (pf["factores"] as Array).has("gran_velocidad")
		and (pf["factores"] as Array).has("profesional"), "por detrás + a gran velocidad + último hombre (%s)" % str(pf["factores"]))
	_comprobar(float(pf["puntos"]) >= MotorJugable.UMBRAL_ROJA, "suma de roja directa (%.1f)" % float(pf["puntos"]))
	## 2) De frente, sin velocidad y con compañeros cubriendo: carga de hombro.
	(atacante["node"] as Node3D).position = Vector3(10, 0, 0)
	atacante["vel"] = Vector3(0, 0, d * 2.0)
	(defensa["node"] as Node3D).position = Vector3(10, 0, d * 1.0)
	defensa["vel"] = Vector3(0, 0, -d * 1.0)
	(vis[1]["node"] as Node3D).position = Vector3(10, 0, d * 12.0)
	var pf2 := motor.puntos_falta(defensa, atacante, "hombro")
	_comprobar(float(pf2["puntos"]) < MotorJugable.UMBRAL_AMARILLA, "carga de hombro de frente: solo falta (%.1f, %s)" % [float(pf2["puntos"]), str(pf2["factores"])])
	## 3) La falta de verdad: con tarjetas reales, la roja directa expulsa.
	motor.tarjetas_reales = true
	(atacante["node"] as Node3D).position = Vector3(0, 0, arco.z - d * 20.0)
	atacante["vel"] = Vector3(0, 0, d * 7.0)
	(defensa["node"] as Node3D).position = Vector3(0, 0, arco.z - d * 21.5)
	defensa["vel"] = Vector3(0, 0, d * 7.5)
	(vis[1]["node"] as Node3D).position = Vector3(-30, 0, -d * 48.0)
	var antes := motor.jugadores.size()
	var an0 := float(motor.anadido[motor.mitad - 1]) if motor.mitad >= 1 and motor.anadido.size() >= motor.mitad else -1.0
	motor._falta(defensa, atacante, 0.25, "", "deslizante")
	var an1 := float(motor.anadido[motor.mitad - 1]) if an0 >= 0.0 else -1.0
	_comprobar(an0 >= 0.0 and an1 > an0, "M-139: la entrada dura suma añadido (%.2f → %.2f)" % [an0, an1])
	_comprobar(String(motor.ultima_falta.get("sancion", "")) == "roja", "se pita roja directa (%s)" % str(motor.ultima_falta))
	_comprobar(String(defensa.get("anim_actual", "")) in ["discutir_arbitro", "protestar"], "M-105: el amonestado protesta al árbitro (%s)" % String(defensa.get("anim_actual", "")))
	_comprobar(motor.jugadores.size() == antes - 1 or bool(defensa.get("expulsado", false)), "y el infractor se va del campo")
	## M-107: el juez de línea va a la altura del penúltimo defensor.
	var def_mas: Array = []
	for p: Dictionary in motor.jugadores:
		if signf(motor._arco_propio(p).z) > 0.0:
			def_mas.append(p)
	for i in def_mas.size():
		(def_mas[i]["node"] as Node3D).position = Vector3(float(i) * 2.0 - 10.0, 0, 5.0)
	(def_mas[0]["node"] as Node3D).position = Vector3(0, 0, 51.0)
	(def_mas[1]["node"] as Node3D).position = Vector3(5, 0, 33.0)
	_comprobar(is_equal_approx(motor.linea_fuera_de_juego(1.0), 33.0), "M-107: la línea del fuera de juego es la del penúltimo (%.1f)" % motor.linea_fuera_de_juego(1.0))
	raiz.queue_free()

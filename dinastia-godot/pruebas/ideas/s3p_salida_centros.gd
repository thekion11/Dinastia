extends BaseIdea
## s3p · EL PORTERO SALE A LOS CENTROS (semana 3 del plan, «Partido II: porteros», 27-10-2026,
## `SalidaPortero`). Un centro que baja en su zona (0,8-11 m de la línea, ±14 m) le hace salir si llega
## antes que el balón; lo que cae lejos, fuera de su zona o con dueño, no. Ya debajo, lo atrapa o lo
## despeja de puño, y en un rato de partido con centros no rompe nada.

const T_CAIDA := 1.2

func _probar() -> void:
	_titulo("S3P: el portero sale a los centros")
	var r := _motor()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	var gk: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if bool(p["por"]) and bool(p["es_local"]):
			gk = p
	motor.estado = "juego"
	var arco := motor._arco_propio(gk)
	_comprobar(absf(arco.z + 52.5) < 0.6, "el arco local está en z = -52,5 (%.1f)" % arco.z)
	## Desde la banda derecha al punto entre el área chica y el penal (6,5 m de la línea).
	var sale := _salidas(motor, gk, Vector3(25, 1.0, -40), Vector2(2.0, -46.0))
	_linea("  (centro al área: sale en %d de 100)" % sale)
	_comprobar(sale >= 40, "a un centro que cae a 6,5 m de su línea sale casi siempre (%d de 100)" % sale)
	var lejos := _salidas(motor, gk, Vector3(25, 1.0, -30), Vector2(0.0, -36.0))
	_comprobar(lejos == 0, "al que cae a 16 m, fuera de su zona, no sale (%d)" % lejos)
	var abierto := _salidas(motor, gk, Vector3(30, 1.0, -40), Vector2(19.0, -47.0))
	_comprobar(abierto == 0, "al que cae abierto, a 19 m del centro del arco, tampoco (%d)" % abierto)
	## Con un delantero rival esperando justo donde cae, no sale (le dejaría el arco vacío al cabezazo).
	var nueve: Dictionary = {}
	for q: Dictionary in motor.jugadores:
		if not bool(q["es_local"]) and not bool(q["por"]):
			nueve = q
	var antes: Vector3 = (nueve["node"] as Node3D).position
	(nueve["node"] as Node3D).position = Vector3(2.0, 0, -45.0)
	var ganado := _salidas(motor, gk, Vector3(25, 1.0, -40), Vector2(2.0, -46.0))
	(nueve["node"] as Node3D).position = antes
	_comprobar(ganado == 0, "si un delantero llega antes a la caída, no sale (%d)" % ganado)
	_centro(motor, gk, Vector3(25, 1.0, -40), Vector2(2.0, -46.0))
	motor.poseedor = motor.jugadores[5]
	_comprobar(SalidaPortero.punto(motor, gk) == Vector3.INF, "con el balón en un pie (dueño), no sale")
	## Ya debajo: atrapa o despeja (el balón deja de ir hacia su arco suelto).
	var atrapa := 0
	var despeja := 0
	for i in 60:
		_centro(motor, gk, Vector3(25, 1.0, -40), Vector2(2.0, -46.0))
		gk["_centro_visto"] = -1
		var obj := SalidaPortero.punto(motor, gk)
		if obj == Vector3.INF:
			continue
		(gk["node"] as Node3D).position = obj
		motor.balon.position = obj + Vector3(0.2, SalidaPortero.ALTO_MANOS - 0.2, 0.0)
		if SalidaPortero.atrapar(motor, gk):
			if motor.poseedor == gk:
				atrapa += 1
			else:
				despeja += 1
	_linea("  (debajo del balón: atrapa %d, despeja %d)" % [atrapa, despeja])
	_comprobar(atrapa + despeja > 0 and atrapa > 0, "debajo del balón lo atrapa (%d) o lo despeja (%d)" % [atrapa, despeja])
	## El tiro raso (LT + tiro): va pegado al césped; el normal, a media altura.
	var raso := _altura_tiro(motor, "raso")
	var normal := _altura_tiro(motor, "")
	_comprobar(raso < 0.8 and raso < normal, "el tiro raso no pasa de 0,8 m (%.2f m; el normal, %.2f m)" % [raso, normal])
	## Robo limpio: de 300 entradas de pie con éxito, el defensor se queda el balón en una parte;
	## la barrida lo deja siempre suelto.
	var limpio := _robos(motor, false)
	var barrida := _robos(motor, true)
	_linea("  (entradas con éxito: de pie se la queda en %d %%, con barrida en %d %%)" % [limpio, barrida])
	_comprobar(limpio >= 30 and limpio <= 85 and barrida == 0, "de pie, el defensor se queda el balón a veces (%d %%); con barrida, nunca (%d %%)" % [limpio, barrida])
	## Preset Arcade frente a Realista: menos error de pase y tiro y menos faltas.
	motor.fijar_preset("realista")
	var err_r := motor.preset_error
	var falta_r := motor._escala_falta()
	motor.fijar_preset("arcade")
	var err_a := motor.preset_error
	var falta_a := motor._escala_falta()
	motor.fijar_preset("realista")
	_comprobar(err_a < err_r and falta_a < falta_r, "Arcade: error de pase y tiro ×%.2f (Realista ×%.2f) y faltas ×%.2f (×%.2f)" % [err_a, err_r, falta_a, falta_r])
	_comprobar(MotorJugable.PRESETS.has(VistaEstadio.preset_guardado()), "el preset guardado es válido («%s»)" % VistaEstadio.preset_guardado())
	## Un rato de partido con centros de verdad no rompe nada.
	motor.autopiloto = true
	motor._saque_de_centro(true)
	for i in 900:
		motor.paso(1.0 / 30.0)
	_comprobar(motor.pos(gk).distance_to(arco) < 25.0, "tras 30 s de partido el portero sigue cerca de su arco (%.1f m)" % motor.pos(gk).distance_to(arco))
	raiz.queue_free()

## Altura máxima media de 20 tiros desde 18 m con el modificador `mod`, carga 0,9.
func _altura_tiro(motor: MotorJugable, mod: String) -> float:
	var tirador: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if not bool(p["por"]) and bool(p["es_local"]):
			tirador = p
	var suma := 0.0
	for i in 20:
		motor.estado = "juego"
		motor._tiro_vivo = {}
		(tirador["node"] as Node3D).position = Vector3(2.0, 0, 34.5)
		motor.balon.position = Vector3(2.0, 0.11, 35.0)
		motor._tomar(tirador)
		motor._mod_tiro = mod
		motor._tirar(tirador, Vector2(0.4, 0.0), 0.9)
		var alto := 0.0
		for k in 50:
			motor.paso(1.0 / 60.0)
			alto = maxf(alto, motor.balon.position.y)
		suma += alto
	return suma / 20.0

## De las entradas que salen bien, en qué % el defensor se queda con el balón.
func _robos(motor: MotorJugable, barrida: bool) -> int:
	var atac: Dictionary = {}
	var defe: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if not bool(p["por"]):
			if bool(p["es_local"]):
				atac = p
			else:
				defe = p
	var ok := 0
	var suyo := 0
	for i in 300:
		motor.estado = "juego"
		motor._tiro_vivo = {}
		(atac["node"] as Node3D).position = Vector3(0, 0, 0)
		(defe["node"] as Node3D).position = Vector3(0, 0, 0.9)
		motor.balon.position = Vector3(0, 0.11, 0.3)
		motor.poseedor = {}
		motor._tomar(atac)
		atac["regate_hasta"] = 0.0
		motor._entrada(defe, barrida)
		if motor.poseedor != atac:
			if motor.poseedor == defe:
				suyo += 1
				ok += 1
			elif motor.ultimo_toque == defe and motor.estado == "juego":
				ok += 1
	return int(100.0 * suyo / maxf(ok, 1))

## Lanza un centro desde `b` que baja a la altura de las manos en `destino` (x, z) a los T_CAIDA s.
func _centro(motor: MotorJugable, gk: Dictionary, b: Vector3, destino: Vector2) -> void:
	motor.estado = "juego"
	motor.poseedor = {}
	motor._tiro_vivo = {}
	motor._n_patada += 1
	gk["centro_hasta"] = 0.0
	(gk["node"] as Node3D).position = Vector3(0, 0, -51.0)
	motor.balon.position = b
	var h := (destino - Vector2(b.x, b.z)) / (T_CAIDA * SalidaPortero.FRENO_AIRE)
	var vy := (SalidaPortero.ALTO_MANOS - b.y + 0.5 * SalidaPortero.G * T_CAIDA * T_CAIDA) / T_CAIDA
	motor.vel_balon = Vector3(h.x, vy, h.y)

## De 100 centros iguales, en cuántos sale.
func _salidas(motor: MotorJugable, gk: Dictionary, b: Vector3, destino: Vector2) -> int:
	var n := 0
	for i in 100:
		_centro(motor, gk, b, destino)
		if SalidaPortero.punto(motor, gk) != Vector3.INF:
			n += 1
	return n

func _motor() -> Array:
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
	motor.preparar(lista, ball, "", 7)
	return [motor, raiz, a]

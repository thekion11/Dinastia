extends BaseIdea
## P3 (3-11): LÍMITES FÍSICOS DE LA ZONA DE LOS ÁRBITROS. Un partido de 11 contra 11 llevado por la IA (a 60 Hz, el equivalente de unos 8 minutos de juego) con el trío
## arbitral: ninguno puede salir del recinto, el árbitro no se mete en las áreas chicas ni en las porterías, los jueces de línea no pisan el
## césped, nadie atraviesa a un jugador y todos quedan a una distancia mínima del balón. Se mide por muestreo y se informa del peor caso.

const DT := 1.0 / 60.0
const SEGUNDOS := 480

func _ready() -> void:
	await get_tree().process_frame
	_titulo("P3 · LOS ÁRBITROS Y SUS LÍMITES")
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
	lista.append_array(sp.spawn_arbitros(raiz, {}))
	var balon := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.preparar(lista, balon, "", 7)
	motor._saque_de_centro(true)
	_comprobar(motor.arbitros.size() == 3, "el motor lleva al trío arbitral (%d)" % motor.arbitros.size())
	var fuera_recinto := 0
	var en_area_chica := 0
	var linea_en_cesped := 0
	var atraviesa := 0
	var peor_cuerpo := 99.0
	var peor_area := 99.0
	var peor_linea := 99.0
	var peor_balon := 99.0
	var en_juego := 0
	for i in int(SEGUNDOS / DT):
		motor.paso(DT)
		if i % 6 != 0:
			continue
		en_juego += 1
		for ar: Dictionary in motor.arbitros:
			var n := ar["node"] as Node3D
			var p := n.position
			var id := String(ar["id"])
			if absf(p.x) > MotorJugable.ANCHO + 4.0 or absf(p.z) > MotorJugable.LARGO + 1.5:
				fuera_recinto += 1
			if id == "arbitro":
				## Las áreas chicas (5,5 m × 18,3 m) y la portería: el árbitro de campo no entra.
				var dentro_chica := absf(p.z) > MotorJugable.LARGO - 5.5 and absf(p.x) < 9.2
				if dentro_chica:
					en_area_chica += 1
				peor_area = minf(peor_area, MotorJugable.LARGO - 5.5 - absf(p.z) if absf(p.x) < 9.2 else 99.0)
			else:
				## Los jueces de línea van por fuera de la banda (|x| ≥ 34 + algo): nunca sobre el césped de juego.
				if absf(p.x) < MotorJugable.ANCHO + 0.5:
					linea_en_cesped += 1
				peor_linea = minf(peor_linea, absf(p.x) - MotorJugable.ANCHO)
			for j: Dictionary in motor.jugadores:
				var d := Vector2(p.x - (j["node"] as Node3D).position.x, p.z - (j["node"] as Node3D).position.z).length()
				peor_cuerpo = minf(peor_cuerpo, d)
				if d < 0.7:
					atraviesa += 1
			if id == "arbitro":
				peor_balon = minf(peor_balon, Vector2(p.x - balon.position.x, p.z - balon.position.z).length())
	print("  muestras %d · peor distancia árbitro-jugador %.2f m (radio %.2f) · árbitro al área chica: %.1f m · juez de línea a la banda: %.2f m · árbitro-balón mín. %.1f m" % [en_juego, peor_cuerpo, MotorJugable.RADIO_CUERPO, peor_area, peor_linea, peor_balon])
	_comprobar(fuera_recinto == 0, "ningún árbitro sale del recinto (%d muestras fuera)" % fuera_recinto)
	_comprobar(en_area_chica == 0, "el árbitro no entra en las áreas chicas ni en las porterías (%d muestras)" % en_area_chica)
	_comprobar(linea_en_cesped == 0, "los jueces de línea no pisan el césped de juego (%d muestras)" % linea_en_cesped)
	_comprobar(atraviesa == 0, "ningún árbitro atraviesa a un jugador (%d muestras a menos de 0,7 m)" % atraviesa)
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

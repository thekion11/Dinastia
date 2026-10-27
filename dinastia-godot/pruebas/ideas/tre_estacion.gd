extends BaseIdea
## LA ESTACIÓN CENTRAL CON TRENES (27-10-2026): vías, andén, túnel y dos trenes que entran, esperan y salen desfasados.

func _probar() -> void:
	_titulo("CIUDAD · ESTACIÓN CENTRAL CON TRENES")
	var b := CityBuilder.new()
	add_child(b)
	var m := StandardMaterial3D.new()
	var est := EstacionCentral.montar(b, Vector3(110, 0.2, -550), 96.0, 96.0, {"claro": m, "vidrio": m, "piedra": m})
	_comprobar(est.cuenta["trenes"] == 2 and est.cuenta["tramos"] >= 8, "dos vías con %d tramos del kit y un tren en cada una" % est.cuenta["tramos"])
	var p0 := est.posicion_tren(0, 0.0)
	_comprobar(bool(p0["visible"]) and not bool(p0["parado"]), "al empezar, el tren 1 está llegando por el túnel")
	var p1 := est.posicion_tren(0, EstacionCentral.LLEGADA + 5.0)
	_comprobar(bool(p1["parado"]) and is_equal_approx(float(p1["z"]), float(est._trenes[0]["z1"])), "luego espera parado en el andén")
	var p2 := est.posicion_tren(0, EstacionCentral.CICLO - 3.0)
	_comprobar(not bool(p2["visible"]), "y al final del ciclo la vía queda vacía")
	var q0 := est.posicion_tren(1, 0.0)
	_comprobar(bool(q0["parado"]) and bool(p0["parado"]) == false, "el segundo tren va desfasado media vuelta")
	var dentro := true
	for k in 70:
		var pk := est.posicion_tren(0, float(k))
		var z: float = pk["z"]
		dentro = dentro and z >= float(est._trenes[0]["z0"]) - 0.01 and z <= float(est._trenes[0]["z1"]) + 0.01
	_comprobar(dentro, "el tren nunca se sale de la vía (ni atraviesa el tope)")
	est._process(10.0)
	_comprobar((est._trenes[0]["nodo"] as Node3D).position.z > float(est._trenes[0]["z0"]), "con el tiempo el nodo del tren avanza")
	_comprobar(b.asientos.size() >= 8, "los bancos del andén registran %d asientos para los pasajeros (GenteSentada)" % b.asientos.size())
	var rj := Reloj.new()
	EstacionCentral.reloj = rj
	rj.minuto = 3 * 60
	est._process(0.0)
	_comprobar(not (est._trenes[0]["nodo"] as Node3D).visible and not (est._trenes[1]["nodo"] as Node3D).visible, "de madrugada (03:00) no hay servicio")
	rj.minuto = 577   ## 09:37: t = 3462 s → 102 s del ciclo del tren 1 (parado en el andén)
	est._process(0.0)
	_comprobar((est._trenes[0]["nodo"] as Node3D).visible and est._reloj_rotulo.text == "09:37", "a las 09:37 hay trenes y el reloj de la fachada marca la hora del juego")
	var antes := est.posicion_tren(0, (rj.dia * 1440 + rj.minuto) * 6.0)
	rj.minuto = 578
	est._process(0.0)
	_comprobar(float((est._trenes[0]["nodo"] as Node3D).position.z) != float(antes["z"]) or bool(antes["parado"]), "el ciclo avanza con los minutos del reloj del juego")
	EstacionCentral.reloj = null
	_comprobar(est.get_child_count() > 35, "estación levantada (%d piezas)" % est.get_child_count())
	_probar_suavidad(est)

## F-3: el perfil de llegada y salida es suave (aceleración continua, cero al parar), y el tren se inclina al frenar.
func _probar_suavidad(est: EstacionCentral) -> void:
	_linea("· Movimiento del tren")
	var dt := 0.05
	var a_ant := float(est.posicion_tren(0, 0.0)["a"])   ## (entra por el túnel, fuera de la vista: no cuenta el salto de 0 a la aceleración de entrada)
	var tiron := 0.0
	var amax := 0.0
	var vmax := 0.0
	var z_ant := float(est.posicion_tren(0, 0.0)["z"])
	var t := dt
	while t < EstacionCentral.LLEGADA + EstacionCentral.ESPERA + EstacionCentral.SALIDA:
		var p := est.posicion_tren(0, t)
		if bool(p["visible"]):
			tiron = maxf(tiron, absf(float(p["a"]) - a_ant) / dt)
			amax = maxf(amax, absf(float(p["a"])))
			vmax = maxf(vmax, absf(float(p["v"])))
			a_ant = float(p["a"])
		t += dt
	_comprobar(amax < 2.0, "acelera y frena como mucho a %.2f m/s²" % amax)
	_comprobar(tiron < 0.6, "con tirón máximo de %.2f m/s³ (nada de saltos)" % tiron)
	_comprobar(vmax > 10.0 and vmax < 40.0, "entra a %.1f m/s (%.0f km/h) y no más" % [vmax, vmax * 3.6])
	var cerca := est.posicion_tren(0, EstacionCentral.LLEGADA - 0.01)
	_comprobar(absf(float(cerca["v"])) < 0.01 and absf(float(cerca["a"])) < 0.001, "al parar, velocidad y aceleración llegan a cero (v %.3f, a %.4f)" % [float(cerca["v"]), float(cerca["a"])])
	est._process(0.0)
	var pit_frenando := absf((est._trenes[0]["nodo"] as Node3D).rotation.x)
	_comprobar(pit_frenando <= 0.02 + 0.0001, "el cabeceo está acotado (%.4f rad)" % pit_frenando)
	_comprobar(z_ant <= float(est._trenes[0]["z0"]) + 0.01, "arranca desde dentro del túnel")
	_probar_pasajeros(est)

## F-3b: pasajeros que bajan y suben del tren (PasajerosEstacion).
func _probar_pasajeros(est: EstacionCentral) -> void:
	_linea("· Pasajeros")
	EstacionCentral.reloj = null
	est._process(0.0)
	_comprobar(est._gente.size() == 8, "ocho pasajeros (cuatro por tren) creados al primer tren con servicio (%d)" % est._gente.size())
	var z1: float = est._trenes[0]["z1"]
	var sx: float = (est._trenes[0]["nodo"] as Node3D).position.x
	var zf := est.z_vestibulo
	var bajan := 0
	var suben := 0
	var en_anden := true
	var u := 0.0
	while u < EstacionCentral.CICLO:
		for k in PasajerosEstacion.PLAN.size():
			var e := PasajerosEstacion.estado(k, sx, z1, zf, u)
			if bool(e["visible"]):
				var p: Vector3 = e["p"]
				en_anden = en_anden and absf(p.x - sx) <= 8.0 and p.z <= zf + 0.01 and p.z >= z1 - 17.0 and is_equal_approx(p.y, PasajerosEstacion.ALTO_ANDEN)
		u += 0.25
	for k in PasajerosEstacion.PLAN.size():
		var baja: bool = PasajerosEstacion.PLAN[k][1]
		var llega := EstacionCentral.LLEGADA + float(PasajerosEstacion.PLAN[k][2])
		var antes := PasajerosEstacion.estado(k, sx, z1, zf, llega - 0.5)
		var justo := PasajerosEstacion.estado(k, sx, z1, zf, llega + 0.01)
		if baja:
			bajan += 1 if (not bool(antes["visible"]) and bool(justo["visible"])) else 0
		else:
			var a_puerta := PasajerosEstacion.estado(k, sx, z1, zf, llega - 0.02)
			var p2: Vector3 = a_puerta["p"]
			var z_puerta := z1 + float(PasajerosEstacion.PUERTAS[int(PasajerosEstacion.PLAN[k][0])])
			suben += 1 if (bool(antes["visible"]) and absf(p2.z - z_puerta) < 0.2 and not bool(justo["visible"])) else 0
	_comprobar(bajan == 2, "dos pasajeros aparecen en las puertas cuando el tren para y se bajan (%d)" % bajan)
	_comprobar(suben == 2, "dos llegan a la puerta justo cuando para y suben (%d)" % suben)
	_comprobar(en_anden, "todos andan por el andén (a su altura, entre el tren y el vestíbulo)")
	var sin_tren := PasajerosEstacion.estado(0, sx, z1, zf, EstacionCentral.CICLO - 1.0)
	_comprobar(not bool(sin_tren["visible"]), "con la vía vacía no hay nadie en el andén")
	var rj := Reloj.new()
	EstacionCentral.reloj = rj
	rj.minuto = 3 * 60
	est._process(0.0)
	var algun_visible := false
	for g: Dictionary in est._gente:
		algun_visible = algun_visible or (g["nodo"] as Node3D).visible
	_comprobar(not algun_visible, "de madrugada (03:00) no hay pasajeros")
	EstacionCentral.reloj = null
	_probar_via_exterior(est)

## F-3c: la vía que sale de la ciudad (ViaEstacion): tramo abierto, dos bocas y el tren que se oculta bajo tierra.
func _probar_via_exterior(est: EstacionCentral) -> void:
	_linea("· Vía exterior")
	var info: Dictionary = est.get_meta("via_exterior", {})
	_comprobar(not info.is_empty() and float(info["z_a"]) - float(info["z_b"]) >= 190.0 and int(info["porticos"]) >= 3, "tramo abierto de %.0f m con %d pórticos de catenaria" % [float(info["z_a"]) - float(info["z_b"]), int(info["porticos"])])
	var largo := est.largo_del_tren
	_comprobar(largo > 15.0 and largo < 30.0, "el tren mide %.1f m (tres coches)" % largo)
	_comprobar(ViaEstacion.visible_en(ViaEstacion.Z_BOCA_B - 5.0, largo, est.z_tunel_anden), "empieza dentro del túnel del horizonte, a la vista (dentro de su boca)")
	_comprobar(ViaEstacion.visible_en((ViaEstacion.Z_BOCA_A + ViaEstacion.Z_BOCA_B) * 0.5, largo, est.z_tunel_anden), "a cielo abierto en el tramo exterior")
	_comprobar(not ViaEstacion.visible_en(-300.0, largo, est.z_tunel_anden), "por el subsuelo (entre las dos bocas de la ciudad) no se ve")
	_comprobar(ViaEstacion.visible_en(est.z_tunel_anden + largo + 1.0, largo, est.z_tunel_anden), "y reaparece ya dentro del túnel del andén")
	var z0: float = est._trenes[0]["z0"]
	_comprobar(z0 < ViaEstacion.Z_BOCA_B and z0 - largo > ViaEstacion.Z_BOCA_B - ViaEstacion.LARGO_BOCA, "arranca con todo el tren dentro de la boca lejana (z %.0f)" % z0)
	var abierto := 0.0
	var u := 0.0
	var z_ant := float(est.posicion_tren(0, 0.0)["z"])
	while u < EstacionCentral.LLEGADA:
		u += 0.5
		var z := float(est.posicion_tren(0, u)["z"])
		if z > ViaEstacion.Z_BOCA_B and z < ViaEstacion.Z_BOCA_A:
			abierto += 0.5
		z_ant = z
	_comprobar(abierto > 5.0 and abierto < 40.0, "el tren recorre el tramo exterior en %.1f s (se le ve venir)" % abierto)
	## 27-10 (revisión del líder: la vía cruzaba tres calles a nivel): ahora va por el subsuelo hasta pasada la autopista del anillo.
	var z_estacion := -5.0 * CiudadExpansion.CELDA
	var borde_autopista := -(Autopista.R + Autopista.ANCHO * 0.5)
	_comprobar(z_estacion + ViaEstacion.Z_BOCA_A + ViaEstacion.LARGO_BOCA < borde_autopista, "la boca cercana (con su túnel) queda más allá del borde norte de la autopista (z %.0f < %.0f): ninguna calle se cruza a nivel" % [z_estacion + ViaEstacion.Z_BOCA_A + ViaEstacion.LARGO_BOCA, borde_autopista])
	_comprobar(not ViaEstacion.visible_en(-250.0, est.largo_del_tren, est.z_tunel_anden) and not ViaEstacion.visible_en(-700.0, est.largo_del_tren, est.z_tunel_anden), "y por debajo de las calles (y de la autopista) el tren no se ve, no pisa ninguna")

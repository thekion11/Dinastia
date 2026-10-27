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
	rj.minuto = 600
	est._process(0.0)
	_comprobar((est._trenes[0]["nodo"] as Node3D).visible and est._reloj_rotulo.text == "10:00", "a las 10:00 hay trenes y el reloj de la fachada marca la hora del juego")
	var antes := est.posicion_tren(0, (rj.dia * 1440 + rj.minuto) * 6.0)
	rj.minuto = 601
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
	_comprobar(vmax > 4.0 and vmax < 20.0, "entra a %.1f m/s (%.0f km/h) y no más" % [vmax, vmax * 3.6])
	var cerca := est.posicion_tren(0, EstacionCentral.LLEGADA - 0.01)
	_comprobar(absf(float(cerca["v"])) < 0.01 and absf(float(cerca["a"])) < 0.001, "al parar, velocidad y aceleración llegan a cero (v %.3f, a %.4f)" % [float(cerca["v"]), float(cerca["a"])])
	est._process(0.0)
	var pit_frenando := absf((est._trenes[0]["nodo"] as Node3D).rotation.x)
	_comprobar(pit_frenando <= 0.02 + 0.0001, "el cabeceo está acotado (%.4f rad)" % pit_frenando)
	_comprobar(z_ant <= float(est._trenes[0]["z0"]) + 0.01, "arranca desde dentro del túnel")

extends BaseIdea
## POLICÍA Y BOMBEROS CON VIDA (27-10-2026, pieza E): incidentes por hash, rutas por las calles, vehículos que salen/llegan/vuelven,
## fuego más lento sin presión de agua, y multa de la cartera por cruzar en rojo con la policía delante.

func _probar() -> void:
	_titulo("CIUDAD · POLICÍA Y BOMBEROS: INCIDENTES")
	## --- Lo puro ---
	var cuenta := {"robo": 0, "incendio": 0, "accidente": 0}
	var total := 0
	var igual := true
	var madrugada := true
	for dia in 30:
		for hora in 24:
			var d := IncidentesCiudad.sortear(7, dia, hora)
			igual = igual and d == IncidentesCiudad.sortear(7, dia, hora)
			if hora < IncidentesCiudad.HORA_DESDE:
				madrugada = madrugada and d.is_empty()
			if not d.is_empty():
				total += 1
				cuenta[d["tipo"]] += 1
	_comprobar(igual and madrugada, "mismos (semilla, día, hora) → mismo incidente, y de madrugada no pasa nada")
	_comprobar(total >= 30 and total <= 110, "en 30 días hay %d incidentes (≈ 2 al día)" % total)
	_comprobar(int(cuenta["robo"]) > 3 and int(cuenta["incendio"]) > 3 and int(cuenta["accidente"]) > 3, "salen de los tres tipos: %s" % str(cuenta))
	var inc := IncidentesCiudad.nuevo("incendio", Vector3(341, 0.2, 365))
	_comprobar(inc["esperados"] == 2 and IncidentesCiudad.avanzar(inc, 5.0) == "camino", "el incendio espera a dos camiones y mientras tanto no se apaga")
	IncidentesCiudad.llega(inc)
	IncidentesCiudad.llega(inc)
	_comprobar(IncidentesCiudad.avanzar(inc, 1.0) == "atendiendo" and IncidentesCiudad.pendiente(inc) < 1.0, "al llegar los dos, atienden")
	var t_sano := 0.0
	while IncidentesCiudad.avanzar(inc, 0.5, IncidentesCiudad.ritmo_fuego(true)) != "resuelto":
		t_sano += 0.5
	var inc2 := IncidentesCiudad.nuevo("incendio", Vector3.ZERO)
	inc2["llegados"] = 2
	var t_seco := 0.0
	while IncidentesCiudad.avanzar(inc2, 0.5, IncidentesCiudad.ritmo_fuego(false)) != "resuelto":
		t_seco += 0.5
	_comprobar(t_seco > t_sano * 2.0, "sin presión de agua el incendio tarda %.0f s en vez de %.0f s" % [t_seco, t_sano])
	var desde := Vector3(240, 0.2, 97)
	var hasta := Vector3(341, 0.2, 365)
	var ruta := IncidentesCiudad.ruta_calles(desde, hasta)
	var calle_ok := true
	for p in ruta:
		var dx := absf(p.x - roundf(p.x / 110.0) * 110.0)
		var dz := absf(p.z - roundf(p.z / 110.0) * 110.0)
		calle_ok = calle_ok and minf(dx, dz) < 1.0 + 14.0
	_comprobar(ruta[0] == desde and absf(ruta[ruta.size() - 1].z - hasta.z) < 0.01 and absf(ruta[ruta.size() - 1].x - 330.0) < 0.01, "la ruta sale del parque y acaba en la avenida del sitio")
	_comprobar(calle_ok and IncidentesCiudad.largo_de(ruta) >= 100.0 + 268.0 - 40.0, "va por las calles de la rejilla (%.0f m), no a campo través" % IncidentesCiudad.largo_de(ruta))
	var recta := PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0, -100)])
	_comprobar(absf(float(IncidentesCiudad.punto_en(recta, 40.0)[1]) - PI) < 0.01 or absf(float(IncidentesCiudad.punto_en(recta, 40.0)[1]) + PI) < 0.01, "hacia el norte (−Z) el rumbo es ±180°")
	## --- Los vehículos ---
	ServiciosVida.estaciones = {}
	ServiciosVida.registrar("comisaria", Vector3(550, 0.2, 110), 100.0, 100.0)
	ServiciosVida.registrar("bomberos", Vector3(660, 0.2, 110), 100.0, 100.0)
	ServiciosVida.registrar("hospital", Vector3(550, 0.2, -110), 100.0, 100.0)
	var m := Mundo.new()
	m.generar(["CHI"], 11)
	m.roles = Roles.new(m)
	var v := VidaCiudad.new()
	v.mundo = m
	v.expl = ExploradorCiudad.new()
	v.expl._aviso = Label.new()
	add_child(v.expl)
	var sv := ServiciosVida.crear(v)
	_comprobar(sv.vehiculos.size() == 1 and sv.vehiculos[0]["estado"] == "patrulla", "la comisaría tiene su coche patrulla en marcha")
	var s0 := float(sv.vehiculos[0]["s"])
	sv._process(1.0)
	_comprobar(float(sv.vehiculos[0]["s"]) > s0 + 7.0, "y avanza por las calles de al lado")
	var sitio := Vector3(3.0 * 110.0 + 11.0, 0.2, 3.0 * 110.0 + 35.0)
	_comprobar(sv.iniciar("incendio", sitio) and sv.vehiculos.size() == 3, "un incendio saca dos camiones (y sigue el patrulla)")
	_comprobar(not sv.iniciar("robo", sitio), "con un incidente en marcha no empieza otro")
	var vmax := 0.0
	var llegaron := false
	var paso := 0
	while paso < 4000 and (not sv.incidente.is_empty() or sv.vehiculos.size() > 1):
		sv._process(0.1)
		paso += 1
		for ve in sv.vehiculos:
			vmax = maxf(vmax, float(ve["vel"]))
		if not sv.incidente.is_empty() and sv.incidente["fase"] == "atendiendo":
			llegaron = true
	_comprobar(llegaron, "los dos camiones llegan al sitio y atienden")
	_comprobar(vmax <= ServiciosVida.V_MAX + 0.01 and vmax > 8.0, "sin pasar de %.0f m/s (máximo %.1f)" % [ServiciosVida.V_MAX, vmax])
	_comprobar(sv.incidente.is_empty() and sv.vehiculos.size() == 1, "se apaga, vuelven al parque (desaparecen) y queda solo el patrulla (%.0f s)" % (float(paso) * 0.1))
	## --- La multa ---
	m.roles.cartera.efectivo = 300
	_comprobar(sv.multar(90) == "efectivo" and m.roles.cartera.efectivo == 210 and v.expl.multas == 1, "la multa se paga de la cartera (300 → 210 €)")
	m.roles.cartera.efectivo = 0
	m.roles.cartera.bloqueada = true
	_comprobar(sv.multar(90) == "" and sv.multas_puestas == 2 and v.expl.multas == 2, "sin dinero queda anotada igualmente")
	m.roles.cartera.bloqueada = false
	m.roles.cartera.efectivo = 500
	var sem := Semaforos.new()
	sem.t = 22.0    ## eje 0 (norte-sur) en rojo y eje 1 (este-oeste) en verde
	sv._cruces[Vector2i(3, 3)] = Vector3(330, 0, 330)
	var patrulla: Node3D = sv.vehiculos[0]["nodo"]
	patrulla.position = Vector3(330, 0.2, 380)
	var antes := sv.multas_puestas
	for k in 40:
		sv.vigilar_en(Vector3(330, 0.2, 300.0 + float(k) * 1.5), 12.0, sem)
	_comprobar(sv.multas_puestas == antes + 1 and m.roles.cartera.efectivo == 410, "cruzar en rojo con la policía a la vista = una multa (500 → 410 €), no una por fotograma")
	for k in 40:
		sv.vigilar_en(Vector3(330.0 + float(k) * 1.5 - 30.0, 0.2, 330), 12.0, sem)
	_comprobar(sv.multas_puestas == antes + 1, "cruzar en el otro sentido (eje en verde) no multa")
	patrulla.position = Vector3(2000, 0.2, 2000)
	sv._cruce_multado = Vector2i(1 << 20, 0)
	for k in 40:
		sv.vigilar_en(Vector3(330, 0.2, 300.0 + float(k) * 1.5), 12.0, sem)
	_comprobar(sv.multas_puestas == antes + 1, "sin policía cerca no hay multa")
	sem.t = 3.0
	patrulla.position = Vector3(330, 0.2, 380)
	for k in 40:
		sv.vigilar_en(Vector3(330, 0.2, 300.0 + float(k) * 1.5), 12.0, sem)
	_comprobar(sv.multas_puestas == antes + 1, "ni en verde")
	Sonido._generar_todo()
	_comprobar(Sonido.banco("sirena").size() > 0 and (Sonido.banco("sirena")[0] as AudioStreamWAV).data.size() > 1000, "la sirena existe como sonido sintetizado")

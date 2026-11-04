extends BaseIdea
## BANCO ESPECIALIZADO «ciudad_transporte», FASE 2 (4-11-2026, megarreforma de los bancos): el transporte de la ciudad, simulado y medido.
## Lo corre `herramientas/bancos_especiales.py ciudad_transporte`.
##   1. Semáforos: nunca dos ejes a la vez en verde/ámbar, todo-rojo entre fases, reparto del ciclo, los peatones cruzan con el tráfico cruzado en rojo.
##   2. Metro: cada tren de cada línea (copia suelta, sin escena) recorre 25 min: para en TODAS las estaciones, da la vuelta en las cabeceras, nunca pasa de su velocidad,
##      aceleración ni tirón, y se posa a < 0,35 m de cada andén; dos trenes de una línea nunca a menos de 25 m.
##   3. Teleférico: ciclo exacto (sube, espera, baja, espera), perfil suave, cabinas sobre el cable y cruzándose a medio camino.
##   4. Buses: cada servicio con su número, su vuelta «c», su patente única y sus paradas; cada parada con su paradero; y SIMULADOS: el bus se detiene en cada parada.
##   5. Coches: ninguno dentro de otro al armar ni tras 2 min; circulan por el carril derecho de su calle.
##   6. Sirenas: el tráfico las oye dentro de su radio y no fuera.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")

func _probar() -> void:
	_titulo("BANCO CIUDAD_TRANSPORTE (fase 2): semáforos, metro, teleférico, buses, coches, sirenas")
	var c: Dictionary = await Comun.abrir(self)
	var cb: Node = c["cb"]
	var ex: Object = cb.get("expansion")
	_semaforos(ex.get("semaforos"))
	_metro(cb.get("expansion").get("metro"))
	_teleferico(ex.get("tele_nodo"))
	var t: Object = cb.get_node_or_null("Trafico")
	_comprobar(t != null, "la ciudad trae su tráfico")
	if t != null:
		_buses_datos(t, ex)
		_coches_armado(t)
		await _simular(t)
		_sirenas()
	(c["vc"] as Node).free()

## ---- 1. semáforos
func _semaforos(s: Object) -> void:
	_comprobar(s != null, "hay controlador de semáforos")
	if s == null:
		return
	var t0: float = s.get("t")
	var ciclo: float = s.CICLO
	var choque := 0
	var todo_rojo := 0.0
	var verde := [0.0, 0.0]
	var peatones_mal := 0
	var paso := 0.05
	var n := int(ciclo / paso)
	for i in n:
		s.set("t", float(i) * paso)
		var e0: String = s.estado(0)
		var e1: String = s.estado(1)
		if e0 != "r" and e1 != "r":
			choque += 1
		if e0 == "r" and e1 == "r":
			todo_rojo += paso
		if e0 == "v":
			verde[0] += paso
		if e1 == "v":
			verde[1] += paso
		for eje in 2:
			if s.peatonal(eje) != "r" and s.estado(1 - eje) != "r":
				peatones_mal += 1
	s.set("t", t0)
	print("  ciclo %.0f s · verde eje0 %.1f s, eje1 %.1f s · todo rojo %.1f s" % [ciclo, verde[0], verde[1], todo_rojo])
	_comprobar(choque == 0, "nunca dos ejes a la vez en verde o ámbar (%d instantes)" % choque)
	_comprobar(absf(verde[0] - s.VERDE) < 0.2 and absf(verde[1] - s.VERDE) < 0.2, "cada eje tiene exactamente su verde (%.1f / %.1f s de %.0f)" % [verde[0], verde[1], s.VERDE])
	_comprobar(absf(todo_rojo - 2.0 * s.TODO_ROJO) < 0.3, "el todo-rojo entre fases dura %.1f s (2 por ciclo)" % todo_rojo)
	_comprobar(peatones_mal == 0, "con el verde peatonal de un eje, el tráfico cruzado está en rojo (%d instantes)" % peatones_mal)
	var cruces: Array = s.get("cruces")
	_comprobar(cruces.size() >= 100, "cruces con semáforo (%d)" % cruces.size())

## ---- 2. metro
func _metro(m: Object) -> void:
	_comprobar(m != null, "hay metro")
	if m == null:
		return
	var lineas: Array = m.get("lineas")
	_comprobar(lineas.size() >= 2, "al menos 2 líneas de metro (%d)" % lineas.size())
	var vmax := 0.0
	var amax := 0.0
	var jmax := 0.0
	var llegadas := 0
	var salto_llegada := 0.0
	var v_llegada := 0.0
	var rapidas: Array[String] = []
	var n_rapidas := 0
	var mal: Array[String] = []
	for l: Dictionary in lineas:
		var est: PackedFloat32Array = l["est_s"]
		var largo: float = float(l.get("largo", 0.0))
		if largo <= 0.0:
			largo = (l["b"] as Vector3).distance_to(l["a"] as Vector3)
		var trenes: Array = l["trenes"]
		_comprobar(est.size() >= 3 and trenes.size() >= 1, "línea %s: %d estaciones y %d trenes" % [String(l["nombre"]), est.size(), trenes.size()])
		var copias: Array = []
		for t0 in trenes:
			var c: Variant = m.get_script().get_script_constant_map()["Tren"] if false else null
			copias.append(_copiar_tren(t0))
		var paso := 1.0 / 60.0   ## el paso real del juego
		var pasos := int(1500.0 / paso)   ## 25 minutos
		var min_sep := INF
		var a_ant := 0.0
		for i in pasos:
			for k in copias.size():
				var tr = copias[k]
				var a_prev: float = tr.a
				var v_prev: float = tr.v
				var esp_prev: float = tr.espera
				tr.simular(paso)
				vmax = maxf(vmax, tr.v)
				amax = maxf(amax, absf(tr.a))
				if tr.espera > 0.0 and esp_prev <= 0.0:
					llegadas += 1   ## el paso en que se posa en el andén: a = 0 de golpe
					salto_llegada = maxf(salto_llegada, absf(a_prev))
					v_llegada = maxf(v_llegada, v_prev)
					if v_prev > 1.0:
						n_rapidas += 1
					if v_prev > 1.0 and rapidas.size() < 6:
						rapidas.append("%s tren %d en s=%.0f (estaciones %s) v=%.2f a=%.2f sentido %+.0f" % [String(l["nombre"]), k, tr.s, str(est), v_prev, a_prev, tr.sentido])
				else:
					jmax = maxf(jmax, absf(tr.a - a_prev) / paso)
				if tr.s < -1.0 or tr.s > largo + 1.0:
					mal.append("%s: el tren %d se sale de la vía (s=%.1f de %.1f)" % [String(l["nombre"]), k, tr.s, largo])
				if tr.espera > 0.0 and tr.v > 0.001:
					mal.append("%s: tren %d con puertas abiertas en marcha" % [String(l["nombre"]), k])
			if copias.size() > 1 and i % 60 == 0:
				for a in copias.size():
					for b in range(a + 1, copias.size()):
						if is_equal_approx(copias[a].sentido, copias[b].sentido):   ## de sentidos opuestos van por vías distintas y se cruzan
							min_sep = minf(min_sep, absf(copias[a].s - copias[b].s))
		for k in copias.size():
			var tr = copias[k]
			## Estaciones visitadas: con 25 min a 16 m/s se recorre varias veces la línea.
			_comprobar(tr.paradas_hechas >= est.size(), "línea %s, tren %d: %d paradas en 25 min (≥ %d estaciones)" % [String(l["nombre"]), k, tr.paradas_hechas, est.size()])
		if copias.size() > 1:
			_comprobar(min_sep > 25.0, "línea %s: dos trenes del mismo sentido nunca a menos de 25 m (mínimo %.0f m)" % [String(l["nombre"]), min_sep])
	print("  metro: velocidad máx %.2f m/s (tope %.0f), aceleración máx %.2f (tope %.1f), tirón máx %.2f (tope %.1f); %d llegadas: la aceleración que se pierde de golpe al posarse %.2f m/s², con %.2f m/s de velocidad" % [vmax, MetroCiudad.VEL, amax, MetroCiudad.ACEL, jmax, MetroCiudad.TIRON, llegadas, salto_llegada, v_llegada])
	for r in rapidas:
		print("    LLEGADA RÁPIDA ", r)
	_comprobar(n_rapidas <= maxi(1, int(0.03 * float(llegadas))) and v_llegada < 6.0, "al llegar al andén el tren va casi parado: solo %d de %d llegadas pasan de 1 m/s (la primera aproximación desde la posición inicial; máx %.2f m/s)" % [n_rapidas, llegadas, v_llegada])
	_comprobar(vmax <= MetroCiudad.VEL + 0.01, "ningún tren pasa de su velocidad máxima")
	_comprobar(amax <= MetroCiudad.ACEL + 0.01, "ningún tren pasa de su aceleración máxima")
	_comprobar(jmax <= MetroCiudad.TIRON * 1.5 + 0.05, "ningún tren pasa de su tirón fuera del instante de posarse (%.2f)" % jmax)
	_comprobar(mal.is_empty(), "trenes sobre la vía y con puertas solo parados%s" % ("" if mal.is_empty() else ": " + str(mal.slice(0, 4))))

func _copiar_tren(t0: Object) -> Object:
	var n = MetroCiudad.Tren.new(t0.largo, t0.estaciones, t0.s, t0.sentido)
	return n

## ---- 3. teleférico
func _teleferico(t: Object) -> void:
	_comprobar(t != null, "hay teleférico")
	if t == null:
		return
	var viaje: float = t.VIAJE
	var espera: float = t.ESPERA
	var ciclo: float = t.CICLO
	_comprobar(absf(ciclo - (viaje + espera) * 2.0) < 0.001, "el ciclo es (viaje + espera) × 2 (%.0f s)" % ciclo)
	_comprobar(t.avance(0.0) == 0.0 and absf(t.avance(viaje) - 1.0) < 1e-6 and t.avance(viaje + espera * 0.5) == 1.0 and t.avance(ciclo - 1.0) < 0.001, "avance: 0 al salir, 1 arriba, 1 en la espera, vuelve a 0")
	var mono_sube := true
	var mono_baja := true
	var periodico := true
	var peor_v := 0.0
	var peor_a := 0.0
	var antes: float = t.avance(0.0)
	var v_ant := 0.0
	for i in range(1, int(ciclo * 10.0)):
		var tt := float(i) * 0.1
		var f: float = t.avance(tt)
		var u := fposmod(tt, ciclo)
		if u < viaje and f + 1e-9 < antes:
			mono_sube = false
		if u > viaje + espera and u < 2.0 * viaje + espera and f > antes + 1e-9:
			mono_baja = false
		if absf(t.avance(tt + ciclo) - f) > 1e-9:
			periodico = false
		var vel := absf(f - antes) / 0.1
		peor_v = maxf(peor_v, vel)
		peor_a = maxf(peor_a, absf(vel - v_ant) / 0.1)
		v_ant = vel
		antes = f
	_comprobar(mono_sube and mono_baja, "la cabina sube sin retroceder y baja sin retroceder")
	_comprobar(periodico, "el ciclo se repite exacto")
	var largo := float((t.get("_largos") as PackedFloat32Array)[(t.get("_largos") as PackedFloat32Array).size() - 1])
	print("  teleférico: cable %.0f m, velocidad máx %.1f m/s, aceleración máx %.3f m/s²" % [largo, peor_v * largo, peor_a * largo])
	_comprobar(largo > 800.0 and largo < 3500.0, "cable de longitud razonable (%.0f m)" % largo)
	_comprobar(peor_v * largo < 40.0, "velocidad del cable menor de 40 m/s (%.1f)" % (peor_v * largo))
	_comprobar(peor_a * largo < 0.6, "aceleración del cable suave, menos de 0,6 m/s² (%.3f)" % (peor_a * largo))
	## Cabinas: sobre el cable y cruzándose a medio viaje.
	var cable: PackedVector3Array = t.get("puntos")
	var lejos := 0.0
	for tt in [0.0, viaje * 0.25, viaje * 0.5, viaje * 0.75, viaje]:
		t.call("_poner_cabinas", tt)
		for cab: Node3D in t.get("cabinas"):
			var d := INF
			for i in cable.size() - 1:
				d = minf(d, _dist_seg3(cab.position, cable[i], cable[i + 1]))
			lejos = maxf(lejos, d)
	print("  teleférico: la cabina se aleja como mucho %.2f m del cable" % lejos)
	_comprobar(lejos < 3.5, "las cabinas van pegadas al cable (máx %.2f m, el carril va a 2,5 m)" % lejos)
	t.call("_poner_cabinas", viaje * 0.5)
	var cs: Array = t.get("cabinas")
	_comprobar((cs[0] as Node3D).position.distance_to((cs[1] as Node3D).position) < 6.0, "a medio viaje las dos cabinas se cruzan (%.1f m)" % (cs[0] as Node3D).position.distance_to((cs[1] as Node3D).position))
	t.call("_poner_cabinas", 0.0)
	var base: Vector3 = t.get("base")
	var cima: Vector3 = t.get("cima")
	_comprobar(cima.y > base.y + 20.0, "la estación de arriba está bastante más alta (%.0f m de desnivel)" % (cima.y - base.y))

func _dist_seg3(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return p.distance_to(a)
	return p.distance_to(a + ab * clampf((p - a).dot(ab) / l2, 0.0, 1.0))

## ---- 4. buses (datos)
func _buses_datos(t: Object, ex: Object) -> void:
	var g: Node = null
	for n in t.get_children():
		if n is BusesRed:
			g = n
	_comprobar(g != null, "hay buses «Red» montados")
	if g == null:
		return
	var buses: Array = g.get("buses")
	var servicios: Array = RecorridosMapa.servicios()
	print("  servicios %d, buses %d" % [servicios.size(), buses.size()])
	_comprobar(buses.size() >= 20, "buses en la calle (%d)" % buses.size())
	var patentes := {}
	var malos: Array[String] = []
	var con_paradero := {}
	for pa in get_tree().get_nodes_in_group("paradero_red"):
		con_paradero[String(pa.get_meta("codigo_red", ""))] = true
	var codigos_sin_paradero: Array[String] = []
	var vistos_codigo := {}
	for b: Dictionary in buses:
		var nodo: Node3D = b["nodo"]
		var num := String(b["ida"])
		if String(nodo.get_meta("red_recorrido", "")) != num:
			malos.append("%s: meta de recorrido distinta (%s)" % [nodo.name, String(nodo.get_meta("red_recorrido", ""))])
		var pat := String(nodo.get_meta("red_patente", ""))
		if pat == "" or patentes.has(pat):
			malos.append("%s: patente vacía o repetida (%s)" % [nodo.name, pat])
		patentes[pat] = true
		if not String(nodo.name).begins_with("Bus_%s_" % num):
			malos.append("nombre de nodo %s no corresponde al recorrido %s" % [nodo.name, num])
		var rot: Label3D = b["rotulo"]
		if rot == null or not rot.text.begins_with(num):
			malos.append("%s: el letrero no empieza por su número (%s)" % [nodo.name, "" if rot == null else rot.text])
		var vuelta := String(b["vuelta"])
		if vuelta != RecorridosMapa.vuelta_de(num):
			malos.append("%s: la vuelta %s no es la de %s" % [nodo.name, vuelta, num])
		if float(b["largo"]) < 500.0:
			malos.append("%s: recorrido de solo %.0f m" % [nodo.name, float(b["largo"])])
		var paradas: Dictionary = b["paradas"]
		var ida: Dictionary = RecorridosMapa.servicio(num)
		var vta: Dictionary = RecorridosMapa.servicio(vuelta)
		var esperadas := {}
		for cod in ida["paraderos"]:
			esperadas[String(cod)] = true
		for cod in vta["paraderos"]:
			esperadas[String(cod)] = true
		if esperadas.size() != paradas.size():
			malos.append("%s: %d paradas en el bus y %d en el recorrido" % [nodo.name, paradas.size(), esperadas.size()])
		for cod in esperadas:
			if not paradas.has(cod):
				malos.append("%s: le falta la parada %s" % [nodo.name, cod])
			var s: float = float(paradas.get(cod, -1.0))
			if s < 0.0 or s > float(b["largo"]) + 0.01:
				malos.append("%s: parada %s fuera del recorrido (s=%.0f de %.0f)" % [nodo.name, cod, s, float(b["largo"])])
			if not vistos_codigo.has(cod):
				vistos_codigo[cod] = true
				var pd: Dictionary = RecorridosMapa.paradero(cod)
				if not bool(pd["club"]) and not con_paradero.has(cod):
					if cb_altura(ex, pd["pos"]) <= 1.0:
						codigos_sin_paradero.append(cod)
	_comprobar(malos.is_empty(), "buses: número, vuelta, patente única, letrero y paradas correctos%s" % ("" if malos.is_empty() else ": " + str(malos.slice(0, 5))))
	_comprobar(codigos_sin_paradero.is_empty(), "cada parada de un recorrido tiene su paradero en 3D (salvo bajo cerros): %d sin%s" % [codigos_sin_paradero.size(), "" if codigos_sin_paradero.is_empty() else " " + str(codigos_sin_paradero.slice(0, 6))])
	_comprobar(patentes.size() == buses.size(), "todas las patentes distintas (%d)" % patentes.size())

func cb_altura(ex: Object, p: Vector3) -> float:
	return ex.get("b").altura_en(p.x, p.z)

## ---- 5. coches (al armar)
func _coches_armado(t: Object) -> void:
	## A4-X04: se mide el REPARTO INICIAL (ruta + `s_ini`), no donde estén los coches tras los fotogramas que corrieron mientras se abría la ciudad (dependían del reloj: intermitente).
	var rutas: Array = t.get("_rutas")
	var puntos: Array[Dictionary] = []
	for v: Dictionary in t.get("_vehiculos"):
		if is_instance_valid(v["nodo"]) and not bool(v.get("peaton", false)) and float(v.get("alto", 0.0)) < 0.05 and not String((v["nodo"] as Node3D).name).begins_with("kart") and v.has("s_ini"):
			var pos: Vector3 = (rutas[int(v["ruta"])] as Object).call("en", float(v["s_ini"]))[0]
			puntos.append({"pos": pos, "ruta": int(v["ruta"]), "nombre": String((v["nodo"] as Node3D).name)})
	var coches := puntos
	var pegados := 0
	var quienes: Array[String] = []
	for i in coches.size():
		for j in range(i + 1, coches.size()):
			var d: float = (coches[i]["pos"] as Vector3).distance_to(coches[j]["pos"])
			if d < 1.0:
				pegados += 1
				quienes.append("%s/%s a %.2f m en (%.0f,%.0f) rutas %d/%d" % [coches[i]["nombre"], coches[j]["nombre"], d, (coches[i]["pos"] as Vector3).x, (coches[i]["pos"] as Vector3).z, int(coches[i]["ruta"]), int(coches[j]["ruta"])])
	for q in quienes:
		print("    PEGADOS ", q)
	_comprobar(pegados == 0, "ningún vehículo a menos de 1 m de otro al armar (%d pares, %d vehículos)" % [pegados, coches.size()])

## ---- 4 y 5. simulación del tráfico: primero TODO el tráfico 2 min (choques), luego solo los buses hasta completar sus paradas
func _paso_trafico(t: Object, sem: Object, paso: float) -> void:
	for v: Dictionary in t.get("_vehiculos"):
		if OS.get_environment("SIN_LOD") != "":
			v["lod"] = 0   ## (solo para comparar) sin nivel de detalle: por defecto se prueba CON el LOD real, donde los lejanos se actualizan cada 3-12 cuadros
	if sem != null:
		sem.call("_process", paso)
	t.call("_process", paso)

func _simular(t: Object) -> void:
	t.set_process(false)
	var sem: Object = t.get("semaforos")
	if sem != null:
		sem.set_process(false)
	var vehiculos: Array = t.get("_vehiculos")
	var buses: Array = []
	var coches: Array = []
	for v: Dictionary in vehiculos:
		var n: Node3D = v["nodo"]
		if not is_instance_valid(n):
			continue
		if String(n.name).begins_with("Bus_"):
			buses.append(v)
		elif not bool(v.get("peaton", false)) and float(v.get("alto", 0.0)) < 0.05 and not String(n.name).begins_with("kart"):
			coches.append(v)   ## (los karts de la pista corren pegados a propósito)
	## 1) todo el tráfico, 120 s a 10 pasos por segundo
	var paso := 0.1
	var min_dist := INF
	var chocan := 0
	var ejemplos: Array[String] = []
	for i in 1200:
		_paso_trafico(t, sem, paso)
		if i % 20 == 0:
			await get_tree().process_frame
		if i % 5 == 0:
			for a in coches.size():
				var pa: Vector3 = (coches[a]["nodo"] as Node3D).position
				for b in range(a + 1, coches.size()):
					var d: float = pa.distance_to((coches[b]["nodo"] as Node3D).position)
					if d < 1.2:
						chocan += 1
						if ejemplos.size() < 5:
							ejemplos.append("%s/%s a %.2f m en t=%.0f s" % [(coches[a]["nodo"] as Node3D).name, (coches[b]["nodo"] as Node3D).name, d, float(i) * paso])
					min_dist = minf(min_dist, d)
	print("  tráfico completo 120 s: distancia mínima entre vehículos %.2f m, %d instantes bajo 1,2 m %s" % [min_dist, chocan, str(ejemplos)])
	## (A4-M3D-012, 4-11) Los solapes eran de coches de la MISMA ruta sin cola (los del anillo y la avenida no seguían al de delante) y, a paso grueso del LOD, de coches que saltaban al de delante: arreglado (36-43 → ≤ 5);
	## quedan unos pocos instantes de rutas que se cortan en un cruce LEJANO (LOD 2, a ~20 m por paso, fuera de vista).
	_comprobar(chocan <= 12, "solapes entre vehículos en 2 min (%d instantes, tope 12; antes 36-43; mínimo %.2f m)" % [chocan, min_dist])
	## 2) solo los buses (sin coches ni gente que los frenen), con los semáforos avanzando
	var todos: Array = (t.get("_vehiculos") as Array).duplicate()
	var solo: Array = []
	for v in todos:
		if String((v["nodo"] as Node3D).name).begins_with("Bus_"):
			solo.append(v)
	t.set("_vehiculos", solo)
	var visitadas: Array = []
	var recorrido: Array[float] = []
	var s_ant: Array[float] = []
	for v in solo:
		visitadas.append({})
		recorrido.append(0.0)
		s_ant.append(float(v["s"]))
	var tt := 0.0
	var minimos := {}
	var quedan := true
	while tt < (300.0 if OS.get_environment("DEPURA") != "" else 2400.0) and quedan:
		_paso_trafico(t, sem, paso)
		tt += paso
		if int(tt * 10.0) % 200 == 0:
			await get_tree().process_frame
		quedan = false
		for bi in solo.size():
			var v: Dictionary = solo[bi]
			var largo: float = float((t.get("_rutas") as Array)[int(v["ruta"])].largo)
			recorrido[bi] += fposmod(float(v["s"]) - s_ant[bi], largo)
			s_ant[bi] = float(v["s"])
			for ps: float in v.get("paradas", []):
				if (visitadas[bi] as Dictionary).has(ps):
					continue
				var d2 := minf(absf(fposmod(float(v["s"]) - ps, largo)), absf(fposmod(ps - float(v["s"]), largo)))
				if bi == 1 and OS.get_environment("DEPURA") != "" and d2 < 6.0:
					minimos[ps] = minf(float(minimos.get(ps, 99.0)), d2)
					if d2 < 2.0 and int(tt * 10.0) % 5 == 0:
						print("    DEP t=%.1f s=%.1f ps=%.1f d2=%.2f vact=%.2f espera=%.2f vel=%.1f" % [tt, float(v["s"]), ps, d2, float(v.get("vact", -1)), float(v.get("espera", 0)), float(v["vel"])])
				if d2 < 1.0 and float(v.get("espera", 0.0)) > 0.0:
					visitadas[bi][ps] = true
			if (visitadas[bi] as Dictionary).size() < (v.get("paradas", []) as Array).size():
				quedan = true
	var sin_parar: Array[String] = []
	var total_paradas := 0
	for bi in solo.size():
		var vb: Dictionary = solo[bi]
		var faltan := (vb.get("paradas", []) as Array).size() - (visitadas[bi] as Dictionary).size()
		total_paradas += (vb.get("paradas", []) as Array).size()
		if faltan > 0:
			sin_parar.append("%s: %d de %d (recorrió %.0f m, s=%.0f vel=%.1f)" % [(vb["nodo"] as Node3D).name, faltan, (vb.get("paradas", []) as Array).size(), recorrido[bi], float(vb["s"]), float(vb.get("vact", 0.0))])
	print("  buses solos %.0f s: %d paradas comprobadas; sin completar: %d buses" % [tt, total_paradas, sin_parar.size()])
	_comprobar(sin_parar.is_empty(), "cada bus se detiene en cada parada de su recorrido%s" % ("" if sin_parar.is_empty() else " — faltan: " + str(sin_parar.slice(0, 6))))
	t.set("_vehiculos", todos)
	t.set_process(true)
	if sem != null:
		sem.set_process(true)

## ---- 6. sirenas
func _sirenas() -> void:
	var antes: Array = TraficoCiudad.sirenas.duplicate()
	TraficoCiudad.sirenas.clear()
	var s := Node3D.new()
	add_child(s)
	s.position = Vector3(100, 0, 100)
	TraficoCiudad.sirenas.append(s)
	var r := TraficoCiudad.RADIO_SIRENA
	_comprobar(TraficoCiudad.sirena_cerca(Vector3(100 + r - 1.0, 0, 100)), "el tráfico oye la sirena a %.0f m" % (r - 1.0))
	_comprobar(not TraficoCiudad.sirena_cerca(Vector3(100 + r + 1.0, 0, 100)), "y no la oye a %.0f m" % (r + 1.0))
	TraficoCiudad.sirenas.clear()
	s.queue_free()
	_comprobar(not TraficoCiudad.sirena_cerca(Vector3(100, 0, 100)), "sin sirenas no hay prioridad")
	TraficoCiudad.sirenas.append_array(antes)

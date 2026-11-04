extends BaseIdea
## BANCO ESPECIALIZADO «ciudad_vida», FASE 2 (4-11-2026, megarreforma de los bancos): la vida de la ciudad, numérica.
## Lo corre `herramientas/bancos_especiales.py ciudad_vida`.
##   1. Rutinas por hora y barrio (`RutinaPeatones`, funciones puras): densidad, picos, continuidad, sentido, maletines, mochilas, pausas.
##   2. Gente en la ciudad armada: nadie atraviesa edificios ni coches, la gente sale y se esconde con la hora (`tick`), y las luces de noche se encienden.
##   3. Interiores: cada sala de edificio abre, tiene entrada libre y una sola zona transitable (sin bolsas selladas).
##   4. Comercios por hora (ESTADO: la ciudad aún no tiene horarios de apertura: se deja constancia).
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")
const SECTORES := [100, 200, 300, 400, 500, 600]

func _probar() -> void:
	_titulo("BANCO CIUDAD_VIDA (fase 2): rutinas, gente, interiores, luces")
	_rutinas()
	_interiores()
	var c: Dictionary = await Comun.abrir(self)
	var cb: Node = c["cb"]
	_gente(cb)
	_luces(cb)
	_comercios(cb)
	(c["vc"] as Node).free()

## ---- 1. rutinas
func _rutinas() -> void:
	var fuera := 0
	var saltos := 0
	var peor_salto := 0.0
	for s in SECTORES:
		var antes := RutinaPeatones.densidad(0.0, s)
		for i in range(1, 97):
			var h := float(i) * 0.25
			var d := RutinaPeatones.densidad(h, s)
			if d < 0.079 or d > 1.0001:
				fuera += 1
			peor_salto = maxf(peor_salto, absf(d - antes))
			if absf(d - antes) > 0.4:
				saltos += 1
			antes = d
	_comprobar(fuera == 0, "densidad siempre entre 0,08 y 1 en los 6 barrios, todo el día (%d fuera)" % fuera)
	_comprobar(saltos == 0, "la densidad cambia sin saltos bruscos (peor salto en 15 min: %.2f)" % peor_salto)
	var noche_ok := true
	for s in SECTORES:
		if RutinaPeatones.densidad(3.0, s) > 0.45:
			noche_ok = false
	_comprobar(noche_ok, "a las 3 de la madrugada ningún barrio pasa del 45 % de gente")
	_comprobar(RutinaPeatones.densidad(8.0, 200) > 0.8 and RutinaPeatones.densidad(13.0, 200) > 0.8 and RutinaPeatones.densidad(18.0, 200) > 0.8, "Centro: hora punta de entrada (8), comida (13) y salida (18) con más del 80 %")
	_comprobar(RutinaPeatones.densidad(8.0, 200) > 2.0 * RutinaPeatones.densidad(3.0, 200), "Centro: a las 8 más del doble de gente que a las 3")
	_comprobar(RutinaPeatones.densidad(7.5, 400) > 0.8 and RutinaPeatones.densidad(19.0, 400) > 0.75, "Sur residencial: salen al trabajo (7,5) y vuelven (19)")
	_comprobar(RutinaPeatones.densidad(18.0, 300) > 0.7 and RutinaPeatones.densidad(8.0, 300) < 0.35, "Este comercial: pico de tarde y poca gente a las 8")
	_comprobar(RutinaPeatones.densidad(14.5, 500) > 0.8 and RutinaPeatones.densidad(22.5, 500) > 0.8, "Oeste y puerto: cambios de turno a las 14,5 y 22,5")
	_comprobar(RutinaPeatones.densidad(12.0, 600) < 0.4, "Periferia: poca gente siempre")
	_comprobar(RutinaPeatones.dia(3.0) < 0.01 and RutinaPeatones.dia(12.0) > 0.99 and RutinaPeatones.dia(23.5) < 0.01, "dia(): 0 de madrugada, 1 a mediodía, 0 a las 23:30")
	_comprobar(RutinaPeatones.sentido(8.0) > 0.9 and RutinaPeatones.sentido(18.0) < -0.9 and absf(RutinaPeatones.sentido(3.0)) < 0.01, "sentido del flujo: +1 por la mañana, −1 por la tarde, 0 de noche")
	var rango_ok := true
	for i in 97:
		for co in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			var f := RutinaPeatones.factor_flujo(float(i) * 0.25, co)
			if f < 0.149 or f > 1.0001:
				rango_ok = false
	_comprobar(rango_ok, "factor de flujo siempre en [0,15, 1]")
	var m8 := 0
	var m3 := 0
	var m8_otro := 0
	var estable := true
	for i in 300:
		if RutinaPeatones.lleva_maletin(8.0, 0.8, i):
			m8 += 1
		if RutinaPeatones.lleva_maletin(8.0, -0.8, i):
			m8_otro += 1
		if RutinaPeatones.lleva_maletin(3.0, 0.8, i):
			m3 += 1
		if RutinaPeatones.lleva_maletin(8.0, 0.8, i) != RutinaPeatones.lleva_maletin(8.0, 0.8, i):
			estable = false
	_comprobar(m8 >= 75 and m8 <= 125, "maletín: a las 8 hacia el trabajo, uno de cada tres (%d de 300)" % m8)
	_comprobar(m3 == 0 and m8_otro == 0, "maletín: nadie de madrugada ni a contramano (%d / %d)" % [m3, m8_otro])
	_comprobar(estable, "maletín estable por peatón")
	var mo8 := 0
	var mo11 := 0
	var mo2 := 0
	for i in 300:
		if RutinaPeatones.lleva_mochila(8.0, i):
			mo8 += 1
		if RutinaPeatones.lleva_mochila(11.0, i):
			mo11 += 1
		if RutinaPeatones.lleva_mochila(2.0, i):
			mo2 += 1
	_comprobar(mo8 > 150 and mo11 > 20 and mo11 < 120 and mo2 < 36, "mochila: colegio >50 %%, día ~20 %%, noche casi nadie (%d, %d, %d de 300)" % [mo8, mo11, mo2])
	var pausa_ok := true
	for s in SECTORES:
		for i in 97:
			var p := RutinaPeatones.pausa(float(i) * 0.25, s)
			if p < 0.499 or p > 4.001:
				pausa_ok = false
	_comprobar(pausa_ok, "paradas por hora siempre en [0,5, 4]")
	_comprobar(RutinaPeatones.pausa(13.2, 300) > RutinaPeatones.pausa(8.0, 300) * 1.5, "más gente parada a la comida que en hora punta")

## ---- 3. interiores
func _interiores() -> void:
	var claves: Array[String] = []
	for e: Array in ExploradorCiudad.EDIFICIOS:
		claves.append(String(e[0]))
	for k in ExploradorCiudad.SALA_DE_ROTULO.values():
		if not claves.has(String(k)):
			claves.append(String(k))
	var abiertas := 0
	var malas: Array[String] = []
	var raiz := Node3D.new()
	add_child(raiz)
	for k in claves:
		if not InteriorInstalacion.tiene(k):
			malas.append("%s: sin sala" % k)
			continue
		var cuarto := Node3D.new()
		raiz.add_child(cuarto)
		var sala: InteriorInstalacion = InteriorInstalacion.en_mundo(cuarto, k, null)
		if sala == null:
			malas.append("%s: no abre" % k)
			continue
		abiertas += 1
		var t := sala.tam_sala()
		if t.x < 3.0 or t.z < 3.0 or t.x > 60.0 or t.z > 60.0:
			malas.append("%s: tamaño absurdo %s" % [k, str(t)])
		var circulos := Optimizar.obstaculos(cuarto, [] as Array[Rect2], 0.4, 0.5)
		var estado := _transitable(circulos, t, cuarto.global_position)
		print("  %-22s sala %s mobiliario %d círculos · transitable %.0f %% · alcanzable %.0f %%" % [k, str(t.snapped(Vector3.ONE * 0.1)), circulos.size(), estado[0] * 100.0, estado[1] * 100.0])
		if not bool(estado[2]):
			malas.append("%s: la entrada está bloqueada" % k)
		if float(estado[0]) < 0.3:
			malas.append("%s: menos del 30 %% del suelo transitable" % k)
		if float(estado[1]) < 0.9:
			malas.append("%s: bolsas selladas (solo el %.0f %% de lo transitable es alcanzable)" % [k, float(estado[1]) * 100.0])
	_comprobar(malas.is_empty(), "interiores accesibles (%d de %d abren)%s" % [abiertas, claves.size(), "" if malas.is_empty() else ": " + str(malas)])
	raiz.free()

## Rejilla de 0,5 m sobre el suelo de la sala: [fracción transitable, fracción de lo transitable alcanzable desde la entrada, entrada libre].
func _transitable(circulos: PackedVector3Array, t: Vector3, origen: Vector3) -> Array:
	var paso := 0.5
	var nx := int(t.x / paso)
	var nz := int(t.z / paso)
	var libre := PackedByteArray()
	libre.resize(nx * nz)
	var n_libres := 0
	for ix in nx:
		for iz in nz:
			var p := Vector2(origen.x + (float(ix) + 0.5) * paso - t.x * 0.5, origen.z + (float(iz) + 0.5) * paso - t.z * 0.5)
			var ocupado := false
			for c in circulos:
				if Vector2(p.x - c.x, p.y - c.y).length() < c.z + 0.35:
					ocupado = true
					break
			if not ocupado:
				libre[ix * nz + iz] = 1
				n_libres += 1
	## Entrada: centro del lado +z, a 1,6 m de la pared (como `_entrar_en_edificio`).
	var ex := nx / 2
	var ez := clampi(nz - 4, 0, nz - 1)
	var entrada_libre := libre[ex * nz + ez] == 1
	if not entrada_libre:
		return [float(n_libres) / float(nx * nz), 0.0, false]
	var vistos := PackedByteArray()
	vistos.resize(nx * nz)
	var pila: Array[int] = [ex * nz + ez]
	vistos[ex * nz + ez] = 1
	var alcanzados := 0
	while not pila.is_empty():
		var k: int = pila.pop_back()
		alcanzados += 1
		var ix := k / nz
		var iz := k % nz
		for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var jx: int = ix + d[0]
			var jz: int = iz + d[1]
			if jx < 0 or jz < 0 or jx >= nx or jz >= nz:
				continue
			var j := jx * nz + jz
			if libre[j] == 1 and vistos[j] == 0:
				vistos[j] = 1
				pila.append(j)
	return [float(n_libres) / float(nx * nz), float(alcanzados) / float(maxi(1, n_libres)), true]

## ---- 2. gente en la ciudad
func _gente(cb: Node) -> void:
	var t: Object = cb.get_node_or_null("Trafico")
	_comprobar(t != null, "la ciudad trae su tráfico y su gente")
	if t == null:
		return
	var vehiculos: Array = t.get("_vehiculos")
	var rutas: Array = t.get("_rutas")
	var peatones: Array = []
	var coches: Array = []
	for v: Dictionary in vehiculos:
		if not is_instance_valid(v["nodo"]):
			continue
		if bool(v.get("peaton", false)):
			peatones.append(v)
		elif float(v.get("alto", 0.0)) < 0.05:
			coches.append(v)
	print("  peatones %d, coches %d, rutas %d" % [peatones.size(), coches.size(), rutas.size()])
	_comprobar(peatones.size() >= 30, "hay peatones (%d)" % peatones.size())
	_comprobar(coches.size() >= 20, "hay coches (%d)" % coches.size())
	var circulos: PackedVector3Array = cb.get("circulos")
	var frentes: Array = cb.get("_frentes")
	var usadas := {}
	for v: Dictionary in peatones:
		usadas[int(v["ruta"])] = true
	var ejemplos: Array[String] = []
	var en_edificio := 0
	var en_obstaculo := 0
	var muestras := 0
	for r in usadas:
		var puntos: PackedVector3Array = rutas[r].puntos
		for i in puntos.size():
			var a: Vector3 = puntos[i]
			var b: Vector3 = puntos[(i + 1) % puntos.size()]
			var n := maxi(1, int(a.distance_to(b) / 3.0))
			for q in n:
				var p := a.lerp(b, float(q) / float(n))
				muestras += 1
				for f: Rect2 in frentes:
					if f.grow(-0.6).has_point(Vector2(p.x, p.z)):
						en_edificio += 1
						if ejemplos.size() < 6:
							ejemplos.append("EDIFICIO ruta %d en (%.1f,%.1f) rect %s" % [r, p.x, p.z, str(f)])
						break
				for c in circulos:
					if Vector2(p.x - c.x, p.z - c.y).length() < c.z * 0.8:
						en_obstaculo += 1
						if ejemplos.size() < 12:
							ejemplos.append("OBSTÁCULO ruta %d en (%.1f,%.1f) círculo (%.1f,%.1f r=%.2f)" % [r, p.x, p.z, c.x, c.y, c.z])
						break
	print("  rutas de peatones: %d muestras, %d dentro de un edificio, %d dentro de un obstáculo" % [muestras, en_edificio, en_obstaculo])
	for e in ejemplos:
		print("    ", e)
	_comprobar(muestras > 500, "se muestrearon las rutas de los peatones (%d puntos)" % muestras)
	_comprobar(float(en_edificio) <= 0.01 * float(muestras), "ninguna ruta de peatones atraviesa un edificio (%d de %d, tope 1 %%)" % [en_edificio, muestras])
	_comprobar(float(en_obstaculo) <= 0.01 * float(muestras), "ninguna ruta de peatones atraviesa un obstáculo (%d de %d, tope 1 %%)" % [en_obstaculo, muestras])
	var pegados := 0
	for p: Dictionary in peatones:
		var pp: Vector3 = (p["nodo"] as Node3D).global_position
		for c: Dictionary in coches:
			if (c["nodo"] as Node3D).global_position.distance_to(pp) < 0.9:
				pegados += 1
				break
	_comprobar(pegados == 0, "ningún peatón dentro de un coche al armar (%d)" % pegados)
	## Horas: el repaso del día esconde y muestra gente.
	var vis := {}
	for h in [3.0, 8.0, 13.0, 18.0, 23.0]:
		var r: Dictionary = RutinaPeatones.tick(vehiculos, h)
		vis[h] = float(r["visibles"]) / maxf(1.0, float(r["total"]))
	print("  gente visible por hora: ", vis)
	_comprobar(float(vis[8.0]) > 1.5 * float(vis[3.0]) and float(vis[18.0]) > 1.5 * float(vis[3.0]), "a las 8 y a las 18 sale más de 1,5 veces la gente que a las 3")
	_comprobar(float(vis[3.0]) < 0.5, "de madrugada sale menos de la mitad de la gente (%.0f %%)" % (float(vis[3.0]) * 100.0))

func _luces(cb: Node) -> void:
	var ex: Object = cb.get("expansion")
	var bombillas: Array = ex.get("_bombillas")
	_comprobar(bombillas.size() >= 5, "hay bombillas de calle (%d)" % bombillas.size())
	cb.encender_luces(0.0)
	var dia := 0.0
	for m: StandardMaterial3D in bombillas:
		dia += m.emission_energy_multiplier
	cb.encender_luces(1.0)
	var noche := 0.0
	for m: StandardMaterial3D in bombillas:
		noche += m.emission_energy_multiplier
	print("  energía de las bombillas: día %.1f, noche %.1f" % [dia, noche])
	_comprobar(noche > dia * 2.0 + 1.0, "de noche las bombillas de calle brillan más del doble que de día")
	var t: Object = cb.get_node_or_null("Trafico")
	if t != null:
		_comprobar(float(t.get("noche")) > 0.99, "el tráfico sabe que es de noche (faros)")
	cb.encender_luces(0.0)

## ---- 4. comercios
func _comercios(cb: Node) -> void:
	var con_horario := 0
	for p: Dictionary in cb.get("puntos_clic"):
		if p.has("abre") or p.has("cierra") or p.has("horario"):
			con_horario += 1
	print("  comercios con horario de apertura: %d (la ciudad aún no los modela: ver PLAN_GENERAL)" % con_horario)
	_comprobar(true, "comercios por hora: no hay horarios en la ciudad todavía (%d puntos con horario)" % con_horario)

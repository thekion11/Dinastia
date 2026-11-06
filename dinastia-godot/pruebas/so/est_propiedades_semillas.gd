extends BaseSO
## ESTÁNDAR · PRUEBA DE PROPIEDADES con semillas ALEATORIAS: 50 mundos distintos (cambian en cada ejecución), y en cada uno se cumplen los invariantes de la
## simulación: ids únicos, plantillas de tamaño sano, calendario de ida y vuelta, tabla cuadrada (goles a favor = en contra, puntos = 3·victorias + empates),
## marcadores enteros y no negativos, determinismo (misma semilla → mismo partido) y cajas finitas tras 8 semanas.
## Si falla, imprime «SEMILLA QUE FALLA: n» y se repite con `SEMILLA_BASE=<n> SEMILLAS_N=1`. `SEMILLAS_N` cambia cuántas (50 por defecto).
func _nombre() -> String:
	return "est_propiedades_semillas"

func _primer_partido(semilla: int) -> Dictionary:
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, semilla)
	var l: Liga = m.ligas[0]
	return Partido.new(l.clubes[0], l.clubes[1]).simular()

func _revisar(semilla: int) -> Array[String]:
	var mal: Array[String] = []
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ids := {}
	var jids := {}
	for c: Club in m.clubes.values():
		if ids.has(c.id): mal.append("club repetido %s" % c.id)
		ids[c.id] = true
		if c.plantilla.size() < 16 or c.plantilla.size() > 40: mal.append("%s con %d jugadores" % [c.nombre, c.plantilla.size()])
		for j: Jugador in c.plantilla:
			if jids.has(j.id): mal.append("jugador repetido %s" % j.id)
			jids[j.id] = true
			if j.ovr < 1 or j.ovr > 99 or j.edad < 15 or j.edad > 45: mal.append("%s fuera de rango (media %d, edad %d)" % [j.nombre, j.ovr, j.edad])
	var l: Liga = m.ligas[0]
	var n := l.clubes.size()
	if n >= 4 and n % 2 == 0:
		var vistos_por_jornada_ok := true
		for jornada: Array in l.calendario:
			var v := {}
			for par: Array in jornada:
				v[(par[0] as Club).id] = true
				v[(par[1] as Club).id] = true
			vistos_por_jornada_ok = vistos_por_jornada_ok and v.size() == n
		if not vistos_por_jornada_ok: mal.append("en alguna jornada no juegan todos")
		if l.jornadas() != 2 * (n - 1): mal.append("%d jornadas para %d clubes" % [l.jornadas(), n])
		var gf := 0
		var gc := 0
		var pts := 0
		var emp := 0
		var vic := 0
		for f: Dictionary in l.jugar_temporada():
			gf += int(f["gf"]); gc += int(f["gc"]); pts += int(f["pts"]) + int(f["sancion"]); emp += int(f["e"]); vic += int(f["g"])
		if gf != gc: mal.append("goles a favor %d ≠ en contra %d" % [gf, gc])
		if pts != l.puntos_victoria * vic + emp: mal.append("puntos %d ≠ %d·%d + %d" % [pts, l.puntos_victoria, vic, emp])
	## Determinismo: dos mundos recién generados con la misma semilla juegan el mismo primer partido (un partido ya jugado cambia el estado: forma, lesiones).
	var r1 := _primer_partido(semilla)
	var r2 := _primer_partido(semilla)
	if r1["local"] != r2["local"] or r1["visita"] != r2["visita"]: mal.append("la misma semilla da dos mundos que juegan distinto: %s contra %s" % [str(r1), str(r2)])
	if int(r1["local"]) < 0 or int(r1["visita"]) < 0 or int(r1["local"]) + int(r1["visita"]) > 15: mal.append("marcador raro %s" % str(r1))
	for i in 8:
		m.avanzar_semana()
	for c: Club in m.clubes.values():
		if absi(c.saldo) > 1 << 50: mal.append("caja absurda en %s" % c.nombre)
	return mal

func _probar() -> void:
	_titulo("ESTÁNDAR · propiedades con semillas aleatorias [%s]" % sistema())
	var base := int(OS.get_environment("SEMILLA_BASE")) if OS.get_environment("SEMILLA_BASE") != "" else int(Time.get_unix_time_from_system()) % 1000000007
	var cuantas := int(OS.get_environment("SEMILLAS_N")) if OS.get_environment("SEMILLAS_N") != "" else 50
	print("  SEMILLA_BASE=%d  (repetir: SEMILLA_BASE=%d SEMILLAS_N=%d)" % [base, base, cuantas])
	var malas := 0
	for i in cuantas:
		var semilla := base + i * 7919
		var fallos := _revisar(semilla)
		if not fallos.is_empty():
			malas += 1
			print("  SEMILLA QUE FALLA: %d → %s" % [semilla, str(fallos.slice(0, 3))])
		if i % 10 == 9:
			await get_tree().process_frame
	_comprobar(malas == 0, "los invariantes se cumplen en las %d semillas (%d con fallo)" % [cuantas, malas])

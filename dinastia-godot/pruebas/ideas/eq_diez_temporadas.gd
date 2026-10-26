extends BaseIdea
## BALANCE DEL MUNDO A LARGO PLAZO (paquete eq, 26-10-2026; plan §10 «balance de dificultad» y §8).
## Diez temporadas × tres semillas, al mando del club más GRANDE y del más CHICO de la Primera chilena, sin que
## el humano toque nada (como `eco_medicion` y `cant_estabilidad`). Cada temporada se saca una foto del mundo y
## se compara con rangos «sanos» FIJOS, puestos con criterio de fútbol real:
##   · edad media del mundo 25,5-28,0: las ligas profesionales viven en 26-27,5 (la de Chile, ~26,5).
##   · media OVR: a ±2,0 de la inicial. Sin una tendencia real que la empuje, el nivel del mundo no deriva.
##   · valor medio del mercado de la IA (sin tu club, que sin gestionar se llena de canteranos): ×0,75-×1,50
##     respecto a t0, y en la larga (EQ_MODO=rendimiento) el año 20 a ±15 % del 10: sin inflación propia, lo
##     que no puede haber es una subida sin fin. Medido el 26-10: con el valor viejo (sin retasar al cumplir
##     años) ×1,56 y subiendo; retasado, ×1,36-×1,45 en t10 y plano después (t20 ×1,28). Lo que queda es el
##     asentamiento del mundo generado (2 jugadores 75+ en la IA) al que sostiene la simulación (~25, casi
##     todos de la cantera de los dos o tres grandes de la IA), no una burbuja de precios.
##   · % en último año de contrato: 12-38 %. Con contratos de 3-4 años, ~25-30 % de una liga está en su último.
##   · nómina del club humano sin fichar: ×0,55-×1,60 de la inicial A IGUAL TAMAÑO de club (se divide por
##     `Eco.factor_club(rep)`: el grande que gana todo pasa de rep 88 a 96 y la reposición automática trae
##     repuestos de su nuevo nivel; eso no es la nómina «duplicada sin fichar» de §8). Y en Primera, sueldos
##     ≤ 75 % de los ingresos previstos (la alarma de la UEFA está en el 70 %).
##   · caja del grande: no crece más de 3/4 de su referencia por temporada (M-208). Del chico: en las
##     temporadas que juega en Primera no pierde más de una referencia por año. En Segunda sin gestionar SÍ
##     se hundía (sueldos 140-175 % de los ingresos, −1,2 M/año). Con la CLÁUSULA DE DESCENSO (26-10, dueño:
##     sueldos −30-50 % mientras siga abajo) queda en 95-115 %: en Segunda se exige ≤ 125 %. La nómina «a igual
##     rep» se mide sin la cláusula (sueldo pleno): la rebaja es temporal y no es una nómina que se desplome.
##   · clubes de la IA en rojo ≤ 15 % e intervenidos ≤ 2: el mundo no se arruina solo.
##   · 85+ con menos de 22 años: ≤ máx(2, t0 + 1). En el fútbol real se cuentan con los dedos.
##   · goles por partido de liga 2,1-3,2 (las primeras de Sudamérica y Europa andan en 2,4-2,9).
## Además mide los ms de `avanzar_semana` (media de una temporada) en las temporadas 1, 10 y 20 (plan §10,
## rendimiento de la simulación): EQ_MODO=rendimiento. Medido el 26-10 (máquina compartida, sin GPU, solo
## Chile: 32 clubes, ~780 jugadores): 131 ms/semana el año 1, 82 el 10, 92 el 20; cierre de temporada 45-110 ms.
## Tarda (~3 s por temporada simulada: ~3,5 min la de balance, ~1,5 la de rendimiento): es una ESPECIAL
## (`herramientas/especiales.sh todo`), no del banco. EQ_TEMP / EQ_SEMILLAS para cambiarla.

const EDAD := Vector2(25.5, 28.0)
const OVR_DELTA := 2.0
const VALOR := Vector2(0.75, 1.50)
const ULTIMO := Vector2(12.0, 38.0)
const NOMINA := Vector2(0.55, 1.60)
const SUELDOS_MAX := 75
const SUELDOS_MAX_SEGUNDA := 125
## En Segunda los de más caché pueden pedir salir por la cláusula y se venden: la nómina plena baja más.
const NOMINA_MIN_SEGUNDA := 0.45
const ROJO_MAX := 0.15
const INTERV_MAX := 2
const GOLES := Vector2(2.1, 3.2)

func _probar() -> void:
	if OS.get_environment("TV_IGUAL") != "":   ## medir el reparto solidario de la tele sin activarlo
		Finanzas.reparto_tv_igual = float(OS.get_environment("TV_IGUAL"))
	if OS.get_environment("EQ_MODO") == "rendimiento":
		_rendimiento()
		return
	var temporadas := int(OS.get_environment("EQ_TEMP")) if OS.get_environment("EQ_TEMP") != "" else 10
	var semillas: Array = [101, 202, 303]
	if OS.get_environment("EQ_SEMILLAS") != "":
		semillas = Array(OS.get_environment("EQ_SEMILLAS").split(",")).map(func(x: String) -> int: return int(x))
	_titulo("BALANCE: %d temporadas x %d semillas x (grande, chico)" % [temporadas, semillas.size()])
	for s in semillas:
		for grande: bool in [true, false]:
			_una(int(s), temporadas, grande)

func _mundo_con(semilla: int, grande: bool) -> Mundo:
	var m := Mundo.new()
	m.generar(["CHI"], semilla)
	var primera: Array = m.ligas[0].clubes.duplicate()
	primera.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	m.tomar_el_mando((primera[0] if grande else primera[primera.size() - 1]).id)
	return m

func _una(semilla: int, temporadas: int, grande: bool) -> void:
	var m := _mundo_con(semilla, grande)
	var yo: Club = m.clubes[m.mi_club_id]
	var et := "s%d %s" % [semilla, "GRANDE" if grande else "CHICO"]
	_linea("")
	_linea("--- %s (%s, rep %d) ---" % [et, yo.nombre, yo.rep])
	var f0 := _foto(m, 0.0)
	_linea("  t0  " + _texto(f0))
	var caja0 := yo.saldo
	var fallos: Array[String] = []
	var f := f0
	var perdida_primera := 0.0
	var en_primera := 0
	for t in temporadas:
		var caja_antes := yo.saldo
		var div_antes := yo.division
		m.jugar_temporada()
		f = _foto(m, _goles_por_partido(m))
		m.nueva_temporada()
		## La foto de plantillas y contratos, tras el cierre (renovaciones, retiros, cantera).
		var g: float = f["gpp"]
		f = _foto(m, g)
		_linea("  t%-2d " % (t + 1) + _texto(f))
		_revisar(f, f0, t + 1, fallos)
		if div_antes == 1:
			en_primera += 1
			perdida_primera += float(yo.saldo - caja_antes) / Eco.ref_caja(yo.rep)
	## Caja: tendencia en todo el tramo (la de un año suelto es ruido de premios y ascensos).
	var ref := Eco.ref_caja(yo.rep)
	if grande:
		var crece := float(yo.saldo - caja0) / float(temporadas)
		_comprobar(crece < ref * 0.75, "%s: la caja del grande no se dispara sola (%.2f M/temporada; ref %.2f M)" % [et, crece / 1e6, ref / 1e6])
	else:
		var media := perdida_primera / maxf(1.0, float(en_primera))
		_comprobar(media > -1.0, "%s: en Primera la caja del chico no se hunde sola (%+.2f referencias/temporada en %d temporadas; caja final %.2f M, ref %.2f M)" % [et, media, en_primera, yo.saldo / 1e6, ref / 1e6])
	_comprobar(fallos.is_empty(), "%s: %d temporadas dentro de los rangos sanos%s" % [et, temporadas, "" if fallos.is_empty() else " · fuera: " + ", ".join(fallos)])

func _revisar(f: Dictionary, f0: Dictionary, t: int, fallos: Array[String]) -> void:
	var v: float = f["valor_ia"] / maxf(1.0, f0["valor_ia"])
	var nom: float = float(f["nomina"]) / maxf(1.0, float(f0["nomina"])) / (Eco.factor_club(f["rep"]) / Eco.factor_club(f0["rep"]))
	var pruebas := {
		"edad %.1f" % f["edad"]: f["edad"] >= EDAD.x and f["edad"] <= EDAD.y,
		"ovr %.1f" % f["ovr"]: absf(f["ovr"] - f0["ovr"]) <= OVR_DELTA,
		"valor IA x%.2f" % v: v >= VALOR.x and v <= VALOR.y,
		"último año %d%%" % f["ultimo"]: f["ultimo"] >= ULTIMO.x and f["ultimo"] <= ULTIMO.y,
		"nómina x%.2f a igual rep" % nom: nom >= (NOMINA_MIN_SEGUNDA if int(f["div"]) != 1 else NOMINA.x) and nom <= NOMINA.y,
		"sueldos %d%% de los ingresos en Primera" % f["pct_sal"]: int(f["div"]) != 1 or int(f["pct_sal"]) <= SUELDOS_MAX,
		"sueldos %d%% de los ingresos en Segunda" % f["pct_sal"]: int(f["div"]) == 1 or int(f["pct_sal"]) <= SUELDOS_MAX_SEGUNDA,
		"IA en rojo %d" % f["rojo"]: float(f["rojo"]) <= ROJO_MAX * float(f["clubes"]),
		"intervenidos %d" % f["interv"]: int(f["interv"]) <= INTERV_MAX,
		"85+ <22: %d" % f["precoces"]: int(f["precoces"]) <= maxi(2, int(f0["precoces"]) + 1),
		"goles %.2f" % f["gpp"]: f["gpp"] >= GOLES.x and f["gpp"] <= GOLES.y,
	}
	for k: String in pruebas:
		if not pruebas[k]:
			fallos.append("t%d %s" % [t, k])

## Goles por partido de las ligas en la temporada que acaba (antes de `nueva_temporada`, que borra la tabla).
func _goles_por_partido(m: Mundo) -> float:
	var gf := 0
	var pj := 0
	for l in m.ligas:
		for fila: Dictionary in l.tabla_puntos.values():
			gf += int(fila["gf"])
			pj += int(fila["pj"])
	return float(gf) / maxf(1.0, float(pj) / 2.0)

func _foto(m: Mundo, gpp: float) -> Dictionary:
	var n := 0
	var ovr := 0.0
	var edad := 0.0
	var ultimo := 0
	var precoces := 0
	var val_ia := 0.0
	var n_ia := 0
	for j: Jugador in m.jugadores():
		n += 1
		ovr += j.ovr
		edad += j.edad
		if j.anios_contrato <= 1:
			ultimo += 1
		if j.edad < 22 and j.ovr >= 85:
			precoces += 1
		if j.club_id != m.mi_club_id:
			val_ia += j.valor
			n_ia += 1
	var rojo := 0
	var interv := 0
	for c: Club in m.clubes.values():
		if c.id == m.mi_club_id:
			continue
		if c.saldo < 0:
			rojo += 1
		if m.insolvencia != null and m.insolvencia.intervenido(m, c):
			interv += 1
	var yo: Club = m.clubes[m.mi_club_id]
	var fin := Finanzas.new(yo, 0.0, 0, 0.0)
	fin.aplica_operacion = true
	var proy := fin.proyeccion_anual(15, m.ingreso_tienda(yo))
	var k := maxf(1.0, float(n))
	return {"n": n, "ovr": ovr / k, "edad": edad / k, "ultimo": int(100.0 * ultimo / k), "precoces": precoces,
		"valor_ia": val_ia / maxf(1.0, float(n_ia)), "rojo": rojo, "interv": interv, "clubes": m.clubes.size() - 1,
		"nomina": yo.plantilla.reduce(func(a: int, j: Jugador) -> int: return a + int(round(j.sueldo / j.factor_clausula())), 0), "caja": yo.saldo, "gpp": gpp,
		"div": yo.division, "rep": yo.rep, "plantel": yo.plantilla.size(), "pct_sal": int(proy["pct_salarial"]), "resultado": int(proy["resultado"]),
		"veedor": m.banco != null and m.banco.hay_veedor()}

func _texto(f: Dictionary) -> String:
	return "edad %.1f · ovr %.1f · valor IA %.0f · último año %d%% · nómina %d · caja %.2f M · rojo %d/%d · interv %d · 85+<22 %d · goles %.2f · div %d rep %d plantel %d · sueldos/ingresos %d%% · resultado previsto %.2f M%s" % [
		f["edad"], f["ovr"], f["valor_ia"], f["ultimo"], f["nomina"], f["caja"] / 1e6, f["rojo"], f["clubes"], f["interv"], f["precoces"], f["gpp"], f["div"], f["rep"], f["plantel"], f["pct_sal"], f["resultado"] / 1e6, " · VEEDOR" if f["veedor"] else ""]

## RENDIMIENTO: ms por `avanzar_semana` (media de la temporada) en las temporadas 1, 10 y 20. El tope es
## holgado (máquina compartida, sin GPU): lo que se vigila es que el año 20 no se dispare respecto al 1.
func _rendimiento() -> void:
	var hasta := int(OS.get_environment("EQ_TEMP")) if OS.get_environment("EQ_TEMP") != "" else 20
	_titulo("RENDIMIENTO: ms por avanzar_semana en %d temporadas (semilla 101, grande)" % hasta)
	var m := _mundo_con(101, true)
	var ms: Dictionary = {}
	var valores: Dictionary = {}
	for t in range(1, hasta + 1):
		var semanas := 0
		var t0 := Time.get_ticks_usec()
		while m.temporada_en_curso():
			m.avanzar_semana()
			semanas += 1
		var media := float(Time.get_ticks_usec() - t0) / 1000.0 / maxf(1.0, float(semanas))
		var t1 := Time.get_ticks_usec()
		m.nueva_temporada()
		var cierre := float(Time.get_ticks_usec() - t1) / 1000.0
		if t == 10 or t == hasta:
			valores[t] = float(_foto(m, 0.0)["valor_ia"])
		if t == 1 or t % 5 == 0:
			var f := _foto(m, 0.0)
			_linea("  temporada %2d: %6.1f ms/semana (%d semanas) · cierre %6.0f ms · jugadores %d · valor IA %.0f · edad %.1f · ovr %.1f" % [
				t, media, semanas, cierre, f["n"], f["valor_ia"], f["edad"], f["ovr"]])
		ms[t] = media
	var ultima: int = hasta
	var diez: int = mini(10, hasta)
	var v_diez: float = valores.get(diez, 0.0)
	var v_fin: float = valores.get(ultima, 0.0)
	_comprobar(v_diez > 0.0 and absf(v_fin / v_diez - 1.0) <= 0.15, "el valor medio de la IA se planta: año %d %.0f, año %d %.0f (x%.2f)" % [diez, v_diez, ultima, v_fin, v_fin / maxf(1.0, v_diez)])
	_comprobar(float(ms[ultima]) < float(ms[1]) * 2.0 + 20.0, "la semana del año %d no se dispara (%.1f ms frente a %.1f ms el año 1)" % [ultima, ms[ultima], ms[1]])

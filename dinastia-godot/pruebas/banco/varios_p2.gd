extends "res://pruebas/banco/varios_p2_h.gd"
## [Capa 2/10 de `varios.gd`] _probar_pie_habil, _probar_banquillo, _probar_banco, _probar_necesidades_con_efecto, _probar_viajes

## EL PIE HÁBIL: "D.d==='LAT'&&D.b&&j.pie&&D.b!==j.pie" del HTML. `Jugador.
## pie()` YA EXISTÍA -de un hash de su id, no guardado, misma proporción
## 76/24 del HTML- pero solo lo leía `aptitud_en()`, usado en un único sitio
## de la interfaz; nunca llegaba a la fuerza real del partido. Se prueba con
## dos jugadores IDÉNTICOS salvo el id -que es de donde sale el pie-, puestos
## de laterales derechos: el zurdo tiene que rendir un 6% menos, ni un
## central ni un delantero pierden nada por jugar del pie contrario.
func _probar_pie_habil() -> void:
	_titulo("EL PIE HÁBIL: LOS LATERALES SÍ LO NOTAN")
	var m := Mundo.new()
	m.generar(["CHI"], 5150)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var p := Partido.new(a, b)

	## `pie()` sale del id, así que para comparar un diestro con un zurdo hay
	## que buscar dos ids -no importa cuáles- cuyo hash caiga a cada lado.
	var id_d := ""
	var id_i := ""
	for i in 200:
		var candidato := "prueba_pie_%d" % i
		var j0 := Jugador.new()
		j0.id = candidato
		if j0.pie() == "D" and id_d == "":
			id_d = candidato
		elif j0.pie() == "I" and id_i == "":
			id_i = candidato
		if id_d != "" and id_i != "":
			break
	_comprobar(id_d != "" and id_i != "", "se encuentran ids de sobra para un diestro y un zurdo")

	var diestro := Jugador.new()
	diestro.id = id_d; diestro.pos_e = "LD"; diestro.pos = "DEF"; diestro.ovr = 75
	diestro.forma = 60; diestro.fisico = 70; diestro.moral = 60
	var zurdo := Jugador.new()
	zurdo.id = id_i; zurdo.pos_e = "LD"; zurdo.pos = "DEF"; zurdo.ovr = 75
	zurdo.forma = 60; zurdo.fisico = 70; zurdo.moral = 60

	var media_diestro := p._media_linea([diestro], "DEF")
	var media_zurdo := p._media_linea([zurdo], "DEF")
	_linea("  LD con pie D: %.2f   ·   LD con pie I: %.2f" % [media_diestro, media_zurdo])
	_comprobar(media_zurdo < media_diestro,
		"un lateral del pie contrario a su banda rinde menos (%.2f < %.2f)" % [media_zurdo, media_diestro])
	_comprobar(absf(media_zurdo / media_diestro - 0.94) < 0.001,
		"la penalizacion es exactamente la del HTML, 0.94 (%.4f)" % (media_zurdo / media_diestro))

	## Un central zurdo, en cambio, no pierde nada: "es_lateral()" es falso
	## para DFC.
	var central_zurdo := Jugador.new()
	central_zurdo.id = id_i; central_zurdo.pos_e = "DFC"; central_zurdo.pos = "DEF"; central_zurdo.ovr = 75
	central_zurdo.forma = 60; central_zurdo.fisico = 70; central_zurdo.moral = 60
	var central_diestro := Jugador.new()
	central_diestro.id = id_d; central_diestro.pos_e = "DFC"; central_diestro.pos = "DEF"; central_diestro.ovr = 75
	central_diestro.forma = 60; central_diestro.fisico = 70; central_diestro.moral = 60
	var media_central_zurdo := p._media_linea([central_zurdo], "DEF")
	var media_central_diestro := p._media_linea([central_diestro], "DEF")
	_comprobar(absf(media_central_zurdo - media_central_diestro) < 0.001,
		"un central no pierde nada por ser zurdo (%.2f vs %.2f)" % [media_central_zurdo, media_central_diestro])

	## Y de nacimiento: casi 8 de cada 10 futbolistas del mundo son diestros
	## -se mide sobre el mundo generado de verdad, con los ids que de verdad
	## reparte `Mundo.crear_jugador()` ("j1","j2","j3"...), no sobre una
	## muestra sintética-.
	var m2 := Mundo.new()
	m2.generar(["CHI", "ARG", "BRA"], 6060)
	var diestros := 0
	var total := 0
	for c: Club in m2.clubes.values():
		for j: Jugador in c.plantilla:
			total += 1
			if j.pie() == "D":
				diestros += 1
	var pct := float(diestros) / float(maxi(total, 1))
	_linea("  %d futbolistas: %.0f%% diestros" % [total, pct * 100.0])
	_comprobar(pct > 0.68 and pct < 0.84, "la proporcion diestro/zurdo ronda el 76%% del HTML (%.0f%%)" % (pct * 100.0))


func _probar_banquillo() -> void:
	_titulo("BANQUILLO: ONCE, CAMBIOS Y PENALES")
	_bq_once()
	_bq_cambios()
	_bq_penales_dirigido()

## `vBanco()` del HTML: creditos, cuota francesa y el camino a la liquidacion.
## El motor (`nucleo/banco.gd`) y la pantalla ya estaban completos -ya gateaba
## el mercado de fichajes en mora, `_motivo_fichaje_bloqueado()` lo usa esta
## misma sesion-, pero no tenia ni una prueba funcional propia: solo un ida y
## vuelta de guardado que comprobaba la serializacion, no la matematica de la
## deuda ni la escalada a la liquidacion.
func _probar_banco() -> void:
	_titulo("EL BANCO: CUOTA FRANCESA, MORA Y LIQUIDACION")
	_bn_cuota_pedir_bono()
	_bn_prepagar_renegociar()
	_bn_semana_sobregiro()
	_bn_escalada()
	_bn_mora_estado()
	_bn_guardado()

## §2.5 DEL GUION (30-10): «comer y dormir; si fallan, aumentan las posibilidades de que las
## cosas salgan mal». Cansado y con hambre: más imprevistos y peor preparación del partido;
## con la rutina, todo igual que siempre (mismos bonificadores, mismo sorteo).
func _probar_necesidades_con_efecto() -> void:
	_titulo("NECESIDADES DEL DT CON EFECTO (§2.5)")
	var m := Mundo.new()
	m.generar(["CHI"], 3051)
	var c := m.mi_club() if m.mi_club() != null else m.ligas[0].clubes[0]
	m.tomar_el_mando(c.id)
	m.aplicar_bonificadores()
	var ata0 := c.bonus_ataque
	_comprobar(not m.necesidades.preparacion_cambio() and is_equal_approx(m.necesidades.factor_preparacion(), 1.0),
		"con la rutina la preparación no cambia (×1)")
	m.necesidades.pasar(20 * 60, "horas_extra")
	var prep := m.necesidades.factor_preparacion()
	_comprobar(prep < 1.0 and prep >= 0.96 and m.necesidades.preparacion_cambio(),
		"tras 20 h de horas extra sin comer la preparación baja (×%.3f, tope ×0,96)" % prep)
	m.aplicar_bonificadores()
	_comprobar(c.bonus_ataque < ata0 and not m.necesidades.preparacion_cambio(),
		"el partido lo nota: bonus de ataque %.3f → %.3f" % [ata0, c.bonus_ataque])
	## El imprevisto de la semana: misma semilla, más probable con el riesgo alto.
	var imp := Imprevistos.new()
	var con_rutina := 0
	var cansado := 0
	for s in 120:
		if not imp.semana(m, c, 2026, s, false, 1.0).is_empty():
			con_rutina += 1
		imp.recientes.clear()
		imp.activos.clear()
		if not imp.semana(m, c, 2026, s, false, m.necesidades.factor_riesgo()).is_empty():
			cansado += 1
		imp.recientes.clear()
		imp.activos.clear()
	_comprobar(cansado > con_rutina, "cansado y con hambre hay más imprevistos (%d contra %d en 120 semanas)" % [cansado, con_rutina])
	## En «ligera» no castiga.
	m.necesidades.poner_modo("ligera")
	_comprobar(is_equal_approx(m.necesidades.factor_preparacion(), 1.0) and is_equal_approx(m.necesidades.factor_riesgo(), 1.0), "con la vida ligera, sin castigo")

## LO QUE CUESTA JUGAR (26-10, pedido del dueño): el día de partido y el viaje salen de precios reales y de la
## distancia, no de un porcentaje. Se comprueba la lógica, no cifras sueltas.
func _probar_viajes() -> void:
	_titulo("VIAJES Y DÍA DE PARTIDO POR DISTANCIA Y COSTE DE VIDA")
	var scl := Viajes.distancia_km("CHI", "ESP")
	_comprobar(scl > 10000.0 and scl < 11500.0, "Santiago–Madrid ≈ 10.700 km (sale %d)" % int(scl))
	_comprobar(absf(Viajes.distancia_km("CHI", "ARG") - Viajes.distancia_km("ARG", "CHI")) < 0.01, "la distancia es simétrica")
	_comprobar(is_equal_approx(Viajes.distancia_km("ENG", "ENG"), 220.0), "dentro del mismo país: los km medios de su liga")
	_comprobar(Viajes.medio(300.0) == "bus" and Viajes.medio(2000.0) == "avion" and Viajes.medio(8000.0) == "charter",
		"autocar, avión y chárter según los km")
	var local := Viajes.viaje_interno("ENG", "ENG", 70)
	var lejos := Viajes.viaje_interno("CHI", "ESP", 70)
	_comprobar(lejos > local * 10, "cruzar el océano cuesta mucho más que un viaje local (%d vs %d)" % [lejos, local])
	_comprobar(Viajes.viaje_interno("CHI", "ARG", 85) > Viajes.viaje_interno("CHI", "ARG", 55), "un club grande viaja con más gente y mejor hotel")
	_comprobar(Viajes.viaje_interno("ESP", "ESP", 70) > Viajes.viaje_interno("BOL", "BOL", 70), "el mismo viaje es más caro en España que en Bolivia")
	var chico := Viajes.dia_de_partido_interno("CHI", 5000, 8000)
	var grande := Viajes.dia_de_partido_interno("CHI", 40000, 60000)
	_comprobar(grande > chico * 4, "abrir un estadio grande cuesta mucho más que uno chico (%d vs %d)" % [grande, chico])
	_comprobar(Viajes.dia_de_partido_interno("ENG", 20000, 25000) > Viajes.dia_de_partido_interno("BOL", 20000, 25000),
		"el día de partido es más caro donde la vida es más cara")
	var c := Club.new()
	c.pais = "CHI"
	c.rep = 70
	c.estadio_aforo = 20000
	var f := Finanzas.new(c, 0.0, 0, 0.0)
	var g := f.asistencia()
	var taq := int(round(float(g) * Finanzas.ingreso_por_espectador(c.precio_entrada)))
	var ratio := float(Viajes.dia_de_partido_interno(c.pais, g, c.estadio_aforo)) / float(maxi(taq, 1))
	_comprobar(ratio > 0.25 and ratio < 0.35, "el club medio chileno sigue pagando ~30 %% de su taquilla (%.0f %%)" % (ratio * 100.0))

## (17-11) Rasgos de los jugadores conocidos: piel, pelo, corte y barba por nombre (en la base pública, con la clave del guiño).
func _probar_rasgos_conocidos() -> void:
	_titulo("RASGOS DE LOS CONOCIDOS (RASGOS_JUG)")
	_comprobar(Datos.tiene("RASGOS_JUG"), "la tabla de rasgos existe")
	var t: Dictionary = Datos.tabla("RASGOS_JUG") if Datos.tiene("RASGOS_JUG") else {}
	_comprobar(t.size() >= 50, "trae los rasgos de los conocidos (%d)" % t.size())
	if not Datos.base_real:
		_comprobar(not t.has("Erling Haaland") and not t.has("Lionel Messi"), "la base pública no lleva nombres reales como clave")
	var m := Mundo.new()
	m.generar(["ENG", "ESP", "BRA"], 17)
	var con_rasgos := 0
	var mal := 0
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			var r: Variant = Cara.rasgos_conocido(j)
			if not (r is Dictionary):
				continue
			con_rasgos += 1
			var lk := Cara.look_de(j)
			if String(lk["piel"]) != String(r["piel"]) or int(lk["barba"]) != int(r["barba"]) or String(lk["pelo"]) != String(r["pelo"]) or String(lk["peloC"]) != String(r["peloC"]):
				mal += 1
	_comprobar(con_rasgos >= 10, "hay conocidos con rasgos en ENG, ESP y BRA (%d)" % con_rasgos)
	_comprobar(mal == 0, "su cara toma exactamente los rasgos de la tabla (%d distintos)" % mal)

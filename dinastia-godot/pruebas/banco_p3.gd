extends "res://pruebas/banco_p2.gd"
## [Capa 3/27 de `banco.gd`] _probar_partidos, _probar_previa, _probar_arbitros, _probar_pie_habil

func _probar_partidos() -> void:
	_titulo("PARTIDOS: LA CURVA DE GOLES")
	var m := Mundo.new()
	m.generar(["CHI"], 21)
	var l := m.ligas[0]
	var goles := 0
	var partidos := 0
	var locales := 0
	var visitas := 0
	var empates := 0
	for i in 400:
		var a: Club = l.clubes[Azar.ent(0, l.clubes.size() - 1)]
		var b: Club = l.clubes[Azar.ent(0, l.clubes.size() - 1)]
		if a == b:
			continue
		var p := Partido.new(a, b)
		var r := p.simular()
		goles += r["local"] + r["visita"]
		partidos += 1
		if r["local"] > r["visita"]: locales += 1
		elif r["local"] < r["visita"]: visitas += 1
		else: empates += 1
	var media := float(goles) / float(maxi(partidos, 1))
	_linea("  %d partidos, %.2f goles por partido" % [partidos, media])
	_linea("  local %d%%  empate %d%%  visita %d%%" % [
		locales * 100 / maxi(partidos, 1), empates * 100 / maxi(partidos, 1), visitas * 100 / maxi(partidos, 1)])
	## Un campeonato real anda entre 2 y 3,5 goles por partido. Fuera de ahi la
	## formula esta mal portada aunque no haya reventado nada.
	_comprobar(media > 1.5 and media < 4.5, "goles por partido dentro de lo creible (%.2f)" % media)
	_comprobar(locales > visitas, "el local gana mas que el visitante (%d vs %d)" % [locales, visitas])
	## Las senales tienen que dispararse: son la unica forma que tiene la
	## interfaz de enterarse de lo que pasa en el campo.
	var oidos := {"gol": 0, "tarjeta": 0, "fin": 0}
	var p2 := Partido.new(l.clubes[0], l.clubes[1])
	p2.gol.connect(func(_c: Club, _j: Jugador, _min: int, _a: Jugador) -> void: oidos["gol"] += 1)
	p2.tarjeta.connect(func(_j: Jugador, _r: bool, _min: int) -> void: oidos["tarjeta"] += 1)
	p2.terminado.connect(func(_a: int, _b: int) -> void: oidos["fin"] += 1)
	var r2 := p2.simular()
	_comprobar(oidos["gol"] == r2["local"] + r2["visita"], "la senal de gol se emite una vez por gol")
	_comprobar(oidos["fin"] == 1, "la senal de fin de partido se emite una vez")

	## "remate": la llegada que no fue gol. Hasta esta sesion `_atacar()` la
	## contaba (remates_local/visita) pero no avisaba a nadie del desenlace, asi
	## que la cronica del partido en vivo se quedaba muda entre gol y gol. Se
	## comprueba que cada remate cae en gol O en una de las tres señales -nunca
	## en las dos, nunca en ninguna- y que las proporciones caen donde caen los
	## mismos cortes r<0.55/r<0.62 del HTML.
	var tipos := {"gol": 0, "atajada": 0, "poste": 0, "fallo": 0, "gol_arbitral": 0}
	var remates_totales := 0
	for i in 40:
		var a3: Club = l.clubes[Azar.ent(0, l.clubes.size() - 1)]
		var b3: Club = l.clubes[Azar.ent(0, l.clubes.size() - 1)]
		if a3 == b3:
			continue
		var p3 := Partido.new(a3, b3)
		p3.gol.connect(func(_c: Club, _j: Jugador, _min: int, _a: Jugador) -> void: tipos["gol"] += 1)
		p3.remate.connect(func(_c: Club, _j: Jugador, tipo: String, _min: int) -> void: tipos[tipo] += 1)
		## EL ÁRBITRO "ESTRICTO" regala un penal llamando a `_anotar()` DIRECTO
		## -mismo camino que el HTML, que tambien lo suma aparte de `r<0.30`-,
		## asi que ese gol emite `gol` sin pasar nunca por `_atacar()`: no
		## suma a `remates_local/visita` ni dispara la señal `remate`. Sin
		## contarlo aparte, la cuenta de abajo se descuadra apenas un
		## "estricto" regala uno en la muestra -encontrado asi, no a proposito-.
		p3.decision_arbitral.connect(func(texto: String, _min: int) -> void:
			## Las dos frases del "estricto" -a favor ("¡GOL de penal!") y en
			## contra ("Penal cobrado en contra")- tienen que contar las dos:
			## las dos llaman a `_anotar()` igual. Sin mayusculas/minusculas
			## porque una empieza con "P" y la otra con "p".
			if texto.to_lower().contains("penal"):
				tipos["gol_arbitral"] += 1)
		p3.simular()
		remates_totales += p3.remates_local + p3.remates_visita
	var no_gol: int = int(tipos["atajada"]) + int(tipos["poste"]) + int(tipos["fallo"])
	var goles_de_remate: int = int(tipos["gol"]) - int(tipos["gol_arbitral"])
	_linea("  %d remates: %d goles, %d atajadas, %d postes, %d fallos (%d goles de penal arbitral, aparte)" % [
		remates_totales, goles_de_remate, tipos["atajada"], tipos["poste"], tipos["fallo"], tipos["gol_arbitral"]])
	_comprobar(remates_totales == goles_de_remate + no_gol,
		"cada remate termina en gol o en una senal de remate, sin contar los penales del arbitro (%d = %d)" % [remates_totales, goles_de_remate + no_gol])
	## Sobre los NO-goles: atajada deberia rondar 25/70 (~36%), poste 7/70
	## (~10%), fallo 38/70 (~54%). Con margen ancho porque son proporciones
	## sobre una muestra de unos pocos cientos, no miles.
	var pct_atajada := float(tipos["atajada"]) / maxf(1.0, float(no_gol))
	var pct_poste := float(tipos["poste"]) / maxf(1.0, float(no_gol))
	_comprobar(pct_atajada > 0.22 and pct_atajada < 0.50, "atajada ronda su proporcion del HTML (%.0f%%)" % (pct_atajada * 100.0))
	_comprobar(pct_poste > 0.03 and pct_poste < 0.20, "poste ronda su proporcion del HTML (%.0f%%)" % (pct_poste * 100.0))

	## Las estadisticas de `M.st` del HTML: posesion, tiros a puerta, xG,
	## corners, faltas y fueras de juego. No mueven el marcador, pero si alguna
	## se descuadra -mas tiros a puerta que remates, mas goles que tiros a
	## puerta- la pantalla de despues del partido miente.
	var mal_puerta := 0
	var mal_goles := 0
	var mal_posesion := 0
	var xg_total := 0.0
	var corners_totales := 0
	var faltas_totales := 0
	var fueras_totales := 0
	var partidos_st := 0
	for i2 in 40:
		var a4: Club = l.clubes[i2 % l.clubes.size()]
		var b4: Club = l.clubes[(i2 + 5) % l.clubes.size()]
		if a4 == b4:
			continue
		var p4 := Partido.new(a4, b4)
		p4.simular()
		partidos_st += 1
		if p4.tiros_puerta_local > p4.remates_local or p4.tiros_puerta_visita > p4.remates_visita:
			mal_puerta += 1
		if p4.goles_local > p4.tiros_puerta_local or p4.goles_visita > p4.tiros_puerta_visita:
			mal_goles += 1
		if p4.posesion_local < 22.0 or p4.posesion_local > 78.0:
			mal_posesion += 1
		xg_total += p4.xg_local + p4.xg_visita
		corners_totales += p4.corners_local + p4.corners_visita
		faltas_totales += p4.faltas_local + p4.faltas_visita
		fueras_totales += p4.fueras_local + p4.fueras_visita
	var corners_media := float(corners_totales) / maxf(1.0, float(partidos_st))
	var faltas_media := float(faltas_totales) / maxf(1.0, float(partidos_st))
	var fueras_media := float(fueras_totales) / maxf(1.0, float(partidos_st))
	_linea("  por partido: %.1f corners, %.1f faltas, %.1f fueras de juego, %.2f xG" % [
		corners_media, faltas_media, fueras_media, xg_total / maxf(1.0, float(partidos_st))])
	_comprobar(mal_puerta == 0, "nunca hay mas tiros a puerta que remates (%d mal)" % mal_puerta)
	_comprobar(mal_goles == 0, "nunca hay mas goles que tiros a puerta (%d mal)" % mal_goles)
	_comprobar(mal_posesion == 0, "la posesion se queda entre 22 y 78 (%d fuera)" % mal_posesion)
	## Con las probabilidades del HTML (10%+9% corners, 16%+17% faltas, 5%+5%
	## fueras por minuto sobre 90) lo esperable ronda 17 corners, 30 faltas y 9
	## fueras por partido. Margen ancho: es un sorteo, no una cuenta fija.
	_comprobar(corners_media > 9.0 and corners_media < 26.0, "los corners por partido son creibles (%.1f)" % corners_media)
	_comprobar(faltas_media > 18.0 and faltas_media < 42.0, "las faltas por partido son creibles (%.1f)" % faltas_media)
	_comprobar(fueras_media > 3.0 and fueras_media < 16.0, "los fueras de juego por partido son creibles (%.1f)" % fueras_media)
	_comprobar(xg_total > 0.0, "el xG se acumula de verdad (%.1f en %d partidos)" % [xg_total, partidos_st])

## `vPrevia()`: árbitro, DT rival y cuotas. Nada de esto guarda estado, así que
## lo que hay que probar es que sea ESTABLE (el mismo árbitro toda la semana, el
## mismo DT toda la vida del club) y que las cuotas digan lo mismo que el motor.
func _probar_previa() -> void:
	_titulo("LA PREVIA: ARBITRO, DT RIVAL Y CUOTAS")
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var l := m.ligas[0]
	var fuerte: Club = l.clubes[0]
	var flojo: Club = l.clubes[0]
	for c: Club in l.clubes:
		if c.rep > fuerte.rep:
			fuerte = c
		if c.rep < flojo.rep:
			flojo = c
	_linea("  fuerte: %s (rep %d)   flojo: %s (rep %d)" % [fuerte.nombre, fuerte.rep, flojo.nombre, flojo.rep])

	var a1 := Previa.arbitro_de(flojo.id, 5)
	var a2 := Previa.arbitro_de(flojo.id, 5)
	_comprobar(String(a1["nombre"]) == String(a2["nombre"]), "el arbitro es el mismo toda la semana (%s)" % String(a1["nombre"]))
	_comprobar(String(a1["descripcion"]) != "", "el arbitro trae su descripcion (%s)" % String(a1["descripcion"]))
	var distintos := {}
	for semana in range(1, 30):
		distintos[String(Previa.arbitro_de(flojo.id, semana)["nombre"])] = true
	_comprobar(distintos.size() > 3, "no pita siempre el mismo en toda la temporada (%d arbitros en 29 fechas)" % distintos.size())

	var dt1 := Previa.dt_de(flojo)
	var dt2 := Previa.dt_de(flojo)
	_comprobar(String(dt1["nombre"]) == String(dt2["nombre"]), "el DT rival es parte de la identidad del club, no cambia (%s)" % String(dt1["nombre"]))
	_comprobar(String(dt1["nombre"]) != String(Previa.dt_de(fuerte)["nombre"]) or flojo == fuerte, "dos clubes distintos no comparten DT")
	_comprobar(String(dt1["descripcion"]) != "", "el DT rival trae su estilo (%s)" % String(dt1["estilo"]))

	## Las cuotas: se miden con las fuerzas de verdad de los dos onces.
	var p := Partido.new(fuerte, flojo)
	p.preparar()
	var f_fuerte := p.fuerza(p.once_local, fuerte)
	var f_flojo := p.fuerza(p.once_visita, flojo)
	_linea("  fuerzas reales -> %s ata=%.1f def=%.1f   |   %s ata=%.1f def=%.1f" % [
		fuerte.nombre, f_fuerte["ata"], f_fuerte["def"],
		flojo.nombre, f_flojo["ata"], f_flojo["def"]])
	## OJO: las fuerzas de arriba salen casi iguales aunque la reputacion sea
	## 88 contra 67. Eso NO es cosa de las cuotas -es el armado del once, ver la
	## nota "un rep 88 no es mas fuerte que un rep 67" en el LEEME-, asi que la
	## matematica de la cuota se prueba con numeros CONTROLADOS, que es lo unico
	## que este modulo decide. Con fuerzas de verdad solo se comprueba que no
	## reviente y que sume 1.
	var c_fuerte := Previa.cuotas(f_fuerte, f_flojo, true)
	var suma: float = float(c_fuerte["p_gano"]) + float(c_fuerte["p_empate"]) + float(c_fuerte["p_pierdo"])
	_linea("  el fuerte de local: gana %.0f%%  empata %.0f%%  pierde %.0f%%   (cuotas %.2f / %.2f / %.2f)" % [
		float(c_fuerte["p_gano"]) * 100.0, float(c_fuerte["p_empate"]) * 100.0, float(c_fuerte["p_pierdo"]) * 100.0,
		float(c_fuerte["cuota_gano"]), float(c_fuerte["cuota_empate"]), float(c_fuerte["cuota_pierdo"])])
	_comprobar(absf(suma - 1.0) < 0.001, "las tres probabilidades suman 1 (%.4f)" % suma)
	_comprobar(float(c_fuerte["cuota_gano"]) >= 1.03, "ninguna cuota baja de 1.03 (%.2f)" % float(c_fuerte["cuota_gano"]))

	## Con numeros CONTROLADOS: un equipo claramente mejor (ata 80/def 80) contra
	## uno claramente peor (ata 50/def 50), que es lo que la reputacion deberia
	## producir y hoy no produce.
	var top := {"ata": 80.0, "def": 80.0}
	var malo := {"ata": 50.0, "def": 50.0}
	var c_top := Previa.cuotas(top, malo, true)
	var c_malo := Previa.cuotas(malo, top, true)
	_linea("  controlado -> bueno en casa gana %.0f%%   malo en casa gana %.0f%%" % [
		float(c_top["p_gano"]) * 100.0, float(c_malo["p_gano"]) * 100.0])
	_comprobar(float(c_top["p_gano"]) > float(c_top["p_pierdo"]), "el mejor es favorito")
	_comprobar(float(c_top["cuota_gano"]) < float(c_top["cuota_pierdo"]), "al favorito se le paga menos")
	_comprobar(float(c_top["p_gano"]) > float(c_malo["p_gano"]),
		"a igualdad de campo, el mejor tiene mas opciones (%.0f%% vs %.0f%%)" % [
			float(c_top["p_gano"]) * 100.0, float(c_malo["p_gano"]) * 100.0])
	## La localia: el MISMO cruce, cambiando solo de campo, tiene que mover la
	## probabilidad hacia el que juega en casa.
	var c_visitante := Previa.cuotas(top, malo, false)
	_comprobar(float(c_top["p_gano"]) > float(c_visitante["p_gano"]),
		"jugar en casa sube tus opciones (%.0f%% vs %.0f%%)" % [float(c_top["p_gano"]) * 100.0, float(c_visitante["p_gano"]) * 100.0])
	## Y los goles esperados tienen que estar en la escala de GOLES, no de
	## llegadas: dos equipos parejos rondan 1,3 cada uno, no 4.
	var lam_parejo := Previa._goles_esperados(60.0, 60.0, 1.0)
	_comprobar(lam_parejo > 0.8 and lam_parejo < 2.2,
		"los goles esperados estan en escala de goles, no de llegadas (%.2f)" % lam_parejo)
	## LA JERARQUIA DEPORTIVA. Esto empezo siendo un aviso: un rep 88 y un rep
	## 67 daban fuerzas casi iguales (59.3 contra 59.5), o sea que un grande no
	## se distinguia de un chico en el campo. La causa estaba en `reales.gd`
	## -reescalaba el `ovr` sin regenerar los atributos, y encima anclaba la
	## banda a los reales en vez de a la reputacion-. Arreglado, esto se queda
	## como red: si la jerarquia se vuelve a aplastar, salta aqui.
	var ata_fuerte: float = f_fuerte["ata"]
	var ata_flojo: float = f_flojo["ata"]
	_comprobar(ata_fuerte > ata_flojo,
		"un club de rep %d ataca mas que uno de rep %d (%.1f vs %.1f)" % [
			fuerte.rep, flojo.rep, ata_fuerte, ata_flojo])
	var brecha := ata_fuerte - ata_flojo
	_comprobar(brecha > 4.0,
		"y la diferencia se nota de verdad, no por decimas (%.1f puntos)" % brecha)

## EL ÁRBITRO YA NO ES SOLO UN NOMBRE EN LA PREVIA: decide cosas durante el
## propio partido -`_chequeo_arbitral()`-, y esas decisiones tenían que
## consumir `Azar` de verdad porque cambian tarjetas y algún marcador -a
## diferencia de un adorno cosmético, que nunca debe tocarlo-. Lo que se
## prueba aquí es que el MISMO árbitro que `Previa.arbitro_de()` anuncia antes
## del partido es el que de verdad pita (`Partido.preparar()` no recalcula el
## hash con una fórmula distinta), y que sus decisiones narran y mueven el
## marcador cuando tienen que hacerlo.
func _probar_arbitros() -> void:
	_titulo("EL ÁRBITRO EN EL PROPIO PARTIDO")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	var l := m.ligas[0]
	var a: Club = l.clubes[0]
	var b: Club = l.clubes[1]
	## `Partido.preparar()` fija `ctx_semana`/`ctx_club_id` desde los estaticos:
	## se ponen a mano, como hace `Mundo.avanzar_semana()` cada semana.
	Partido.ctx_semana = 5
	Partido.ctx_club_id = ""
	var p := Partido.new(a, b)
	p.preparar()
	var esperado := Previa.arbitro_de(b.id, 5)
	_comprobar(String(p.arbitro["nombre"]) == String(esperado["nombre"]),
		"el que pita en el partido es el mismo que anuncia la previa (%s)" % String(p.arbitro["nombre"]))

	## Con volumen -las probabilidades son de 0,3% a 1% POR LLEGADA- tiene que
	## verse de todo: tarjetas de mas, algun penal, y la narracion propia.
	##
	## CONTADORES EN UN DICCIONARIO, NO EN `var int` SUELTAS: una lambda de
	## GDScript captura una variable local de tipo valor (int/float/bool) por
	## COPIA en el momento en que se crea, así que `narraciones += 1` dentro
	## del closure solo movía su propia copia privada y el contador de fuera
	## se quedaba siempre en 0 -el mismo motivo por el que `_probar_partidos()`,
	## mas arriba, ya usaba un diccionario (`oidos`) para esto mismo: un
	## Dictionary es un tipo por referencia, así que sí se comparte con quien
	## conectó la señal-.
	var cont := {"narraciones": 0, "tarjetas": 0}
	var goles_totales := 0
	for i in 500:
		var p2 := Partido.new(l.clubes[i % l.clubes.size()], l.clubes[(i + 4) % l.clubes.size()])
		if p2.local == p2.visita:
			continue
		p2.decision_arbitral.connect(func(_t: String, _m: int) -> void: cont["narraciones"] += 1)
		p2.tarjeta.connect(func(_j: Jugador, _r: bool, _m: int) -> void: cont["tarjetas"] += 1)
		var r2 := p2.simular()
		goles_totales += r2["local"] + r2["visita"]
	_comprobar(int(cont["narraciones"]) > 0, "el arbitro narra al menos una decision en 500 partidos (%d)" % int(cont["narraciones"]))
	_linea("  %d partidos: %d decisiones arbitrales narradas, %d tarjetas repartidas (arbitrales + normales)" % [
		500, int(cont["narraciones"]), int(cont["tarjetas"])])
	_comprobar(goles_totales > 0, "el motor sigue anotando goles con el arbitro metido en el medio (%d)" % goles_totales)

	## `Prensa.arbitro_dudoso()`: la rama de "reclamo formal" en el despacho
	## estaba completa desde antes y nadie la llamaba -quedo anotado en el
	## LEEME como pendiente-. Se busca una semana en la que el arbitro de un
	## cruce sea "casero" o "figura" -no se espera al sorteo real, que podria
	## tardar temporadas en dar ese perfil- y se le fabrica una derrota.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 314)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	var mio2 := m2.mi_club()
	var rival2: Club = null
	var semana_mala := -1
	for s in 60:
		for c2: Club in m2.ligas[0].clubes:
			if c2 == mio2:
				continue
			var arb2 := Previa.arbitro_de(c2.id, s)
			if String(arb2["perfil"]) == "casero" or String(arb2["perfil"]) == "figura":
				rival2 = c2
				semana_mala = s
				break
		if rival2 != null:
			break
	_comprobar(rival2 != null, "se encuentra alguna semana con arbitro casero/figura para probar el aviso")
	if rival2 != null:
		_comprobar(m2.prensa.arbitro_polemico == "", "no hay reclamo pendiente antes de perder")
		m2.semana = semana_mala
		m2._avisar_a_la_directiva([{"local": mio2, "visita": rival2, "gl": 0, "gv": 1}])
		_comprobar(m2.prensa.arbitro_polemico != "",
			"perder con un arbitro casero/figura deja listo el reclamo formal (%s)" % m2.prensa.arbitro_polemico)
	## Los estaticos de contexto son GLOBALES a la clase: si se dejan puestos,
	## el siguiente `Partido` suelto que arme otra prueba -sin pasar por
	## `Mundo.avanzar_semana()`, que los vuelve a fijar- heredaria la semana 5
	## de esta prueba.
	Partido.limpiar_contexto()

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

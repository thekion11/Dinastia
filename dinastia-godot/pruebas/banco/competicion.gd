extends "res://pruebas/banco/base.gd"
## [Banco · grupo «competicion»] Generado al partir el banco por grupos (26-10).

func _probar_calendario() -> void:
	_titulo("CALENDARIO")
	var m := Mundo.new()
	m.generar(["CHI"], 3)
	var l := m.ligas[0]
	var n := l.clubes.size()
	_linea("  %s: %d clubes, %d jornadas" % [l.nombre, n, l.jornadas()])
	var esperadas := (n - 1) * 2 if n % 2 == 0 else n * 2
	_comprobar(l.jornadas() == esperadas, "jornadas = %d (esperadas %d)" % [l.jornadas(), esperadas])
	## Nadie puede jugar dos veces en la misma jornada.
	var repetidos := 0
	for jornada: Array in l.calendario:
		var vistos := {}
		for par: Array in jornada:
			for c: Club in par:
				if vistos.has(c.id):
					repetidos += 1
				vistos[c.id] = true
	_comprobar(repetidos == 0, "nadie juega dos veces en una jornada (%d casos)" % repetidos)
	## Todos contra todos, ida y vuelta: cada cruce con campo fijo, una sola vez.
	var cruces := {}
	for jornada: Array in l.calendario:
		for par: Array in jornada:
			var k: String = par[0].id + ">" + par[1].id
			cruces[k] = int(cruces.get(k, 0)) + 1
	var mal := 0
	for k: String in cruces:
		if int(cruces[k]) != 1:
			mal += 1
	_comprobar(mal == 0, "cada cruce local-visita aparece una sola vez (%d mal)" % mal)

func _probar_continental() -> void:
	_titulo("COPAS CONTINENTALES")
	var m := Mundo.new()
	m.generar([], 5150)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_linea("  torneos sorteados: %s" % [m.continentales.keys()])
	_comprobar(m.continentales.size() >= 2, "se sortean al menos dos torneos continentales")

	var vacios := 0
	for k: String in m.continentales:
		var t: Continental = m.continentales[k]
		_linea("  %-5s %-28s %2d inscritos, %2d vivos, %s" % [
			k, Continental.nombre_conti(k), t.participantes.size(), t.vivos.size(),
			t.nombre_de_ronda()])
		if t.participantes.is_empty():
			vacios += 1
	_comprobar(vacios == 0, "ningun torneo se sortea vacio (%d vacios)" % vacios)

	## Nadie puede estar en dos torneos de la misma confederacion a la vez.
	var en_dos := 0
	var visto := {}
	for k: String in m.continentales:
		var t: Continental = m.continentales[k]
		for c: Club in t.participantes:
			if visto.has(c.id) and Continental.confed_de(visto[c.id]) == Continental.confed_de(k):
				en_dos += 1
			visto[c.id] = k
	_comprobar(en_dos == 0, "ningun club juega dos copas de su misma confederacion (%d)" % en_dos)

	## Y lo que de verdad importa: que el torneo LLEGUE a tener campeon. Un
	## torneo que se queda sin nadie vivo antes de la final no reparte el premio
	## y ademas no se nota: no revienta nada, simplemente no pasa.
	var mio := m.mi_continental()
	_comprobar(mio != null, "tu club juega una copa continental")
	if mio != null:
		_linea("  la tuya: %s con %d inscritos" % [mio.nombre, mio.participantes.size()])
	var con_campeon := 0
	for k: String in m.continentales:
		var t: Continental = m.continentales[k]
		var vueltas := 0
		while t.en_curso() and vueltas < 20:
			t.jugar_ronda()
			vueltas += 1
		if t.campeon != null:
			con_campeon += 1
			_linea("  campeon de %s: %s" % [Continental.nombre_conti(k), t.campeon.nombre])
	_comprobar(con_campeon == m.continentales.size(),
		"todos los torneos llegan a tener campeon (%d de %d)" % [con_campeon, m.continentales.size()])

	## Y que ganar TU continental celebre el titulo -confianza, socios, moral al
	## tope- igual que la liga o la copa. El gancho vive en Mundo.avanzar_semana(),
	## no en jugar_ronda(): se prueba forzando una final a dos y comprobando que
	## SI mi club sale campeon, cae en la vitrina en la semana exacta.
	## Una sola final forzada puede perderla hasta el favorito absoluto -es una
	## eliminatoria de un partido, no una liga-, así que se insiste con semillas
	## distintas antes de rendirse. Sin insistir, esta prueba salía inconclusa
	## una de cada dos corridas y no decía nada real.
	var conti_verificado := false
	var ultimo_muro_antes := 0
	var ultimo_muro_despues := 0
	for intento_semilla in 6:
		var m3 := Mundo.new()
		m3.generar(["CHI"], 5150 + intento_semilla)
		m3.tomar_el_mando(m3.ligas[0].clubes[0].id)
		var t: Continental = m3.mi_continental()
		if t == null:
			continue
		var debil: Club = null
		for c: Club in m3.clubes.values():
			if c.id != m3.mi_club_id and (debil == null or c.rep < debil.rep):
				debil = c
		t.preparar([m3.mi_club(), debil] as Array[Club])
		var muro_antes := m3.logros.muro.size()
		var intentos := 0
		while t.en_curso() and intentos < 10:
			m3.avanzar_semana()
			intentos += 1
		if t.campeon == m3.mi_club():
			ultimo_muro_antes = muro_antes
			ultimo_muro_despues = m3.logros.muro.size()
			conti_verificado = true
			break
	if conti_verificado:
		_comprobar(ultimo_muro_despues > ultimo_muro_antes,
			"ganar un continental de clubes celebra el titulo (vitrina %d -> %d)" % [ultimo_muro_antes, ultimo_muro_despues])
	else:
		_linea("  (el club fuerte perdio la final forzada en las 6 semillas probadas; no se pudo verificar el gancho esta corrida)")

func _probar_copa() -> void:
	_titulo("COPA: ELIMINACION DIRECTA")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	var aspirantes: Array[Club] = []
	for c: Club in m.clubes.values():
		aspirantes.append(c)
	var copa := Copa.new("Copa de prueba")
	copa.preparar(aspirantes)
	_linea("  %d clubes inscritos -> %d en el cuadro (%s)" % [
		aspirantes.size(), copa.participantes.size(), copa.nombre_de_ronda()])
	## El cuadro tiene que ser potencia de dos: con 32 equipos y byes repartidos
	## a mano, el sorteo parece amanado y ademas hay que inventar rondas previas.
	var n := copa.participantes.size()
	var potencia := n > 0 and (n & (n - 1)) == 0
	_comprobar(potencia, "el cuadro es una potencia de dos (%d)" % n)
	_comprobar(n <= aspirantes.size(), "no se inventan participantes")

	var rondas := 0
	var nombres: Array[String] = []
	while copa.en_curso():
		nombres.append(copa.nombre_de_ronda())
		var res := copa.jugar_ronda()
		## En cada cruce tiene que pasar uno y solo uno, y el que pasa tiene que
		## ser uno de los dos que jugaron.
		for r: Dictionary in res:
			if r["pasa"] != r["local"] and r["pasa"] != r["visita"]:
				_fallos.append("pasa un club que no jugo el cruce")
			if r["gl"] == r["gv"] and r["penales"].is_empty():
				_fallos.append("un empate sin penales en eliminacion directa")
		rondas += 1
		if rondas > 12:
			break
	_linea("  rondas: %s" % ", ".join(nombres))
	_comprobar(copa.campeon != null, "la copa tiene campeon: %s" % (copa.campeon.nombre if copa.campeon else "ninguno"))
	_comprobar(rondas == int(log(float(n)) / log(2.0)), "se juegan las rondas justas (%d para %d clubes)" % [rondas, n])
	_comprobar(nombres.has("Final") and nombres.has("Semifinales"), "las rondas se llaman por su nombre")
	_comprobar(copa.participantes.has(copa.campeon), "el campeon estaba inscrito")

	## El premio es fijo y se cobra. Es lo que hace que una copa cambie el ano
	## de un club chico.
	var antes := copa.campeon.saldo
	var copa2 := Copa.new("Otra")
	copa2.preparar(aspirantes)
	var c2 := copa2.jugar_hasta_el_final()
	_linea("  premio de copa: %s (fijo, no escalado al tamano del club)" % _dinero(Copa.PREMIO))
	_comprobar(c2 != null, "jugar_hasta_el_final devuelve campeon")

	## Y la final se juega en cancha neutral: sin el 1,08 del local.
	##
	## SE MIDE POR GOLES, NO POR VICTORIAS. La version anterior contaba
	## victorias en 300 partidos y comparaba los dos numeros a pelo: con p~0,4 y
	## n=300 el ruido propio es de +-8 victorias, o sea que comparaba dos cifras
	## cuya diferencia esperada cabe entera dentro del error. Pasaba por suerte,
	## y el dia que las plantillas cambiaron de fuerza salio 118 contra 126 -al
	## reves- sin que nada estuviera roto. Los goles son una senal continua: el
	## bono de local (1,08 contra 0,94) los mueve directamente y se ve con mucha
	## menos muestra.
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var goles_en_casa := 0
	var goles_neutral := 0
	var remates_casa := 0
	var remates_neutral := 0
	## MUESTRA SUBIDA DE 300 A 800 (11-9-2026): con el árbitro metido en cada
	## llegada (`Partido._chequeo_arbitral()`, que gasta `Azar` en CADA ataque,
	## haya decisión o no) la posición del sorteo compartido se corre un poco
	## para todo lo que se simule después en el banco. La brecha esperada entre
	## casa y neutral (~4.47 contra ~4.24, un 0,23 de diferencia) cabía casi
	## entera dentro del error propio de 300 muestras -el mismo problema que
	## esta prueba ya había tenido una vez con "victorias" en vez de "goles",
	## documentado arriba-, así que bastó ese corrimiento para que en esta
	## semilla el resultado saliera al revés (4.16 contra 4.38) sin que la
	## ventaja de local se hubiera roto: `neutral=true` sigue sin sumar el
	## 1,08 de `simular_minuto()`, nadie tocó esa cuenta. Con 800 partidos por
	## lado el error baja de ~0,12 a ~0,07 remates, con margen de sobra sobre
	## la brecha real.
	for i in 800:
		var p1 := Partido.new(a, b, false)
		p1.simular()
		goles_en_casa += p1.goles_local
		remates_casa += p1.remates_local
		var p2 := Partido.new(a, b, true)
		p2.simular()
		goles_neutral += p2.goles_local
		remates_neutral += p2.remates_local
	var media_casa := float(goles_en_casa) / 800.0
	var media_neutral := float(goles_neutral) / 800.0
	var rem_casa := float(remates_casa) / 800.0
	var rem_neutral := float(remates_neutral) / 800.0
	_linea("  el local: %.2f goles y %.2f remates en casa | %.2f goles y %.2f remates en neutral" % [
		media_casa, rem_casa, media_neutral, rem_neutral])
	## SE MIDE POR REMATES, que es donde pega el bono. El camino hasta aqui:
	##  1) La version original contaba VICTORIAS en 300 partidos. Ruido propio
	##     +-8 victorias, diferencia esperada menor que eso: pasaba por suerte.
	##  2) Se cambio a GOLES, y salio 1.31 en casa contra 1.32 en neutral -o sea
	##     ninguna diferencia-, lo que parecia un bug gordo: que jugar de local
	##     no valiera nada. NO lo era: el gol es una moneda al 30% sobre cada
	##     remate, y ese sorteo se traga una diferencia del 5%.
	##  3) Medido en REMATES, que es lo que el bono multiplica directamente, la
	##     ventaja aparece limpia: 4.47 contra 4.24.
	## La leccion: medir el efecto donde ocurre, no tres sorteos mas abajo.
	_comprobar(rem_casa > rem_neutral,
		"en cancha neutral se pierde la ventaja de local (%.2f remates vs %.2f)" % [rem_casa, rem_neutral])

func _probar_selecciones() -> void:
	_titulo("SELECCIÓN NACIONAL Y MUNDIAL DE CLUBES")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 909)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_comprobar(m.selecciones != null, "tomar el mando crea la selección")
	_comprobar(m.selecciones.pais_seleccion() == m.mi_club().pais,
		"la selección que sigues es la de tu club, no Chile a fuego (%s)" % m.selecciones.pais_seleccion())
	_comprobar(m.selecciones.fuerza("Brasil") == 88 and m.selecciones.fuerza("España") == 88,
		"las seis grandes valen 88")
	var antes_conti := m.continentales.size()

	## Tres temporadas: cae al menos una prenómina, una fecha FIFA, un torneo
	## continental de selecciones (par) y, a la tercera (2028), la Copa del Mundo.
	##
	## Se comprueba el estado directo (`prenomina_ids`, `nomina_ids`) y no las
	## señales: un lambda de GDScript captura las variables locales POR VALOR, no
	## por referencia, así que `func(): vio = true` conectado a una señal escribe
	## en una copia y la variable de fuera nunca cambia -sin error, sin aviso.
	var ultimo_resumen := {}
	for temporada in 3:
		m.jugar_temporada()
		ultimo_resumen = m.nueva_temporada()
	_comprobar(not m.selecciones.prenomina_ids.is_empty(), "se publica al menos una prenómina en tres temporadas")
	_comprobar(not m.selecciones.nomina_ids.is_empty(), "se cierra al menos una convocatoria en tres temporadas")
	_comprobar(m.selecciones.nomina_ids.size() <= 18, "la nómina final no pasa de 18 (%d)" % m.selecciones.nomina_ids.size())
	_comprobar(m.selecciones.resultados.size() > 0, "quedan resultados de la selección anotados")
	_comprobar(ultimo_resumen.get("selecciones", {}).has("mundial"),
		"nueva_temporada() devuelve el resumen de selecciones")
	## 2026 -> 2027 -> 2028: la Copa del Mundo cae al cerrar 2028.
	_comprobar(not m.selecciones.mundial.is_empty(), "la Copa del Mundo se jugó al llegar a 2028 (%s)" % m.selecciones.mundial.get("campeon", "?"))
	_comprobar(m.continentales.size() == antes_conti,
		"los continentales se re-sortean cada temporada con el mismo número de torneos (%d)" % m.continentales.size())

	## Guardado y carga: la cabeza de la selección (caps, nacionalizados, mundial)
	## tiene que sobrevivir igual que el resto de sistemas de TU club.
	Partida.borrar("_prueba_selecciones")
	_comprobar(Partida.guardar(m, "_prueba_selecciones"), "una partida con selección se guarda")
	var m2 := Partida.cargar("_prueba_selecciones")
	_comprobar(m2 != null, "esa partida se recarga")
	if m2 != null:
		_comprobar(m2.selecciones != null, "la selección vuelve al cargar")
		_comprobar(m2.selecciones.mundial.get("campeon", "") == m.selecciones.mundial.get("campeon", ""),
			"vuelve el mismo campeón del mundo (%s)" % m2.selecciones.mundial.get("campeon", "?"))
		_comprobar(m2.selecciones.resultados.size() == m.selecciones.resultados.size(),
			"vuelven los mismos resultados anotados (%d)" % m2.selecciones.resultados.size())
	Partida.borrar("_prueba_selecciones")

func _probar_ascensos() -> void:
	_titulo("ASCENSOS, DESCENSOS Y PREMIOS")
	var m := Mundo.new()
	m.generar(["CHI"], 4040)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var primera := m.ligas[0]
	var segunda := m.ligas[1]
	_comprobar(primera.division() == 1 and segunda.division() == 2, "las dos divisiones estan marcadas")
	m.jugar_temporada()

	var t1 := primera.tabla()
	var t2 := segunda.tabla()
	var campeon: Club = t1[0]["club"]
	var caja_antes := campeon.saldo
	var rep_antes := campeon.rep
	var ultimo: Club = t1[t1.size() - 1]["club"]
	var penultimo: Club = t1[t1.size() - 2]["club"]
	var primero_b: Club = t2[0]["club"]
	var segundo_b: Club = t2[1]["club"]
	var n1 := primera.clubes.size()
	var n2 := segunda.clubes.size()

	var resumen := m.nueva_temporada()
	_linea("  campeon: %s   suben: %s, %s   bajan: %s, %s" % [
		campeon.nombre, primero_b.nombre, segundo_b.nombre, ultimo.nombre, penultimo.nombre])
	_comprobar(campeon.saldo > caja_antes, "el campeon cobra el premio")
	_comprobar(campeon.rep == rep_antes + 1, "ganar la liga sube la reputacion del club")

	## Lo que de verdad hay que comprobar: que los clubes CAMBIAN de lista, no
	## solo de etiqueta. Mover la etiqueta sin mover la lista deja a un club
	## descendido jugando en primera y cobrando de segunda.
	_comprobar(segunda.clubes.has(ultimo) and segunda.clubes.has(penultimo), "los dos ultimos estan ahora en segunda")
	_comprobar(primera.clubes.has(primero_b) and primera.clubes.has(segundo_b), "los dos primeros de segunda estan ahora en primera")
	_comprobar(not primera.clubes.has(ultimo), "el descendido ya no esta en primera")
	_comprobar(ultimo.division == 2 and primero_b.division == 1, "la division del club acompana al cambio de liga")
	_comprobar(primera.clubes.size() == n1 and segunda.clubes.size() == n2,
		"las dos ligas conservan su tamano (%d y %d)" % [primera.clubes.size(), segunda.clubes.size()])

	## Y el castigo economico del descenso, que es el que de verdad duele.
	var f_abajo := Finanzas.new(ultimo)
	var f_arriba := Finanzas.new(primero_b)
	_linea("  television: el descendido cobra %s, el ascendido %s" % [
		_dinero(f_abajo.derechos_tv()), _dinero(f_arriba.derechos_tv())])
	_comprobar(f_abajo.derechos_tv() < f_arriba.derechos_tv() or ultimo.rep > primero_b.rep + 8,
		"bajar de division cuesta dinero de television")

	## El calendario nuevo tiene que incluir a los recien llegados.
	_comprobar(primera.jornadas() > 0 and primera.emparejamiento_de(primero_b).size() == 2,
		"el ascendido tiene partido en el calendario nuevo")


func _probar_temporadas() -> void:
	_titulo("TEMPORADAS COMPLETAS")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 55)
	var t0 := Time.get_ticks_msec()
	for temporada in 3:
		m.jugar_temporada()
		var tabla := m.ligas[0].tabla()
		var campeon: Dictionary = tabla[0]
		_linea("  %d: campeon %s con %d puntos (%d-%d-%d), %d jugadores en el mundo" % [
			m.anio, campeon["club"].nombre, campeon["pts"],
			campeon["g"], campeon["e"], campeon["p"], m.cuantos_jugadores()])
		## La tabla tiene que cuadrar: los puntos salen de los resultados y los
		## goles a favor de todos son los goles en contra de todos.
		var gf := 0
		var gc := 0
		for fila: Dictionary in tabla:
			if fila["pts"] != fila["g"] * 3 + fila["e"]:
				_fallos.append("puntos mal sumados en %s" % fila["club"].nombre)
			if fila["pj"] != fila["g"] + fila["e"] + fila["p"]:
				_fallos.append("partidos mal sumados en %s" % fila["club"].nombre)
			gf += fila["gf"]
			gc += fila["gc"]
		_comprobar(gf == gc, "los goles a favor igualan a los goles en contra (%d/%d)" % [gf, gc])
		m.nueva_temporada()
	_linea("  tres temporadas en %d ms" % (Time.get_ticks_msec() - t0))
	var viejos := 0
	var plantillas_cortas := 0
	for c: Club in m.clubes.values():
		if c.plantilla.size() < 18:
			plantillas_cortas += 1
		for j in c.plantilla:
			if j.edad > 40:
				viejos += 1
	_comprobar(viejos == 0, "nadie sigue jugando pasados los 40 (%d)" % viejos)
	_comprobar(plantillas_cortas == 0, "ninguna plantilla se vacia con los anos (%d)" % plantillas_cortas)

	## Las plantillas tampoco se pueden deformar. Reponiendo al azar, en diez
	## temporadas un club acaba con seis porteros y sin lateral izquierdo, porque
	## los retiros no caen por igual en cada demarcacion.
	var deformes := 0
	var max_porteros := 0
	for c: Club in m.clubes.values():
		var porteros := 0
		var lineas := {}
		for j in c.plantilla:
			lineas[Datos.grupo(j.pos_e)] = true
			if j.es_portero():
				porteros += 1
		max_porteros = maxi(max_porteros, porteros)
		if lineas.size() < 4 or porteros > 5:
			deformes += 1
	_linea("  el club con mas porteros tiene %d" % max_porteros)
	_comprobar(deformes == 0, "ninguna plantilla se deforma tras tres temporadas (%d)" % deformes)

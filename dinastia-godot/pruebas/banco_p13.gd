extends "res://pruebas/banco_p12.gd"
## (Parte 13 de 25 de `banco.gd`.)

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

func _probar_economia() -> void:
	_titulo("ECONOMIA (las curvas del HTML, sin retocar)")
	## El valor es exponencial sobre la media, no lineal: es lo que hace que
	## fichar a un 90 sea una decision de club y no una compra mas.
	var valores := {}
	for ovr in [60, 70, 80, 90]:
		var j := Jugador.new()
		j.ovr = ovr
		j.pot = ovr
		j.edad = 26
		j.anios_contrato = 3
		j.tasar()
		valores[ovr] = j.valor
		_linea("  media %d -> valor %s, sueldo %s" % [ovr, _dinero(j.valor), _dinero(j.sueldo)])
	_comprobar(valores[70] > valores[60] * 2, "de 60 a 70 el valor mas que se duplica")
	_comprobar(valores[80] > valores[70] * 2, "de 70 a 80 el valor mas que se duplica")
	_comprobar(valores[90] > valores[80] * 2, "de 80 a 90 el valor mas que se duplica")
	## La edad manda: el mismo 78 no vale lo mismo a los 19 que a los 34.
	var joven := Jugador.new(); joven.ovr = 78; joven.pot = 90; joven.edad = 19; joven.anios_contrato = 4; joven.tasar()
	var viejo := Jugador.new(); viejo.ovr = 78; viejo.pot = 78; viejo.edad = 34; viejo.anios_contrato = 4; viejo.tasar()
	_linea("  mismo 78: a los 19 vale %s, a los 34 vale %s" % [_dinero(joven.valor), _dinero(viejo.valor)])
	_comprobar(joven.valor > viejo.valor * 4, "la joya de 19 vale mucho mas que el veterano de 34")
	## Y la caja de los clubes tambien es exponencial sobre la reputacion.
	_linea("  caja de referencia: rep 60 -> %s | rep 70 -> %s | rep 88 -> %s" % [
		_dinero(int(Eco.ref_caja(60))), _dinero(int(Eco.ref_caja(70))), _dinero(int(Eco.ref_caja(88)))])
	_comprobar(Eco.ref_caja(88) > Eco.ref_caja(70) * 5.0, "un grande maneja mucha mas caja que uno medio")

func _probar_sala_de_prensa() -> void:
	_titulo("SALA DE PRENSA (portavoz, television, portadas y el ano contado)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 7373)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)

	## LA PROYECCION NO COBRA. Este es el fallo mas caro que ha tenido la
	## economia y no lo veia nadie: `proyeccion_anual()` llamaba a `derechos_tv()`,
	## `patrocinio()` y `cuotas_socios()`, que MUEVEN el saldo. Abrir la pantalla
	## de Finanzas le regalaba al club un mes de ingresos en cada repintado.
	var caja_antes := m.mi_club().saldo
	var fin_p := Finanzas.new(m.mi_club(), 0.0, 0, 0.0)
	for i in 5:
		fin_p.proyeccion_anual(15, 0)
	_comprobar(m.mi_club().saldo == caja_antes,
		"mirar la proyeccion anual cinco veces no mueve un peso de la caja (%d -> %d)" % [caja_antes, m.mi_club().saldo])

	## LOS DERECHOS DE TELEVISION. Los tres multiplicadores existian y ninguno
	## llegaba a la caja: el reparto de la asamblea, el modelo de contrato y el
	## plus del horario.
	var pr := m.prensa
	_comprobar(is_equal_approx(pr.factor_tv(), 1.0), "en bloque la television no lleva multiplicador")
	var rep_mia := m.mi_club().rep
	pr.negociar_tv(true, m.mi_club())
	var esperado := 1.35 if rep_mia >= Prensa.REP_VENDE_SOLO else 0.70
	_linea("  rep %d -> vender solo multiplica x%.2f" % [rep_mia, pr.factor_tv()])
	_comprobar(is_equal_approx(pr.factor_tv(), esperado),
		"negociar por tu cuenta con rep %d da x%.2f" % [rep_mia, esperado])
	var f_tv := Finanzas.new(m.mi_club(), 0.0, 0, 0.0)
	var limpio := f_tv.derechos_tv_base()
	f_tv.factor_tv = pr.factor_tv()
	var caja_tv := m.mi_club().saldo
	f_tv.derechos_tv()
	var cobrado := m.mi_club().saldo - caja_tv
	_comprobar(cobrado == int(round(float(limpio) * esperado)),
		"y la television paga el multiplicador de verdad (%d sobre %d)" % [cobrado, limpio])
	pr.negociar_tv(false, m.mi_club())
	_comprobar(is_equal_approx(pr.factor_tv(), 1.0), "volver al bloque quita el multiplicador")

	## EL PORTAVOZ reparte a la mitad lo que mueve la rueda de prensa. Sin esto
	## el boton prometia en su texto algo que no cobraba en ninguna cuenta.
	var mio := m.mi_club()
	mio.plantilla[0].capitan = true
	_comprobar(pr.vocero.is_empty(), "de entrada das tu la cara")
	pr.nombrar_vocero(mio)
	_comprobar(not pr.vocero.is_empty(), "se puede nombrar portavoz a un capitan")
	pr.abrir_rueda(true, false)
	_comprobar(pr.hay_rueda(), "la rueda se abre")
	var con_vocero := pr.responder(0)
	pr.nombrar_vocero(mio)
	_comprobar(pr.vocero.is_empty(), "y se le puede quitar")
	pr.abrir_rueda(true, false)
	var sin_vocero := pr.responder(0)
	_linea("  misma respuesta: con portavoz %+d de moral, sin portavoz %+d" % [
		int(con_vocero.get("moral", 0)), int(sin_vocero.get("moral", 0))])
	_comprobar(absi(int(con_vocero.get("moral", 0))) <= absi(int(sin_vocero.get("moral", 0))),
		"con portavoz la rueda mueve menos")

	## EL ARCHIVO DE PORTADAS. Se escribian tras cada partido grande y se perdian
	## al cambiar de pantalla.
	_comprobar(pr.portadas.is_empty(), "el archivo empieza vacio")
	var salieron := 0
	for i in 40:
		pr.portada_tras_resultado(i % 3 == 0, i % 3 == 1, false, "semilla-%d" % i)
		salieron = pr.portadas.size()
	_linea("  de 40 partidos se archivaron %d portadas" % salieron)
	_comprobar(salieron > 5 and salieron < 35, "no sale portada de cada partido, pero si de bastantes")
	_comprobar(String(pr.portadas[0].get("t", "")) != "", "la portada mas nueva va primera y tiene titular")
	## Y NO USA `Azar`: es decoracion. Si lo usara, desplazaria la simulacion
	## entera y dos partidas identicas dejarian de serlo.
	var t1 := pr.titular_prensa(true, false, false, "misma-semilla")
	var t2 := pr.titular_prensa(true, false, false, "misma-semilla")
	_comprobar(String(t1["tit"]) == String(t2["tit"]),
		"el mismo partido escribe siempre el mismo titular (no toca el azar)")

	## EL ANO CONTADO: un parrafo, no una tabla.
	var relato := pr.narrador_temporada()
	_linea("  relato: %s" % relato.substr(0, 110))
	_comprobar(relato.length() > 40, "el narrador cuenta la temporada en un parrafo")
	_comprobar(relato.contains(m.mi_club().nombre), "y nombra a tu club")

func _probar_auspicio() -> void:
	_titulo("AUSPICIO (la marca del pecho)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 8181)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var a := m.auspicio
	var mio := m.mi_club()

	_comprobar(a != null, "el club tiene mercado de auspicios desde el primer dia")
	_comprobar(a.ofertas.size() == Auspicio.OFERTAS,
		"hay %d marcas sobre la mesa (%d)" % [Auspicio.OFERTAS, a.ofertas.size()])
	_comprobar(a.contrato.is_empty(), "y todavia ninguna firmada")
	_comprobar(a.semanal() == 0, "sin firmar no entra un peso")
	## Las marcas llegan limpias de leetspeak: la tabla las guarda escritas con
	## ceros y cuatros, como los clubes.
	var sucias := 0
	for o: Dictionary in a.ofertas:
		var n := String(o["marca"])
		if n.contains("0") or n.contains("4") or n.contains("1"):
			sucias += 1
		_linea("  %s pide top %d por %s" % [n, int(o["exig_pos"]), _dinero(int(o["monto"]))])
	_comprobar(sucias == 0, "los nombres de las marcas llegan legibles, sin ceros ni cuatros")

	## Firmar: se cobra semana a semana, no de golpe.
	var monto := int(a.ofertas[0]["monto"])
	_comprobar(a.firmar(0) == "", "se puede firmar la primera oferta")
	_comprobar(a.ofertas.is_empty(), "y las otras marcas se retiran")
	_comprobar(a.firmar(0) != "", "no se puede firmar dos veces en la misma temporada")
	_comprobar(a.semanal() == int(round(float(monto) / float(Auspicio.SEMANAS_TEMPORADA))),
		"el aporte gotea en %d semanas (%s a la semana)" % [Auspicio.SEMANAS_TEMPORADA, _dinero(a.semanal())])
	var caja := mio.saldo
	m.avanzar_semana()
	_comprobar(mio.saldo != caja, "y la semana lo ingresa de verdad en la caja")

	## LA EXIGENCIA. Terminar por debajo de lo pactado encoge las ofertas del
	## ano siguiente: es lo que convierte elegir la cifra mas alta en una apuesta
	## y no en una obviedad.
	var pedido := int(a.contrato["exig_pos"])
	a.cierre(pedido + 5)
	_comprobar(a.quedaron_molestos, "terminar por debajo del top pactado deja molesta a la marca")
	_comprobar(a.contrato.is_empty(), "y el contrato se acaba con la temporada")
	a.generar_ofertas(mio, false)
	var flaca := 0
	for o: Dictionary in a.ofertas:
		flaca += int(o["monto"])
	a.quedaron_molestos = false
	a.generar_ofertas(mio, false)
	var gorda := 0
	for o: Dictionary in a.ofertas:
		gorda += int(o["monto"])
	_linea("  ofertas tras fallar: %s   ·   tras cumplir: %s" % [_dinero(flaca), _dinero(gorda)])
	_comprobar(flaca < gorda, "y al ano siguiente las ofertas llegan mas flacas")

	## Un grande cobra varias veces lo que un chico: la curva es exponencial
	## sobre la reputacion, como todo el resto de la economia.
	var chico := m.ligas[0].clubes[m.ligas[0].clubes.size() - 1]
	_linea("  base de %s (rep %d): %s   ·   base de %s (rep %d): %s" % [
		mio.nombre, mio.rep, _dinero(Auspicio.base_de(mio)),
		chico.nombre, chico.rep, _dinero(Auspicio.base_de(chico))])
	_comprobar(Auspicio.base_de(mio) > Auspicio.base_de(chico),
		"un grande cobra mas por la camiseta que un chico")

## La proyeccion media de una camada, con o sin epoca dorada en el pais. Mismo
## mundo y misma semilla en los dos casos: lo unico que cambia es la epoca.
func _media_techo_camada(semilla: int, tipo: String) -> float:
	var m := Mundo.new()
	m.generar(["CHI"], semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	if tipo != "":
		m.eras.activas["CHI"] = {"tipo": tipo, "desde": m.anio, "hasta": m.anio + 5}
	var suma := 0.0
	var n := 0
	for c: Club in m.clubes.values():
		for j: Jugador in m.cantera._camada_de(c):
			suma += float(j.pot)
			n += 1
	return suma / float(maxi(1, n))

func _probar_eras_y_precios() -> void:
	_titulo("EPOCAS DORADAS Y PRECIOS DINAMICOS")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 9191)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)

	## LAS EPOCAS. Un pais entero ganando o perdiendo una generacion.
	var e := m.eras
	_comprobar(e != null, "el mundo tiene mapa del talento")
	_comprobar(is_equal_approx(e.bono("CHI", m.anio), 1.0), "sin epoca marcada, el pais no lleva bono")
	e.activas["CHI"] = {"tipo": "dorada", "desde": m.anio, "hasta": m.anio + 5}
	_comprobar(is_equal_approx(e.bono("CHI", m.anio), Eras.BONO_DORADA),
		"en epoca dorada las camadas suben un 13%")
	_comprobar(is_equal_approx(e.bono("ARG", m.anio), 1.0), "y el pais de al lado sigue igual")
	_comprobar(is_equal_approx(e.bono("CHI", m.anio + 9), 1.0), "la epoca caduca sola cuando pasa su ultimo ano")
	e.activas["ARG"] = {"tipo": "decadencia", "desde": m.anio, "hasta": m.anio + 4}
	_comprobar(is_equal_approx(e.bono("ARG", m.anio), Eras.BONO_DECADENCIA),
		"en decadencia las camadas bajan un 10%")
	var mapa := e.mapa_del_talento(m.anio)
	_comprobar(mapa.size() == 2, "el mapa del talento enseña los dos paises marcados (%d)" % mapa.size())
	for f: Dictionary in mapa:
		_linea("  %s: %s hasta %d (%s)" % [String(f["pais"]), String(f["tipo"]), int(f["hasta"]), String(f["texto"])])

	## Y se nota en la camada: mismo club, mismo ano, dos mundos con y sin epoca.
	## Se comparan MEDIAS de proyeccion sobre las dos camadas completas, que es
	## donde el 13% se ve; jugador a jugador el azar tapa el efecto.
	var techo_con := _media_techo_camada(9292, "dorada")
	var techo_sin := _media_techo_camada(9292, "")
	_linea("  proyeccion media de la camada: con epoca dorada %.1f, sin ella %.1f" % [techo_con, techo_sin])
	_comprobar(techo_con > techo_sin, "la epoca dorada se nota de verdad en la camada")

	## LOS PRECIOS DINAMICOS: el mismo asiento no vale lo mismo contra el lider
	## que contra el colista.
	var h := m.hinchada
	var base := 8
	_comprobar(not h.precio_dinamico, "de entrada el precio es fijo")
	_comprobar(h.precio_efectivo(base, 90) == base, "y con precio fijo da igual contra quien juegues")
	h.alternar_precio_dinamico()
	_comprobar(h.precio_dinamico, "el interruptor enciende los precios dinamicos")
	var caro := h.precio_efectivo(base, 90)
	var barato := h.precio_efectivo(base, 45)
	_linea("  entrada de %d: contra un rep 90 se cobra %d, contra un rep 45 se cobra %d" % [base, caro, barato])
	_comprobar(caro > base, "contra un grande la entrada sube")
	_comprobar(barato < base, "contra un chico la entrada baja")
	_comprobar(h.precio_efectivo(base, 200) <= Hinchada.PRECIO_MAX, "con techo: nunca pasa de %d" % Hinchada.PRECIO_MAX)
	_comprobar(h.precio_efectivo(base, 0) >= Hinchada.PRECIO_MIN, "y con suelo: nunca baja de %d" % Hinchada.PRECIO_MIN)
	_comprobar(h.castigo_por_subida(base, caro) > 0, "subirla se paga en animo")
	_comprobar(h.castigo_por_subida(base, barato) == 0, "bajarla no molesta a nadie")

	## LA FRASE DE LA PARED Y EL UNIFORME DEL CUERPO TECNICO.
	var cd := m.club_dentro
	_comprobar(cd.frase == "", "la pared empieza en blanco")
	cd.escribir_frase("   Aqui no se rinde nadie   ")
	_comprobar(cd.frase == "Aqui no se rinde nadie", "la frase se guarda limpia de espacios")
	cd.escribir_frase("x".repeat(200))
	_comprobar(cd.frase.length() == ClubDentro.FRASE_MAX,
		"y recortada a %d caracteres (%d)" % [ClubDentro.FRASE_MAX, cd.frase.length()])
	_comprobar(cd.color_ct1(m.mi_club()) == m.mi_club().color1,
		"sin elegir color, el cuerpo tecnico viste de los colores del club")
	cd.ct_color1 = "#ff0000"
	_comprobar(cd.color_ct1(m.mi_club()) == "#ff0000", "y si eliges uno, manda el tuyo")
	cd.vestir("abrigo")
	_comprobar(cd.ct_ropa == "abrigo" and cd.ct_color1 == "",
		"cambiar de prenda borra los colores a mano: el abrigo no hereda el verde del chandal")

func _probar_analitica_y_academias() -> void:
	_titulo("DEPARTAMENTO DE DATOS Y ACADEMIAS INTERNACIONALES")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "BRA"], 5757)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var oj := m.ojeadores
	var mio := m.mi_club()
	mio.mover_saldo(20000000)

	## EL MODELO DE DATOS.
	_comprobar(oj.analitica_nivel == 0, "el departamento empieza sin montar")
	var caja := mio.saldo
	_comprobar(oj.mejorar_analitica(mio) == "", "se puede montar el departamento")
	_comprobar(mio.saldo < caja, "y se paga de la caja")
	_comprobar(oj.analitica_nivel == 1, "queda en nivel 1")
	var c1 := oj.coste_analitica(mio)
	oj.mejorar_analitica(mio)
	var c2 := oj.coste_analitica(mio)
	_linea("  ampliar de 1 a 2 cuesta %s; de 2 a 3, %s" % [_dinero(c1), _dinero(c2)])
	_comprobar(c2 > c1, "cada nivel cuesta mas que el anterior")
	oj.mejorar_analitica(mio)
	_comprobar(oj.analitica_nivel == Ojeadores.ANALITICA_MAX, "se llega al tope")
	_comprobar(oj.mejorar_analitica(mio) != "", "y del tope no se pasa")

	## Los hallazgos aparecen solos y son jugadores de verdad, jovenes y baratos.
	oj.hallazgos.clear()
	for i in 60:
		oj.semana_analitica(3)
	_linea("  en 60 semanas el modelo senalo %d nombres" % oj.hallazgos.size())
	_comprobar(not oj.hallazgos.is_empty(), "el modelo acaba senalando a alguien")
	_comprobar(oj.hallazgos.size() <= 8, "y guarda como mucho ocho (%d)" % oj.hallazgos.size())
	_comprobar(oj.analitica_tension > 0, "con un jefe de ojeadores de la vieja escuela, la tension sube")
	for h: Dictionary in oj.hallazgos:
		var j := m.jugador_por_id(String(h["pid"]))
		if j == null:
			continue
		_comprobar(j.edad <= 24 and j.pot - j.ovr >= 10,
			"%s: joven (%d) y con recorrido (+%d)" % [j.nombre, j.edad, j.pot - j.ovr])
		break
	_comprobar(not oj.hallazgos_vivos().is_empty(), "y se pueden leer resueltos para la pantalla")

	## LAS ACADEMIAS.
	mio.mover_saldo(40000000)
	_comprobar(oj.academias.is_empty(), "no hay sedes internacionales de entrada")
	_comprobar(oj.alternar_academia("ARG", mio) == "", "se puede abrir una sede")
	_comprobar(oj.tiene_academia("ARG"), "y queda abierta")
	_comprobar(oj.mantencion_academias(mio) > 0, "que cuesta todas las semanas")
	oj.alternar_academia("BRA", mio)
	oj.alternar_academia("CHI", mio)
	_comprobar(oj.academias.size() == Ojeadores.ACADEMIAS_MAX,
		"caben %d sedes (%d)" % [Ojeadores.ACADEMIAS_MAX, oj.academias.size()])
	_comprobar(oj.alternar_academia("ESP", mio) != "", "y no una mas")
	## La joya de pretemporada: una por sede, con techo alto de verdad.
	var antes := mio.plantilla.size()
	var joyas := oj.joyas_de_academia(mio)
	_linea("  llegan %d joyas: %s" % [joyas.size(),
		", ".join(joyas.map(func(j: Jugador) -> String: return "%s (%s, proy %d)" % [j.nombre, j.pais, j.pot]))])
	_comprobar(joyas.size() == oj.academias.size(), "llega una joya por sede")
	for j: Jugador in joyas:
		_comprobar(j.pot - j.ovr >= 12, "%s viene con recorrido de verdad (+%d)" % [j.nombre, j.pot - j.ovr])
		break
	_comprobar(mio.plantilla.size() == antes,
		"y `joyas_de_academia` NO las mete sola en el plantel: eso lo hace el mundo, y solo en pretemporada")
	## Cerrar una devuelve algo de dinero.
	var caja2 := mio.saldo
	oj.alternar_academia("ARG", mio)
	_comprobar(mio.saldo > caja2 and not oj.tiene_academia("ARG"), "cerrar una sede la vende y devuelve caja")

## HABILIDADES ESPECIALES: "sortearHabilidades()"/"HABS" del HTML. Nacen con
## el jugador -"LAS HABILIDADES DE NACIMIENTO" en `Mundo.crear_jugador()`- y
## viven en `Entrenamiento` (diccionario id->lista), no en `Jugador`: por
## vivir fuera nunca habían tenido una prueba propia -se encontró revisando
## por qué el editor parecía no tener de dónde sacar `habs`, y resultó que sí
## estaba, solo que en otra clase-.
func _probar_habilidades() -> void:
	_titulo("HABILIDADES ESPECIALES: NACIMIENTO Y BONO DE VALOR")
	var m := Mundo.new()
	m.generar(["CHI"], 8080)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ent := m.entrenamiento

	## Nacen con el jugador: cuanta mejor la media, mas probable que traiga
	## alguna de fábrica.
	var con_habs := 0
	var total := 0
	for c: Club in m.ligas[0].clubes:
		for j: Jugador in c.plantilla:
			total += 1
			if not ent.habilidades(j).is_empty():
				con_habs += 1
	_linea("  %d futbolistas, %d nacieron con alguna habilidad especial" % [total, con_habs])
	_comprobar(con_habs > 0, "al menos alguien nace con una habilidad")

	## `dar_habilidad()`/`habilidades()`: no se repite, y solo entra si esta
	## en la tabla.
	var j := m.mi_club().plantilla[0]
	_comprobar(not ent.dar_habilidad(j, "no_existe_esta_clave"), "una clave que no esta en HABS no se agrega")
	var pool_j: Array = Datos.tabla("HAB_POR" if j.es_portero() else "HAB_CAMPO")
	if not pool_j.is_empty():
		var clave := String(pool_j[0])
		var ya_la_tenia := ent.habilidades(j).has(clave)
		var dado := ent.dar_habilidad(j, clave)
		_comprobar(dado != ya_la_tenia, "dar_habilidad devuelve si de verdad se agrego (%s)" % dado)
		_comprobar(ent.habilidades(j).has(clave), "la habilidad queda anotada")
		_comprobar(not ent.dar_habilidad(j, clave), "pedirla otra vez no la duplica")

	## EL BONO DE VALOR: "if(j.habs.length>=3)v*=1.05" del HTML. Dos
	## jugadores idénticos salvo la cantidad de habilidades.
	var pool: Array = Datos.tabla("HAB_CAMPO")
	if pool.size() >= 3:
		var con3 := Jugador.new()
		con3.ovr = 80; con3.edad = 26; con3.pot = 80; con3.anios_contrato = 3
		con3.tasar()
		var valor_sin := con3.valor
		for i in 3:
			ent.dar_habilidad(con3, String(pool[i]))
		ent._tasar(con3)
		_comprobar(con3.valor > valor_sin,
			"tres habilidades o mas suben el valor (%d -> %d)" % [valor_sin, con3.valor])
		_comprobar(absf(float(con3.valor) / float(valor_sin) - 1.05) < 0.02,
			"la subida ronda el 5%% del HTML (%.1f%%)" % ((float(con3.valor) / float(valor_sin) - 1.0) * 100.0))

extends "res://pruebas/banco/varios_p3.gd"
## [Banco · grupo «varios» · capa 4/10] Generado al partir el banco por grupos (26-10).


func _probar_fundar_club() -> void:
	_titulo("CREAR TU CLUB: FUNDAR DE CERO")
	var m := Mundo.new()
	m.generar([], 6001)

	## En Chile tiene que tomar el colista de ASCENSO, no de Primera.
	var segunda: Liga = null
	for l: Liga in m.ligas:
		if l.pais == "CHI" and l.division() == 2:
			segunda = l
			break
	_comprobar(segunda != null, "el mundo trae la Primera B de Chile")
	var peor_antes: Club = null
	if segunda != null:
		for c: Club in segunda.clubes:
			if peor_antes == null or c.rep < peor_antes.rep:
				peor_antes = c
	var club := m.fundar_club("Deportivo Prueba", "CHI")
	_comprobar(club != null, "fundar_club() devuelve el club fundado")
	if club != null:
		_comprobar(club.nombre == "Deportivo Prueba", "el club queda con el nombre elegido")
		_comprobar(club.rep == Mundo.REP_FUNDACION, "la reputación de fundación es %d (%d)" % [Mundo.REP_FUNDACION, club.rep])
		_comprobar(club.color1 == "#1e4030" and club.color2 == "#c9a227", "los colores son los del escudo del juego")
		_comprobar(club.division == 2, "sigue en Ascenso -se refunda el club, no se lo asciende")
		_comprobar(club.plantilla.size() >= 18, "el plantel se rehizo entero (%d fichas)" % club.plantilla.size())
		_comprobar(peor_antes != null and club.id == peor_antes.id, "fundar toma al colista real de Ascenso, no cualquiera")
		_comprobar(m.mi_club_id == club.id, "tomar_el_mando() ya se hizo solo: no hace falta un paso más")
		_comprobar(segunda.clubes.has(club), "el club fundado sigue en el calendario de su liga -mismo objeto, no uno nuevo")

	## Fuera de Chile no hay Ascenso: toma el más flojo de la única división.
	var esp: Liga = null
	for l: Liga in m.ligas:
		if l.pais == "ESP":
			esp = l
			break
	if esp != null:
		var peor_esp: Club = esp.clubes[0]
		for c: Club in esp.clubes:
			if c.rep < peor_esp.rep:
				peor_esp = c
		var club2 := m.fundar_club("Fundado FC", "ESP")
		_comprobar(club2 != null and club2.id == peor_esp.id,
			"fuera de Chile toma el más flojo de su única división")

	## Guardado: nombre, colores, reputación y plantel nuevo sobreviven.
	Partida.borrar("_prueba_fundar")
	_comprobar(Partida.guardar(m, "_prueba_fundar"), "una partida con un club fundado se guarda")
	var m2 := Partida.cargar("_prueba_fundar")
	if m2 != null and club != null:
		var recargado: Club = m2.clubes.get(club.id)
		_comprobar(recargado != null and recargado.nombre == "Deportivo Prueba" and recargado.rep == Mundo.REP_FUNDACION,
			"el club fundado vuelve igual al cargar")
	Partida.borrar("_prueba_fundar")

func _probar_consejeros() -> void:
	_titulo("CONSEJEROS DEL DIRECTORIO")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	var d := m.directiva

	## Sin caja, no se puede contratar.
	mio.saldo = 0
	var motivo := d.alternar_consejero("dep")
	_comprobar(motivo != "" and not d.tiene_consejero("dep"), "sin caja no se contrata un consejero (%s)" % motivo)

	mio.mover_saldo(5000000)
	_comprobar(d.alternar_consejero("dep") == "", "se contrata al consejero deportivo")
	_comprobar(d.tiene_consejero("dep"), "queda contratado")
	_comprobar(d.honorarios_semanales() == Directiva.HONORARIO_CONSEJERO_SEMANAL, "el honorario semanal cuenta un asiento (%d)" % d.honorarios_semanales())

	_comprobar(d.alternar_consejero("mkt") == "", "se contrata al consejero de marketing")
	_comprobar(d.consejeros.size() == 2, "hay dos consejeros a la vez")
	var lleno := d.alternar_consejero("leg")
	_comprobar(lleno != "" and not d.tiene_consejero("leg"), "no cabe un tercer consejero (%s)" % lleno)
	_comprobar(d.honorarios_semanales() == Directiva.HONORARIO_CONSEJERO_SEMANAL * 2, "el honorario cuenta los dos asientos")

	## dep: afina la niebla de ojeo en TODO el mundo, no solo en paises cubiertos.
	var rival: Jugador = null
	for c: Club in m.clubes.values():
		if c.id != mio.id and c.pais != mio.pais and not c.plantilla.is_empty():
			rival = c.plantilla[0]
			break
	if rival != null:
		var nivel_con := m.ojeadores.nivel_de(rival)
		d.alternar_consejero("dep")   ## lo cesa
		var nivel_sin := m.ojeadores.nivel_de(rival)
		_comprobar(nivel_con - nivel_sin > 0.35 and nivel_con - nivel_sin < 0.45, "el consejero deportivo suma 0.4 al nivel de ojeo en cualquier pais (%.2f vs %.2f)" % [nivel_con, nivel_sin])
		d.alternar_consejero("dep")   ## lo vuelve a contratar para lo que sigue

	## mkt: +10% en patrocinio.
	var sin_mkt := Finanzas.new(mio).patrocinio()
	var con_mkt := Finanzas.new(mio, 0.0, 0, 0.1).patrocinio()
	_comprobar(con_mkt > sin_mkt and con_mkt <= int(round(float(sin_mkt) * 1.1)) + 1, "el consejero de marketing sube el patrocinio un 10%% (%d vs %d)" % [sin_mkt, con_mkt])

	## Cesar libera el asiento y deja de cobrar honorario.
	_comprobar(d.alternar_consejero("mkt") == "", "se cesa al consejero de marketing")
	_comprobar(not d.tiene_consejero("mkt"), "el asiento queda libre")
	_comprobar(d.honorarios_semanales() == Directiva.HONORARIO_CONSEJERO_SEMANAL, "el honorario baja a un solo asiento")

	## EMBAJADOR DEL CLUB: reutiliza Cantera.leyendas, sembradas al generar.
	_comprobar(m.cantera != null and not m.cantera.leyendas.is_empty(), "hay leyendas sembradas para elegir embajador")
	var candidatas := Directiva.candidatas_embajador(m.cantera.leyendas, m.anio)
	_comprobar(not candidatas.is_empty(), "candidatas_embajador() devuelve al menos una terna (%d)" % candidatas.size())
	var candidatas2 := Directiva.candidatas_embajador(m.cantera.leyendas, m.anio)
	_comprobar(candidatas[0]["nombre"] == candidatas2[0]["nombre"], "las candidatas son deterministas para el mismo año")

	var elegido: Dictionary = candidatas[0]
	var costo_emb := 400000 + int(elegido.get("nivel", 80)) * 8000
	mio.saldo = 0
	_comprobar(d.contratar_embajador(elegido) != "", "sin caja no se puede fichar al embajador")
	mio.mover_saldo(costo_emb + 1000000)
	var saldo_antes := mio.saldo
	_comprobar(d.contratar_embajador(elegido) == "", "se ficha al embajador")
	_comprobar(not d.embajador.is_empty() and String(d.embajador["nombre"]) == String(elegido["nombre"]), "queda registrado con su nombre")
	_comprobar(mio.saldo == saldo_antes - costo_emb, "el fichaje cobra el costo exacto, nivel incluido (%d)" % costo_emb)

	var socios_antes := mio.socios
	m.avanzar_semana()
	_comprobar(mio.socios >= socios_antes + Directiva.SOCIOS_POR_SEMANA_EMBAJADOR, "el embajador suma socios cada semana (%d -> %d)" % [socios_antes, mio.socios])

	_comprobar(d.cesar_embajador() == "", "se cesa al embajador -hay caja para el finiquito-")
	_comprobar(d.embajador.is_empty(), "el puesto queda vacante")

	## El entrenador empleado tambien cobra -"G.rol!=='dt'&&G.dtEmp" del HTML-,
	## y solo cuando no diriges tu mismo. Se comprueba el asiento en el libro
	## financiero, no la caja total, porque un mes entero de partidos mueve la
	## caja por mil motivos a la vez.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 8181)
	m2.tomar_el_mando(m2.ligas[0].clubes[1].id)
	m2.mi_club().mover_saldo(50000000)
	_comprobar(m2.roles.dt_empleado.is_empty(), "de entrenador (dt) todavia no hay a quien pagarle")
	m2.roles.rol = Roles.DIR
	m2.roles.call("_contratar_dt_empleado")
	for s in Finanzas.SEMANAS_DEL_MES:
		m2.avanzar_semana()
	var hay_sueldo_dt := false
	for mov: Dictionary in m2.libro_financiero:
		if String(mov.get("concepto", "")).begins_with("Sueldo del entrenador"):
			hay_sueldo_dt = true
			_comprobar(int(mov["monto"]) == -Roles.SUELDO_SEMANAL_DT_EMPLEADO * Finanzas.SEMANAS_DEL_MES,
				"el sueldo mensual del entrenador empleado es el correcto (%d)" % int(mov["monto"]))
	_comprobar(hay_sueldo_dt, "siendo director, el entrenador empleado cobra su sueldo al cierre de mes")

## "EL ATHLETIC CLUB DE BILBAO SOLO FICHA JUGADORES DE ESPAÑA" (22-9-2026,
## pedido directo del usuario). El club SÍ existe en el juego (`Ath. Bilbao`
## en `PAISES_LIGAS.ESP`, en leetspeak en la tabla -"B1lbao"-, por eso una
## búsqueda literal de "Bilbao" no lo encontraba la primera vez). La regla
## real (cantera vasca) no se puede portar literal -`Jugador` solo trackea
## `pais`, nunca ciudad/región-, así que se aproxima por "mismo país" (ESP).
## `Mercado._buscar_objetivo()` ahora salta cualquier candidato que no sea de
## España cuando el comprador es Bilbao (`Mercado.CLUBES_SOLO_MISMO_PAIS`).
##
## Mundo PROPIO, aislado -no reusa `m1`/`m2` de otra función, ni genera un
## tercer mundo dentro de una función ajena, la misma trampa que ya colgó el
## banco tres veces con la prueba de apellidos por país (ver esa sección de
## `LEEME.md`).
func _probar_bilbao_solo_local() -> void:
	_titulo("ATHLETIC BILBAO: SOLO FICHA DE ESPAÑA")
	var m := Mundo.new()
	m.generar(["ESP"], 4711)
	var bilbao: Club = null
	for c: Club in m.clubes.values():
		if Nombres.limpiar(c.nombre) == "Ath. Bilbao":
			bilbao = c
			break
	if bilbao == null:
		_comprobar(false, "Ath. Bilbao existe en PAISES_LIGAS.ESP")
		return
	var extranjeros_antes := 0
	for j in bilbao.plantilla:
		if j.pais != bilbao.pais:
			extranjeros_antes += 1
	## 100 semanas de mercado de la IA -bastante para que, sin la regla, le
	## hubiera entrado al menos un extranjero de los otros 15 clubes de la
	## liga (`mover(6)` sortea 6 compradores por semana entre TODOS los
	## clubes del mundo, Bilbao incluido con probabilidad real).
	for semana in 100:
		m.mercado.mover(6)
	var extranjeros_despues := 0
	for j in bilbao.plantilla:
		if j.pais != bilbao.pais:
			extranjeros_despues += 1
	_comprobar(extranjeros_despues <= extranjeros_antes,
		"100 semanas de mercado IA no le suman extranjeros a Bilbao (antes %d, después %d)" % [
			extranjeros_antes, extranjeros_despues])

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

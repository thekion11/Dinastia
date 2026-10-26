extends "res://pruebas/banco/base.gd"
## [Capa 1/3 de `gestion.gd`] _probar_finanzas, _probar_mercado, _probar_directiva, _probar_staff, _probar_obras, _probar_cantera … (+1)

func _probar_finanzas() -> void:
	_titulo("FINANZAS")
	var m := Mundo.new()
	m.generar(["CHI"], 88)
	var c: Club = m.ligas[0].clubes[0]
	var f := Finanzas.new(c)
	_linea("  %s: aforo %d, %d socios, entrada %.1f" % [c.nombre, c.estadio_aforo, c.socios, c.precio_entrada])
	var base := f.asistencia()
	_linea("  asistencia con entrada a 6: %d (%.0f%% del aforo)" % [base, 100.0 * float(base) / float(c.estadio_aforo)])
	## Subir el precio tiene que VACIAR el estadio, o el precio no es una
	## decision: es un boton de dinero gratis.
	c.precio_entrada = 14.0
	var cara := f.asistencia()
	c.precio_entrada = 2.0
	var barata := f.asistencia()
	c.precio_entrada = 6.0
	_linea("  a 14 entran %d, a 2 entran %d" % [cara, barata])
	_comprobar(cara < base and base < barata, "el precio de la entrada mueve la asistencia en el sentido correcto")
	_comprobar(f.asistencia() >= int(float(c.estadio_aforo) * 0.12), "nunca baja del 12% del aforo")
	c.precio_entrada = 99.0
	_comprobar(f.asistencia() >= int(float(c.estadio_aforo) * 0.12), "ni con la entrada a 99 se vacia del todo")
	c.precio_entrada = 6.0
	## Una semana con partido en casa tiene que dejar mas que una sin el.
	var antes := c.saldo
	f.semana(true)
	var con_casa := c.saldo - antes
	c.saldo = antes
	f.semana(false)
	var sin_casa := c.saldo - antes
	c.saldo = antes
	_linea("  semana en casa: %s   |   semana fuera: %s" % [_dinero(con_casa), _dinero(sin_casa)])
	_comprobar(con_casa > sin_casa, "jugar en casa deja mas dinero que jugar fuera")

	## El cierre de mes, que es donde se paga todo de golpe.
	var m4 := f.mes()
	c.saldo = antes
	_linea("  cierre de mes: entran %s, salen %s, neto %s" % [
		_dinero(m4["entra"]), _dinero(m4["sale"]), _dinero(m4["neto"])])
	_comprobar(m4["entra"] > 0 and m4["sale"] > 0, "el mes tiene ingresos y gastos")

	## Y lo que de verdad importa: que un club llevado por la IA ni quiebre ni se
	## haga de oro solo con dejar pasar el tiempo. Es la prueba que caza los
	## errores de unidades, que son los que no hacen ruido.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 606)
	var vigilados: Array[Club] = [m2.ligas[0].clubes[0], m2.ligas[0].clubes[8], m2.ligas[1].clubes[0]]
	var caja0: Array[int] = []
	for v in vigilados:
		caja0.append(v.saldo)
	for temporada in 3:
		m2.jugar_temporada()
		m2.nueva_temporada()
	var rotos := 0
	var ricos := 0
	for i in vigilados.size():
		var v := vigilados[i]
		var factor := float(v.saldo) / float(maxi(caja0[i], 1))
		_linea("  %-22s %s -> %s  (x%.1f)" % [v.nombre, _dinero(caja0[i]), _dinero(v.saldo), factor])
		if v.saldo < 0:
			rotos += 1
		if factor > 12.0:
			ricos += 1
	_comprobar(rotos == 0, "ningun club quiebra en tres temporadas (%d)" % rotos)
	_comprobar(ricos == 0, "ningun club multiplica su caja por doce sin hacer nada (%d)" % ricos)

func _probar_mercado() -> void:
	_titulo("MERCADO DE FICHAJES")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	var mk := m.mercado
	var grande: Club = null
	var chico: Club = null
	for c: Club in m.clubes.values():
		if grande == null or c.rep > grande.rep: grande = c
		if chico == null or c.rep < chico.rep: chico = c
	_linea("  club grande: %s (rep %d)   club chico: %s (rep %d)" % [grande.nombre, grande.rep, chico.nombre, chico.rep])

	## La joya de 20 con techo alto tiene que costar bastante mas que su valor.
	var joya := Jugador.new()
	joya.club_id = chico.id
	joya.edad = 20; joya.ovr = 75; joya.pot = 90; joya.anios_contrato = 4
	joya.tasar()
	var normal := Jugador.new()
	normal.club_id = chico.id
	normal.edad = 27; normal.ovr = 75; normal.pot = 75; normal.anios_contrato = 4
	normal.tasar()
	_linea("  joya de 20 (75/90): valor %s, piden %s" % [_dinero(joya.valor), _dinero(mk.valor_pedido(joya))])
	_linea("  jugador de 27 (75/75): valor %s, piden %s" % [_dinero(normal.valor), _dinero(mk.valor_pedido(normal))])
	_comprobar(mk.valor_pedido(joya) > mk.valor_pedido(normal), "por la joya piden mas que por el hecho")
	_comprobar(mk.valor_pedido(joya) > joya.valor, "el club pide por encima del valor de tasacion")

	## El deseo de venir: al grande se va casi cualquiera, al chico no.
	var suyo: Jugador = grande.plantilla[0]
	suyo.club_id = grande.id
	var al_chico: float = mk.deseo_de_venir(suyo, chico)["p"]
	var del_chico: Jugador = chico.plantilla[0]
	var al_grande: float = mk.deseo_de_venir(del_chico, grande)["p"]
	_linea("  del grande al chico: %.0f%% de ganas   |   del chico al grande: %.0f%%" % [al_chico * 100.0, al_grande * 100.0])
	_comprobar(al_grande > al_chico, "se quiere subir de club, no bajar")
	var razones: Array = mk.deseo_de_venir(suyo, chico)["razones"]
	_comprobar(razones.size() > 0, "la negativa viene con motivos que se le pueden ensenar al jugador")

	## Y el que no quiere venir se pone caro en vez de decir que no.
	var pide_al_chico := mk.ficha_que_pide(suyo, chico)
	var pide_al_grande := mk.ficha_que_pide(suyo, grande)
	_linea("  ficha que pide: al chico %s, al grande %s" % [_dinero(pide_al_chico), _dinero(pide_al_grande)])
	_comprobar(pide_al_chico > pide_al_grande, "al club que no le seduce le pide mas ficha")

	## Regateo: el club acepta cerca de lo pedido y nunca una miseria.
	var pedido := mk.valor_pedido(normal)
	_comprobar(mk.club_acepta(normal, pedido), "acepta lo que pide")
	_comprobar(not mk.club_acepta(normal, int(float(pedido) * 0.5)), "no acepta la mitad")

	## El mercado de la IA tiene que mover el mundo, pero sin deshacerlo.
	var antes_totales := m.cuantos_jugadores()
	var hechos := 0
	for semana in 20:
		hechos += mk.mover().size()
	_linea("  %d traspasos entre clubes de la IA en 20 semanas" % hechos)
	_comprobar(hechos > 0, "el mercado de la IA mueve jugadores")
	_comprobar(m.cuantos_jugadores() == antes_totales, "no se pierde ni se duplica ningun jugador (%d)" % m.cuantos_jugadores())
	var cortas := 0
	var sin_club := 0
	for c: Club in m.clubes.values():
		if c.plantilla.size() < 18:
			cortas += 1
		for j in c.plantilla:
			if j.club_id != c.id:
				sin_club += 1
	_comprobar(cortas == 0, "ningun club se queda corto de plantilla por vender (%d)" % cortas)
	_comprobar(sin_club == 0, "cada jugador apunta al club en el que esta (%d descuadrados)" % sin_club)

	## jugador_por_id(): lo usa el comparador nuevo de la ficha para resolver
	## los tres ids que guarda `_comparar_ids` en memoria.
	var cualquiera: Jugador = grande.plantilla[0]
	_comprobar(m.jugador_por_id(cualquiera.id) == cualquiera, "jugador_por_id encuentra al jugador correcto")
	_comprobar(m.jugador_por_id("no-existe-esto") == null, "jugador_por_id no encuentra lo que no existe")

func _probar_directiva() -> void:
	_titulo("LA DIRECTIVA: OBJETIVO, CONFIANZA Y DESPIDO")
	var m := Mundo.new()
	m.generar(["CHI"], 3131)
	var grande: Club = null
	var chico: Club = null
	for c: Club in m.ligas[0].clubes:
		if grande == null or c.rep > grande.rep: grande = c
		if chico == null or c.rep < chico.rep: chico = c

	var d1 := m.tomar_el_mando(grande.id)
	_linea("  a %s (rep %d) le piden: %s" % [grande.nombre, grande.rep, d1.objetivo])
	var m2 := Mundo.new()
	m2.generar(["CHI"], 3131)
	var d2 := m2.tomar_el_mando(chico.id)
	_linea("  a %s (rep %d) le piden: %s" % [chico.nombre, chico.rep, d2.objetivo])
	## El objetivo NO se elige: te lo pone el club segun lo que es. Es lo que hace
	## que dirigir a un grande y a un chico sean dos juegos distintos.
	_comprobar(d1.meta_puesto < d2.meta_puesto, "al grande le exigen mas que al chico (%d vs %d)" % [
		d1.meta_puesto, d2.meta_puesto])

	## Ganar sube la confianza y perder la baja, y el tamano del rival pesa.
	var antes := d1.confianza
	d1.tras_partido(3, 0, chico)
	var por_ganar_al_chico := d1.confianza - antes
	d1.confianza = antes
	d1.tras_partido(3, 0, grande)
	var por_ganar_al_grande := d1.confianza - antes
	d1.confianza = antes
	_linea("  ganar al chico suma %d, ganar a uno grande suma %d" % [por_ganar_al_chico, por_ganar_al_grande])
	_comprobar(por_ganar_al_grande >= por_ganar_al_chico, "ganarle a uno grande vale mas")
	d1.tras_partido(0, 2, chico)
	_comprobar(d1.confianza < antes, "perder baja la confianza")

	## Y lo que de verdad importa: que te puedan echar. Un manager sin despido no
	## es un manager.
	var visto := {"echado": false}
	d1.despedido.connect(func(_motivo: String) -> void: visto["echado"] = true)
	for i in 30:
		d1.tras_partido(0, 3, chico)
	_comprobar(visto["echado"], "una racha de derrotas acaba en despido (confianza %d)" % d1.confianza)
	_comprobar(d1.despedido_ya, "queda marcado como despedido")
	var c_tras := d1.confianza
	d1.tras_partido(5, 0, grande)
	_comprobar(d1.confianza == c_tras, "despues del despido ya no se mueve nada")

	## Cumplir el objetivo repone confianza; fallarlo cuesta mas cuanto mas lejos.
	var d3 := Directiva.new(grande, 1)
	var r_bien := d3.tras_temporada(1, true, false)
	_linea("  campeon cumpliendo: confianza %d (%+d)" % [r_bien["confianza"], r_bien["delta"]])
	_comprobar(r_bien["cumplido"] and r_bien["delta"] > 0, "cumplir y ganar la liga sube la confianza")
	var d4 := Directiva.new(grande, 1)
	var r_mal := d4.tras_temporada(14, false, false)
	_linea("  decimocuarto fallando: confianza %d (%+d)" % [r_mal["confianza"], r_mal["delta"]])
	_comprobar(not r_mal["cumplido"] and r_mal["delta"] < 0, "fallar el objetivo baja la confianza")
	_comprobar(d3.humor() != d4.humor(), "el humor de la directiva se lee distinto en cada caso")

func _probar_staff() -> void:
	_titulo("CUERPO TECNICO")
	var m := Mundo.new()
	m.generar(["CHI"], 616)
	var c: Club = m.ligas[0].clubes[0]
	m.tomar_el_mando(c.id)
	var s := m.staff

	## Solo la parte del cuerpo técnico (el camarín ya suma desde el primer día).
	s.aplicar(c)
	_comprobar(is_equal_approx(c.bonus_ataque, 1.0), "sin staff, los bonificadores estan a uno")
	m.aplicar_bonificadores()
	var caja := c.saldo
	var coste := s.coste_subir("ayudante", c.rep)
	_comprobar(s.subir("ayudante", c) == "", "se contrata al ayudante de campo")
	_linea("  ayudante nivel 1 cuesta %s" % _dinero(coste))
	_comprobar(c.saldo == caja - coste, "el fichaje del staff sale de la caja")
	## Lo que importa: que se NOTE. Un menu que no cambia un numero del motor es
	## un boton de gastar dinero, y este proyecto ya pago ese error varias veces.
	_comprobar(c.bonus_ataque > 1.0, "contratar al ayudante sube el ataque del equipo (%.3f)" % c.bonus_ataque)

	## El coste crece mas rapido que el efecto: llenar los seis puestos al maximo
	## no puede ser la jugada obvia del primer ano.
	var c1 := s.coste_subir("ayudante", c.rep)
	s.subir("ayudante", c)
	var c2 := s.coste_subir("ayudante", c.rep)
	_linea("  subir de 1 a 2 cuesta %s; de 2 a 3, %s" % [_dinero(c1), _dinero(c2)])
	_comprobar(c2 > c1, "cada nivel cuesta mas que el anterior")

	## Y el efecto de cada puesto, uno por uno.
	s.niveles["medico"] = 3
	_comprobar(s.descuento_lesion(8) == 5, "el jefe medico acorta las lesiones (8 -> %d)" % s.descuento_lesion(8))
	_comprobar(s.descuento_lesion(1) >= 1, "pero nunca las cura por decreto")
	s.niveles["ojeador"] = 2
	_comprobar(s.ojo() > 0.0, "el ojeador trae informes")
	s.niveles["fisico"] = 4
	_comprobar(s.aguante() == 4, "el preparador fisico da aguante")
	_comprobar(s.sueldo_semanal(c.rep) > 0, "el cuerpo tecnico cobra todas las semanas")

	## Aplicar dos veces no puede duplicar la bonificacion: al cargar una partida
	## se vuelve a aplicar, y acumulando el equipo saldria con el doble.
	var antes := c.bonus_ataque
	s.aplicar(c)
	s.aplicar(c)
	_comprobar(is_equal_approx(c.bonus_ataque, antes), "aplicar el staff dos veces no duplica el efecto")


func _probar_obras() -> void:
	_titulo("INSTALACIONES")
	var m := Mundo.new()
	m.generar(["CHI"], 2424)
	var c: Club = m.ligas[0].clubes[0]
	m.tomar_el_mando(c.id)
	var o := m.obras
	_linea("  %d obras en el catalogo" % Instalaciones.CATALOGO.size())
	_comprobar(Instalaciones.CATALOGO.size() == 19, "estan las 19 instalaciones del HTML")

	## Las obras NO son instantaneas: es lo que impide comprarlo todo el primer
	## dia y que el sistema desaparezca. En el HTML se cambio a proposito en la
	## v2.5 justo por eso.
	var caja := c.saldo
	var precio := o.coste("cal", c.rep)
	_comprobar(o.iniciar("cal", c) == "", "se puede empezar una obra")
	_comprobar(c.saldo == caja - precio, "la obra se paga por adelantado")
	_comprobar(o.nivel("cal") == 0, "la obra NO sube el nivel al momento")
	_comprobar(o.en_obra("cal"), "queda constancia de que hay obra en marcha")
	_comprobar(o.iniciar("cal", c) != "", "no se puede empezar dos veces la misma obra")
	var retrasos := 0
	for s in o.semanas_de("cal"):
		o.avanzar_semana(c)
		for t: String in o.ultimos_imprevistos:
			retrasos += 1 if t.contains("retrasa") else 0
	for s in retrasos:
		o.avanzar_semana(c)
	_comprobar(o.nivel("cal") == 1, "la obra termina en su plazo (%d semanas%s)" % [o.semanas_de("cal"), " + %d de retraso" % retrasos if retrasos > 0 else ""])
	_comprobar(not o.en_obra("cal"), "y deja de estar en marcha")

	## Y lo que de verdad importa: que se NOTE. Una obra que no mueve un numero
	## visible es un boton de gastar dinero.
	var f_sin := Finanzas.new(c, 0.0)
	var f_con := Finanzas.new(c, o.aporte_ocupacion())
	_linea("  calidad del estadio nivel 1: entran %d en vez de %d" % [
		f_con.asistencia(), f_sin.asistencia()])
	_comprobar(f_con.asistencia() > f_sin.asistencia(), "la calidad del estadio llena mas el estadio")

	## Las tribunas cambian el aforo, y hay que poder construirlas varias veces
	## sin que el aforo se multiplique cada vez que se carga la partida.
	var aforo0 := c.estadio_aforo
	o.niveles["trib"] = 2
	o.aplicar(c)
	var aforo2 := c.estadio_aforo
	_linea("  aforo: %s de fabrica, %s con dos tribunas" % [aforo0, aforo2])
	_comprobar(aforo2 > aforo0, "construir tribunas amplia el aforo")
	o.aplicar(c)
	o.aplicar(c)
	_comprobar(c.estadio_aforo == aforo2, "aplicarlo tres veces no multiplica el aforo")

	## Los ingresos que solo existen con ladrillo.
	o.niveles["com"] = 2
	o.niveles["museo"] = 1
	o.ultima_asistencia = 20000
	o.niveles["park"] = 3
	var ing := o.ingresos_del_mes(c)
	var total := 0
	for i: Dictionary in ing:
		total += int(i["monto"])
		_linea("  %s: %s al mes" % [String(i["concepto"]), _dinero(int(i["monto"]))])
	_comprobar(ing.size() == 3, "la tienda, el museo y los estacionamientos dan ingresos")
	_comprobar(total > 0, "y suman de verdad (%s)" % _dinero(total))
	## M-224: la estrella del plantel vende camisetas.
	var mejor_j: Jugador = c.plantilla[0]
	var ovr0 := mejor_j.ovr
	for j: Jugador in c.plantilla:
		j.ovr = mini(j.ovr, 74)
	var tienda_normal := int(o.ingresos_del_mes(c)[0]["monto"])
	mejor_j.ovr = 90
	var tienda_crack := int(o.ingresos_del_mes(c)[0]["monto"])
	mejor_j.ovr = ovr0
	_comprobar(tienda_crack > tienda_normal * 1.5, "con un crack de 90 la tienda vende más camisetas (%s → %s)" % [_dinero(tienda_normal), _dinero(tienda_crack)])
	## M-227: lo construido se mantiene (cuesta cada mes, más cuanto más hay).
	var mant := o.mantenimiento_del_mes(c.rep)
	o.niveles["trib"] = 4
	_comprobar(mant > 0 and o.mantenimiento_del_mes(c.rep) > mant, "el mantenimiento cuesta y crece con lo construido (%s → %s al mes)" % [_dinero(mant), _dinero(o.mantenimiento_del_mes(c.rep))])
	_comprobar(mant < total * 3, "y no se come lo que rinden las obras (%s vs %s)" % [_dinero(mant), _dinero(total)])
	## M-228: imprevistos — como mucho uno por obra, y repetibles al recargar.
	var imp := Instalaciones.new()
	imp.niveles = o.niveles.duplicate()
	var hubo := 0
	for clave: String in Instalaciones.CATALOGO:
		if imp.nivel(clave) >= imp.maximo(clave):
			continue
		imp.obras[clave] = 6
		for _s in 8:
			imp.avanzar_semana(c)
			hubo += imp.ultimos_imprevistos.size()
	_comprobar(hubo > 0 and hubo <= Instalaciones.CATALOGO.size(), "algunas obras tienen un imprevisto, nunca más de uno (%d)" % hubo)

	## Cada efecto tiene una puerta por la que entra al juego. Si alguna devuelve
	## siempre lo mismo, esa instalacion no hace nada.
	o.niveles["med"] = 2
	o.niveles["rehab"] = 1
	_comprobar(o.descuento_lesion() == 3, "el centro medico y la rehabilitacion acortan lesiones (%d)" % o.descuento_lesion())
	o.niveles["cocina"] = 2
	o.niveles["piscina"] = 2
	_comprobar(o.aguante() == 2, "comedor y piscina dan aguante (%d)" % o.aguante())
	o.niveles["ct"] = 3
	_comprobar(o.ritmo_de_progreso() > 1.0, "el centro de entrenamiento acelera el progreso (%.2f)" % o.ritmo_de_progreso())
	o.niveles["acad"] = 2
	o.niveles["resid"] = 2
	_comprobar(o.techo_cantera() == 3, "academia y residencia suben el techo de la cantera (%d)" % o.techo_cantera())
	o.niveles["huerto"] = 3
	_comprobar(o.abarata_operacion() < 1.0, "el huerto abarata la operacion")

	## El coste crece con el cuadrado del nivel: el quinto nivel tiene que ser
	## una decision de club, no un tramite.
	var c1 := o.coste("gim", c.rep)
	o.niveles["gim"] = 3
	var c4 := o.coste("gim", c.rep)
	_linea("  gimnasio: nivel 1 cuesta %s, nivel 4 cuesta %s" % [_dinero(c1), _dinero(c4)])
	_comprobar(c4 > c1 * 3, "el cuarto nivel cuesta mucho mas que el primero")

func _probar_cantera() -> void:
	_titulo("CANTERA: CAMADA, BECAS Y LINAJE")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 313)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	_comprobar(m.cantera != null, "tomar el mando crea la cantera")
	_comprobar(m.cantera.leyendas.size() > 0, "se siembran leyendas al empezar (%d)" % m.cantera.leyendas.size())

	## Cuatro temporadas: tiene que llegar al menos una camada nueva y, con
	## veintitantas leyendas sembradas, algun hijo antes de la cuarta.
	var hubo_camada := false
	var jugadores_canteranos_vistos := 0
	for temporada in 4:
		m.jugar_temporada()
		m.nueva_temporada()
		if not m.cantera.camada_actual().is_empty():
			hubo_camada = true
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if m.cantera.es_canterano(j):
				jugadores_canteranos_vistos += 1
	_comprobar(hubo_camada, "al menos una temporada trae camada nueva")
	_comprobar(jugadores_canteranos_vistos > 0, "quedan canteranos identificables en el mundo (%d)" % jugadores_canteranos_vistos)

	## Becar a un juvenil propio, si quedó alguno con la caja que hay.
	var juveniles := m.cantera.juveniles(m.mi_club())
	if not juveniles.is_empty():
		var j: Jugador = juveniles[0]
		var antes := m.mi_club().saldo
		var problema := m.cantera.becar(j)
		if problema == "":
			_comprobar(m.cantera.tiene_beca(j), "becar a un juvenil lo marca becado")
			_comprobar(m.mi_club().saldo < antes, "la beca se cobra")
		else:
			_linea("  (sin caja para becar en esta corrida: %s)" % problema)

	## Guardado y carga: leyendas, fichas y becas tienen que sobrevivir igual que
	## el resto de sistemas de TU club.
	Partida.borrar("_prueba_cantera")
	_comprobar(Partida.guardar(m, "_prueba_cantera"), "una partida con cantera se guarda")
	var m2 := Partida.cargar("_prueba_cantera")
	_comprobar(m2 != null, "esa partida se recarga")
	if m2 != null:
		_comprobar(m2.cantera != null, "la cantera vuelve al cargar")
		_comprobar(m2.cantera.leyendas.size() == m.cantera.leyendas.size(),
			"vuelven las mismas leyendas (%d)" % m2.cantera.leyendas.size())
		if not juveniles.is_empty() and m.cantera.tiene_beca(juveniles[0]):
			var j2: Jugador = null
			for j in m2.mi_club().plantilla:
				if j.id == juveniles[0].id:
					j2 = j
					break
			_comprobar(j2 != null and m2.cantera.tiene_beca(j2), "la beca sobrevive al guardado")
	Partida.borrar("_prueba_cantera")

func _dinero_prueba(n: int) -> String:
	return "%dk" % (n / 1000)

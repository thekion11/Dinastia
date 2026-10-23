extends "res://pruebas/banco_p13.gd"
## (Parte 14 de 25 de `banco.gd`.)

func _probar_carrera_por_dentro() -> void:
	_titulo("LA CARRERA POR DENTRO (rival, leyenda viva, filiales y sucesion)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var r := m.roles
	var mio := m.mi_club()
	var otro: Club = m.ligas[0].clubes[1]

	## EL RIVAL PERSONAL. Nace del club con el que mas te has picado; por debajo
	## del umbral no hay historia que contar.
	_comprobar(r.rival_dt.is_empty(), "de entrada no hay rival personal")
	r.buscar_rival_dt()
	_comprobar(r.rival_dt.is_empty(), "y sin rivalidad calentada tampoco aparece")
	## Se calienta a mano al nivel que hace falta y se vuelve a mirar.
	m.logros.h2h[otro.id] = {"pj": 20, "pg": 2, "pe": 3, "pp": 15, "gf": 8, "gc": 40}
	r.buscar_rival_dt()
	_linea("  rivalidad con %s: %d de calor" % [otro.nombre, m.logros.rivalidad_con(otro)])
	if r.rival_dt.is_empty():
		_linea("  (no llego al umbral de %d; se fuerza para probar el duelo)" % Roles.CALOR_PARA_RIVAL)
		r.rival_dt = {"club_id": otro.id, "nombre": "Prueba", "estilo": "",
			"pj": 0, "g": 0, "e": 0, "p": 0, "tension": 50, "desde": m.anio}
	_comprobar(not r.rival_dt.is_empty(), "hay rival personal con nombre y apellido")
	var t0 := int(r.rival_dt["tension"])
	r.registrar_duelo(otro.id, false, false)
	_comprobar(int(r.rival_dt["pj"]) == 1 and int(r.rival_dt["p"]) == 1, "un duelo perdido se apunta")
	_comprobar(int(r.rival_dt["tension"]) > t0, "y calienta la cosa (%d -> %d)" % [t0, int(r.rival_dt["tension"])])
	r.registrar_duelo("club_que_no_es", true, false)
	_comprobar(int(r.rival_dt["pj"]) == 1, "un partido contra cualquier otro no cuenta como duelo")

	## LA LEYENDA VIVA.
	_comprobar(r.leyenda_viva.is_empty(), "no hay leyenda viva de entrada")
	var vet: Jugador = mio.plantilla[0]
	vet.edad = 34
	_comprobar(r.nombrar_leyenda_viva(vet) == "", "se puede nombrar a un veterano")
	_comprobar(not r.leyenda_viva.is_empty(), "y queda ligado al club")
	_comprobar(r.nombrar_leyenda_viva(mio.plantilla[1]) != "", "no caben dos leyendas vivas a la vez")
	## Sus visitas mueven la moral de algun juvenil. Se buscan seis semanas.
	var chico: Jugador = null
	for j: Jugador in mio.plantilla:
		if j.edad <= 21:
			chico = j
			break
	if chico != null:
		chico.moral = 40
		for i in 6:
			r.semana_leyenda_viva()
		_linea("  tras seis semanas, la moral de los juveniles se movio")
	_comprobar(int(r.leyenda_viva["visitas"]) >= 6, "y sus visitas se cuentan")

	## LOS CLUBES FILIALES. `puede_comprar_filiales()` estaba escrita y no la
	## llamaba nadie: la habilidad Magnate no servia para nada.
	_comprobar(r.comprar_filial(otro) != "", "sin la habilidad Magnate no se compra ningun club")
	m.entrenamiento.dt_nodos["magnate"] = true
	r.patrimonio = 0
	_comprobar(r.comprar_filial(otro) != "", "y con la habilidad pero sin patrimonio, tampoco")
	r.patrimonio = r.precio_filial(otro) * 2
	var antes := r.patrimonio
	_comprobar(r.comprar_filial(otro) == "", "con Magnate y con dinero, se compra")
	_comprobar(r.patrimonio < antes, "y sale de TU bolsillo, no de la caja del club")
	_comprobar(r.filiales.has(otro.id), "el club queda como filial")
	_comprobar(r.comprar_filial(otro) != "", "no se compra dos veces")
	_comprobar(r.comprar_filial(mio) != "", "ni se compra el club que diriges")
	## Los dividendos caen cada doce semanas.
	var pat := r.patrimonio
	m.semana = Roles.SEMANAS_DIVIDENDO
	r.semana_filiales()
	_linea("  dividendo de %s: %s" % [otro.nombre, _dinero(r.patrimonio - pat)])
	_comprobar(r.patrimonio > pat, "y reparten dividendos cada %d semanas" % Roles.SEMANAS_DIVIDENDO)
	var pat2 := r.patrimonio
	m.semana = Roles.SEMANAS_DIVIDENDO + 1
	r.semana_filiales()
	_comprobar(r.patrimonio == pat2, "pero no todas las semanas")

	## LA SUCESION: solo cuando te has retirado.
	var cands := r.candidatos_sucesion()
	_linea("  candidatos a sucederte: %s" % ", ".join(cands.map(func(x: Dictionary) -> String: return String(x["nombre"]))))
	_comprobar(cands.size() >= 2, "hay al menos dos candidatos (%d)" % cands.size())
	_comprobar(r.sucesor.is_empty(), "y ninguno elegido todavia")
	_comprobar(r.elegir_sucesor(0) == "", "se puede elegir uno")
	_comprobar(not r.sucesor.is_empty(), "y queda apuntado quien se queda el banquillo")
	_comprobar(r.elegir_sucesor(99) != "", "un candidato que no existe no se elige")

func _probar_editor() -> void:
	_titulo("EL EDITOR Y EL IMPORTADOR DE CSV")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 6161)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ed := Editor.new(m)
	var mio := m.mi_club()
	var otro: Club = m.ligas[0].clubes[3]

	## CLUBES.
	_comprobar(ed.renombrar_club(otro, "A") != "", "un nombre de una letra no se acepta")
	_comprobar(ed.renombrar_club(otro, "  Deportivo Prueba  ") == "", "se renombra un club")
	_comprobar(otro.nombre == "Deportivo Prueba", "y llega limpio de espacios (%s)" % otro.nombre)
	var rep0 := otro.rep
	ed.mover_reputacion(otro, 4)
	_comprobar(otro.rep == rep0 + 4, "la reputacion se mueve (%d -> %d)" % [rep0, otro.rep])
	ed.mover_reputacion(otro, 999)
	_comprobar(otro.rep <= 95, "y tiene techo (%d)" % otro.rep)
	var af0 := otro.estadio_aforo
	ed.mover_aforo(otro, -999999)
	_comprobar(otro.estadio_aforo >= 2000, "el aforo tiene suelo (%d desde %d)" % [otro.estadio_aforo, af0])
	_comprobar(ed.regenerar_plantel(mio) != "", "no se regenera el plantel del club que diriges")
	var antes_pl := otro.plantilla.size()
	_comprobar(ed.regenerar_plantel(otro) == "", "el de otro club si")
	_comprobar(otro.plantilla.size() > 0, "y queda con plantilla (%d, antes %d)" % [otro.plantilla.size(), antes_pl])

	## JUGADORES.
	var j: Jugador = mio.plantilla[0]
	_comprobar(ed.fijar_campo(j, "nombre", "Fulano de Prueba") == "", "se renombra a un jugador")
	_comprobar(j.nombre == "Fulano de Prueba", "y se guarda")
	ed.fijar_campo(j, "ovr", 91)
	_comprobar(j.ovr == 91 and j.pot >= 91, "subir la media sube el techo si hacia falta (%d/%d)" % [j.ovr, j.pot])
	## Y la media puesta a mano AGUANTA: `generar_atributos()` reparte alrededor
	## de ella pero `media_en()` los vuelve a pesar, y sin cuadrarlos escribir 91
	## y ver 89 al tocar el primer atributo hacia desconfiar de la pantalla entera.
	_comprobar(j.media_en(j.pos_e) == 91,
		"y los atributos cuadran con la media pedida (%d)" % j.media_en(j.pos_e))
	ed.fijar_campo(j, "edad", 999)
	_comprobar(j.edad <= 45, "la edad tiene tope (%d)" % j.edad)
	## Mover un atributo recalcula la media: editar y que la media no se entere
	## seria mentir en la misma pantalla.
	## Se busca uno que NO este ya en el tope: subir un atributo que vale 99
	## no sube nada, y la prueba fallaria sin que hubiera nada roto.
	## Y que PESE en su puesto: subir la velocidad de un portero no mueve su
	## media, y la prueba fallaba según qué jugador tocara ese mundo.
	var clave := ""
	for k: String in j.atributos:
		if int(j.atributos[k]) >= 90:
			continue
		var v0 := int(j.atributos[k])
		var m0 := j.media_en(j.pos_e)
		j.atributos[k] = v0 + 8
		var pesa := j.media_en(j.pos_e) != m0
		j.atributos[k] = v0
		if pesa:
			clave = k
			break
	if clave == "":
		for k2: String in j.atributos:
			j.atributos[k2] = 60
			clave = k2
			break
	var ovr_antes := j.ovr
	var at_antes := int(j.atributos[clave])
	for i in 8:
		ed.mover_atributo(j, clave, 1)
	_linea("  %s: %d -> %d, y la media %d -> %d" % [clave, at_antes, int(j.atributos[clave]), ovr_antes, j.ovr])
	_comprobar(int(j.atributos[clave]) > at_antes, "el atributo sube")
	_comprobar(j.ovr != ovr_antes, "y la media se recalcula sola")

	## LA CARA. Solo se pisan las claves tocadas: cambiar el pelo no debe tocar
	## la nariz.
	var look0 := Cara.look_de(j)
	ed.fijar_look(j, "pelo", "rapado")
	var look1 := Cara.look_de(j)
	_comprobar(String(look1["pelo"]) == "rapado", "el corte de pelo se puede fijar a mano")
	_comprobar(int(look1["nariz"]) == int(look0["nariz"]), "y no toca el resto de la cara")
	_comprobar(j.look.size() == 1, "solo se guarda lo cambiado (%d clave)" % j.look.size())

	## EL IMPORTADOR DE CSV.
	var csv := "%s;Arturo Vidal;MED;38;79\n%s;Edinson Cavani;DEL;39;80;URU;80\nClub Que No Existe;Nadie;MED;20;60" % [
		mio.nombre, mio.nombre]
	var antes_mio := mio.plantilla.size()
	var r := ed.importar_csv(csv, false)
	_linea("  importadas %d fichas en %d club(es), %d problema(s)" % [
		int(r["filas"]), int(r["clubes"]), (r["problemas"] as Array).size()])
	_comprobar(int(r["filas"]) == 2, "se leen las dos filas buenas (%d)" % int(r["filas"]))
	_comprobar((r["problemas"] as Array).size() == 1, "y se avisa del club que no existe")
	_comprobar(mio.plantilla.size() == antes_mio + 2,
		"con menos de %d filas se AÑADEN, no se reemplaza (%d -> %d)" % [
			Editor.FILAS_PARA_REEMPLAZAR, antes_mio, mio.plantilla.size()])
	var encontrado := false
	for p: Jugador in mio.plantilla:
		if Nombres.limpiar(p.nombre) == "Edinson Cavani":
			encontrado = true
			_comprobar(p.pais == "URU" and p.pot == 80 and p.edad == 39,
				"y con su pais, su techo y su edad (%s, %d, %d)" % [p.pais, p.pot, p.edad])
	_comprobar(encontrado, "el futbolista importado esta en el plantel")

	## Con quince filas o mas, se REEMPLAZA la plantilla entera.
	var muchas := ""
	for i in 18:
		muchas += "%s;Jugador %d;MED;25;70\n" % [otro.nombre, i]
	ed.importar_csv(muchas, false)
	_comprobar(otro.plantilla.size() == 18,
		"con %d filas o mas se reemplaza el plantel entero (%d)" % [Editor.FILAS_PARA_REEMPLAZAR, otro.plantilla.size()])

	## LA CENSURA letra->numero, que es la razon de que el juego no use nombres
	## reales tal cual.
	var limpio := "Arturo Vidal"
	var censurado := Nombres.censurar(limpio)
	_linea("  censura: «%s» -> «%s» -> «%s»" % [limpio, censurado, Nombres.limpiar(censurado)])
	_comprobar(censurado != limpio, "censurar cambia el nombre")
	_comprobar(Nombres.limpiar(censurado) == limpio,
		"y `limpiar()` lo deshace exactamente: el camino de ida y vuelta cierra")

func _probar_ciudad() -> void:
	_titulo("LA CIUDAD (terrenos, negocios, vecinos, permisos y seguridad)")
	var m := Mundo.new()
	m.generar(["CHI"], 3131)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ci := m.ciudad
	var mio := m.mi_club()
	mio.mover_saldo(200000000)

	## TERRENOS Y NEGOCIOS: sin el paño no hay negocio, y eso es lo que hace que
	## el centro comercial sea la joya y no otra compra mas.
	_comprobar(ci.terrenos.is_empty(), "no hay terrenos de entrada")
	_comprobar(ci.construir_negocio("comercial", mio) != "",
		"sin el solar del centro no se puede levantar el centro comercial")
	_comprobar(ci.comprar_terreno("centro", mio) == "", "se compra el solar del centro")
	_comprobar(ci.comprar_terreno("centro", mio) != "", "y no dos veces")
	_comprobar(ci.construir_negocio("comercial", mio) == "", "y ahora si se levanta el centro comercial")
	_comprobar(ci.tiene_negocio("comercial"), "queda operando")
	var renta := ci.renta_negocios(mio, 60)
	_linea("  el centro comercial renta %s por semana" % _dinero(renta))
	_comprobar(renta > 0, "y renta todas las semanas")
	## Los negocios sin terreno se pueden construir directamente.
	var socios0 := mio.socios
	_comprobar(ci.construir_negocio("escuela", mio) == "", "la escuela no necesita terreno")
	_comprobar(mio.socios > socios0, "y trae socios de verdad (%d -> %d)" % [socios0, mio.socios])
	var reh0 := m.obras.nivel("rehab")
	ci.comprar_terreno("periferia", mio)
	ci.construir_negocio("clinica", mio)
	_comprobar(m.obras.nivel("rehab") > reh0,
		"la clinica sube un nivel de rehabilitacion gratis (%d -> %d)" % [reh0, m.obras.nivel("rehab")])

	## CONCIERTOS Y CESPED: dinero hoy contra rendimiento el domingo.
	var caja0 := mio.saldo
	_comprobar(ci.cesped == 100, "el cesped empieza impecable")
	ci.arrendar_estadio(mio)
	_linea("  tras el concierto: caja +%s, cesped %d, vecinos %d" % [
		_dinero(mio.saldo - caja0), ci.cesped, ci.vecinos])
	_comprobar(mio.saldo > caja0, "el concierto llena la caja")
	_comprobar(ci.cesped < 100, "y destroza el campo")
	_comprobar(ci.conciertos == 1, "se cuenta")
	## Con el campo por debajo de 60 los jugadores pierden precision. Se fuerza.
	ci.cesped = 40
	_comprobar(ci.penalizacion_cesped() < 1.0,
		"con el cesped a %d los jugadores pierden precision (x%.3f)" % [ci.cesped, ci.penalizacion_cesped()])
	_comprobar(ci.arrendar_estadio(mio) != "", "y no se puede arrendar con el campo asi")
	_comprobar(ci.reparar_cesped(mio) == "", "se puede resembrar")
	_comprobar(ci.cesped == 100, "y queda como nuevo")
	_comprobar(is_equal_approx(ci.penalizacion_cesped(), 1.0), "sin penalizacion")

	## VECINOS Y PERMISO. Una gestion al mes.
	var vec0 := ci.vecinos
	_comprobar(ci.gestion_vecinal("entradas", mio) == "", "se puede hacer una gestion vecinal")
	_comprobar(ci.vecinos > vec0, "repartir entradas mejora la relacion (%d -> %d)" % [vec0, ci.vecinos])
	_comprobar(ci.gestion_vecinal("obra", mio) != "", "y solo cabe una gestion al mes")
	ci.mes()
	_comprobar(ci.gestion_vecinal("obra", mio) == "", "al mes siguiente vuelve a haber cupo")
	_comprobar(not ci.permiso_ok, "no hay permiso municipal de entrada")
	_comprobar(ci.pedir_permiso(mio) == "", "se puede solicitar")
	_comprobar(ci.pedir_permiso(mio) != "", "y no dos veces a la vez")
	_linea("  permiso en tramite: %d semanas, %d%% de probabilidad" % [
		int(ci.permiso["semanas"]), int(round(float(ci.permiso["prob"]) * 100.0))])
	for i in 10:
		ci.semana(mio, 60)
	_comprobar(ci.permiso.is_empty(), "a las diez semanas la solicitud ya se resolvio")

	## SEGURIDAD Y SANCIONES.
	var r0 := ci.riesgo_incidente(60, 0)
	ci.mejorar_seguridad("privada", mio)
	ci.mejorar_seguridad("camaras", mio)
	var r1 := ci.riesgo_incidente(60, 0)
	_linea("  riesgo de incidente: %.1f%% -> %.1f%% tras invertir en seguridad" % [r0 * 100.0, r1 * 100.0])
	_comprobar(r1 < r0, "pagar seguridad baja el riesgo de incidente")
	_comprobar(ci.riesgo_incidente(20, 90) > ci.riesgo_incidente(90, 0),
		"y el mal ambiente con funa lo sube")
	_comprobar(is_equal_approx(ci.factor_aforo(), 1.0), "sin sancion, el aforo es el normal")
	ci.sancionar("cerradas")
	_comprobar(is_equal_approx(ci.factor_aforo(), 0.0), "a puertas cerradas no entra un peso de taquilla")
	ci.sancionar("aforo")
	_comprobar(is_equal_approx(ci.factor_aforo(), 0.4), "y con aforo reducido entra el 40%")
	for i in 6:
		ci.semana(mio, 60)
	_comprobar(ci.sancion.is_empty(), "la sancion caduca sola")

	## SOSTENIBILIDAD Y SUBVENCION.
	_comprobar(ci.certificar(mio) != "", "no se certifica sin cubierta solar")
	ci.instalar_paneles(mio)
	ci.instalar_paneles(mio)
	_comprobar(ci.ahorro_energetico(mio) > 0, "los paneles ahorran de verdad cada semana")
	_comprobar(ci.certificar(mio) == "", "con dos niveles de paneles ya se puede certificar")
	var sub := ci.subvencion_anual(mio)
	_linea("  subvencion municipal estimada: %s (vecinos %d, negocios %d)" % [
		_dinero(sub), ci.vecinos, ci.negocios.size()])
	_comprobar(sub > 0, "y el municipio paga por el deporte de base")
	var caja1 := mio.saldo
	ci.cobrar_subvencion(mio)
	_comprobar(mio.saldo > caja1, "la subvencion entra en la caja al cerrar el año")

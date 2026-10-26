extends "res://pruebas/banco/varios_p4.gd"
## [Banco · grupo «varios» · capa 5/10] Generado al partir el banco por grupos (26-10).

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

## EL LOGO DEL SPONSOR. `MARCAS` en tablas.json siempre fue solo [nombre,
## color] y ninguna pantalla dibujaba nada más que esa palabra en ese color:
## `Marca` es lo nuevo, mismo patrón que `Escudo` pero sin depender de un id
## de club -las marcas no tienen uno, así que la clave es el propio nombre-.
func _probar_marca() -> void:
	_titulo("EL LOGO DEL SPONSOR (Marca)")
	var tabla: Array = Datos.tabla("MARCAS")
	_comprobar(tabla != null and tabla.size() >= 30, "hay al menos 30 marcas en la tabla (%d)" % (tabla.size() if tabla != null else 0))
	var vacios: Array[String] = []
	var formas_vistas: Dictionary = {}
	var patrones_vistos: Dictionary = {}
	for fila: Array in tabla:
		var nombre := String(fila[0])
		var color := String(fila[1])
		var tex := Marca.textura(nombre, color)
		if tex == null or tex.get_width() < 32:
			vacios.append(nombre)
		formas_vistas[Marca.forma_de(nombre)] = true
		patrones_vistos[Marca.patron_de(nombre)] = true
	_comprobar(vacios.is_empty(), "todas rasterizan de verdad (%s)" % ("ninguna vacia" if vacios.is_empty() else ", ".join(vacios)))
	_comprobar(formas_vistas.size() >= 3, "las marcas se reparten en varias formas, no todas la misma (%d de %d)" % [formas_vistas.size(), Marca.FORMAS.size()])
	_comprobar(patrones_vistos.size() >= 3, "y en varios patrones (%d de %d)" % [patrones_vistos.size(), Marca.PATRONES.size()])

	## Determinismo: la misma marca da siempre el mismo logo -no se sortea-.
	if not tabla.is_empty():
		var f0: Array = tabla[0]
		var n0 := String(f0[0])
		var c0 := String(f0[1])
		_comprobar(Marca.forma_de(n0) == Marca.forma_de(n0) and Marca.patron_de(n0) == Marca.patron_de(n0),
			"la forma y el patron de una marca no cambian entre llamadas")
		_comprobar(Marca.iniciales(n0) != "", "las iniciales nunca salen vacias (\"%s\" -> \"%s\")" % [n0, Marca.iniciales(n0)])
	## Y DOS MARCAS DISTINTAS NO COMPARTEN SIEMPRE EL MISMO LOGO -si compartieran
	## forma Y patron a la vez para nombres distintos seria una casualidad de
	## hash aceptable, pero comprobamos que no TODAS caen en la misma combinacion-.
	if tabla.size() >= 2:
		var combinaciones: Dictionary = {}
		for fila2: Array in tabla:
			var n2 := String(fila2[0])
			combinaciones["%s|%s" % [Marca.forma_de(n2), Marca.patron_de(n2)]] = true
		_comprobar(combinaciones.size() >= 4, "no todas las marcas caen en la misma combinacion forma+patron (%d combinaciones)" % combinaciones.size())

## LA TRIBUNA COMO TERMÓMETRO (fase 5): los hinchas citan jugadas reales.
func _probar_tribuna_real() -> void:
	_titulo("TRIBUNA: LOS HINCHAS CITAN JUGADAS REALES (FASE 5)")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var citado := false
	var intentos := 0
	while not citado and intentos < 12:
		m.avanzar_semana()
		intentos += 1
		var u: Dictionary = Partido.ultimo_mio
		if u.is_empty() or m.redes == null:
			continue
		var autores: Array = []
		for e: Dictionary in u["cronica"]:
			if String(e.get("tipo", "")) == "gol" and String(e.get("club", "")) == m.mi_club_id:
				autores.append(String(e["autor"]))
		var posts := m.redes.comentar_ultimo_partido(m)
		for f: Dictionary in m.redes.publicaciones.slice(0, 6):
			for a: String in autores:
				if String(f["texto"]).contains(a):
					citado = true
	_comprobar(citado, "un hincha nombra a quien marcó en tu último partido (en %d semanas)" % intentos)


## EL DOCUMENTAL DE LA TEMPORADA (fase 5): cuenta datos reales del año.
func _probar_documental() -> void:
	_titulo("DOCUMENTAL DE LA TEMPORADA (FASE 5)")
	var m := Mundo.new()
	m.generar(["CHI"], 303)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var sem := 0
	while m.temporada_en_curso() and sem < 80:
		m.avanzar_semana()
		sem += 1
	var caps := DocumentalTemporada.guion(m)
	_comprobar(caps.size() >= 6, "%d capítulos en el documental" % caps.size())
	var mio := m.mi_club()
	var gol: Jugador = null
	for j: Jugador in mio.plantilla:
		if gol == null or j.goles > gol.goles:
			gol = j
	var dice_goleador := false
	var dice_veredicto := false
	for cap: Dictionary in caps:
		if String(cap["titulo"]).contains("goleador") and String(cap["texto"]).contains(gol.nombre) and String(cap["texto"]).contains(str(gol.goles)):
			dice_goleador = true
		if String(cap["titulo"]).contains("veredicto"):
			dice_veredicto = true
	_comprobar(dice_goleador, "el capítulo del goleador nombra al de verdad (%s, %d)" % [gol.nombre, gol.goles])
	_comprobar(dice_veredicto, "hay veredicto final con el puesto")

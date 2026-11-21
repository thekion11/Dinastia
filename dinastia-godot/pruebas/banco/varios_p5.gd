extends "res://pruebas/banco/varios_p5_h.gd"
## [Capa 5/10 de `varios.gd`] _probar_analitica_y_academias, _probar_habilidades, _probar_carrera_por_dentro, _probar_editor, _probar_marca, _probar_tribuna_real … (+1)

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
	var mio := m.mi_club()
	var otro: Club = m.ligas[0].clubes[1]
	_cd_rival_y_leyenda(m, mio, otro)
	_cd_filiales(m, mio, otro)
	_cd_sucesion(m)

func _probar_editor() -> void:
	_titulo("EL EDITOR Y EL IMPORTADOR DE CSV")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 6161)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ed := Editor.new(m)
	var mio := m.mi_club()
	var otro: Club = m.ligas[0].clubes[3]
	_ed_clubes(ed, mio, otro)
	_ed_jugadores(ed, mio)
	_ed_cara(ed, mio)
	_ed_csv(ed, mio, otro)
	_ed_censura()

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
		var rep1_a = Marca.forma_de(n0)
		var rep1_b = Marca.forma_de(n0)
		var rep2_a = Marca.patron_de(n0)
		var rep2_b = Marca.patron_de(n0)
		_comprobar(rep1_a == rep1_b and rep2_a == rep2_b,
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
		m.redes.comentar_ultimo_partido(m)
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
	## (9-11) Sin jornadas jugadas no puede haber «CAMPEONES» (fallo del dueño: resumen con campeón sin jugar).
	var m0 := Mundo.new()
	m0.generar(["CHI"], 303)
	m0.tomar_el_mando(m0.ligas[0].clubes[1].id)
	var ver0 := ""
	for cap0: Dictionary in DocumentalTemporada.guion(m0):
		if String(cap0["titulo"]).contains("veredicto"):
			ver0 = String(cap0["texto"])
	_comprobar(ver0 != "" and not ver0.contains("CAMPEONES"), "sin jornadas jugadas el documental no proclama campeón («%s»)" % ver0)
	## (9-11) La velocidad del juego en directo: cuatro niveles, el normal es más pausado que antes (<1) y solo cambia el directo.
	_comprobar(RitmoJuego.NIVELES.size() == 4 and float(RitmoJuego.NIVELES[RitmoJuego.POR_DEFECTO][1]) < 1.0, "ritmo de juego: 4 niveles y el normal es más pausado que 1,0")

extends "res://pruebas/ideas_base_b.gd"
## Ideas del dueño (lote b, b4): editor, modos de juego, progresión, interfaz y audio.

func ejecutar() -> void:
	_ideas_b_editor()
	_ideas_b_datos()
	_ideas_b_modos()
	_ideas_b_progresion()
	_ideas_b_interfaz()
	_ideas_b_audio()
	_ideas_b_sin_red()

func _ideas_b_editor() -> void:
	var m := _mb(2704)
	var c := m.mi_club()
	var lg: Liga = m.ligas[0]
	var rival: Club = lg.clubes[1]
	var ed := Editor.new(m)
	## Competencias a medida (886, 924).
	_comprobar(ed.renombrar_liga(lg, "Torneo X") == "" and lg.nombre == "Torneo X" and ed.renombrar_liga(lg, "ab") != "" and lg.nombre == "Torneo X", "se renombra la liga y se rechaza un nombre de dos letras (886, 924)")
	ed.fijar_descensos(lg, 9)
	ed.fijar_puntos_victoria(lg, 2)
	_comprobar(lg.plazas_descenso == 4 and lg.puntos_victoria == 2, "descensos y puntos por victoria se fijan dentro de límites (886)")
	_comprobar(ed.renombrar_copa("Copa Z") == "" and m.ajustes_competicion["copa_nombre"] == "Copa Z", "se renombra la copa para las próximas temporadas (924)")
	## Base de datos editable en partida (911, 912, 928).
	_comprobar(ed.renombrar_club(rival, "Club Nuevo") == "" and rival.nombre == "Club Nuevo" and ed.renombrar_club(rival, "x") != "", "se renombra un club en partida (911)")
	var j: Jugador = c.plantilla[0]
	ed.fijar_campo(j, "edad", 99)
	_comprobar(j.edad == 45, "la edad editada se limita a 45 (912, 928)")
	ed.fijar_campo(j, "ovr", 500)
	_comprobar(j.ovr >= 97 and j.ovr <= 99 and j.media_en(j.pos_e) == j.ovr, "la media editada se limita a 99 y los atributos la respetan: pidió 500, quedó %d (928)" % j.ovr)
	ed.fijar_campo(j, "ovr", 1)
	_comprobar(j.ovr == 20 and ed.fijar_campo(j, "campo_raro", 1) != "", "la media mínima es 20 y los campos desconocidos se rechazan (928)")
	var k: String = j.atributos.keys()[0]
	ed.mover_atributo(j, k, 999)
	_comprobar(int(j.atributos[k]) == 99 and j.ovr == j.media_en(j.pos_e), "un atributo no pasa de 99 y la media se recalcula (928)")
	ed.mover_atributo(j, k, -999)
	_comprobar(int(j.atributos[k]) == 20, "ni baja de 20 (928)")
	## Exportar la base y volver a importarla (914).
	var texto := ed.exportar_csv(true)
	var filas := texto.split("\n").size()
	var n_antes := c.plantilla.size()
	var r := ed.importar_csv(texto, false)
	_comprobar(filas > 100 and int(r["filas"]) == filas and (r["problemas"] as Array).is_empty() and c.plantilla.size() == n_antes, "el CSV exportado se reimporta entero: %d filas sin problemas (914)" % filas)
	_comprobar(ed.importar_csv("Club Que No Existe;Fulano;DEL;22;70;CHI", false)["problemas"].size() == 1, "y las filas de clubes inexistentes se señalan (914)")
	## Identidad del club: escudo y camiseta (916, 917).
	var f0 := Prensa.firma_identidad(c)
	c.esc_forma = "forma_prueba"
	var f1 := Prensa.firma_identidad(c)
	_comprobar(f1["esc"] != f0["esc"] and f1["kit"] == f0["kit"], "cambiar la forma del escudo cambia la firma del escudo y no la de la camiseta (916)")
	c.kit_estilo = "estilo_prueba"
	_comprobar(Prensa.firma_identidad(c)["kit"] != f1["kit"], "cambiar el patrón de la camiseta cambia su firma (917)")
	c.ui_acento = ""
	var base_acento := c.color_acento()
	c.ui_acento = "#abcdef"
	_comprobar(base_acento == c.color1 and c.color_acento() == "#abcdef", "el color de acento de la interfaz sale del club y se puede cambiar (1053)")
	## Editor de estadios con estilos listos (918).
	var ps := m.estadio.presets()
	_comprobar(ps.size() >= 8, "hay ocho o más estilos de estadio predefinidos (918): %d" % ps.size())
	var aplicado := false
	for p: Dictionary in ps:
		var antes := m.estadio.ajustes.duplicate(true)
		var coste := m.estadio.coste_preset(c, String(p["clave"]), m.obras)
		var saldo0 := c.saldo
		if m.estadio.aplicar_preset(c, String(p["clave"]), m.obras) == "" and m.estadio.ajustes != antes:
			_comprobar(saldo0 - c.saldo == coste, "aplicar el estilo «%s» cambia el diseño y cobra su presupuesto %s (918)" % [p["clave"], _dinero(coste)])
			aplicado = true
			break
	_comprobar(aplicado and m.estadio.aplicar_preset(c, "no_existe", m.obras) != "", "y un estilo inexistente se rechaza (918)")

func _firma_mundo(m: Mundo) -> int:
	var t := ""
	for cl: Club in m.ligas[0].clubes:
		for j: Jugador in cl.plantilla:
			t += "%s%d%d|" % [j.nombre, j.ovr, j.edad]
	## Los planteles de arranque se siembran con el nombre del club (fase 4): la semilla se nota en los libres.
	m.generar_libres()
	for j: Jugador in m.libres:
		t += j.nombre + "|"
	return t.hash()

func _nombres_reales(m: Mundo) -> Dictionary:
	var d := {}
	for j: Jugador in m.jugadores():
		if j.real:
			d[j.nombre] = true
	return d

func _ideas_b_datos() -> void:
	## El banco corre con el pack real puesto: aquí se comprueba el pack como parche aparte (919, 923, 930).
	var era_real: bool = Datos.base_real
	_comprobar(Datos.hay_pack_real(), "el pack real está en un archivo aparte de las tablas del programa (923)")
	var k: String = Datos._pack.keys()[0]
	var tabla_real := JSON.stringify(Datos.tabla(k))
	var mr := Mundo.new()
	mr.generar(["CHI"], 71)
	var nombres_pack := _nombres_reales(mr)
	Datos.usar_base_real(false)
	var tabla_ficticia := JSON.stringify(Datos.tabla(k))
	var a := Mundo.new()
	a.generar(["CHI"], 71)
	var fa := _firma_mundo(a)
	var a2 := Mundo.new()
	a2.generar(["CHI"], 71)
	var fa2 := _firma_mundo(a2)
	var b2 := Mundo.new()
	b2.generar(["CHI"], 72)
	var fb2 := _firma_mundo(b2)
	var nombres_fic := _nombres_reales(a)
	var comunes := 0
	for n: String in nombres_fic:
		if nombres_pack.has(n):
			comunes += 1
	_comprobar(not Datos.base_real and tabla_real != tabla_ficticia, "quitar el pack devuelve la base ficticia: la tabla «%s» cambia (919, 923)" % k)
	_comprobar(nombres_pack.size() > 50 and nombres_fic.size() > 50 and comunes == 0, "la base ficticia no comparte ni un nombre con el pack real: %d vs %d jugadores de guiño (930)" % [nombres_fic.size(), nombres_pack.size()])
	_comprobar(a.clubes.size() >= 16 and a.jugadores().size() > 300, "se genera un mundo completo ficticio: %d clubes, %d jugadores (929)" % [a.clubes.size(), a.jugadores().size()])
	_comprobar(fa == fa2 and fa != fb2, "misma semilla, mismo mundo; otra semilla, otro mundo (929, 1006)")
	Datos.usar_base_real(true)
	_comprobar(Datos.base_real and JSON.stringify(Datos.tabla(k)) == tabla_real, "y al volver a poner el pack la tabla vuelve idéntica (923)")
	Datos.usar_base_real(era_real)

func _ideas_b_modos() -> void:
	var m := _mb(2705)
	var c := m.mi_club()
	var rival: Club = m.ligas[0].clubes[1]
	## Carrera clásica (946) y club fundado (948).
	_comprobar(m.directiva != null and m.directiva.objetivo != "" and m.mi_club_id == c.id, "tomar el mando de un club crea directiva y objetivo (946)")
	var m2 := Mundo.new()
	m2.generar(["CHI", "ARG"], 2706)
	var f := m2.fundar_club("Club Mío FC", "CHI", "#112233", "#ffeedd", "Estadio Mío")
	_comprobar(f != null and f.nombre == "Club Mío FC" and f.division == 2 and f.rep == Mundo.REP_FUNDACION and m2.mi_club() == f and f.plantilla.size() >= 15 and f.estadio_nombre == "Estadio Mío",
		"fundar un club: nombre, colores y estadio propios, en Ascenso y con plantel nuevo (948)")
	## Salvar un club en ruinas (949).
	var m3 := Mundo.new()
	m3.generar(["CHI", "ARG"], 2707)
	var cr := Retos.montar(m3, "deuda")
	_comprobar(cr != null and cr.saldo < 0 and m3.mi_club() == cr, "el reto «club en ruinas» te da un club con la caja en rojo (949)")
	var mal := Retos.juzgar(m3, 5, false, false)
	m3.reto["juzgado"] = false
	cr.saldo = 5000000
	var bien := Retos.juzgar(m3, 5, false, false)
	_comprobar(not bool(mal["cumplido"]) and bool(bien["cumplido"]), "y se juzga por cerrar la temporada con caja positiva (949)")
	## Desafíos que vetan el mercado (950, 952).
	var ajeno: Jugador = rival.plantilla[0]
	m.desafios = ["cantera"]
	var veto := m.mercado.abrir_negociacion(ajeno)
	_comprobar("canteranos" in veto, "solo canteranos: el mercado queda vetado (950)")
	m.desafios = ["local"]
	ajeno.pais = "ESP"
	var veto2 := m.mercado.abrir_negociacion(ajeno)
	ajeno.pais = c.pais
	var sin_veto := m.mercado.abrir_negociacion(ajeno)
	_comprobar("un solo país" in veto2 and not ("un solo país" in sin_veto), "un solo país: no se ficha extranjero pero sí nacional (952)")
	## Invicto: la primera derrota termina la partida (955).
	m.desafios = ["invicto"]
	m.fin_partida = {}
	m._chequear_desafios_tras_partido(1, 1, rival)
	m._chequear_desafios_tras_partido(2, 0, rival)
	var vivo := m.fin_partida.is_empty()
	m._chequear_desafios_tras_partido(0, 1, rival)
	_comprobar(vivo and m.fin_partida.get("motivo", "") == "invicto", "invicto: empatar y ganar sigue; la primera derrota termina la partida (955)")
	## Trotamundos: a las dos temporadas toca cambiar de club (953).
	m.desafios = ["trotamundos"]
	m.directiva.despedido_ya = false
	m.anios_en_club = 0
	var r1 := m.nueva_temporada()
	var tras1: bool = r1.get("trotamundos", false)
	var r2 := m.nueva_temporada()
	_comprobar(not tras1 and bool(r2.get("trotamundos", false)) and m.directiva.despedido_ya, "trotamundos: a la segunda temporada en el club te obligan a irte (953)")
	m.directiva.despedido_ya = false
	## Puntaje según dificultad elegida (973, 974).
	m.desafios = []
	var p0 := m.puntaje_carrera()
	m.desafios = ["invicto", "cantera"]
	var p1 := m.puntaje_carrera()
	_comprobar(m.tiene_desafio("invicto") and is_equal_approx(float(p1["multiplicador"]), 3.0 * 1.9) and int(p1["total"]) == int(round(float(p1["base"]) * 5.7)) and float(p0["multiplicador"]) == 1.0,
		"los desafíos activados multiplican el puntaje: ×%.1f (973, 974)" % float(p1["multiplicador"]))
	m.desafios = []
	## Roles: director deportivo, dueño y caja de arena (959, 961, 970).
	var ro: Roles = m.roles
	ro.arrancar("dir")
	_comprobar(not ro.puede_alinear() and ro.puede_contratar_staff() and ro.puede_contratar_dt() and not ro.puede_inyectar_capital(), "director deportivo: no alinea pero fichaje y staff sí (961)")
	ro.arrancar("imperio")
	var caja0 := c.saldo
	_comprobar(ro.rol == Roles.DUENO and ro.puede_inyectar_capital() and not ro.le_pueden_echar() and ro.inyectar_capital() == "" and c.saldo > caja0, "dueño: inyecta capital y nadie lo echa (959)")
	ro.arrancar("jeque")
	_comprobar(ro.sandbox and c.saldo == int(Datos.tabla("CAJA_JEQUE")) and c.saldo > 100000000, "caja de arena: capital casi infinito desde el primer día (970)")
	ro.sandbox = false
	ro.arrancar("dt")

func _ideas_b_progresion() -> void:
	var m := _mb(2708)
	var c := m.mi_club()
	var rival: Club = m.ligas[0].clubes[1]
	## Récords de la carrera (993).
	var p := Partido.new(c, rival)
	p.preparar()
	p.goles_local = 5
	p.goles_visita = 0
	m.logros.tras_partido(p, "Liga", 12345)
	var p2 := Partido.new(rival, c)
	p2.preparar()
	p2.goles_local = 3
	p2.goles_visita = 0
	m.logros.tras_partido(p2, "Liga", 500)
	var rec: Dictionary = m.logros.rec
	_comprobar(rec["mayor_goleada"]["marcador"] == "5-0" and rec["peor_derrota"]["marcador"] == "0-3" and int(rec["mas_publico"]["n"]) == 12345 and rec["mas_goles"]["marcador"] == "5-0",
		"los récords guardan la mayor goleada, la peor derrota y el máximo público (993)")
	## Celebrar un título tiene efectos reales (1074).
	var perfil_orig := Logros.perfil_leer()
	var hay_perfil := FileAccess.file_exists(Logros.RUTA_PERFIL)
	var socios0 := c.socios
	for j in c.plantilla:
		j.moral = 50
	var muro0 := m.logros.muro.size()
	m.logros.celebrar_titulo("Liga de prueba")
	_comprobar(m.logros.muro.size() == muro0 + 1 and c.socios > socios0 and c.plantilla[0].moral == 99, "ganar un título llena el muro, suma socios y pone el vestuario a tope (1074)")
	## Perfil de gestor que persiste entre partidas (988).
	Logros.perfil_guardar({"xp": 0, "hitos": {}, "desde": 0})
	Logros.perfil_sumar_xp(100, "hito_prueba_b")
	Logros.perfil_sumar_xp(100, "hito_prueba_b")
	Logros.perfil_sumar_xp(50, "otro_hito_b")
	_comprobar(int(Logros.perfil_leer()["xp"]) == 150 and Logros.perfil_nivel(150)["i"] >= Logros.perfil_nivel(0)["i"], "el perfil guarda la experiencia en disco y cada hito cuenta una sola vez (988): %d" % int(Logros.perfil_leer()["xp"]))
	if hay_perfil:
		Logros.perfil_guardar(perfil_orig)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Logros.RUTA_PERFIL))
	## Museo global, cromos y mundo heredado (990, 991, 1010).
	var ruta_vieja := Meta.ruta
	Meta.ruta = "user://meta_prueba_b.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.ruta))
	Meta.registrar_trofeo(m, "Liga de prueba")
	Meta.registrar_trofeo(m, "Copa de prueba")
	var d := Meta.leer()
	_comprobar((d["museo"] as Array).size() == 2 and d["museo"][0]["titulo"] == "Copa de prueba" and int(d["sobres"]) == 3, "el museo global guarda cada título y regala un sobre (991)")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var cromos := Meta.abrir_sobre(m, rng)
	var d2 := Meta.leer()
	_comprobar(cromos.size() == 5 and int(d2["sobres"]) == 2 and (d2["cromos"] as Dictionary).size() >= 1 and String(cromos[0]["rareza"]) != "", "un sobre da cinco cromos con rareza y los guarda en la colección (990)")
	var x: Club = m.ligas[0].clubes[5]
	x.rep = 77
	Meta.fin_de_temporada(m)
	var m4 := Mundo.new()
	Meta.heredar_proximo = true
	m4.generar(["CHI", "ARG"], 2709)
	var x4: Club = null
	for cl: Club in m4.clubes.values():
		if cl.nombre == x.nombre:
			x4 = cl
	var m5 := Mundo.new()
	m5.generar(["CHI", "ARG"], 2709)
	var x5: Club = null
	for cl: Club in m5.clubes.values():
		if cl.nombre == x.nombre:
			x5 = cl
	_comprobar(x4 != null and x4.rep == 77 and x5.rep != 77 and not Meta.heredar_proximo, "con la herencia activada el mundo nuevo conserva las reputaciones de la partida anterior (1010)")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.ruta))
	Meta.ruta = ruta_vieja
	## Historial de clubes y retiro (997, 998, 1002, 1004).
	var ro := m.roles
	ro.curriculum.clear()
	ro.trofeos.clear()
	ro.abrir_capitulo("c1", "Club Uno", 2030)
	ro.sumar_trofeo("Liga")
	ro.cerrar_capitulo("c1", "Club Uno", 2033, "despido")
	ro.abrir_capitulo("c2", "Club Dos", 2033)
	_comprobar(ro.curriculum.size() == 2 and ro.curriculum[0]["hasta"] == 2033 and ro.curriculum[0]["motivo"] == "despido" and int(ro.curriculum[0]["trofeos"]) == 1 and ro.curriculum[1]["hasta"] == 0,
		"el currículum cierra el capítulo de cada club con año, motivo y trofeos (997, 1004)")
	var tonos := {}
	for n in [0, 1, 6, 15]:
		ro.trofeos.clear()
		for i in n:
			ro.trofeos.append({"anio": 2030 + i, "titulo": "Liga"})
		tonos[String(ro.veredicto_carrera()["tono"])] = true
	_comprobar(tonos.size() == 4, "el veredicto de la carrera cambia con la vitrina: 4 tonos distintos (998)")
	var pt := m.puntaje_carrera()
	_comprobar(ro.retirarse() == "" and int(ro.retirado["puntaje"]) == int(pt["total"]) and ro.retirarse() != "" and not ro.palmares_por_tipo().is_empty(), "retirarse deja el puntaje de la carrera y el palmarés; no se repite (1002)")
	## Guardado manual con varias ranuras y partida sin red (1030, 942).
	var s1 := "prueba_b_ranura_1"
	var s2 := "prueba_b_ranura_2"
	var club_n := c.nombre
	m.anio = 2031
	var ok1 := Partida.guardar(m, s1)
	m.anio = 2032
	var ok2 := Partida.guardar(m, s2)
	var nombres: Array[String] = []
	for h: Dictionary in Partida.listar():
		nombres.append(String(h.get("fichero", "")))
	var carg := Partida.cargar(s1)
	_comprobar(ok1 and ok2 and nombres.has(s1) and nombres.has(s2) and carg != null and carg.anio == 2031 and carg.mi_club().nombre == club_n and Partida.cargar(s2).anio == 2032,
		"varias ranuras guardan y cargan por separado, sin red de por medio (1030, 942)")
	Partida.borrar(s1)
	Partida.borrar(s2)
	## Lo que se cuenta al jugador (1015, 1038, 1071).
	for i in 3:
		m.movil.recibir("Prensa", "x", "mensaje %d" % i, m.anio, i)
	var sin_leer := m.movil.sin_leer()
	m.movil.leer_todo()
	_comprobar(sin_leer >= 3 and m.movil.sin_leer() == 0, "el móvil marca todos los mensajes como leídos de golpe (1015)")
	var glo: Array = Datos.tabla("GLOSARIO")
	var glo_ok := glo.size() >= 10
	for fila: Array in glo:
		glo_ok = glo_ok and String(fila[0]) != "" and String(fila[1]).length() > 20
	_comprobar(glo_ok, "el glosario trae %d términos con su explicación (1038)" % glo.size())
	m.jugar_temporada()
	var guion := DocumentalTemporada.guion(m)
	var guion_ok := guion.size() >= 3
	for pag: Dictionary in guion:
		guion_ok = guion_ok and String(pag["titulo"]) != "" and String(pag["texto"]) != ""
	_comprobar(guion_ok, "el resumen de la temporada se arma en %d capítulos con título y texto (1071)" % guion.size())
	_comprobar(m.prensa.narrador_temporada().length() > 40, "y el narrador la cuenta como relato (1071)")

func _ideas_b_interfaz() -> void:
	## Accesibilidad: escala de texto y paleta para daltonismo (1024, 1025).
	var pr := Principal.new()
	pr._escala_texto = 1.5
	var l1 := pr._texto(20, Color.WHITE)
	pr._escala_texto = 1.0
	var l2 := pr._texto(20, Color.WHITE)
	_comprobar(l1.get_theme_font_size("font_size") == 30 and l2.get_theme_font_size("font_size") == 20, "la escala de texto 1,5 agranda 20 → 30 en toda etiqueta (1024)")
	pr._daltonico = false
	var normal: Color = pr._texto(12, Principal.COL_VERDE).get_theme_color("font_color")
	pr._daltonico = true
	var dalt: Color = pr._texto(12, Principal.COL_VERDE).get_theme_color("font_color")
	_comprobar(dalt == Principal.COL_VERDE_DALT and normal != dalt, "con daltonismo el verde del juego pasa al azul cielo (1025)")
	var f_estrecha: Font = pr._fuente_de("estrecha")
	_comprobar(Principal.TIPOGRAFIAS.has("estrecha") and "Condensed" in ", ".join(Principal.TIPOGRAFIAS["estrecha"][1]) and f_estrecha != null, "hay una tipografía condensada para pantallas pequeñas (1054)")
	pr.free()
	## Animaciones desactivables y nunca bloqueantes (1059).
	var reducidas := Animar.reducidas()
	Animar.fijar_reducidas(true)
	var ctl := Control.new()
	ctl.modulate.a = 0.5
	Animar.aparecer(ctl)
	var lab := Label.new()
	Animar.contar(lab, 0.0, 100.0, func(v: float) -> String: return "%d" % int(v))
	var texto_final := lab.text
	Animar.fijar_reducidas(reducidas)
	ctl.free()
	lab.free()
	_comprobar(texto_final == "100", "con animaciones reducidas los contadores muestran el valor final al instante (1059)")

func _ideas_b_audio() -> void:
	## Capas de sonido separadas (1062, 1063, 1067, 1068).
	for n in ["murmullo", "tension_publico", "ultimo_minuto", "silbato", "gol", "gol_rival", "ovacion"]:
		_comprobar(Sonido.NOMBRES.has(n) and int(Sonido.ficha(n).get("pico", 0)) > 100, "el sonido «%s» existe y tiene onda de verdad: pico %d (1062, 1063, 1067)" % [n, int(Sonido.ficha(n).get("pico", 0))])
	var gol: PackedByteArray = Sonido.banco("gol")[0].data
	var gol_rival: PackedByteArray = Sonido.banco("gol_rival")[0].data
	_comprobar(gol != gol_rival, "el gol propio y el rival suenan distinto (1067)")
	var vol0: float = Sonido.volumen[Sonido.Bus.EFECTOS]
	var vol_amb: float = Sonido.volumen[Sonido.Bus.AMBIENTE]
	Sonido.volumen[Sonido.Bus.EFECTOS] = 0.1
	_comprobar(Sonido.volumen[Sonido.Bus.AMBIENTE] == vol_amb and Sonido.volumen.size() == 3, "cada bus (efectos, ambiente, interfaz) tiene su volumen independiente (1063)")
	Sonido.volumen[Sonido.Bus.EFECTOS] = vol0
	var enc: bool = Sonido.encendido
	Sonido.encendido = false
	var voz0: int = Sonido._siguiente
	Sonido.toca("gol")
	var mudo := Sonido._siguiente == voz0
	Sonido.encendido = true
	Sonido.toca("gol")
	var suena := Sonido._siguiente == voz0 + 1
	Sonido.encendido = enc
	_comprobar(mudo and suena, "el interruptor de sonido silencia todo y al volver a encenderlo suena (1068)")
	## Música discreta y desactivable (1065).
	var mus_enc: bool = Musica.encendida
	var mus_vol: float = Musica.volumen
	Musica.encendida = false
	Musica.poner("oficina")
	Musica.ambientar("partido")
	_comprobar(Musica._sonando == "", "con la música apagada no suena nada aunque la pidan (1065)")
	Musica.volumen = 0.0
	Musica.aplicar_volumen()
	var db: float = Musica._voz.volume_db if Musica._voz != null else -60.0
	Musica.volumen = mus_vol
	Musica.aplicar_volumen()
	Musica.encendida = mus_enc
	_comprobar(db <= -50.0 and Musica.volumen == mus_vol, "bajar el volumen a cero deja la música inaudible (1065): %.0f dB" % db)

func _ideas_b_sin_red() -> void:
	## Escaneo del código: ni red, ni telemetría, ni compras (942, 1080, 1096, 1097).
	var prohibidos := ["HTTPRequest", "HTTPClient", "WebSocketPeer", "ENetMultiplayer", "StreamPeerTCP", "PacketPeerUDP", "WebRTC",
		"telemetr", "analytics", "InAppStore", "GodotGooglePlayBilling", "AdMob"]
	var n_archivos := [0]
	var hallazgos: Array[String] = []
	var pistas := [0]
	for dir in ["res://nucleo", "res://ui", "res://visor"]:
		_escanear(dir, prohibidos, n_archivos, hallazgos, pistas)
	_comprobar(n_archivos[0] > 300 and pistas[0] > 10, "el escáner vio %d scripts (y encuentra «FileAccess» %d veces)" % [n_archivos[0], pistas[0]])
	_comprobar(hallazgos.is_empty(), "ninguna clase de red, telemetría ni compras en nucleo/ui/visor (942, 1080, 1096, 1097): %s" % ", ".join(hallazgos))

func _escanear(dir: String, prohibidos: Array, n_archivos: Array, hallazgos: Array[String], pistas: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		_escanear(dir + "/" + sub, prohibidos, n_archivos, hallazgos, pistas)
	for f in d.get_files():
		if not f.ends_with(".gd"):
			continue
		n_archivos[0] += 1
		var txt := FileAccess.get_file_as_string(dir + "/" + f)
		if txt.contains("FileAccess"):
			pistas[0] += 1
		for p: String in prohibidos:
			if txt.contains(p):
				hallazgos.append("%s:%s" % [f, p])

extends "res://pruebas/banco/varios_p11.gd"
## [Capa 12 de `varios.gd`, 10-11] _probar_selector_direccional, _probar_eventos_club, _probar_copas_mundo, _probar_festejos_titulo, _probar_torneos_selecciones (rueda de prensa en cruz y eventos con diálogo)

## LA CRUZ DE RESPUESTAS (10-11): un botón por opción, delegar al centro, el analógico apunta por direcciones y elegir emite el índice.
func _probar_selector_direccional() -> void:
	_titulo("RUEDA DE PRENSA: SELECCIÓN DIRECCIONAL EN CRUZ")
	var s := SelectorDireccional.crear(["Uno", "Dos", "🙋 Que responda mi ayudante", "Cuatro", "Cinco"], Color.CORNFLOWER_BLUE)
	_comprobar(s.get_child_count() == 5, "un botón hijo por opción, en su orden (5)")
	_comprobar(s._centro == s.get_child(2) and s._brazos.size() == 4, "la de delegar va al centro y las demás a los 4 brazos")
	_comprobar(SelectorDireccional.direccion_de(Vector2(0, -1)) == 0 and SelectorDireccional.direccion_de(Vector2(0.9, 0.2)) == 1
		and SelectorDireccional.direccion_de(Vector2(0, 1)) == 2 and SelectorDireccional.direccion_de(Vector2(-1, 0.3)) == 3, "el analógico se lee en 4 direcciones")
	var dos := SelectorDireccional.crear(["A", "B"], Color.WHITE)
	_comprobar(dos._huecos() == [3, 1], "con dos respuestas: izquierda y derecha")
	var tres := SelectorDireccional.crear(["A", "B", "C"], Color.WHITE)
	_comprobar(tres._huecos() == [0, 3, 1], "con tres: arriba, izquierda y derecha")
	var got := [-1]
	s.elegido.connect(func(i: int) -> void: got[0] = i)
	s.elegir(3)   ## fuera del árbol: sin animación, inmediato
	_comprobar(got[0] == 3, "elegir emite el índice de la opción")
	s.elegir(1)
	_comprobar(got[0] == 3, "tras elegir se bloquea: no se contesta dos veces")
	for x: Node in [s, dos, tres]:
		x.free()

## EVENTOS DEL CLUB CON DIÁLOGO (10-11): solo en su fecha, una vez, y la respuesta mueve moral y confianza.
func _probar_eventos_club() -> void:
	_titulo("EVENTOS DEL CLUB CON DIÁLOGO (directiva, clásico, mitad de liga)")
	var m := Mundo.new()
	m.generar(["CHI"], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	m.semana = 1
	var ev := EventosClub.pendiente(m)
	_comprobar(not ev.is_empty() and String(ev["id"]) == "directiva", "semana 1: toca la reunión con la directiva")
	_comprobar((ev.get("opciones", []) as Array).size() == 4, "cuatro respuestas, una por brazo de la cruz")
	var conf0 := m.directiva.confianza
	var r := EventosClub.aplicar(m, ev, 1)
	_comprobar(m.directiva.confianza == conf0 + int(r["confianza"]) and int(r["confianza"]) > 0, "«a por más» sube la confianza (%d → %d)" % [conf0, m.directiva.confianza])
	_comprobar(EventosClub.pendiente(m).get("id", "") != "directiva", "ya vista: no vuelve a salir")
	_comprobar(m.prensa.eventos_vistos.has("directiva:%d" % m.anio), "queda anotada para el guardado")
	m.semana = 10
	var liga := m.liga_de(m.mi_club())
	liga.jornada_actual = 3   ## lejos de la mitad
	var otro := EventosClub.pendiente(m)
	_comprobar(otro.is_empty() or String(otro["id"]) == "clasico", "fuera de fecha no sale nada (salvo la semana de un clásico)")
	liga.jornada_actual = liga.jornadas() / 2
	m.prensa.eventos_vistos.append(EventosClub._clave(m, "clasico"))
	var mitad := EventosClub.pendiente(m)
	_comprobar(not mitad.is_empty() and String(mitad["id"]) == "mitad", "la jornada de la mitad: el balance con el ayudante")
	_comprobar(EventosClub.capitan(m.mi_club()) != null, "hay capitán para la escena del clásico")

## LAS COPAS Y SUPERCOPAS DE TODOS LOS PAÍSES (10-11, encargo del dueño): se juegan todas, quedan sus campeones y sobreviven a guardar y cargar.
## (Regla 34: un club de otro país, no el de siempre.)
func _probar_copas_mundo() -> void:
	_titulo("TORNEOS: LAS COPAS Y SUPERCOPAS DE TODOS LOS PAÍSES")
	var m := Mundo.new()
	m.generar(["ESP", "ARG", "ENG"], 314)
	var liga_esp: Liga = m.ligas.filter(func(l: Liga) -> bool: return l.pais == "ESP")[0]
	m.tomar_el_mando(liga_esp.clubes[5].id)
	var paises := {}
	for c: Club in m.clubes.values():
		paises[c.pais] = true
	_comprobar(m.copas_otras.size() >= paises.size() - 1, "se sortean las copas de los demás países (%d copas, %d países)" % [m.copas_otras.size(), paises.size()])
	var inglesas: Array = m.copas_otras.filter(func(cp: Copa) -> bool: return String(cp.get_meta("pais", "")) == "ENG")
	_comprobar(inglesas.size() == 2, "Inglaterra juega sus dos copas el mismo año (%d)" % inglesas.size())
	var mio := m.mi_club()
	_comprobar(not m.copas_otras.any(func(cp: Copa) -> bool: return cp.participantes.has(mio)), "tu club no está en las copas de los demás")
	var guard := 0
	while m.temporada_en_curso() and guard < 80:
		m.avanzar_semana()
		guard += 1
	CierreTorneos.cerrar_pendientes(m)
	_comprobar(m.copas_otras.all(func(cp: Copa) -> bool: return cp.campeon != null), "al terminar la liga todas las copas tienen campeón")
	var copas_en_palmares := m.palmares_mundo.filter(func(t: Dictionary) -> bool: return String(t["torneo"]) != "Supercopa").size()
	_comprobar(copas_en_palmares >= m.copas_otras.size(), "y quedan en el palmarés del mundo, con las ligas (%d)" % copas_en_palmares)
	Partida.borrar("_prueba_copas_mundo")
	_comprobar(Partida.guardar(m, "_prueba_copas_mundo"), "se guarda")
	var m2 := Partida.cargar("_prueba_copas_mundo")
	_comprobar(m2 != null and m2.copas_otras.size() == m.copas_otras.size() and m2.palmares_mundo.size() == m.palmares_mundo.size(), "y se carga con sus copas y su palmarés")
	## Cuántas supercopas toca jugar: los países (menos el tuyo) cuyo campeón de liga no ganó también la copa principal. Con
	## unos campeones u otros, esa cuenta cambia: la prueba no puede exigir «al menos una» a ciegas.
	var esperadas := 0
	for pais: String in m.campeones_liga_otros:
		if pais == mio.pais:
			continue
		for cp: Copa in m.copas_otras:
			if String(cp.get_meta("pais", "")) == pais:
				if cp.campeon != null and cp.campeon != m.campeones_liga_otros[pais]:
					esperadas += 1
				break
	m.nueva_temporada()
	var supers := m.palmares_mundo.filter(func(t: Dictionary) -> bool: return String(t["torneo"]) == "Supercopa" and int(t["anio"]) == m.anio).size()
	_comprobar(supers == esperadas, "al empezar la temporada se juegan las supercopas de los demás países (%d de %d)" % [supers, esperadas])
	_comprobar(m.copas_otras.all(func(cp: Copa) -> bool: return cp.campeon == null and cp.en_curso()), "y se sortean copas nuevas")
	Partida.borrar("_prueba_copas_mundo")

## CADA TÍTULO, SU FESTEJO (10-11): el tipo sale del nombre de la competición y decide la escena y los extras.
func _probar_festejos_titulo() -> void:
	_titulo("FESTEJOS POR TIPO DE TÍTULO")
	for semilla: int in [11, 77]:   ## regla 34: más de un mundo y más de un club
		var m := Mundo.new()
		m.generar(["CHI", "ARG"], semilla)
		m.tomar_el_mando(m.ligas[semilla % m.ligas.size()].clubes[semilla % 7].id)
		var liga := m.liga_de(m.mi_club())
		_comprobar(TipoTitulo.de(m, liga.nombre) == "liga", "%s: «%s» es una liga" % [m.mi_club().nombre, liga.nombre])
		if m.copa != null:
			_comprobar(TipoTitulo.de(m, m.copa.nombre) == "copa", "«%s» es una copa" % m.copa.nombre)
		for k: String in m.continentales:
			_comprobar(TipoTitulo.de(m, Continental.nombre_conti(k)) == "continental", "«%s» es continental" % Continental.nombre_conti(k))
			break
		_comprobar(TipoTitulo.de(m, "Supercopa de Chile") == "supercopa" and TipoTitulo.de(m, "Permanencia (interinato)") == "salvacion", "supercopa y permanencia por su nombre")
		_comprobar(TipoTitulo.de_fin_de_liga(m) in ["", "ascenso", "salvacion"], "fin de liga: ascenso, salvación o nada")
	var vistos := {}
	for t: String in ["liga", "copa", "continental", "supercopa", "ascenso", "salvacion"]:
		vistos[TipoTitulo.ESCENA[t]] = true
		_comprobar(not TipoTitulo.extras(t).is_empty(), "%s tiene festejos extra" % t)
	_comprobar(vistos.size() == 4, "cuatro escenas principales distintas (escenario, palco, fuegos, sobrio)")
	_comprobar(TipoTitulo.extras("liga").has("pasillo") and not TipoTitulo.extras("ascenso").has("desfile"), "pasillo solo en liga; el ascenso es sobrio (sin desfile)")
	var e := EscenaFestejo.new()
	for modo: String in ["escenario", "palco", "fuegos", "sobrio", "foto", "manteo", "champan", "desfile", "pasillo"]:
		e.poner(modo)
		if e.con_confeti():
			e._mover_confeti(0.1)
	_comprobar(e._confeti.is_empty(), "el pasillo no lleva confeti (se limpia al cambiar de escena)")
	e.free()
	## (10-11) La versión 3D: sin pantalla no se monta y la escena 2D queda de respaldo; los modos 3D son principales o extras reales.
	_comprobar(not FestejoCampo3D.con_3d() and FestejoCampo3D.crear("escenario", Mundo.new().mi_club(), "") == null, "sin pantalla, sin 3D (la escena 2D es el respaldo)")
	for modo: String in FestejoCampo3D.MODOS:
		_comprobar(modo in TipoTitulo.ESCENA.values() or modo in TipoTitulo.extras("liga"), "el modo 3D «%s» lo usa algún festejo" % modo)

## LAS SELECCIONES COMO EQUIPOS Y SUS TORNEOS CON PARTIDOS DE VERDAD (10-11, encargo del dueño, punto 2). Regla 34: varias selecciones.
func _probar_torneos_selecciones() -> void:
	_titulo("SELECCIONES: EQUIPOS DE VERDAD Y TORNEOS CON PARTIDOS")
	var m := Mundo.new()
	m.generar(["ARG", "BRA", "ESP", "FRA"], 2026)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	var sel := m.selecciones
	var arg := SeleccionEquipo.club_de(m, "Argentina", sel.fuerza("Argentina"), m.anio)
	var sen := SeleccionEquipo.club_de(m, "Senegal", sel.fuerza("Senegal"), m.anio)
	_comprobar(arg.plantilla.size() == 23 and sen.plantilla.size() == 23, "cada selección lleva 23 convocados (Argentina %d, Senegal %d)" % [arg.plantilla.size(), sen.plantilla.size()])
	_comprobar(arg.plantilla.all(func(j: Jugador) -> bool: return j.pais == "ARG"), "Argentina convoca a jugadores argentinos del mundo del juego")
	var reales_arg := 0
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			if j.pais == "ARG" and arg.plantilla.any(func(x: Jugador) -> bool: return x.id == j.id and x != j):
				reales_arg += 1
	_comprobar(reales_arg >= 20, "son COPIAS de los reales (sus goles no cuentan en la liga) (%d)" % reales_arg)
	_comprobar(SeleccionEquipo.club_de(m, "Senegal", sel.fuerza("Senegal"), m.anio).plantilla[5].nombre == sen.plantilla[5].nombre, "una selección sin liga se completa siempre igual (misma temporada)")
	var t := SeleccionesTorneos.mundial(sel, m, 2026)
	_comprobar(t.equipos.size() == 48 and t.grupos.size() == 12, "el Mundial de 2026: 48 selecciones en 12 grupos (%d en %d)" % [t.equipos.size(), t.grupos.size()])
	t.jugar_entero()
	var de_grupos := t.resultados.filter(func(r: Dictionary) -> bool: return String(r["fase"]).begins_with("Fase de grupos")).size()
	_comprobar(de_grupos == 72 and t.resultados.size() == 72 + 31, "72 partidos de grupos y 31 de eliminatorias, desde dieciseisavos (%d en total)" % t.resultados.size())
	var goles := 0
	for rr: Dictionary in t.resultados:
		goles += int(rr["gl"]) + int(rr["gv"])
	_comprobar(goles > 103, "los partidos simulados tienen goles de verdad (%d en 103 partidos; antes todos 0-0)" % goles)
	_comprobar(t.campeon != null and t.puesto_de(t.campeon) == 0, "tiene campeón (%s)" % (t.campeon.nombre if t.campeon else "—"))
	var otro := TorneoSelecciones.crear("Copa Africana", 2027, SeleccionesTorneos._equipos(sel, m, (SeleccionesTorneos.POR_CONFED["afr"] as Array).slice(0, 6), 2027))
	otro.jugar_entero()
	_comprobar(otro.grupos.size() == 2 and otro.campeon != null, "un torneo de 6 selecciones: 2 grupos de 3 y campeón (%s)" % (otro.campeon.nombre if otro.campeon else "—"))
	var r := sel.cierre_de_temporada(2026)
	_comprobar(not (r.get("mundial", {}) as Dictionary).is_empty() and sel.ultimo_torneo != null, "el cierre de 2026 juega el Mundial de verdad (%s)" % String(r.get("mundial", {}).get("campeon", "")))

func _probar_cargo_seleccionador() -> void:
	_titulo("EL CARGO DE SELECCIONADOR (ofertas por prestigio, doble cargo y torneos jugables)")
	## (regla 34) dos mundos distintos: un club de Brasil y uno de España
	for caso: Array in [[["BRA", "ARG", "ESP"], 1, "Uruguay", 2028], [["ESP", "FRA", "ITA"], 0, "Portugal", 2026]]:
		var m := Mundo.new()
		var paises: Array[String] = []
		paises.assign(caso[0])
		m.generar(paises, 2026)
		m.anio = int(caso[3])
		var l: Liga = m.ligas[int(caso[1])]
		m.tomar_el_mando(l.clubes[5].id)
		var club_id := m.mi_club_id
		var cargo := m.selecciones.cargo
		m.roles.prestigio = 40
		var hubo := false
		for k in 60:
			m.semana = k + 1
			hubo = hubo or not cargo.sortear(m, m.selecciones).is_empty()
		_comprobar(not hubo, "con poco prestigio no llama ninguna selección (%s)" % m.mi_club().nombre)
		m.roles.prestigio = 75
		var estado: int = Azar._rng.state
		var of := {}
		for a in 4:
			for k in 60:
				m.semana = k + 1
				m.anio = int(caso[3]) + a
				of = cargo.sortear(m, m.selecciones)
				if not of.is_empty():
					break
			if not of.is_empty():
				break
		m.anio = int(caso[3])
		_comprobar(Azar._rng.state == estado, "sortear la oferta no toca el azar del resto del juego")
		_comprobar(not of.is_empty() and int(of["fuerza"]) <= CargoSeleccion._alcanza(75), "con prestigio llama una selección a su alcance (%s, fuerza %d)" % [String(of.get("nombre", "—")), int(of.get("fuerza", 0))])
		cargo.ofrecer(String(caso[2]), m.selecciones.fuerza(String(caso[2])), 2000)
		cargo.responder(m, true)
		_comprobar(cargo.activo() and cargo.seleccion == String(caso[2]) and m.mi_club_id == club_id, "aceptar: diriges %s SIN dejar tu club" % cargo.seleccion)
		var guardado := m.selecciones.a_dic()
		var otro := Selecciones.new(m)
		otro.desde_dic(JSON.parse_string(JSON.stringify(guardado)))
		_comprobar(otro.cargo.seleccion == cargo.seleccion and otro.cargo.sueldo == 2000, "el cargo se guarda y se carga")
		var ts := cargo.torneos_del_anio(m, m.selecciones, m.anio)
		_comprobar(not ts.is_empty(), "%d: tu selección juega %s" % [m.anio, ", ".join(ts.map(func(x: TorneoSelecciones) -> String: return x.nombre))])
		var t: TorneoSelecciones = ts[0]
		var mia := cargo.mi_equipo(t)
		var par := t.partido_de(mia)
		var p := Partido.new(par[0], par[1], true)
		p.simular()
		var antes := t.resultados.size()
		t.jugar_fecha(p)
		var r: Dictionary = t.resultados.filter(func(x: Dictionary) -> bool: return x["local"] == mia or x["visita"] == mia)[0]
		_comprobar(t.resultados.size() > antes and int(r["gl"]) == p.goles_local and int(r["gv"]) == p.goles_visita, "tu partido jugado (%s %d-%d %s) cuenta en el torneo" % [(r["local"] as Club).nombre, p.goles_local, p.goles_visita, (r["visita"] as Club).nombre])
		var res := m.selecciones.cierre_de_temporada(m.anio)
		_comprobar(not t.en_curso() and cargo.historial.size() == ts.size(), "el cierre termina los torneos de tu selección y los apunta (%s)" % str(cargo.historial))
		_comprobar(res.has("seleccionador"), "el cierre devuelve los torneos del seleccionador")
		cargo.dimitir(m)
		_comprobar(not cargo.activo() and cargo.sueldo == 0, "dimitir deja el cargo")
	## (10-11) Título de TU SELECCIÓN: el festejo es de la selección (sus colores y jugadores), no del club; y los 3 extras 3D existen.
	var ms := Mundo.new()
	ms.generar(["ARG"], 5)
	ms.tomar_el_mando(ms.ligas[0].clubes[3].id)
	if ms.selecciones != null:
		var equipo: Club = ms.ligas[0].clubes[6]
		ms.selecciones.cargo.ultimo_titulo = {"torneo": "Copa de Naciones", "equipo": equipo}
		_comprobar(TipoTitulo.de(ms, "Copa de Naciones") == "seleccion" and TipoTitulo.equipo_seleccion(ms, "Copa de Naciones") == equipo, "el título de la selección se festeja con la selección")
		_comprobar(TipoTitulo.de(ms, ms.liga_de(ms.mi_club()).nombre) == "liga", "un título del club sigue siendo del club")
	for extra: String in ["champan", "desfile", "pasillo"]:
		_comprobar(extra in FestejoCampo3D.MODOS, "«%s» tiene versión 3D" % extra)

func _probar_convocatoria_seleccion() -> void:
	_titulo("LA CONVOCATORIA DEL SELECCIONADOR (hasta 26 del país en todo el mundo)")
	var m := Mundo.new()
	var paises: Array[String] = ["COL", "ARG", "ITA"]
	m.generar(paises, 2026)
	m.anio = 2028
	m.tomar_el_mando(m.ligas[2].clubes[4].id)
	var cargo := m.selecciones.cargo
	cargo.ofrecer("Colombia", m.selecciones.fuerza("Colombia"), 1000)
	cargo.responder(m, true)
	var cands := SeleccionEquipo.candidatos(m, "Colombia", 60)
	_comprobar(cands.size() >= 30 and cands.all(func(j: Jugador) -> bool: return j.pais == "COL"), "candidatos: los colombianos del mundo del juego (%d)" % cands.size())
	var porteros := cands.filter(func(j: Jugador) -> bool: return j.pos == "POR")
	var elegidos: Array[String] = [porteros[0].id]   ## solo un portero: el segundo se genera
	for j: Jugador in cands:
		if j.pos != "POR" and elegidos.size() < 30:
			cargo.alternar(j.id)
			elegidos.append(j.id)
	cargo.alternar(porteros[0].id)
	_comprobar(cargo.convocados.size() == SeleccionEquipo.MAX_CONVOCADOS, "no se pueden marcar más de 26 (%d)" % cargo.convocados.size())
	var ts := cargo.torneos_del_anio(m, m.selecciones, 2028)
	var mia := cargo.mi_equipo(ts[0])
	var de_lista := mia.plantilla.filter(func(j: Jugador) -> bool: return cargo.convocados.has(j.id)).size()
	var pors := mia.plantilla.filter(func(j: Jugador) -> bool: return j.pos == "POR").size()
	_comprobar(de_lista == cargo.convocados.size(), "tu selección juega con TU lista (%d de %d)" % [de_lista, cargo.convocados.size()])
	_comprobar(pors >= 2, "si falta un portero se completa con uno generado (%d porteros)" % pors)
	var otro := Selecciones.new(m)
	otro.desde_dic(JSON.parse_string(JSON.stringify(m.selecciones.a_dic())))
	_comprobar(otro.cargo.convocados == cargo.convocados, "la convocatoria se guarda")
	## (10-11) Tifos de final: dos lonas (escudo y franjas del club) sobre la grada.
	var rt := Node3D.new()
	var mt := Mundo.new()
	mt.generar(["COL"], 31)
	var club_t: Club = mt.ligas[0].clubes[2]
	_comprobar(FestejoExtra3D.tifos(rt, club_t, Color(club_t.color1), Color(club_t.color2)) == 2 and rt.get_child_count() == 2, "los tifos de una final: dos lonas (%s)" % club_t.nombre)
	rt.free()

## (10-11, orden del dueño) Cada club con su formación y su estilo de la vida real; regla 34: varios países.
func _probar_estilos_club() -> void:
	_titulo("ESTILOS DE CLUB: FORMACIÓN Y ESTILO DE LA VIDA REAL")
	var m := Mundo.new()
	var paises: Array[String] = ["ESP", "ITA", "ARG", "BRA", "ENG", "GER", "CHI", "JPN"]
	m.generar(paises, 12)
	var forms := {}
	var estilos := {}
	for c: Club in m.clubes.values():
		forms[c.tactica.formacion] = true
		estilos[EstiloClub.estilo_de(c)] = true
	_comprobar(forms.size() >= 6 and estilos.size() >= 7, "los clubes ya no juegan todos igual: %d formaciones y %d estilos (%s)" % [forms.size(), estilos.size(), ", ".join(forms.keys())])
	var cap: Club = null   ## el 13.º de Italia en la tabla (con la base real o la ficticia, el mismo puesto)
	for l: Liga in m.ligas:
		if l.pais == "ITA":
			for c2: Club in l.clubes:
				if EstiloClub.de(c2.nombre, "ITA", c2.rep) == ["3-5-2", "bloque"] and c2.rep >= 78:
					cap = c2
	_comprobar(cap != null and cap.tactica.formacion == "3-5-2" and EstiloClub.estilo_de(cap) == "bloque", "un club de Italia juega con 3 centrales y bloque medio, como el real (%s)" % (cap.nombre if cap else "—"))
	var t := Tactica.new()
	EstiloClub.poner(t, "4-4-2", "contra")
	_comprobar(t.mentalidad == 0 and t.linea == 0 and t.verticalidad == 2, "«contra»: mentalidad defensiva, línea baja y vertical")
	_comprobar(EstiloClub.de("Club Inventado", "ITA", 60) == ["3-5-2", "contra"] and EstiloClub.de("Club Inventado", "ESP", 90) == ["4-3-3", "posesion"], "sin fila: el estilo de su país según su tamaño")
	var mio := m.ligas[0].clubes[2]
	m.tomar_el_mando(mio.id)
	var copia := Partida.desde_instantanea(Partida.instantanea(m))
	var c3: Club = copia.clubes[mio.id]
	_comprobar(c3.tactica.formacion == mio.tactica.formacion and EstiloClub.estilo_de(c3) == EstiloClub.estilo_de(mio), "el estilo se guarda y se carga")
	var viejo := Club.new("x1", "Capitolina")   ## nombre ficticio de la tabla
	viejo.pais = "ITA"
	EstiloClub.aplicar_si_de_fabrica(viejo)
	_comprobar(viejo.tactica.formacion == "3-5-2", "una partida vieja (táctica de fábrica) recupera el estilo del club")
	viejo.tactica.formacion = "4-4-2"
	viejo.tactica.mentalidad = 2
	EstiloClub.aplicar_si_de_fabrica(viejo)
	_comprobar(viejo.tactica.formacion == "4-4-2", "si la táctica se tocó, se respeta")

## FIN DE TEMPORADA CON GUARDADO Y CARGA A MITAD (10-11, caza de fallos, orden 31): 3 clubes de 3 países. Liga terminada con la copa a medias,
## se guarda y se carga; tras cargar, el cierre de torneos, la foto, los festejos de fin de liga y la nueva temporada siguen funcionando.
func _probar_fin_temporada_guardado() -> void:
	_titulo("FIN DE TEMPORADA: GUARDAR Y CARGAR A MITAD (3 PAÍSES)")
	for par: Array in [["CHI", 61], ["ARG", 62], ["COL", 63]]:
		var m := Mundo.new()
		m.generar([String(par[0])], int(par[1]))
		m.tomar_el_mando(m.ligas[0].clubes[int(par[1]) % m.ligas[0].clubes.size()].id)
		var nombre := m.mi_club().nombre
		var guard := 0
		while m.temporada_en_curso() and guard < 80:
			m.avanzar_semana()
			guard += 1
		m._montar_copa()   ## copa a medias al terminar la liga
		m.prensa.eventos_vistos.append("festejo_prueba:%d" % m.anio)
		m.prensa.despedida_ofrecida_anio = m.anio
		var tipo_antes := TipoTitulo.de_fin_de_liga(m)
		_comprobar(Partida.guardar(m, "_prueba_fin_temporada"), "%s: se guarda con la liga terminada y la copa a medias" % nombre)
		var c := Partida.cargar("_prueba_fin_temporada")
		_comprobar(c != null and not c.temporada_en_curso(), "%s: al cargar, la liga sigue terminada" % nombre)
		if c == null:
			continue
		_comprobar(c.prensa.eventos_vistos.has("festejo_prueba:%d" % m.anio) and c.prensa.despedida_ofrecida_anio == m.anio, "%s: los eventos vistos y la despedida ofrecida se guardan (no se repiten)" % nombre)
		_comprobar(TipoTitulo.de_fin_de_liga(c) == tipo_antes, "%s: el festejo de fin de liga es el mismo tras cargar («%s»)" % [nombre, tipo_antes])
		var cerrados := CierreTorneos.cerrar_pendientes(c)
		_comprobar(not CierreTorneos.hay_pendientes(c) and CierreTorneos.cerrar_pendientes(c).is_empty(), "%s: tras cargar, la copa se cierra una sola vez (%d torneos)" % [nombre, cerrados.size()])
		var foto := CierreTorneos.foto(c)
		var resumen := c.nueva_temporada()
		_comprobar(c.temporada_en_curso() and ResumenTemporada.datos(foto, resumen)["campeon"] is Club, "%s: la temporada nueva empieza y el resumen tiene campeón" % nombre)
		_comprobar(not EventosClub.pendiente(c).is_empty() and String(EventosClub.pendiente(c)["id"]) == "directiva", "%s: en la temporada nueva vuelve la reunión con la directiva" % nombre)
	Partida.borrar("_prueba_fin_temporada")


## (10-11) La fecha FIFA de la selección que diriges: un partido de verdad (eliminatoria o amistoso), jugable o simulado; regla 34: 2 casos.
func _probar_fecha_seleccion() -> void:
	_titulo("FECHA FIFA DE TU SELECCIÓN: PARTIDO DE VERDAD")
	for caso: Array in [[["PER", "ESP"], "Perú"], [["MAR", "FRA"], "Marruecos"]]:
		var m := Mundo.new()
		var paises: Array[String] = []
		paises.assign(caso[0])
		m.generar(paises, 41)
		m.tomar_el_mando(m.ligas[0].clubes[6].id)
		var s := m.selecciones
		var cargo := s.cargo
		cargo.ofrecer(String(caso[1]), s.fuerza(String(caso[1])), 900)
		cargo.responder(m, true)
		var estado: int = Azar._rng.state
		var pend := FechaSeleccion.preparar(m, s, cargo)
		_comprobar(Azar._rng.state == estado and not pend.is_empty(), "%s: la fecha FIFA prepara un partido (%s contra %s) sin tocar el azar del juego" % [cargo.seleccion, String(pend.get("tipo", "")), String(pend.get("rival", ""))])
		_comprobar(absi(s.fuerza(String(pend["rival"])) - s.fuerza(cargo.seleccion)) <= FechaSeleccion.MARGEN_RIVAL, "el rival es de fuerza parecida")
		var linea := FechaSeleccion.simular(m, s, cargo)
		_comprobar(linea != "" and cargo.fecha_pendiente.is_empty() and cargo.fechas.size() == 1, "simulado: resultado apuntado (%s)" % linea)
		FechaSeleccion.preparar(m, s, cargo)
		m.semana += 1
		FechaSeleccion.semana(m, s, cargo, false)
		_comprobar(cargo.fecha_pendiente.is_empty() and cargo.fechas.size() == 2, "si nadie lo juega, se simula solo la semana siguiente")
		var otro := Selecciones.new(m)
		otro.desde_dic(JSON.parse_string(JSON.stringify(s.a_dic())))
		_comprobar(otro.cargo.fechas.size() == 2, "las fechas se guardan")
	var sl := Selecciones.new(null)
	_comprobar(FechaSeleccion.tipo_de(sl, "ucl", "afr", 2027) == "Amistoso" and FechaSeleccion.tipo_de(sl, "ucl", "ucl", 2028) == "Eliminatoria"
		and FechaSeleccion.tipo_de(sl, "ucl", "ucl", 2026) == "Nations League" and FechaSeleccion.tipo_de(sl, "lib", "lib", 2026) == "Amistoso",
		"el tipo de partido: amistoso, eliminatoria (antes de un Mundial) o Nations League (Europa y Concacaf)")

## PIEZAS DE ESTADIOS REALES (10-11): opcionales (sin la clave no se añade nada) y una sola malla por pieza.
func _probar_piezas_estadio_real() -> void:
	_titulo("ESTADIOS REALES: ARCO, TORRES DE RAMPAS, COSTILLAS Y TECHO POR LADOS")
	var r0 := Node3D.new()
	_comprobar(PiezasRealesEstadio.montar(r0, {"forma": "cuenco"}, 60.0, 80.0, 30.0, 25.0) == 0 and r0.get_child_count() == 0, "un perfil sin piezas no añade nada (el estadio de siempre)")
	var r1 := Node3D.new()
	var nivel := Calidad.elegida
	Calidad.elegida = Calidad.MEDIO
	var n := PiezasRealesEstadio.montar(r1, {"arco": {"alto": 100, "lado": "centro"}, "torres_rampa": 11, "costillas": 40}, 60.0, 80.0, 30.0, 25.0)
	_comprobar(n == 3 and r1.get_child_count() == 3 and r1.get_children().all(func(x: Node) -> bool: return x is MultiMeshInstance3D), "arco, torres y costillas: 3 piezas, cada una UN MultiMesh")
	_comprobar((r1.get_node("TorresRampa") as MultiMeshInstance3D).multimesh.instance_count == 11, "11 torres de rampas")
	Calidad.elegida = Calidad.MINIMO
	var r2 := Node3D.new()
	_comprobar(PiezasRealesEstadio.montar(r2, {"costillas": 40}, 60.0, 80.0, 30.0, 25.0) == 0, "en calidad mínima, sin costillas")
	Calidad.elegida = nivel
	var r3 := Node3D.new()
	_comprobar(PiezasRealesEstadio.montar(r3, {"fachada_curva": {"color": "#cccccc"}, "colchon": {"color": "#dc052d", "filas": 3}}, 60.0, 80.0, 30.0, 25.0) == 2
		and (r3.get_node("Colchon") as MultiMeshInstance3D).multimesh.instance_count == 3 * 56, "fachada curva y colchón (3 filas de 56 paneles en UNA malla)")
	r3.free()
	## Niveles por lado y esquinas una a una (constructor).
	var obra := EstadioObra.new()
	obra.est = {"niveles_lado": {"este": 4}, "esquinas_abiertas": ["suroeste"]}
	obra.dx = 45.0
	obra.dz = 62.0
	obra.niveles = 1
	obra.alto = StadiumBuilder.ALTURA_PIE + StadiumBuilder.subida_bandeja()
	obra.fondo_trib = StadiumBuilder.fondo_tribuna(1)
	obra.principal = -1
	var ts := StadiumBuilder._tribunas(obra)
	var este := StadiumBuilder._tribuna_de(obra, ts[2])
	var oeste := StadiumBuilder._tribuna_de(obra, ts[3])
	_comprobar(este.niv_s == 4 and oeste.niv_s == 1 and este.alto_s > oeste.alto_s * 2.0 and este.pos.x > 0.0, "niveles por lado: la tribuna este sube a 4 bandejas, la oeste sigue con 1")
	_comprobar(StadiumBuilder.esquina_abierta(obra.est, -1.0, 1.0) and not StadiumBuilder.esquina_abierta(obra.est, 1.0, 1.0) and not StadiumBuilder.esquina_abierta({}, -1.0, 1.0), "esquinas una a una: solo la suroeste queda abierta")
	var c := Club.new()
	c.nombre = "Club de prueba sin fila real"
	_comprobar(not c.perfil_estadio().has("bandejas"), "sin fila real no hay techo por lados")
	for x: Node in [r0, r1, r2]:
		x.free()

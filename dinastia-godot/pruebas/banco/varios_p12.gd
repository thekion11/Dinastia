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
	m.nueva_temporada()
	var supers := m.palmares_mundo.filter(func(t: Dictionary) -> bool: return String(t["torneo"]) == "Supercopa" and int(t["anio"]) == m.anio).size()
	_comprobar(supers >= 1, "al empezar la temporada se juegan las supercopas de los demás países (%d)" % supers)
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
	_comprobar(t.equipos.size() == 32 and t.grupos.size() == 8, "el Mundial: 32 selecciones en 8 grupos")
	t.jugar_entero()
	var de_grupos := t.resultados.filter(func(r: Dictionary) -> bool: return String(r["fase"]).begins_with("Fase de grupos")).size()
	_comprobar(de_grupos == 48 and t.resultados.size() == 48 + 15, "48 partidos de grupos y 15 de eliminatorias (%d en total)" % t.resultados.size())
	var goles := 0
	for rr: Dictionary in t.resultados:
		goles += int(rr["gl"]) + int(rr["gv"])
	_comprobar(goles > 63, "los partidos simulados tienen goles de verdad (%d en 63 partidos; antes todos 0-0)" % goles)
	_comprobar(t.campeon != null and t.puesto_de(t.campeon) == 0, "tiene campeón (%s)" % (t.campeon.nombre if t.campeon else "—"))
	var otro := TorneoSelecciones.crear("Copa Africana", 2027, SeleccionesTorneos._equipos(sel, m, SeleccionesTorneos.POR_CONFED["afr"], 2027))
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

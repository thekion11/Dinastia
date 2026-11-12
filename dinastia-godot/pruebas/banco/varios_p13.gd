extends "res://pruebas/banco/varios_p12.gd"
## [Capa 13 de `varios.gd`, 10-11] _probar_finalissima, _probar_estadios_variedad, _probar_socios_cabecera, _probar_pie_mando, _probar_solo_primera_persona

## (10-11) La FINALISSIMA: campeón de Europa contra campeón de América, el año de los dos torneos, sin tocar el azar del juego.
func _probar_finalissima() -> void:
	_titulo("FINALISSIMA: CAMPEÓN DE EUROPA CONTRA CAMPEÓN DE AMÉRICA")
	_comprobar(Finalissima.toca(2028) and not Finalissima.toca(2027) and not Finalissima.toca(2030), "toca el año de la Eurocopa y la Copa América (2028 sí; 2027 y 2030 no)")
	for caso: Array in [[["ARG", "ESP"], "Argentina", 2028], [["MEX", "FRA"], "Francia", 2032]]:
		var m := Mundo.new()
		var paises: Array[String] = []
		paises.assign(caso[0])
		m.generar(paises, 77)
		m.tomar_el_mando(m.ligas[0].clubes[4].id)
		var s := m.selecciones
		s.cargo.ofrecer(String(caso[1]), s.fuerza(String(caso[1])), 800)
		s.cargo.responder(m, true)
		var estado: int = Azar._rng.state
		var f := Finalissima.jugar(s, m, int(caso[2]))
		_comprobar(not f.is_empty() and String(f["campeon"]) != String(f["rival"]) and Azar._rng.state == estado,
			"%d: campeona %s (final %s %d-%d) sin tocar el azar del juego" % [int(caso[2]), String(f.get("campeon", "")), String(f.get("local", "")), int(f.get("gl", 0)), int(f.get("gv", 0))])
		_comprobar(int(f.get("gl", 0)) != int(f.get("gv", 0)) or (f.get("penales", []) as Array).size() == 2, "con empate se decide por penaltis")
		_comprobar(Finalissima.jugar(s, m, int(caso[2])).is_empty() and s.finalissimas.size() == 1, "no se juega dos veces el mismo año")
		var mia := Nombres.limpiar(String(caso[1]))
		var jugo := Nombres.limpiar(String(f["campeon"])) == mia or Nombres.limpiar(String(f["rival"])) == mia
		var apuntada := s.cargo.historial.any(func(h: Dictionary) -> bool: return String(h["torneo"]) == Finalissima.NOMBRE)
		_comprobar(jugo == apuntada, "%s: en tu historial de seleccionador solo si tu selección la jugó (%s)" % [String(caso[1]), "la jugó" if jugo else "no la jugó"])
		var otro := Selecciones.new(m)
		otro.desde_dic(JSON.parse_string(JSON.stringify(s.a_dic())))
		_comprobar(otro.finalissimas.size() == 1 and String((otro.finalissimas[0] as Dictionary)["campeon"]) == String(f["campeon"]), "la Finalissima se guarda con la partida")

## (10-11) El fútbol de los JUEGOS OLÍMPICOS: 16 selecciones sub-23 (hasta 3 mayores) por cupos de confederación, sin tocar el azar del juego.
func _probar_olimpicos() -> void:
	_titulo("JUEGOS OLÍMPICOS: SUB-23 CON TRES MAYORES")
	_comprobar(Olimpicos.toca(2028) and Olimpicos.toca(2032) and not Olimpicos.toca(2030) and not Olimpicos.toca(2024), "cada cuatro años desde 2028")
	for caso: Array in [[["BRA", "ITA"], 2028], [["JPN", "NGA", "ENG"], 2032]]:
		var m := Mundo.new()
		var paises: Array[String] = []
		paises.assign(caso[0])
		m.generar(paises, 303)
		m.tomar_el_mando(m.ligas[0].clubes[2].id)
		var s := m.selecciones
		var nombres := Olimpicos.participantes(s)
		var sin_rep := {}
		for n: String in nombres:
			sin_rep[n] = true
		_comprobar(nombres.size() == Olimpicos.PLAZAS and sin_rep.size() == Olimpicos.PLAZAS, "%s: 16 selecciones distintas (%s…)" % [", ".join(caso[0]), ", ".join(nombres.slice(0, 4))])
		var pais_nombre := String((Datos.tabla("PAIS_SELECCION") as Dictionary).get(String((caso[0] as Array)[0]), ""))
		if nombres.has(pais_nombre):
			var eq := Olimpicos.equipo(s, m, pais_nombre, int(caso[1]))
			var mayores := eq.plantilla.filter(func(j: Jugador) -> bool: return j.edad > Olimpicos.EDAD_MAX and not j.id.begins_with(eq.id)).size()
			_comprobar(mayores <= Olimpicos.MAYORES and eq.nombre.ends_with("Sub-23") and eq.id.ends_with("_sub23"), "%s: como mucho %d mayores de 23 (%d) y su propio id" % [eq.nombre, Olimpicos.MAYORES, mayores])
		var estado: int = Azar._rng.state
		var f := Olimpicos.jugar(s, m, int(caso[1]))
		_comprobar(not f.is_empty() and String(f["oro"]) != String(f["plata"]) and Azar._rng.state == estado, "%d: oro %s, plata %s (%s) sin tocar el azar del juego" % [int(caso[1]), String(f.get("oro", "")), String(f.get("plata", "")), String(f.get("final", ""))])
		_comprobar(Olimpicos.jugar(s, m, int(caso[1])).is_empty() and s.olimpicos.size() == 1 and s.cargo.historial.is_empty(), "no se repite el mismo año y no cuenta como seleccionador")
		var otro := Selecciones.new(m)
		otro.desde_dic(JSON.parse_string(JSON.stringify(s.a_dic())))
		_comprobar(otro.olimpicos.size() == 1, "los Juegos se guardan con la partida")

## (10-11) La Finalissima en dos pasos (como la juega la interfaz en directo): `preparar` la deja sin jugar y `registrar` la apunta una vez.
func _probar_finalissima_directo() -> void:
	_titulo("FINALISSIMA EN DIRECTO: PREPARAR Y REGISTRAR")
	var m := Mundo.new()
	m.generar(["URU", "POR"], 515)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	var s := m.selecciones
	var t := Finalissima.preparar(s, m, 2028)
	_comprobar(t != null and t.en_curso() and t.partidos_de_la_fecha().size() == 1 and t.nombre_fase() == "Final", "preparada sin jugar: una final pendiente")
	var par: Array = t.partidos_de_la_fecha()[0]
	var p := Partido.new(par[0], par[1], true)
	p.simular()
	t.jugar_fecha(p)
	var r: Dictionary = t.resultados[0]
	_comprobar(not t.en_curso() and int(r["gl"]) == p.goles_local and int(r["gv"]) == p.goles_visita, "el partido jugado aparte cuenta (%s %d-%d %s)" % [(par[0] as Club).nombre, p.goles_local, p.goles_visita, (par[1] as Club).nombre])
	var f := Finalissima.registrar(s, m, t)
	_comprobar(not f.is_empty() and s.finalissimas.size() == 1 and Finalissima.jugar(s, m, 2028).is_empty() and Finalissima.preparar(s, m, 2028) == null, "se apunta una vez y el cierre ya no la repite (campeón %s)" % String(f.get("campeon", "")))

## (10-11) VARIEDAD DE ESTADIOS GENERADA POR CLUB (`herramientas/estadios_variedad.py`): los clubes sin arquitectura escrita a mano ya no salen casi todos «rect» o «ingles».
## Mide la tabla `ESTADIO_CLUB` del mundo (base y pack real: las mismas filas con otro nombre) y comprueba que lo generado cabe en el aforo real del club.
func _probar_estadios_variedad() -> void:
	_titulo("ESTADIOS: VARIEDAD DE ARQUITECTURA POR CLUB")
	var filas: Dictionary = Datos.tabla("ESTADIO_CLUB") as Dictionary
	var aforo := {}
	for pais: String in (Datos.tabla("PAISES_LIGAS") as Dictionary):
		var d: Dictionary = (Datos.tabla("PAISES_LIGAS") as Dictionary)[pais]
		var todos: Array = (d["clubes"] as Array).duplicate()
		if d.has("segunda"):
			todos.append_array((d["segunda"] as Dictionary)["clubes"])
		for c: Array in todos:
			aforo[String(c[0])] = int(c[4])
	var nucleos := {}
	var formas := {}
	var mal: Array[String] = []
	for nombre: String in filas:
		var f: Dictionary = filas[nombre]
		nucleos["%s|%s|%s|%s|%s|%s" % [f.get("forma"), f.get("niveles"), f.get("techo"), f.get("focos"), f.get("fachada"), f.get("pista")]] = true
		formas[String(f.get("forma"))] = int(formas.get(String(f.get("forma")), 0)) + 1
		var a := int(aforo.get(nombre, 0))
		if a > 0 and a < 10000 and String(f.get("forma")) in ["oval", "caldera", "cuenco"] and f.get("rasgo", "") == "":
			mal.append("%s (%d, %s)" % [nombre, a, f.get("forma")])   ## un club chico no tiene un óvalo
		if String(f.get("forma")) in ["dos", "estrecho", "principal"] and int(f.get("niveles", 1)) > 2:
			mal.append("%s (%s con %d niveles)" % [nombre, f.get("forma"), int(f.get("niveles", 1))])
	var peor := 0
	for k: String in formas:
		peor = maxi(peor, int(formas[k]))
	_linea("  %d filas, %d perfiles de arquitectura distintos, %d formas; la más repetida: %d (%.0f %%)" % [filas.size(), nucleos.size(), formas.size(), peor, 100.0 * float(peor) / float(maxi(1, filas.size()))])
	_comprobar(filas.size() >= 1000, "hay un estadio por club (%d)" % filas.size())
	_comprobar(nucleos.size() >= 300, "al menos 300 perfiles de arquitectura distintos (hay %d; antes 99)" % nucleos.size())
	_comprobar(formas.size() >= 8, "al menos 8 formas distintas (hay %d)" % formas.size())
	_comprobar(float(peor) / float(maxi(1, filas.size())) <= 0.4, "ninguna forma pasa del 40 %% de los estadios (la mayor: %d de %d)" % [peor, filas.size()])
	_comprobar(mal.is_empty(), "lo generado cabe en el aforo del club (fallan %d: %s)" % [mal.size(), ", ".join(mal.slice(0, 4))])

## (12-11, menú central frente al del PES 2020) Los socios del club en la cabecera, con puntos de miles.
func _probar_socios_cabecera() -> void:
	_titulo("SOCIOS DEL CLUB EN LA CABECERA")
	_comprobar(ResumenInicio.miles(20187) == "20.187" and ResumenInicio.miles(1500000) == "1.500.000" and ResumenInicio.miles(999) == "999", "puntos de miles (20.187, 1.500.000, 999)")
	for caso: Array in [["ESP", 4242], ["ARG", 91]]:
		var m := Mundo.new()
		var paises: Array[String] = []
		paises.assign([caso[0]])
		m.generar(paises, int(caso[1]))
		var c: Club = m.ligas[0].clubes[1]
		_comprobar(c.socios > 0 and ResumenInicio.socios_txt(c).contains(ResumenInicio.miles(c.socios)), "%s: %s sale con sus socios (%s)" % [caso[0], c.nombre, ResumenInicio.socios_txt(c)])
	var vacio := Club.new()
	_comprobar(ResumenInicio.socios_txt(vacio) == "" and ResumenInicio.socios_txt(null) == "", "sin socios no se escribe nada")

## (12-11, PES) El pie con las ayudas del mando: solo con mando, y con lo que hacen los botones según el panel lateral esté abierto o no.
func _probar_pie_mando() -> void:
	_titulo("PIE DE PANTALLA CON LAS AYUDAS DEL MANDO")
	var central := PieMando.ayudas(false)
	var lateral := PieMando.ayudas(true)
	_comprobar(central.size() == 4 and lateral.size() == 4, "cuatro ayudas en cada contexto")
	_comprobar(String(central[0][0]) == String(Mando.NOMBRE_BOTON[JOY_BUTTON_A]) and String(central[1][1]) == "Volver", "A elige y B vuelve, con los nombres de la pantalla de controles")
	_comprobar(String(central[2][1]) == "Sección" and String(lateral[2][1]) == "Submenú" and String(lateral[3][1]) == "Menú", "LB/RB y LT/RT cambian de significado con el panel lateral abierto")
	for a: Array in central + lateral:
		_comprobar(Idiomas.t(String(a[1])) != "", "«%s» tiene texto" % String(a[1]))
	var antes := FocoMando.forzar
	var abierto := [false]
	var pie := PieMando.crear(func() -> bool: return bool(abierto[0]))
	add_child(pie)
	FocoMando.forzar = true
	pie._actualizar()
	_comprobar(pie.visible and pie._fila.get_child_count() == 4, "con mando se ve, con 4 botones")
	FocoMando.forzar = false
	pie._actualizar()
	_comprobar(not pie.visible or not Input.get_connected_joypads().is_empty(), "sin mando no se ve")
	FocoMando.forzar = antes
	pie.free()
	## (12-11) El guardián del foco no toma como capa de arriba una que otra capa aisló (menú abierto encima de un evento).
	var base := Control.new()
	add_child(base)
	var evento := Control.new()
	var menu := Control.new()
	for c: Control in [evento, menu]:
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		base.add_child(c)
	_comprobar(GuardianFoco._tapa(evento), "un evento a pantalla completa tapa")
	FocoMando.aislar(menu)
	_comprobar(not GuardianFoco._tapa(evento) and GuardianFoco.capa_arriba(base) == menu, "con un menú aislando encima, la capa de arriba es el menú")
	FocoMando.liberar(menu)
	_comprobar(GuardianFoco._tapa(evento), "al cerrar el menú, el evento vuelve a contar")
	base.free()

## (12-11, decisión del dueño) En el juego, al mover al personaje solo hay primera persona; las demás vistas, solo para capturas y herramientas.
func _probar_solo_primera_persona() -> void:
	_titulo("SOLO PRIMERA PERSONA EN EL JUEGO")
	var fuera := OS.get_environment("DINASTIA_CAMARAS") == "1"
	_comprobar(fuera or (VistaJuego.solo_primera_persona() and VistaJuego.inicial() and not VistaJuego.puede_cambiar()), "sin DINASTIA_CAMARAS se empieza en primera persona y V no cambia de vista")
	for ruta: String in ["res://visor/explorador_estadio_p1.gd", "res://ui/casa_recorrido.gd"]:
		var src := FileAccess.get_file_as_string(ruta)
		_comprobar(src.contains("var primera_persona := VistaJuego.inicial()"), "%s empieza con la vista de VistaJuego" % ruta.get_file())
	for ruta: String in ["res://visor/explorador_estadio.gd", "res://ui/casa_recorrido.gd"]:
		var src := FileAccess.get_file_as_string(ruta)
		_comprobar(src.contains("KEY_V") and src.contains("VistaJuego.puede_cambiar()"), "%s: la tecla V solo cambia de vista fuera del juego" % ruta.get_file())

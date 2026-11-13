extends "res://pruebas/banco/varios_p12.gd"
## [Capa 13 de `varios.gd`, 10-11] _probar_finalissima, _probar_estadios_variedad, _probar_socios_cabecera, _probar_pie_mando, _probar_solo_primera_persona, _probar_piel_paises_nuevos, _probar_mundo_abandonado, _probar_fila_portadas_sigue_foco, _probar_museo_por_titulos, _probar_funciones_puras_ui, _probar_mallas_grada_minima

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
	## (12-11) La planta de decoración: una sola malla con hojas (antes, caja + esfera verde), la misma para todas, y la de Kenney sustituida.
	var pl := PlantaDecor.nodo()
	var pl2 := PlantaDecor.nodo()
	_comprobar(pl.mesh != null and pl.mesh.get_surface_count() == 1 and pl.mesh == pl2.mesh, "la planta es UNA malla compartida (una llamada de dibujo)")
	_comprobar(pl.get_aabb().size.y > 0.8 and pl.get_aabb().size.y < 1.3, "y mide lo de una planta de interior (%.2f m)" % pl.get_aabb().size.y)
	pl.free()
	pl2.free()
	## (12-11) Mirar en primera persona: el dedo por la DERECHA de la pantalla gira y cabecea; por la izquierda (la cruceta) no; con límites.
	var dr := InputEventScreenDrag.new()
	dr.position = Vector2(900, 300)
	dr.relative = Vector2(40, -20)
	var m1 := VistaJuego.mirada_por_evento(dr, 1000.0)
	_comprobar(m1.x > 0.0 and m1.y < 0.0, "arrastrar a la derecha y arriba gira y levanta la mirada")
	dr.position = Vector2(200, 300)
	_comprobar(VistaJuego.mirada_por_evento(dr, 1000.0) == Vector2.ZERO, "por la izquierda (la cruceta) no se mira")
	_comprobar(is_equal_approx(VistaJuego.cabeceo(0.0, 10.0), VistaJuego.CABECEO_MIN) and is_equal_approx(VistaJuego.cabeceo(0.0, -10.0), VistaJuego.CABECEO_MAX), "el cabeceo tiene tope arriba y abajo")

## (12-11, hallazgo de la sesión 14) Los 88 países añadidos después tienen su tono de piel: antes caían en el defecto (claro y a veces rubio).
func _probar_piel_paises_nuevos() -> void:
	_titulo("PIEL Y PELO DE LOS PAÍSES AÑADIDOS DESPUÉS")
	var codigos: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://datos/paises.json"))["paises"] as Dictionary).keys()
	var sin := codigos.filter(func(c: String) -> bool: return not Cara.TONO_MEDIO.has(c) and not PielPaises.TONO.has(c))
	_comprobar(sin.is_empty(), "todos los países tienen tono de piel (%d sin él: %s)" % [sin.size(), str(sin.slice(0, 6))])
	var medias := {}
	for pais: String in ["SEN", "NGA", "FIN", "IND"]:
		var suma := 0.0
		var rub := 0
		for k in 300:
			var j := Jugador.new()
			j.id = "pn_%s_%d" % [pais, k]
			j.pais = pais
			j.edad = 24
			var l := Cara.look_de(j)
			suma += float(Cara.PIELES.find(String(l["piel"])))
			if String(l["peloC"]) in ["#c8a05a", "#8a6a3a"]:
				rub += 1
		medias[pais] = [suma / 300.0, rub]
	_comprobar(float(medias["SEN"][0]) > 5.0 and float(medias["NGA"][0]) > 5.0, "Senegal y Nigeria salen de piel oscura (%.1f y %.1f de 7)" % [medias["SEN"][0], medias["NGA"][0]])
	_comprobar(int(medias["SEN"][1]) == 0 and int(medias["NGA"][1]) == 0, "y sin rubios (%d y %d de 300)" % [medias["SEN"][1], medias["NGA"][1]])
	_comprobar(float(medias["FIN"][0]) < 2.0 and int(medias["FIN"][1]) > 40, "Finlandia, clara y con rubios (%.1f; %d de 300)" % [medias["FIN"][0], medias["FIN"][1]])
	_comprobar(float(medias["IND"][0]) > 3.0 and float(medias["IND"][0]) < 5.0, "India, tono medio (%.1f)" % medias["IND"][0])
	_comprobar(PielPaises.sesgo("SEN", 1.5) < 0.3 and is_equal_approx(PielPaises.sesgo("XXX", 1.5), 1.5), "la grada de Senegal también sale oscura; un país desconocido mantiene el defecto")

## (12-11, orden 36) EL MUSEO CRECE POR TÍTULOS: la planta 3 se abre con el séptimo título (sin esperar a la obra de nivel 5) y la
## primera visita la abre un mini evento a pantalla completa, saltable. Dos clubes de países distintos (regla 34).
func _probar_museo_por_titulos() -> void:
	_titulo("MUSEO: PLANTA EXTRA POR TÍTULOS CON MINI EVENTO")
	var seis: Array = []
	for i in 6:
		seis.append({"anio": 1990 + i, "titulo": "Liga"})
	var siete: Array = seis.duplicate()
	siete.append({"anio": 2001, "titulo": "Copa"})
	_comprobar(not MuseoAmpliado.existe({"inst": {"museo": 1}, "hitos": seis}), "con 6 títulos (caben en la planta 2) y museo nivel 1 no hay planta 3")
	_comprobar(MuseoAmpliado.existe({"inst": {"museo": 1}, "hitos": siete}) and MuseoAmpliado.terminada({"inst": {"museo": 1}, "hitos": siete}), "el séptimo título abre la planta 3 sin la obra")
	_comprobar(not MuseoAmpliado.en_obra({"inst": {"museo": 4}, "obras": {"museo": 3}, "hitos": siete}), "abierta por títulos no sale en obra aunque haya obra del museo")
	_comprobar(MuseoAmpliado.en_obra({"inst": {"museo": 4}, "obras": {"museo": 3}, "hitos": seis}), "sin títulos de más, la obra del nivel 5 sigue mostrando la planta en obra")
	_comprobar(MuseoAmpliado.existe({"inst": {"museo": 5}, "hitos": []}), "la obra de nivel 5 sigue abriendo la planta 3")
	## Dos clubes de países distintos (ENG y ARG): su palmarés (una vitrina por competición) más los títulos que ganas en tu carrera;
	## la planta 3 aparece justo con el séptimo.
	var m := Mundo.new()
	m.generar(["ENG", "ARG"], 1612)
	var vistos := {}
	var bien := true
	for c: Club in m.clubes.values():
		if vistos.has(c.pais) or not ["ENG", "ARG"].has(c.pais):
			continue
		var base := HistoriaClub.hitos_palmares(c).size()
		if base >= MuseoAmpliado.UMBRAL_TITULOS - 1:
			continue
		vistos[c.pais] = base
		m.roles.trofeos.clear()
		for i in MuseoAmpliado.UMBRAL_TITULOS - 1 - base:
			m.roles.trofeos.append({"anio": 2027 + i, "titulo": "Liga"})
		var antes := MuseoAmpliado.existe(EdificioClub.contexto_de(m, c))
		m.roles.trofeos.append({"anio": 2040, "titulo": "Copa"})
		var ctx := EdificioClub.contexto_de(m, c)
		bien = bien and not antes and MuseoAmpliado.existe(ctx) and not MuseoAmpliado.en_obra(ctx)
	m.roles.trofeos.clear()
	_comprobar(vistos.size() == 2 and bien, "un club inglés y uno argentino: con 6 títulos no hay planta 3 y el séptimo ganado la abre (palmarés de partida %s)" % str(vistos))
	## La sala abierta por títulos monta sus vitrinas y su animación, que guarda lo visto como nivel 5.
	var nueve: Array = siete.duplicate()
	nueve.append_array([{"anio": 2005, "titulo": "Liga"}, {"anio": 2010, "titulo": "Supercopa"}])
	var sala := Node3D.new()
	add_child(sala)
	MuseoAmpliado.montar(sala, Rect2(-8.0, 3.5, 16.0, 4.5), 9.0, Color(0.1, 0.3, 0.7), Color(1, 1, 1), {"inst": {"museo": 1}, "hitos": nueve, "titulos": 9, "pais": "ARG"})
	var anim := sala.get_node_or_null("AnimMuseoAmpliado") as MuseoAmpliadoAnim
	_comprobar(anim != null and MuseoAmpliado.vitrinas.size() == 3 and anim.copas.size() == 3, "9 títulos: 3 vitrinas en la planta 3 (%d)" % MuseoAmpliado.vitrinas.size())
	_comprobar(anim != null and anim.nivel == MuseoAmpliado.NIVEL_PLANTA, "abierta por títulos, lo visto cuenta como nivel 5")
	sala.queue_free()
	## El mini evento: dura lo que dura, se salta y avisa al terminar (una sola vez).
	var ev := EventoMuseo.new()
	ev.titulos = 9
	ev.copas_nuevas = 3
	var avisos := [0]
	ev.terminado.connect(func() -> void: avisos[0] += 1)
	add_child(ev)
	ev._process(1.0)
	_comprobar(avisos[0] == 0 and is_instance_valid(ev), "a mitad del evento sigue en pantalla")
	ev.saltar()
	ev.saltar()
	_comprobar(avisos[0] == 1, "saltarlo lo termina y avisa una sola vez")
	var ev2 := EventoMuseo.new()
	var avisos2 := [0]
	ev2.terminado.connect(func() -> void: avisos2[0] += 1)
	add_child(ev2)
	ev2._process(EventoMuseo.DURACION + 0.1)
	_comprobar(avisos2[0] == 1, "sin tocar nada termina solo a los %.1f s" % EventoMuseo.DURACION)

## (12-11, fallo n.º 1 del plan) La generación del mundo por trozos se ABANDONA si la pantalla que la pidió se fue (`Mundo.abandonada`).
func _probar_mundo_abandonado() -> void:
	_titulo("GENERACIÓN DEL MUNDO ABANDONADA")
	_comprobar(not Mundo.abandonada(Callable()), "sin vigía (la generación de siempre) nunca se abandona")
	_comprobar(not Mundo.abandonada(func() -> bool: return true), "con la pantalla viva sigue")
	_comprobar(Mundo.abandonada(func() -> bool: return false), "con la pantalla fuera del árbol se abandona")
	var n := Node.new()
	var vigia := Callable(n, "is_inside_tree")
	n.free()
	_comprobar(Mundo.abandonada(vigia), "con la pantalla ya liberada también se abandona")

## (12-11) Fuera de Principal no hay guardián del foco: la fila de portadas del título (18 botones, 1966 px en 837 a 1280×720) debe seguir
## al foco con mando o teclado; antes la última quedaba fuera del borde y el desplazamiento seguía en 0.
func _probar_fila_portadas_sigue_foco() -> void:
	_titulo("LA FILA DE PORTADAS DEL TÍTULO SIGUE AL FOCO")
	var ini := Inicio.new()
	add_child(ini)
	var fila: HBoxContainer = ini.get("_fila_picker")
	var sc := fila.get_parent() as ScrollContainer if fila != null else null
	_comprobar(sc != null and sc.follow_focus, "el desplazamiento de las portadas sigue al foco")
	ini.free()

## (13-11) FUNCIONES PURAS de ui/ y visor/ con casos límite: cifras con puntos de miles, estrellas, columnas de la tipografía, tiempo de caída y matrículas.
func _probar_funciones_puras_ui() -> void:
	_titulo("FUNCIONES PURAS DE UI Y VISOR: CASOS LÍMITE")
	for n in 4:
		_comprobar(PlantillaEstilos.texto_estrellas(n).length() == 3 and PlantillaEstilos.texto_estrellas(n).count("★") == n, "%d estrellas: %s" % [n, PlantillaEstilos.texto_estrellas(n)])
	var casos := [
		[{"clave": "caja_total", "valor": 312, "meta": 500}, "312 / 500 M"],
		[{"clave": "goles", "valor": 1000, "meta": 999}, "1.000 / 999"],
		[{"clave": "socios", "valor": 1234567, "meta": 20000000}, "1.234.567 / 20.000.000"],
		[{"clave": "deuda", "valor": -1500, "meta": 0}, "-1.500 / 0"],
		[{"clave": "caja_argentina", "valor": 0, "meta": 1}, "0 / 1 M"]]
	for c: Array in casos:
		var obtenido := ListaLogrosLargo.cifra(c[0])
		_comprobar(obtenido == String(c[1]), "cifra de logro «%s»" % String(c[1]) + ("" if obtenido == String(c[1]) else " (salió «%s»)" % obtenido))
	_comprobar(SponsorKit.columnas("") == 1 and SponsorKit.columnas("   ") == 8 and SponsorKit.columnas("\u0001") == 1, "columnas: vacío = 1, tres espacios = 8, carácter sin letra = 1")
	var letra := String(SponsorKit.FUENTE.keys()[0])
	_comprobar(SponsorKit.columnas(letra) == 5 and SponsorKit.columnas(letra + " " + letra) == 6 * 2 + 3 - 1, "columnas: una letra ocupa 6 menos la separación; dos con un espacio, 14")
	var t := LeagueAcciones.tiempo_a_altura(0.0, 10.0, 0.0, 9.8)
	_comprobar(absf(t - 20.0 / 9.8) < 0.0001, "tiempo a la altura de salida: vuelve a bajar a los %.3f s" % t)
	_comprobar(absf(LeagueAcciones.tiempo_a_altura(0.0, 10.0, 4.0, 9.8) - (10.0 + sqrt(21.6)) / 9.8) < 0.0001, "tiempo bajando por 4 m")
	_comprobar(LeagueAcciones.tiempo_a_altura(0.0, 5.0, 20.0, 9.8) == -1.0, "si no llega a la altura pedida devuelve -1")
	var rx := RegEx.create_from_string("^[A-HJ-NP-PR-VX-Z]{2} \\d{3} [A-HJ-NP-PR-VX-Z]{2}$")
	var bien := true
	for i in [0, 1, 7, 99, 1000, 123456, -5, 2147483647]:
		bien = bien and rx.search(CocheDetalle.texto_placa(i)) != null and CocheDetalle.texto_placa(i) == CocheDetalle.texto_placa(i)
	_comprobar(bien, "matrículas «AB 123 CD»: formato correcto, estable y sin letras prohibidas, incluidos 0, negativos y el mayor entero")
	var distintas := {}
	for i in 200:
		distintas[CocheDetalle.texto_placa(i)] = true
	_comprobar(distintas.size() > 150, "200 coches dan más de 150 matrículas distintas (%d)" % distintas.size())

## (13-11, decisión del dueño) La semilla del mundo ya no sale en la portada: vive en Ajustes → Informe de fallos y el informe copiado la lleva.
func _probar_semilla_en_ajustes() -> void:
	_titulo("LA SEMILLA DEL MUNDO EN AJUSTES")
	for sem: int in [5361, 0, 2147483647]:
		var inf := AjustesRegistro.informe_con_semilla(sem, "linea 1\nlinea 2")
		_comprobar(inf == "Semilla del mundo: %d\nlinea 1\nlinea 2" % sem, "el informe empieza por la semilla %d y conserva el resto" % sem)
	_comprobar(AjustesRegistro.informe_con_semilla(-1, "solo informe") == "solo informe", "sin mundo, el informe es el de siempre")
	var fuente := FileAccess.get_file_as_string("res://ui/principal/ciclo_partida.gd")
	_comprobar(not fuente.contains("Semilla [color"), "el aviso de «Mundo nuevo» de la portada ya no lleva la semilla")

## (13-11, orden del dueño) La MÚSICA LIBRE (`MusicaLibre`): el catálogo está completo y es CC0, cada pista carga, las filas malas se descartan, la
## rotación y la situación funcionan y `Musica` la pone solo en menús/club/parón.
func _probar_musica_libre() -> void:
	_titulo("MÚSICA LIBRE (CC0): CATÁLOGO, FILTRO Y ROTACIÓN")
	var l := MusicaLibre.pistas()
	_comprobar(l.size() >= 1, "hay pistas libres utilizables (%d)" % l.size())
	for d: Dictionary in l:
		var ok_campos := str(d["autor"]) != "" and str(d["url"]).begins_with("https://") and str(d.get("sha256_original", "")).length() == 64 and str(d["licencia"]) in MusicaLibre.LICENCIAS_VALIDAS
		var f := MusicaLibre.cargar(d)
		_comprobar(ok_campos and f != null and f.get_length() > 10.0, "%s: autor, origen, licencia, huella y archivo (%.0f s)" % [d["id"], f.get_length() if f != null else 0.0])
	var buena := {"id": "a", "archivo": "x.ogg", "autor": "Ana", "licencia": "CC0 1.0", "usos": ["oficina"]}
	var filas := [buena, buena.merged({"licencia": "CC-BY 4.0"}, true), buena.merged({"autor": ""}, true), buena.merged({"usos": "oficina"}, true), buena.merged({"id": ""}, true), "no es fila"]
	_comprobar(MusicaLibre._filtrar(filas, false).size() == 1, "el filtro solo deja la fila completa de licencia permitida (CC-BY, sin autor, usos rotos, sin id y no-filas fuera)")
	_comprobar(MusicaLibre._filtrar([buena], true).is_empty(), "una fila cuyo archivo no está en el proyecto se descarta")
	for sit: String in ["partido", "final", "celebracion", "grada"]:
		_comprobar(MusicaLibre.situacion_libre(sit) == "", "en «%s» no suena música grabada (suena la compuesta, que cambia con el juego)" % sit)
	_comprobar(MusicaLibre.situacion_libre("parón") == "paron" and MusicaLibre.situacion_libre("paron") == "paron", "el parón tiene su situación")
	_comprobar(MusicaLibre.situacion_libre("") == "oficina" and MusicaLibre.situacion_libre("cualquier cosa") == "oficina", "lo demás es oficina (menús y club)")
	var n := MusicaLibre.para("oficina").size()
	if n >= 2:
		_comprobar(str(MusicaLibre.elegir("oficina", 0)["id"]) != str(MusicaLibre.elegir("oficina", 1)["id"]), "la rotación cambia de pista")
	_comprobar(MusicaLibre.elegir("oficina", -1) == MusicaLibre.elegir("oficina", n - 1) and MusicaLibre.elegir("oficina", n) == MusicaLibre.elegir("oficina", 0), "la rotación da la vuelta (también con índices negativos)")
	_comprobar(MusicaLibre.elegir("no_existe", 3).is_empty(), "una situación sin pistas da {}")
	_comprobar(MusicaLibre.creditos().size() == l.size(), "los créditos listan una línea por pista")
	var enc := Musica.encendida
	var lib := Musica.libre
	Musica.encendida = true
	Musica.libre = true
	_comprobar(Musica.poner_libre("oficina") and Musica._sonando.begins_with("libre:"), "con la música libre encendida, el menú pone una pista libre")
	Musica.encendida = false
	_comprobar(not Musica.poner_libre("oficina"), "con la música apagada no pone nada")
	Musica.parar()
	Musica.encendida = enc
	Musica.libre = lib

## (13-11, queja del dueño: «siento que la mayoría de los sonidos no se ejecutan») De los 215 sonidos del catálogo, 89 no los pedía ningún código. Esta prueba
## lo vigila: lo que no se pide tiene que estar en `pruebas/sonidos_sin_pedir.txt` (que solo debe encogerse) y lo que ya se pide no puede seguir en ella.
func _probar_sonidos_pedidos() -> void:
	_titulo("TODOS LOS SONIDOS SE PIDEN (O ESTÁN APUNTADOS COMO PENDIENTES)")
	var fuentes := PackedStringArray()
	_buscar_gd("res://", fuentes)
	var texto := ""
	for f: String in fuentes:
		texto += FileAccess.get_file_as_string(f) + "\n"
	var prefijos: Array[String] = []
	var re := RegEx.new()
	re.compile("toca\\(\\s*\"([a-z0-9_]*)\"\\s*\\+|toca\\(\\s*\"([a-z0-9_]*)%[sd]")
	for m: RegExMatch in re.search_all(texto):
		var p := m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
		if p != "":
			prefijos.append(p)
	var pendientes := {}
	for l: String in FileAccess.get_file_as_string("res://pruebas/sonidos_sin_pedir.txt").split("\n"):
		if l.strip_edges() != "" and not l.begins_with("#"):
			pendientes[l.strip_edges()] = true
	var catalogo: Array = Sonido.catalogo()
	var sin_pedir: Array[String] = []
	var ya_pedidos: Array[String] = []
	var nuevos: Array[String] = []
	for n: String in catalogo:
		var pedido := texto.contains("\"" + n + "\"")
		for p: String in prefijos:
			pedido = pedido or n.begins_with(p)
		if not pedido:
			sin_pedir.append(n)
			if not pendientes.has(n):
				nuevos.append(n)
		elif pendientes.has(n):
			ya_pedidos.append(n)
	_linea("  %d sonidos en el catálogo, %d sin pedir, %d apuntados como pendientes" % [catalogo.size(), sin_pedir.size(), pendientes.size()])
	_comprobar(nuevos.is_empty(), "ningún sonido nuevo sin pedir (o se pide, o se apunta en sonidos_sin_pedir.txt): %s" % str(nuevos))
	_comprobar(ya_pedidos.is_empty(), "ningún sonido de la lista de pendientes se pide ya (bórralo de la lista): %s" % str(ya_pedidos))
	for n: String in pendientes:
		if not catalogo.has(n):
			_comprobar(false, "«%s» está en la lista de pendientes pero ya no existe en el catálogo (bórralo de la lista)" % n)

func _buscar_gd(dir: String, sal: PackedStringArray) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub: String in d.get_directories():
		if not (sub in ["pruebas", "terceros", "addons", ".godot", ".git"]):
			_buscar_gd(dir.path_join(sub), sal)
	var rs := RegEx.new()
	rs.compile("^sonido(_p\\d+)*\\.gd$")
	for f: String in d.get_files():
		if f.ends_with(".gd") and rs.search(f) == null:
			sal.append(dir.path_join(f))

## (13-11) Las mallas de grada de MÍNIMA: menos triángulos que antes (butaca 28, público 16) y TODAS las caras hacia fuera (giro horario visto desde fuera; si no, se ven huecas).
func _probar_mallas_grada_minima() -> void:
	_titulo("MALLAS DE GRADA DE MÍNIMA: TRIÁNGULOS Y CARAS HACIA FUERA")
	for caso: Array in [["butaca", MallasGradaMinima.butaca(), 28], ["butaca de MEDIA", MallasGradaMinima.butaca_lejos(), 68], ["público", MallasGradaMinima.hincha(), 16]]:
		var arr: Array = (caso[1] as Mesh).surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var mal := 0
		for t in v.size() / 3:
			var cruz := (v[t * 3 + 1] - v[t * 3]).cross(v[t * 3 + 2] - v[t * 3])
			if cruz.dot(n[t * 3]) >= 0.0 or cruz.length() < 0.0001:
				mal += 1
		_comprobar(v.size() / 3 == int(caso[2]), "%s: %d triángulos (esperados %d)" % [caso[0], v.size() / 3, int(caso[2])])
		_comprobar(mal == 0, "%s: ningún triángulo del revés ni degenerado (%d)" % [caso[0], mal])

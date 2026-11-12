extends "res://pruebas/banco/varios_p12.gd"
## [Capa 13 de `varios.gd`, 10-11] _probar_finalissima, _probar_estadios_variedad, _probar_socios_cabecera, _probar_pie_mando, _probar_solo_primera_persona, _probar_piel_paises_nuevos, _probar_finanzas_por_pantallas, _probar_agentes_confianza, _probar_cantera_por_pantallas, _probar_informe_abre_su_pantalla, _probar_paginador_submenu

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

## (12-11, nota del dueño: menús subdivididos a pantalla completa) Finanzas ya no es una página: cinco submenús de «Dinero», uno por sección
## de `PantallaFinanzas.SECCIONES`, con su tarjeta, su icono dibujado y su banda de cifras clave.
func _probar_finanzas_por_pantallas() -> void:
	_titulo("FINANZAS EN CINCO PANTALLAS (MENÚ DINERO)")
	var seccs: Array = []
	var con_dibujo := true
	for s: Dictionary in MenusLaterales.menu_por_id("dinero")["subs"]:
		if String(s.get("tab", "")) == "Finanzas":
			seccs.append(String(s.get("secc", "")))
			con_dibujo = con_dibujo and String(s.get("desc", "")) != "" and String(s.get("label", "")) != ""
	var guion: GDScript = load("res://ui/pantallas/pantalla_finanzas_p1.gd")   ## la capa donde vive la constante
	var secciones: Array = guion.get_script_constant_map().get("SECCIONES", [])
	_comprobar(seccs.size() == 5 and seccs == secciones, "los 5 submenús de Finanzas son las 5 secciones de la pantalla, en orden (%s)" % [seccs])
	_comprobar(con_dibujo, "cada uno con su nombre y su descripción para la tarjeta de la portada")
	var traducidos := true
	var antes := Idiomas.idioma
	Idiomas.idioma = "en"
	for s: Dictionary in MenusLaterales.menu_por_id("dinero")["subs"]:
		if String(s.get("tab", "")) == "Finanzas" and Idiomas.t(String(s["label"])) == String(s["label"]):
			traducidos = false
	Idiomas.idioma = antes
	_comprobar(traducidos, "y traducidos (inglés)")
	var banda := CifrasClave.banda([["Caja", "1.0M EUR", Color.GREEN], ["Deuda", "sin deuda", Color.GRAY], ["Créditos abiertos", "0", Color.WHITE]], Color.GRAY)
	var rotulos := banda.find_children("*", "Label", true, false)
	_comprobar(banda.get_child_count() == 3 and rotulos.size() == 6 and (rotulos[0] as Label).text == "CAJA" and (rotulos[1] as Label).text == "1.0M EUR",
		"la banda de cifras clave pinta una ficha por cifra: rótulo en mayúsculas y la cifra grande")
	banda.free()
	## En un teléfono de pie, cuatro fichas van de a dos por fila (en fila se cortaban); tres o en horizontal, en fila.
	var forzar_antes := EscalaMovil.forzar
	EscalaMovil.forzar = true
	PantallaMovil.ventana_forzada = Vector2i(1080, 2400)
	var cuatro := [["A", "1", Color.WHITE], ["B", "2", Color.WHITE], ["C", "3", Color.WHITE], ["D", "4", Color.WHITE]]
	var de_pie := CifrasClave.banda(cuatro, Color.GRAY)
	PantallaMovil.ventana_forzada = Vector2i(2400, 1080)
	var tumbado := CifrasClave.banda(cuatro, Color.GRAY)
	PantallaMovil.ventana_forzada = Vector2i.ZERO
	EscalaMovil.forzar = forzar_antes
	_comprobar(de_pie is GridContainer and (de_pie as GridContainer).columns == 2 and de_pie.get_child_count() == 4 and tumbado is HBoxContainer,
		"teléfono de pie: 4 fichas en 2 columnas; tumbado: en fila")
	de_pie.free()
	tumbado.free()
	var oscura := CifrasClave.banda([["Formación", "4-4-2", Color("5a0f1e")]], Color.GRAY)
	var cifra_oscura := oscura.find_children("*", "Label", true, false)[1] as Label
	_comprobar(cifra_oscura.get_theme_color("font_color").get_luminance() >= 0.3, "una cifra en un color de club oscuro se aclara para leerse (luminancia %.2f)" % cifra_oscura.get_theme_color("font_color").get_luminance())
	oscura.free()
	## «Próximo partido» en tres pantallas (`PreviaPartido`).
	var del_partido: Array = []
	for s: Dictionary in MenusLaterales.menu_por_id("partido")["subs"]:
		if String(s.get("tab", "")) == "Partido":
			del_partido.append(String(s.get("secc", "")))
	_comprobar(del_partido == PreviaPartido.SECCIONES, "los 3 submenús de Partido son las 3 secciones de la previa (%s)" % [del_partido])
	## «Táctica» en cuatro pantallas (`TacticaSecciones`), en Plantel; desde Partido se llega a la pizarra y al once.
	var de_tactica: Array = []
	for s: Dictionary in MenusLaterales.menu_por_id("plantel")["subs"]:
		if String(s.get("tab", "")) == "Táctica":
			de_tactica.append(String(s.get("secc", "")))
	_comprobar(de_tactica == TacticaSecciones.SECCIONES, "los 4 submenús de Táctica son las 4 secciones de la pizarra (%s)" % [de_tactica])
	var en_partido := true
	for s: Dictionary in MenusLaterales.menu_por_id("partido")["subs"]:
		if String(s.get("tab", "")) == "Táctica" and not TacticaSecciones.SECCIONES.has(String(s.get("secc", ""))):
			en_partido = false
	_comprobar(en_partido, "y los accesos a Táctica desde el menú Partido apuntan a una sección que existe")
	## «Entrenamiento» en tres pantallas (misma pantalla, `SECC_ENTRENAR`).
	var de_entrenar: Array = []
	for s: Dictionary in MenusLaterales.menu_por_id("plantel")["subs"]:
		if String(s.get("tab", "")) == "Entrenar":
			de_entrenar.append(String(s.get("secc", "")))
	var capa: GDScript = load("res://ui/pantallas/pantalla_club_vida_p3.gd")
	_comprobar(de_entrenar == capa.get_script_constant_map().get("SECC_ENTRENAR", []), "los 3 submenús de Entrenamiento son sus 3 secciones (%s)" % [de_entrenar])

## (12-11) La confianza de un representante va de −10 a +10 y arranca en 0: en Contratos solo va en rojo el que tiene dos clientes o más Y
## desconfía (antes iban todos en rojo desde el primer día), y perderla tiene tope.
func _probar_agentes_confianza() -> void:
	_titulo("AGENTES: QUIÉN APRIETA Y EL TOPE DE LA CONFIANZA")
	_comprobar(not Cantera.agente_aprieta(3, 0) and not Cantera.agente_aprieta(1, -5) and Cantera.agente_aprieta(2, -1) and not Cantera.agente_aprieta(4, 6),
		"aprieta el que tiene 2 clientes o más y confianza negativa; neutral (0) no va en rojo")
	for pais: String in ["ARG", "GER"]:
		var m := Mundo.new()
		m.generar([pais], 1211)
		m.tomar_el_mando(m.ligas[0].clubes[5].id)
		var en_rojo := 0
		for f: Dictionary in m.cantera.agencias_del_plantel():
			if Cantera.agente_aprieta((f["jugadores"] as Array).size(), int(f["confianza"])):
				en_rojo += 1
		_comprobar(not m.cantera.agencias_del_plantel().is_empty() and en_rojo == 0, "%s: partida nueva, hay agencias y ninguna en rojo (%d)" % [pais, en_rojo])
		var ag := String((m.cantera.agencias_del_plantel()[0]["agente"] as Dictionary).get("nombre", ""))
		for k in 9:
			m.cantera._mover_confianza(ag, -2)
		_comprobar(m.cantera.confianza_de(ag) == -10, "%s: perder confianza se queda en −10 (%d)" % [pais, m.cantera.confianza_de(ag)])


## (12-11) «Cantera» en tres pantallas; «Linaje» (menú Historia) abre directamente la suya.
func _probar_cantera_por_pantallas() -> void:
	_titulo("CANTERA EN TRES PANTALLAS")
	var de_cantera: Array = []
	for s: Dictionary in MenusLaterales.menu_por_id("plantel")["subs"]:
		if String(s.get("tab", "")) == "Cantera":
			de_cantera.append(String(s.get("secc", "")))
	var capa: GDScript = load("res://ui/pantallas/pantalla_cantera_p2.gd")
	_comprobar(de_cantera == capa.get_script_constant_map().get("SECC_CANTERA", []), "los 3 submenús de Cantera son sus 3 secciones (%s)" % [de_cantera])
	var sueltos := 0
	for m: Dictionary in MenusLaterales.MENUS:
		for s: Dictionary in m["subs"]:
			if String(s.get("tab", "")) in ["Cantera", "Finanzas", "Partido", "Táctica", "Entrenar", "Clubes"] and String(s.get("secc", "")) == "":
				sueltos += 1
	_comprobar(sueltos == 0, "ningún menú abre una pestaña partida sin decir qué pantalla (%d)" % sueltos)
	var de_clubes: Array = []
	for s: Dictionary in MenusLaterales.menu_por_id("competiciones")["subs"]:
		if String(s.get("tab", "")) == "Clubes":
			de_clubes.append(String(s.get("secc", "")))
	var vistas: GDScript = load("res://ui/principal/vistas_menu.gd")
	_comprobar(de_clubes == vistas.get_script_constant_map().get("SECC_CLUBES", []), "los 3 submenús de Ligas y clubes son sus 3 secciones (%s)" % [de_clubes])

## (12-11) Los avisos del informe semanal que llevan a una pestaña partida en pantallas dicen a cuál (antes abrían la última que se miró).
func _probar_informe_abre_su_pantalla() -> void:
	_titulo("INFORME DE LA SEMANA: CADA AVISO ABRE SU PANTALLA")
	_comprobar(MenusLaterales.secciones_de("Finanzas").size() == 5 and MenusLaterales.secciones_de("Mercado").is_empty(), "se sabe qué pestañas están partidas (Finanzas en 5, Mercado en ninguna)")
	for caso: Array in [["CHI", 3], ["ITA", 11]]:
		var m := Mundo.new()
		m.generar([caso[0]], 1212)
		m.tomar_el_mando(m.ligas[0].clubes[int(caso[1])].id)
		m.mi_club().saldo = -5000   ## fuerza el aviso de la caja en rojo
		var mal: Array = []
		var con_secc := 0
		for f: Dictionary in m.informe_de_gestion():
			var partes := MenusLaterales.secciones_de(String(f.get("tab", "")))
			if partes.is_empty():
				continue
			con_secc += 1
			if not partes.has(String(f.get("secc", ""))):
				mal.append(String(f["txt"]).left(30))
		_comprobar(con_secc >= 1 and mal.is_empty(), "%s: los %d avisos que van a una pestaña partida nombran una pantalla que existe %s" % [caso[0], con_secc, mal])


## (12-11) El paginador en pantalla de un menú: anterior y siguiente saltan las acciones y dan la vuelta; «n / N» cuenta solo pantallas.
func _probar_paginador_submenu() -> void:
	_titulo("PAGINADOR DE MENÚ: ANTERIOR · n / N · SIGUIENTE")
	var subs := [{"tab": "A", "label": "a"}, {"accion": "x", "label": "acción"}, {"tab": "B", "label": "b"}, {"tab": "C", "label": "c"}]
	_comprobar(PaginadorSubmenu.vecino(subs, 0, 1) == 2 and PaginadorSubmenu.vecino(subs, 2, -1) == 0, "anterior y siguiente saltan la acción del medio")
	_comprobar(PaginadorSubmenu.vecino(subs, 3, 1) == 0 and PaginadorSubmenu.vecino(subs, 0, -1) == 3, "y dan la vuelta por los extremos")
	_comprobar(PaginadorSubmenu.puesto(subs, 2) == Vector2i(2, 3), "«2 / 3»: la acción no cuenta como pantalla (%s)" % PaginadorSubmenu.puesto(subs, 2))
	_comprobar(PaginadorSubmenu.vecino([{"tab": "A", "label": "a"}, {"accion": "x", "label": "y"}], 0, 1) == -1, "con una sola pantalla no hay vecina (el paginador se esconde)")
	for id: String in ["dinero", "plantel", "competiciones"]:
		var ss: Array = MenusLaterales.menu_por_id(id)["subs"]
		var vistos := {}
		var i := 0
		while (ss[i] as Dictionary).has("accion"):
			i += 1
		for k in ss.size():
			vistos[i] = true
			i = PaginadorSubmenu.vecino(ss, i, 1)
		_comprobar(vistos.size() == PaginadorSubmenu.puesto(ss, 0).y, "%s: pasando «siguiente» se recorren todas sus pantallas (%d)" % [id, vistos.size()])

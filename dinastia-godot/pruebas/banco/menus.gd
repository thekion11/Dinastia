extends "res://pruebas/banco/base.gd"
## [Banco · grupo «menus»] (12-11) Los menús partidos en pantallas completas y lo que cuelga de ellos: Finanzas, Próximo partido, Táctica,
## Entrenamiento, Cantera y Ligas en secciones, la banda de cifras clave, el paginador, los avisos del informe semanal y la confianza de
## los agentes en Contratos. Archivo propio para no chocar con `varios_p13.gd` en cada fusión con `main`.

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

## (12-11) Las casillas de la convocatoria se ven sobre el azul noche: marco claro sin marcar, cuadro dorado con palomita marcada.
func _probar_casilla_clara() -> void:
	_titulo("CASILLAS VISIBLES SOBRE FONDO OSCURO")
	var cb := CheckBox.new()
	CasillaClara.estilar(cb)
	var sin: Texture2D = cb.get_theme_icon("unchecked")
	var con: Texture2D = cb.get_theme_icon("checked")
	_comprobar(sin != null and con != null and sin != con and sin.get_width() == CasillaClara.LADO, "la casilla lleva sus dos iconos propios, de %d px" % CasillaClara.LADO)
	var borde := sin.get_image().get_pixel(0, CasillaClara.LADO / 2)
	var centro := con.get_image().get_pixel(3, 3)
	_comprobar(borde.a > 0.6 and borde.get_luminance() > 0.8, "sin marcar: un marco claro que se ve sobre fondo oscuro (%.2f)" % borde.get_luminance())
	_comprobar(centro.a > 0.9 and centro.get_luminance() > 0.4, "marcada: un cuadro lleno y claro (%.2f)" % centro.get_luminance())
	var otra := CheckBox.new()
	CasillaClara.estilar(otra)
	_comprobar(otra.get_theme_icon("checked") == con, "los iconos se dibujan una vez y se comparten")
	cb.free()
	otra.free()

## (12-11) Partir una pestaña en pantallas no cambia el nombre de su atajo de teclado: la primera pantalla conserva el de la pestaña (tecla
## de fábrica, migración y teclas reasignadas siguen valiendo) y ninguna acción se repite.
func _probar_atajos_tras_partir() -> void:
	_titulo("ATAJOS DE TECLADO: LOS NOMBRES NO CAMBIAN AL PARTIR UN MENÚ")
	AtajosCentrales._catalogo.clear()
	for par: Array in [["sub:plantel:Táctica", "dinastia_sub_plantel_tactica"], ["sub:dinero:Finanzas", "dinastia_sub_dinero_finanzas"],
			["sub:plantel:Entrenar", "dinastia_sub_plantel_entrenar"], ["sub:partido:Partido", "dinastia_sub_partido_partido"],
			["sub:plantel:Cantera", "dinastia_sub_plantel_cantera"], ["sub:competiciones:Clubes", "dinastia_sub_competiciones_clubes"],
			["sub:estadio:Estadio", "dinastia_sub_estadio_estadio"]]:
		_comprobar(AtajosCentrales.accion_de_clave(String(par[0])) == String(par[1]), "%s sigue siendo %s" % [par[0], par[1]])
	var vistas := {}
	var repetidas: Array = []
	var con_tecla_t := ""
	for e: Dictionary in AtajosCentrales.catalogo():
		if vistas.has(e["accion"]):
			repetidas.append(e["accion"])
		vistas[e["accion"]] = true
		if int(e["tecla"]) == KEY_T:
			con_tecla_t = String(e["accion"])
	_comprobar(repetidas.is_empty(), "ninguna acción de atajo se repite %s" % [repetidas])
	_comprobar(con_tecla_t == "dinastia_sub_plantel_tactica", "la T sigue abriendo Táctica (%s)" % con_tecla_t)
	var faltan: Array = []
	for vieja: String in AtajosCentrales.MIGRACION:
		if AtajosCentrales.accion_de_clave(String(AtajosCentrales.MIGRACION[vieja])) == "":
			faltan.append(vieja)
	_comprobar(faltan.is_empty(), "todas las teclas viejas de la migración tienen destino %s" % [faltan])

## (12-11) Las pantallas sin datos (rivales o goleadores en una partida nueva) dicen qué pasa: icono, título y pista, centrados.
func _probar_estado_vacio() -> void:
	_titulo("ESTADO VACÍO DE UNA PANTALLA")
	var v := EstadoVacio.crear("⚔️", "Sin rivales", "Se construye con cada cruce.", Color.WHITE, Color.GRAY, 300.0)
	_comprobar(v.get_child_count() == 3 and v.custom_minimum_size.y >= 300.0, "icono, título y pista, con su alto")
	var titulo := v.get_child(1) as Label
	var pista := v.get_child(2) as Label
	_comprobar(titulo != null and titulo.text == "Sin rivales" and titulo.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "el título, centrado")
	_comprobar(pista != null and pista.autowrap_mode != TextServer.AUTOWRAP_OFF, "la pista parte renglón (no saca la pantalla del móvil)")
	_comprobar(titulo.get_theme_color("font_color").get_luminance() > pista.get_theme_color("font_color").get_luminance(), "el título pesa más que la pista")
	v.free()

## (12-11) La web del club se propone con el dominio de SU país y sin tildes ni espacios (antes «.cl» para todos).
func _probar_dominio_del_club() -> void:
	_titulo("DOMINIO DE LA WEB DEL CLUB")
	var c := Club.new()
	c.nombre = "Pleiße FC"
	c.pais = "GER"
	_comprobar(ClubDentro.dominio_de(c) == "pleissefc.de", "un club alemán: %s" % ClubDentro.dominio_de(c))
	c.nombre = "Viña Marina"
	c.pais = "CHI"
	_comprobar(ClubDentro.dominio_de(c) == "vinamarina.cl", "uno chileno: %s" % ClubDentro.dominio_de(c))
	c.nombre = "Kashiwa Sol"
	c.pais = "JPN"
	_comprobar(ClubDentro.dominio_de(c) == "kashiwasol.jp", "uno japonés: %s" % ClubDentro.dominio_de(c))
	c.pais = "ZZZ"
	_comprobar(ClubDentro.dominio_de(c).ends_with(".com"), "un país sin dominio conocido va a .com")

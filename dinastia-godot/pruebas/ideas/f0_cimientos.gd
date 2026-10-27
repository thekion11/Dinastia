extends BaseIdea
## f0 · CIMIENTOS (fase 0, pasos 2 y 3): `Principal` dejó de ser el dueño de los
## Ajustes (tipografía, FPS, ranuras, sección) y de los estilos del menú
## (píldoras, rotación de estética). Esta prueba fija el CONTRATO que queda:
## los puentes de `Principal` leen y escriben en la clase dueña, `set()`/`get()`
## por nombre siguen funcionando (lo usan las capturas) y el vestido del menú
## cambia de verdad con el estilo. Usa la pantalla principal real.

var _p: Principal

func _ready() -> void:
	await get_tree().process_frame
	await _probar_async()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _probar_async() -> void:
	_titulo("f0: puentes de Ajustes y de EstilosMenu")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _frames(6)

	## --- Paso 2: Ajustes -------------------------------------------------
	var aj: PantallaAjustes = _p._ui_ajustes
	_comprobar(aj != null, "Principal tiene su PantallaAjustes")
	_comprobar(PantallaAjustes.TIPOGRAFIAS.size() == 7 and PantallaAjustes.TIPOGRAFIAS.has("juego"), "las 7 tipografías viven en PantallaAjustes")
	_comprobar(PantallaAjustes.FPS_OPCIONES == [30, 60, 120, 0] and PantallaAjustes.RANURAS.size() == 3, "FPS y ranuras viven en PantallaAjustes")
	_comprobar(PantallaAjustes.SECCIONES_AJUSTES.size() == 6, "las 6 secciones de Ajustes viven en PantallaAjustes")
	_p._tipografia = "estrecha"
	_comprobar(aj.tipografia == "estrecha", "escribir p._tipografia llega a la dueña")
	aj.tipografia = "titular"
	_comprobar(_p._tipografia == "titular", "leer p._tipografia viene de la dueña")
	_p.set("_fps_elegido", 0)
	_comprobar(aj.fps_elegido == 0 and int(_p.get("_fps_elegido")) == 0, "set()/get() por nombre pasan por el puente de FPS")
	_p.set("_secc_ajustes", "partida")
	_comprobar(aj.seccion == "partida", "la sección abierta vive en la dueña")
	var f := _p._fuente_de("estrecha")
	_comprobar(f != null and f == aj.fuente_de("estrecha"), "la fuente se resuelve una vez y por la dueña (caché compartida)")
	_comprobar(_p._fuente_de("no_existe") == null, "una tipografía desconocida da null, como antes")
	## Pintar la sección Partida (ranuras) y Aspecto (tipografía) sin errores.
	## Abrir el grupo elige su primer chip (y con él la sección «audio»), así
	## que la sección se fija DESPUÉS de abrirlo, como hace uiaj_ajustes.
	_p.call("_elegir_grupo", "ajustes")
	await _frames(2)
	aj.seccion = "partida"
	aj._pintar_ajustes()
	await _frames(2)
	_comprobar(_hay_etiqueta(_p, Idiomas.t("RANURAS DE GUARDADO")), "la sección Partida pinta las ranuras desde PantallaAjustes")
	aj.seccion = "aspecto"
	aj._pintar_ajustes()
	await _frames(2)
	_comprobar(_hay_etiqueta(_p, Idiomas.t("Tipografia")), "la sección Aspecto pinta la tipografía desde PantallaAjustes")
	_p._tipografia = "juego"
	_p._fps_elegido = 60

	## --- Paso 3: EstilosMenu ----------------------------------------------
	var es: EstilosMenu = _p._estilos
	_comprobar(es != null, "Principal tiene su EstilosMenu")
	_comprobar(EstilosMenu.ESTILOS_MENU.size() == 3 and EstilosMenu.DISENOS_CENTRAL.size() == 8, "3 estilos y 8 diseños viven en EstilosMenu")
	_comprobar(is_equal_approx(EstilosMenu.ROTAR_CADA, 600.0), "la rotación sigue siendo cada 10 minutos")
	var reloj := es._reloj_diseno
	_comprobar(reloj != null and reloj.is_inside_tree() and reloj.get_parent() == _p and is_equal_approx(reloj.wait_time, 600.0), "el reloj de la rotación cuelga de Principal con 600 s")
	_p._estilo_menu = "compacto"
	_comprobar(es.estilo == "compacto", "escribir p._estilo_menu llega a la dueña")
	var bc := _p._pildora("Mercado", 12, 32)
	_comprobar(bc.get_theme_font_size("font_size") == 11 and is_equal_approx(bc.custom_minimum_size.y, 28.0), "en «compacto» la píldora es un punto más pequeña y 4 px más baja")
	_p._estilo_menu = "barra"
	var bb := _p._pildora("Mercado", 12, 32)
	var caja_b := bb.get_theme_stylebox("normal") as StyleBoxFlat
	_comprobar(caja_b != null and caja_b.corner_radius_top_left == 3, "en «barra» las esquinas son rectas (radio 3)")
	_p._estilo_menu = "pildora"
	var bp := _p._pildora("Mercado", 12, 32)
	var caja_p := bp.get_theme_stylebox("normal") as StyleBoxFlat
	_comprobar(caja_p != null and caja_p.corner_radius_top_left == 16, "en «píldora» el radio es la mitad del alto")
	## La rotación respeta el interruptor y, encendida, cambia los cuatro ajustes del diseño.
	_p._rotar_diseno = false
	var pal0 := _p._paleta
	var i0 := es._diseno_i
	es.siguiente_diseno()
	await _frames(2)
	_comprobar(es._diseno_i == i0 and _p._paleta == pal0, "con la rotación apagada no cambia nada")
	_p._rotar_diseno = true
	es.siguiente_diseno()
	await _frames(60)
	var d: Array = EstilosMenu.DISENOS_CENTRAL[es._diseno_i]
	_comprobar(es._diseno_i == (i0 + 1) % 8, "la rotación avanza un diseño")
	_comprobar(_p._paleta == String(d[0]) and _p._estilo_menu == String(d[1]) and _p._forma_tarjeta == String(d[2]) and _p._fondo_elegido == String(d[3]), "paleta, estilo, forma y fondo son los del diseño")
	_p._rotar_diseno = true

func _hay_etiqueta(raiz: Node, texto: String) -> bool:
	for l: Label in raiz.find_children("*", "Label", true, false):
		if l.text == texto:
			return true
	return false

extends "res://pruebas/banco/ideas_p1.gd"
## [Capa 2/3 de `ideas.gd`] secciones del 2-11-2026: núcleo sin prueba, filtros del plantel, comparar clubes, modo streamer y perfiles de mando

## M-279 (2-11-2026): las clases del núcleo que ninguna prueba nombraba.
func _probar_nucleo_sueltos() -> void:
	_titulo("NÚCLEO SIN PRUEBA (M-279): pesos por puesto, letra que cabe, paquete real y medición")
	## PesosPuesto: la lista rápida suma lo mismo que la tabla POSD y da su grupo.
	var posd: Dictionary = Datos.tabla("POSD")
	var bien := posd.size() > 5
	for dem: String in posd:
		var e := PesosPuesto.de(dem)
		var suma := 0.0
		for k: String in posd[dem]["p"]:
			suma += float(posd[dem]["p"][k])
		bien = bien and e.size() == 2 and is_equal_approx(Array(e[1]).reduce(func(a, x): return a + x, 0.0), suma) \
			and PesosPuesto.grupo(dem) == String(posd[dem].get("g", ""))
	_comprobar(bien, "los pesos rápidos de %d demarcaciones coinciden con POSD" % posd.size())
	_comprobar(PesosPuesto.de("NO_EXISTE").is_empty() and PesosPuesto.grupo("NO_EXISTE") == "", "una demarcación que no existe no da pesos ni grupo")
	## TextoQueCabe: un botón estrecho encoge su letra (nunca bajo el 72 %) y la recupera si el texto vuelve a caber.
	var bt := Button.new()
	bt.size = Vector2(90, 30)
	add_child(bt)
	var base := bt.get_theme_font_size("font_size")
	bt.text = "Un rótulo bastante más largo que el botón"
	TextoQueCabe.ajustar(bt)
	var chica := bt.get_theme_font_size("font_size")
	bt.text = "Ok"
	TextoQueCabe.ajustar(bt)
	_comprobar(chica < base and chica >= int(ceil(base * TextoQueCabe.MINIMO)) and bt.get_theme_font_size("font_size") == base,
		"la letra que no cabe baja (%d → %d) y vuelve a su tamaño" % [base, chica])
	bt.queue_free()
	## PaqueteReal y Medicion: sin el paquete privado ni `--medir`, el juego arranca público y sin medir.
	PaqueteReal.montar()
	_comprobar(PaqueteReal.montado == "", "sin caras_reales.pck no se monta nada (build público)")
	_comprobar(not Medicion.pedida() and not Medicion.es_largo(), "sin --medir ni --benchmark no se mide")
	_comprobar(CompilarFondo.CARPETAS_FUERA.has("res://pruebas"), "la compilación de fondo no gasta tiempo en las pruebas")

## M-293 (2-11-2026): el filtro por estado del plantel.
func _probar_filtros_plantel() -> void:
	_titulo("FILTROS DEL PLANTEL POR ESTADO (M-293)")
	var m := Mundo.new()
	m.generar(["CHI"], 2930)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var a: Jugador = c.plantilla[0]
	var b: Jugador = c.plantilla[1]
	a.lesion = 3
	b.transferible = true
	b.edad = 19
	b.anios_contrato = 1
	_comprobar(PanelPlantel._estado_ok(m, a, "bajas") and not PanelPlantel._estado_ok(m, a, "disponibles"), "el lesionado sale en bajas y no en disponibles")
	_comprobar(PanelPlantel._estado_ok(m, b, "transferibles") and PanelPlantel._estado_ok(m, b, "jovenes") and PanelPlantel._estado_ok(m, b, "contrato"),
		"transferible, joven y con contrato acabando a la vez")
	var lista := VBoxContainer.new()
	add_child(lista)
	lista.set_meta(PanelPlantel.META_ESTADO, "bajas")
	PanelPlantel.pintar(lista, c, m, "ovr", true, Color.WHITE, func(x): return x,
		func(g: GridContainer, _j: Jugador, textos: Array, _cols: Array) -> void:
			for t in textos:
				var l := Label.new()
				l.text = String(t)
				g.add_child(l),
		func(_k): pass)
	var g := lista.find_children("*", "GridContainer", true, false)
	var filas := ((g[0] as GridContainer).get_child_count() - 6) / 6 if not g.is_empty() else -1
	var bajas := c.plantilla.filter(func(j: Jugador) -> bool: return j.lesion > 0 or j.suspension > 0).size()
	_comprobar(filas == bajas, "con «Bajas» la lista enseña solo las %d bajas (%d filas)" % [bajas, filas])
	lista.queue_free()
	## M-295: el historial guarda el valor y la ficha lo dibuja.
	var jh: Jugador = c.plantilla[2]
	jh.historial.clear()
	jh.registrar_temporada(2026, c.nombre)
	jh.registrar_temporada(2027, c.nombre)
	var gr := GraficoEvolucion.de(jh.historial, {"escala": 1.0})
	gr.size = Vector2(300, 90)
	_comprobar(int(jh.historial[0].get("val", -1)) == jh.valor and gr._get_tooltip(Vector2(0, 0)).contains("2026"),
		"el historial guarda el valor y el gráfico de la ficha lo enseña al pasar el ratón")
	gr.free()

## M-294 (2-11-2026): tu club frente a otro en su ficha.
func _probar_compara_clubes() -> void:
	_titulo("TU CLUB FRENTE A OTRO (M-294)")
	var m := Mundo.new()
	m.generar(["CHI"], 2940)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	var otro: Club = m.ligas[0].clubes[1]
	mio.rep = 80
	otro.rep = 60
	var caja := VBoxContainer.new()
	add_child(caja)
	ComparaClubes.pintar(caja, mio, otro, Color.GRAY, Color.WHITE, Color.GREEN, Color.RED)
	var g := caja.find_children("*", "GridContainer", true, false)
	_comprobar(not g.is_empty() and (g[0] as GridContainer).get_child_count() == 3 * (ComparaClubes.filas().size() + 1), "una fila por dato y una de cabecera")
	var rep_mia := (g[0] as GridContainer).get_child(4) as Label
	_comprobar(rep_mia.text.begins_with("80") and rep_mia.text.contains("▲"), "gana la reputación más alta y se marca (%s)" % rep_mia.text)
	_comprobar(ComparaClubes._miles(1234567) == "1.234.567" and ComparaClubes._miles(950) == "950", "los miles con punto")
	var vacio := VBoxContainer.new()
	ComparaClubes.pintar(vacio, mio, mio, Color.GRAY, Color.WHITE, Color.GREEN, Color.RED)
	_comprobar(vacio.get_child_count() == 0, "contigo mismo no hay comparación")
	vacio.free()
	caja.queue_free()

## M-312 (2-11-2026): el modo streamer quita las fotos reales sin tocar la preferencia de caras.
func _probar_modo_streamer() -> void:
	_titulo("MODO STREAMER (M-312)")
	var antes_f := Cara.usar_fotos
	var antes_s := Cara.modo_streamer
	Cara.usar_fotos = true
	Cara.modo_streamer = false
	_comprobar(Cara.fotos_permitidas(), "sin modo streamer, la preferencia FOTO manda")
	Cara.modo_streamer = true
	_comprobar(not Cara.fotos_permitidas() and Cara.usar_fotos, "con modo streamer no hay fotos, y la preferencia sigue en FOTO")
	var j := Jugador.new()
	j.real = true
	j.nombre = "Alguien Real"
	_comprobar(Cara.foto_real(j) == null and Cara.ruta_foto(j) == "", "ni foto ni ruta de un jugador real")
	Cara.usar_fotos = antes_f
	Cara.modo_streamer = antes_s

## M-442 (2-11-2026): perfiles de mando en tres huecos.
func _probar_perfiles_mando() -> void:
	_titulo("PERFILES DE MANDO (M-442)")
	var ruta_antes := MandoPerfiles.ruta
	MandoPerfiles.ruta = "user://prueba_perfiles_mando.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MandoPerfiles.ruta))
	Mando.cargar()
	var antes := {"esquema": Mando.esquema, "propio": Mando.propio.duplicate(true), "ayudas": Mando.ayudas.duplicate()}
	_comprobar(not MandoPerfiles.tiene(1) and not MandoPerfiles.cargar_de(1), "los huecos empiezan vacíos")
	Mando.esquema = "clasico"
	Mando.ayudas["tiro"] = "manual"
	MandoPerfiles.guardar_en(2)
	Mando.esquema = "wasd"
	Mando.ayudas["tiro"] = "asistido"
	_comprobar(MandoPerfiles.tiene(2) and MandoPerfiles.cargar_de(2) and Mando.esquema == "clasico" and Mando.ayuda("tiro") == "manual",
		"guardar en el 2 y cargarlo devuelve esquema y ayudas")
	MandoPerfiles.guardar_en(9)
	_comprobar(not MandoPerfiles.tiene(9), "solo hay tres huecos")
	Mando.esquema = String(antes["esquema"])
	Mando.propio = antes["propio"]
	Mando.ayudas = antes["ayudas"]
	Mando.guardar()
	Mando.aplicar()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MandoPerfiles.ruta))
	MandoPerfiles.ruta = ruta_antes

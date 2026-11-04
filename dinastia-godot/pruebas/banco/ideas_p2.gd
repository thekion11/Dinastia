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

## M-441 (2-11-2026): el teclado en pantalla para el mando (sin esperas: el banco no aguarda a las secciones).
func _probar_teclado_pantalla() -> void:
	_titulo("TECLADO EN PANTALLA (M-441)")
	_comprobar(not TecladoPantalla.hace_falta() or not Input.get_connected_joypads().is_empty(), "sin mando no hace falta (en el banco no hay mando)")
	TecladoPantalla.forzar = true
	_comprobar(TecladoPantalla.hace_falta(), "con mando (forzado) sí")
	var campo := LineEdit.new()
	add_child(campo)
	var enviado: Array = []
	campo.text_submitted.connect(func(tx: String) -> void: enviado.append(tx))
	var t := TecladoPantalla.new()
	t.objetivo = campo
	add_child(t)
	_comprobar(t._teclas.size() == 40, "cuarenta teclas en cuatro filas")
	t._escribir("a")
	t._escribir("n")
	t._escribir("a")
	t._borrar()
	t._escribir("i")
	_comprobar(campo.text == "Ani", "escribe con mayúscula solo la primera y borra (%s)" % campo.text)
	t.aceptar()
	_comprobar(enviado == ["Ani"] and TecladoPantalla._saltar_foco == false and campo.has_focus(), "Aceptar envía el texto y devuelve el foco al campo sin reabrir el teclado")
	TecladoPantalla.forzar = false
	campo.queue_free()

## M-304 (2-11-2026): la entrada común de pantallas y diálogos respeta las animaciones reducidas.
func _probar_entrada_comun() -> void:
	_titulo("ENTRADA COMÚN DE PANTALLAS (M-304)")
	var antes := Animar._reducidas
	var c := Control.new()
	add_child(c)
	Animar._reducidas = 1
	c.modulate.a = 0.0
	Animar.entrar(c)
	_comprobar(is_equal_approx(c.modulate.a, 1.0), "con animaciones reducidas aparece al instante (nunca transparente)")
	Animar._reducidas = 0
	Animar.entrar(c)
	_comprobar(c.modulate.a == 0.0 and c.scale.x < 1.0, "sin ellas, entra con fundido y leve escala")
	var fuera := Control.new()
	Animar.entrar(fuera)
	_comprobar(fuera.modulate.a == 0.0 and fuera.tree_entered.get_connections().size() == 1, "si aún no está en pantalla, espera a entrar")
	fuera.free()
	c.queue_free()
	Animar._reducidas = antes

## M-284 (2-11-2026): los avisos emergentes pasan por el lector de pantalla si está encendido.
func _probar_lector_avisos() -> void:
	_titulo("LECTOR: AVISOS EMERGENTES (M-284)")
	var antes := LectorPantalla.activo()
	LectorPantalla.ultimo_anuncio = ""
	LectorPantalla.fijar(false)
	LectorPantalla.anunciar("No debería")
	_comprobar(LectorPantalla.ultimo_anuncio == "", "apagado, no lee nada")
	LectorPantalla.fijar(true)
	Aviso.mostrar(self, "logro", "🏆", "Primer día", "Terminaste el prólogo.")
	_comprobar(LectorPantalla.ultimo_anuncio.begins_with("Primer día"), "encendido, lee el aviso de logro (%s)" % LectorPantalla.ultimo_anuncio)
	LectorPantalla.fijar(antes)

## M-285 (2-11-2026): el foco con mando entra en el contenido.
func _probar_foco_mando() -> void:
	_titulo("FOCO CON MANDO EN LAS PANTALLAS (M-285)")
	var raiz := VBoxContainer.new()
	add_child(raiz)
	var oculto := Button.new()
	oculto.visible = false
	raiz.add_child(oculto)
	var etiqueta := Label.new()
	raiz.add_child(etiqueta)
	var caja := HBoxContainer.new()
	raiz.add_child(caja)
	var apagado := Button.new()
	apagado.disabled = true
	caja.add_child(apagado)
	var bueno := Button.new()
	caja.add_child(bueno)
	_comprobar(FocoMando.primero(raiz) == bueno, "salta lo oculto, lo que no se enfoca y lo desactivado")
	FocoMando.forzar = false
	if Input.get_connected_joypads().is_empty():
		FocoMando.enfocar(raiz)
		_comprobar(not bueno.has_focus(), "sin mando no toca el foco")
	FocoMando.forzar = true
	FocoMando.enfocar(raiz)
	_comprobar(bueno.has_focus(), "con mando el foco cae en el primer control usable")
	FocoMando.forzar = false
	raiz.queue_free()

## (2-11-2026) El nivel gráfico MÍNIMO, la versión ultra ligera dentro del juego.
func _probar_calidad_minima() -> void:
	_titulo("CALIDAD MÍNIMA (ultra ligera)")
	_comprobar(Calidad.MINIMO < Calidad.MEDIO and Calidad.MEDIO == 0 and Calidad.ULTRA == 2, "MÍNIMO va por debajo sin mover los valores guardados (0, 1, 2)")
	var sol := Calidad.sol(Calidad.MINIMO)
	var sol_m := Calidad.sol(Calidad.MEDIO)
	_comprobar(not sol.shadow_enabled and sol_m.shadow_enabled, "sin sombras en MÍNIMO; MEDIO las conserva")
	sol.free()
	sol_m.free()
	var vp := SubViewport.new()
	add_child(vp)
	Calidad.aplicar_viewport(vp, Calidad.MINIMO)
	_comprobar(vp.msaa_3d == Viewport.MSAA_DISABLED and is_equal_approx(vp.scaling_3d_scale, Calidad.ESCALA_MINIMO), "MÍNIMO: sin MSAA (decisión del dueño, A4-PARTIDO-R01) y el 3D a la escala elegida")
	Calidad.aplicar_viewport(vp, Calidad.MEDIO)
	_comprobar(vp.msaa_3d == Viewport.MSAA_2X, "MEDIO conserva el MSAA x2")
	var elegida_antes_msaa := Calidad.elegida
	Calidad.elegida = Calidad.MINIMO
	_comprobar(Calidad.msaa_ui(Viewport.MSAA_4X) == Viewport.MSAA_DISABLED, "las vistas 3D secundarias también van sin MSAA en MÍNIMO")
	Calidad.elegida = Calidad.MEDIO
	_comprobar(Calidad.msaa_ui(Viewport.MSAA_4X) == Viewport.MSAA_4X, "y en MEDIO o más no cambian")
	Calidad.elegida = elegida_antes_msaa
	Calidad.aplicar_viewport(vp, Calidad.MINIMO)
	Calidad.aplicar_viewport(vp, Calidad.ALTO)
	_comprobar(is_equal_approx(vp.scaling_3d_scale, 1.0), "al subir de nivel vuelve al 100 %")
	vp.queue_free()
	var we := Calidad.entorno(Calidad.MINIMO)
	_comprobar(we.environment.reflected_light_source == Environment.REFLECTION_SOURCE_DISABLED and not we.environment.ssao_enabled, "sin reflejos del cielo ni oclusión ambiental")
	we.free()
	_comprobar(CespedCapas.capas_por_calidad() >= 0, "el césped por capas sabe responder")
	_comprobar(CalidadAuto.muy_debil({"gpu": "Mali-400 MP", "ram_mb": 2048, "hilos": 4, "debil": true}), "un móvil viejo (Mali-400, 2 GB) es muy débil → MÍNIMO")
	_comprobar(not CalidadAuto.muy_debil({"gpu": "Intel(R) UHD Graphics 620", "ram_mb": 8192, "hilos": 8, "debil": true}), "una Intel UHD con 8 GB se queda en MEDIO")
	_comprobar(not CalidadAuto.muy_debil({"gpu": "llvmpipe (LLVM 15)", "ram_mb": 2048, "hilos": 2, "debil": true}), "el render por software de los servidores no cuenta")
	var antes := Calidad.elegida
	var existia := FileAccess.file_exists(Calidad.ARCHIVO)
	Calidad.elegida = Calidad.MINIMO
	Calidad.guardar()
	Calidad.elegida = Calidad.ULTRA
	Calidad.cargar()
	_comprobar(Calidad.elegida == Calidad.MINIMO, "MÍNIMO se guarda y se lee (no se recorta a MEDIO)")
	Calidad.elegida = antes
	if existia:
		Calidad.guardar()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Calidad.ARCHIVO))

## (3-11, orden 22) La pantalla de antes del partido: jugar, solo las importantes o simular.
func _probar_eleccion_partido() -> void:
	_titulo("ANTES DEL PARTIDO: JUGAR, SOLO LAS IMPORTANTES O SIMULAR")
	var j := EleccionPartido.eleccion("jugar")
	var i := EleccionPartido.eleccion("importantes")
	var s := EleccionPartido.eleccion("simular", "vivo")
	_comprobar(j["modo"] == "completo" and j["control"] and not j["ocasiones"], "jugar = 3D completo manejando a tu equipo")
	_comprobar(i["modo"] == "destacados" and not i["control"] and i["ocasiones"], "solo las importantes = corre solo y para en tus ocasiones")
	_comprobar(s["modo"] == "vivo" and not s["control"] and not s["ocasiones"], "simular respeta cómo quieres verlo")
	_comprobar(EleccionPartido.eleccion("simular", "raro")["modo"] == "resumen", "un modo desconocido simula en resumen")
	var el := EleccionPartido.new()
	el.titulo = "A vs B"
	add_child(el)
	_comprobar(el.find_child("Opcion_jugar", true, false) != null and el.find_child("Opcion_importantes", true, false) != null and el.find_child("Opcion_simular", true, false) != null, "las tres tarjetas a pantalla completa")
	el.queue_free()

## (3-11, orden 22) Cambiar de club, dimitir y ver a cuánto estás del despido, desde «Mi carrera».
func _probar_carrera_salidas() -> void:
	_titulo("TU PUESTO Y TUS SALIDAS (cambiar de club, dimitir, despido)")
	var m := Mundo.new()
	m.generar(["CHI"], 3110)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var antes := Azar._rng.state
	var a := CarreraSalidas.ofertas(m)
	var b := CarreraSalidas.ofertas(m)
	_comprobar(a.size() > 0 and a.size() <= 3 and a == b and Azar._rng.state == antes, "hasta 3 ofertas, estables en la semana y sin gastar el azar del mundo (%d)" % a.size())
	var ok := true
	for c: Club in a:
		ok = ok and c.id != m.mi_club_id and c.rep <= m.roles.prestigio + 18
	_comprobar(ok, "solo clubes alcanzables con tu prestigio, nunca el tuyo")
	var viejo := m.mi_club_id
	_comprobar(m.roles.aceptar_trabajo(a[0].id) == "" and m.mi_club_id == a[0].id and m.mi_club_id != viejo, "firmar con otro club te lleva a él")
	m.roles.quedar_sin_banco()
	_comprobar(m.roles.sin_club and not m.roles.ofertas_trabajo().is_empty(), "dimitir te deja sin club y con ofertas para elegir")

## (3-11, orden 22) La grada suena siempre: el fondo en bucle sube con el peligro y con el gol.
func _probar_grada_fondo() -> void:
	_titulo("FONDO DE LA GRADA (sonido continuo del estadio)")
	var w := GradaFondo.onda()
	_comprobar(w != null and w.loop_mode == AudioStreamWAV.LOOP_FORWARD and w.data.size() > Sonido.FRECUENCIA * 2 * 6, "un bucle de varios segundos")
	_comprobar(GradaFondo.onda() == w, "se sintetiza una vez y se reutiliza")
	var peligro := [0.0]
	var raiz := Node.new()
	add_child(raiz)
	var g := GradaFondo.montar(raiz, func() -> float: return peligro[0])
	var calma := g._objetivo_db()
	peligro[0] = 1.0
	var area := g._objetivo_db()
	g.gol()
	var tras_gol := g._objetivo_db()
	_comprobar(area > calma and tras_gol > area, "sube con el balón en el área y más tras un gol (%.0f → %.0f → %.0f dB)" % [calma, area, tras_gol])
	raiz.queue_free()

## (3-11, orden 22) Cualquier bloque de la pantalla principal se abre a pantalla completa y vuelve a su sitio.
func _probar_pantalla_ampliada() -> void:
	_titulo("BLOQUE A PANTALLA COMPLETA (⤢)")
	var raiz := Control.new()
	add_child(raiz)
	var caja := VBoxContainer.new()
	raiz.add_child(caja)
	var antes := Label.new()
	caja.add_child(antes)
	var bloque := VBoxContainer.new()
	bloque.add_child(Label.new())
	caja.add_child(bloque)
	caja.add_child(Label.new())
	var a := PantallaAmpliada.abrir(raiz, bloque, "PRUEBA")
	_comprobar(a != null and a.is_ancestor_of(bloque) and not caja.is_ancestor_of(bloque), "el bloque se muda entero a la pantalla completa (el mismo nodo)")
	_comprobar(PantallaAmpliada.abrir(raiz, bloque, "PRUEBA") == null, "pulsar «⤢» otra vez la cierra")
	_comprobar(bloque.get_parent() == caja and bloque.get_index() == 1, "y vuelve exactamente a su sitio")
	var b := PantallaAmpliada.abrir(raiz, bloque, "PRUEBA")
	b.free()   ## otra pantalla la borra sin cerrarla
	_comprobar(is_instance_valid(bloque) and not b.is_ancestor_of(bloque) if is_instance_valid(b) else is_instance_valid(bloque), "si la borran sin cerrar, el bloque no muere con ella (vuelve al siguiente momento libre)")
	raiz.queue_free()

func _probar_funciones_escondidas() -> void:
	_titulo("ORDEN 22 U6: LO QUE EXISTÍA Y NO SE USABA (cesión de prensa, roles del once, cantera)")
	var m := Mundo.new()
	m.generar(["CHI"], 3111)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	var joven: Jugador = null
	for j: Jugador in mio.plantilla:
		if j.edad <= 21:
			joven = j
			break
	if joven == null:
		joven = mio.plantilla[0]
		joven.edad = 19
	while mio.plantilla.size() <= 18:
		mio.plantilla.append(mio.plantilla[0])
	var cedio := m.prensa._ceder(m, mio, joven)
	_comprobar(cedio and m.cesiones.esta_cedido(joven.id) and not m.prensa.cesiones.has(joven.id), "la cesión de un evento de prensa se firma en Cesiones (la que se resuelve)")
	m.cesiones.resolver(m.anio + 1)
	_comprobar(joven.club_id == mio.id and not m.cesiones.esta_cedido(joven.id), "y al cambiar de temporada el chico vuelve a casa")
	var ok := true
	for k: String in RolTactico.DE_VESTUARIO:
		var t: Variant = (Datos.tabla("ROLES") as Dictionary).get(k)
		ok = ok and t != null and RolTactico.existe(String(RolTactico.DE_VESTUARIO[k])) and String((t as Array)[1]) == String(RolTactico.CATALOGO[RolTactico.DE_VESTUARIO[k]]["grupo"])
	_comprobar(ok and RolTactico.DE_VESTUARIO.size() == (Datos.tabla("ROLES") as Dictionary).size(), "cada rol de la pantalla de Táctica tiene su rol del partido, de la misma línea")
	var por: Jugador = null
	for j: Jugador in mio.once():
		if Datos.grupo(j.pos_e) == "POR":
			por = j
	if por != null:
		_comprobar(mio.tactica.poner_rol(por, String(RolTactico.DE_VESTUARIO["porLibero"])) == "" and mio.tactica.roles.has(por.id), "elegir «Portero-líbero» llega a Tactica.roles (lo que lee el partido)")
	_comprobar(m.roles.subir_al_primer_equipo(joven) != "", "subir al primer equipo solo vale siendo director de cantera (si no, dice por qué)")

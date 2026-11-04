extends BaseIdea
## BANCO «accesibilidad_tutorial» · PRUEBAS PROPIAS (fase 2, 4-11-2026): (A) el contraste de los colores de `Tema` en cifras (razón WCAG), con el modo de contraste
## alto; (B) la paleta para daltonismo: el par bien/mal separado en protanopia, deuteranopia y tritanopia (simuladas) y los colores sin significado, intactos; (C) la escala
## de texto de 0,7 a 1,6: el tamaño de letra sigue la escala (con suelo de 8 px) y las pantallas clave no se cortan ni se salen; (D) el tutorial entero, en 8 modos y con la escala
## más grande: cada paso cabe en pantalla, su texto no se corta y su objetivo está a la vista; (E) el lector de pantalla y los avisos visuales de sonido.
var _p: Principal

func _frames(n: int = 4) -> void:
	for i in n:
		await get_tree().process_frame

# ---------------------------------------------------------------- color

static func _lineal(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)

static func luminancia(c: Color) -> float:
	return 0.2126 * _lineal(c.r) + 0.7152 * _lineal(c.g) + 0.0722 * _lineal(c.b)

## Razón de contraste WCAG entre un color y un fondo (el fondo opaco; el color se mezcla con él si trae alfa).
static func razon(c: Color, fondo: Color) -> float:
	var f := Color(fondo, 1.0)
	var m := Color(c.r * c.a + f.r * (1.0 - c.a), c.g * c.a + f.g * (1.0 - c.a), c.b * c.a + f.b * (1.0 - c.a))
	var a := luminancia(m) + 0.05
	var b := luminancia(f) + 0.05
	return maxf(a, b) / minf(a, b)

## Simulación de daltonismo (Machado et al. 2009, severidad 1.0) sobre RGB lineal.
const SIM := {
	"protanopia": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
	"deuteranopia": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
	"tritanopia": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}

static func simular(c: Color, tipo: String) -> Color:
	var m: Array = SIM[tipo]
	var l := [_lineal(c.r), _lineal(c.g), _lineal(c.b)]
	var o: Array[float] = []
	for f in 3:
		var v: float = float(m[f][0]) * l[0] + float(m[f][1]) * l[1] + float(m[f][2]) * l[2]
		o.append(clampf(v, 0.0, 1.0))
	var g := func(x: float) -> float: return 12.92 * x if x <= 0.0031308 else 1.055 * pow(x, 1.0 / 2.4) - 0.055
	return Color(g.call(o[0]), g.call(o[1]), g.call(o[2]))

## Distancia de color perceptual sencilla (en Lab).
static func distancia(a: Color, b: Color) -> float:
	var la := _lab(a)
	var lb := _lab(b)
	return la.distance_to(lb)

static func _lab(c: Color) -> Vector3:
	var r := _lineal(c.r)
	var g := _lineal(c.g)
	var bl := _lineal(c.b)
	var x := (0.4124 * r + 0.3576 * g + 0.1805 * bl) / 0.95047
	var y := 0.2126 * r + 0.7152 * g + 0.0722 * bl
	var z := (0.0193 * r + 0.1192 * g + 0.9505 * bl) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	var fx: float = f.call(x)
	var fy: float = f.call(y)
	var fz: float = f.call(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))

func _probar() -> void:
	_titulo("BANCO ACCESIBILIDAD_TUTORIAL · contraste, daltonismo, escala de texto, tutorial, lector")
	_respaldar_user()
	Idiomas.idioma = "es"
	_contraste()
	_daltonismo()
	var m := Mundo.new()
	m.generar(["CHI"], 20261104)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	PedidoPartida.mundo_pregenerado = m
	CapasTutorial.forzar = false
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _frames(6)
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	Idiomas.idioma = "es"
	var ayudas := CapasTutorial.activas()
	CapasTutorial.poner_activas(false)
	await _escala_de_texto()
	await _escala_con_idiomas()
	await _tutorial()
	_lector_y_avisos()
	CapasTutorial.poner_activas(ayudas)
	_p._escala_texto = 1.0
	_restaurar_user()

## (A) Razones de contraste (WCAG): texto normal ≥ 4,5; texto principal ≥ 7; lo grande o de interfaz ≥ 3.
func _contraste() -> void:
	Tema.contraste = false
	Tema.daltonico = false
	var fondos := {"FONDO": Tema.FONDO, "PANEL": Tema.PANEL, "TARJETA": Tema.TARJETA}
	for nf: String in fondos:
		var f: Color = fondos[nf]
		var r_texto := razon(Tema.TEXTO, f)
		var r_suave := razon(Tema.SUAVE, f)
		_comprobar(r_texto >= 7.0, "texto principal sobre %s: %.1f:1 (≥ 7)" % [nf, r_texto])
		_comprobar(r_suave >= 4.5, "texto suave sobre %s: %.1f:1 (≥ 4,5)" % [nf, r_suave])
		_comprobar(razon(Tema.ORO, f) >= 4.5, "oro (títulos) sobre %s: %.1f:1 (≥ 4,5)" % [nf, razon(Tema.ORO, f)])
		_comprobar(razon(Tema.BIEN, f) >= 3.0 and razon(Tema.MAL, f) >= 3.0, "bien (%.1f) y mal (%.1f) sobre %s: ≥ 3 (elementos de interfaz)" % [razon(Tema.BIEN, f), razon(Tema.MAL, f), nf])
		_comprobar(razon(Tema.ACENTO, f) >= 3.0, "acento sobre %s: %.1f:1 (≥ 3)" % [nf, razon(Tema.ACENTO, f)])
	for pos: String in Tema.POS:
		_comprobar(razon(Tema.POS[pos], Tema.PANEL) >= 3.0, "color de la posición %s sobre el panel: %.1f:1 (≥ 3)" % [pos, razon(Tema.POS[pos], Tema.PANEL)])
	Tema.contraste = true
	var t_alto := Tema.accesible(Tema.TEXTO)
	var s_alto := Tema.accesible(Tema.SUAVE)
	_comprobar(razon(t_alto, Tema.PANEL) >= 15.0, "contraste alto: texto principal %.1f:1 (≥ 15)" % razon(t_alto, Tema.PANEL))
	_comprobar(razon(s_alto, Tema.PANEL) >= 9.0, "contraste alto: texto suave %.1f:1 (≥ 9)" % razon(s_alto, Tema.PANEL))
	_comprobar(razon(s_alto, Tema.PANEL) > razon(Tema.SUAVE, Tema.PANEL) + 2.0, "contraste alto: el suave mejora más de 2 puntos")
	_comprobar(Tema.accesible(Color(Tema.TEXTO, 0.5)).a == 0.5, "contraste alto: el alfa se conserva")
	_comprobar(Tema.accesible(Tema.ACENTO) == Tema.ACENTO, "contraste alto: un color sin significado no cambia")
	Tema.contraste = false

## (B) Daltonismo: bien/mal separados en las tres simulaciones y mejor que el par normal.
func _daltonismo() -> void:
	for tipo: String in SIM:
		var normal := distancia(simular(Tema.BIEN, tipo), simular(Tema.MAL, tipo))
		var dalt := distancia(simular(Tema.BIEN_DALT, tipo), simular(Tema.MAL_DALT, tipo))
		_comprobar(dalt >= 30.0, "%s: el par bien/mal daltónico se separa %.0f (≥ 30 en Lab; el normal %.0f)" % [tipo, dalt, normal])
		if tipo != "tritanopia":
			_comprobar(dalt > normal, "%s: el par daltónico se distingue mejor que el verde/rojo normal (%.0f > %.0f)" % [tipo, dalt, normal])
		var d_oro := distancia(simular(Tema.ORO_DALT, tipo), simular(Tema.BIEN_DALT, tipo))
		_comprobar(d_oro >= 18.0, "%s: el oro daltónico se separa del «bien» (%.0f ≥ 18)" % [tipo, d_oro])
	Tema.daltonico = true
	_comprobar(Tema.bien() == Tema.BIEN_DALT and Tema.mal() == Tema.MAL_DALT and Tema.oro() == Tema.ORO_DALT, "con el modo daltónico, bien()/mal()/oro() dan la paleta Okabe-Ito")
	_comprobar(Tema.accesible(Color(Tema.BIEN, 0.4)) == Color(Tema.BIEN_DALT, 0.4), "el alfa se conserva en el color daltónico")
	_comprobar(Tema.accesible(Tema.ACENTO) == Tema.ACENTO and Tema.accesible(Tema.TEXTO) == Tema.TEXTO, "los colores sin significado no cambian")
	for c: Color in [Tema.BIEN_DALT, Tema.MAL_DALT, Tema.ORO_DALT]:
		_comprobar(razon(c, Tema.PANEL) >= 3.0, "el color daltónico %s se lee sobre el panel (%.1f:1 ≥ 3)" % [c.to_html(false), razon(c, Tema.PANEL)])
	Tema.daltonico = false
	_comprobar(Tema.bien() == Tema.BIEN, "apagado, vuelve el verde de siempre")

## (C) La escala de texto 0,7-1,6.
func _escala_de_texto() -> void:
	for tam: int in [Tema.TAM_ROTULO, Tema.TAM_CUERPO, Tema.TAM_DESTACADO, Tema.TAM_TITULO, Tema.TAM_MARCADOR]:
		Tema.escala_texto = 1.0
		_comprobar(Tema.letra(tam) == tam, "escala 1,0: la letra de %d px queda igual" % tam)
		Tema.escala_texto = 0.7
		_comprobar(Tema.letra(tam) >= 8, "escala 0,7: la letra de %d px no baja de 8 (%d)" % [tam, Tema.letra(tam)])
		Tema.escala_texto = 1.6
		_comprobar(Tema.letra(tam) == int(round(tam * 1.6)), "escala 1,6: la letra de %d px sube a %d" % [tam, Tema.letra(tam)])
		Tema.escala_texto = 2.5
		_comprobar(Tema.letra(tam) == int(round(tam * 1.6)), "una escala fuera de rango (2,5) se acota a 1,6")
	var cortados: Dictionary = {}
	var medias: Dictionary = {}
	for esc: float in [0.85, 1.0, 1.15, 1.3, 1.6]:
		_p._escala_texto = esc
		var n_cort := 0
		var n_sale := 0
		var ejemplos: Array[String] = []
		for destino: Array in [["plantel", 0], ["plantel", 1], ["dinero", 0], ["dinero", 1], ["competiciones", 0], ["partido", 0], ["ajustes", 3], ["estadio", 0], ["gente", 0], ["historia", 0]]:
			_p._menu_lateral.abrir_menu(String(destino[0]), int(destino[1]))
			await _frames(6)
			var r := _medir()
			n_cort += r[0]
			n_sale += r[1]
			if ejemplos.size() < 3 and not (r[2] as Array).is_empty():
				ejemplos.append("%s/%d: %s" % [destino[0], destino[1], (r[2] as Array)[0]])
			var pm: Variant = _p._menu_lateral.pantalla_abierta
			if is_instance_valid(pm):
				(pm as PantallaMenu).cerrar()
			await _frames(22)
		cortados[esc] = n_cort
		medias[esc] = _media_letra()
		_comprobar(n_sale == 0, "escala %.2f: nada se sale de la pantalla por la derecha (%d) %s" % [esc, n_sale, str(ejemplos)])
		_linea("  escala %.2f: %d textos cortados en 10 pantallas" % [esc, n_cort])
	_comprobar(int(cortados[1.6]) <= int(cortados[1.0]) + 12, "al 160 %% no se cortan más de 12 textos más que al 100 %% (%d → %d)" % [cortados[1.0], cortados[1.6]])
	_comprobar(int(cortados[1.15]) <= int(cortados[1.0]) + 4, "al 115 %% no se cortan más de 4 más que al 100 %% (%d → %d)" % [cortados[1.0], cortados[1.15]])
	_comprobar(float(medias[1.6]) >= float(medias[1.0]) * 1.3, "la escala llega al contenido: la letra media de las pantallas sube de %.1f a %.1f px al 160 %% (≥ ×1,3)" % [medias[1.0], medias[1.6]])
	_comprobar(float(medias[0.85]) <= float(medias[1.0]) * 0.95, "y baja al 85 %% (%.1f px)" % medias[0.85])
	_p._escala_texto = 1.0
	_comprobar(is_equal_approx(Tema.escala_texto, 1.0), "el interruptor de Principal vuelca la escala en Tema (y se restaura)")

## La escala grande con los idiomas de palabras largas: se mide lo que se sale y lo que se corta (con topes de regresión).
func _escala_con_idiomas() -> void:
	var antes := Idiomas.idioma
	for config: Array in [["de", 1.3], ["de", 1.6], ["tr", 1.3], ["tr", 1.6], ["fr", 1.6]]:
		Idiomas.idioma = String(config[0])
		_p._escala_texto = float(config[1])
		var n_cort := 0
		var n_sale := 0
		for destino: Array in [["plantel", 0], ["dinero", 0], ["partido", 0], ["ajustes", 3], ["estadio", 0]]:
			_p._menu_lateral.abrir_menu(String(destino[0]), int(destino[1]))
			await _frames(6)
			var r := _medir()
			n_cort += r[0]
			n_sale += r[1]
			var pm: Variant = _p._menu_lateral.pantalla_abierta
			if is_instance_valid(pm):
				(pm as PantallaMenu).cerrar()
			await _frames(22)
		_linea("  %s al %d %%: %d textos cortados y %d que se salen (5 pantallas)" % [config[0], int(float(config[1]) * 100.0), n_cort, n_sale])
		_comprobar(n_sale == 0 and n_cort <= 12, "%s al %d %%: se salen %d (tope 0) y se cortan %d (tope 12)" % [config[0], int(float(config[1]) * 100.0), n_sale, n_cort])
	Idiomas.idioma = antes
	_p._escala_texto = 1.0

## ¿Tiene `c` un ScrollContainer por encima cuya ventana cabe en la pantalla y que se desplaza en horizontal?
func _en_desplazable(c: Control) -> bool:
	var q: Node = c.get_parent()
	var ancho := get_viewport().get_visible_rect().size.x
	while q != null:
		if q is ScrollContainer and (q as ScrollContainer).horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED \
				and (q as ScrollContainer).get_global_rect().end.x <= ancho + 2.0:
			return true
		q = q.get_parent()
	return false

## Tamaño medio de la letra de las etiquetas y botones visibles (la prueba de que la escala llega al contenido de las pantallas).
func _media_letra() -> float:
	var suma := 0.0
	var n := 0
	for c in _p.find_children("*", "Control", true, false):
		if (c is Label or c is Button) and (c as Control).is_visible_in_tree() and String((c as Control).get("text")).strip_edges() != "":
			suma += float((c as Control).get_theme_font_size("font_size"))
			n += 1
	return suma / maxf(float(n), 1.0)

## [cortados, que se salen, ejemplos]
func _medir() -> Array:
	var ancho := get_viewport().get_visible_rect().size.x
	var cort := 0
	var sale := 0
	var ej: Array[String] = []
	for n in _p.find_children("*", "Control", true, false):
		var c := n as Control
		if not (c is Button or c is Label) or not c.is_visible_in_tree() or c.get_window() != get_tree().root:
			continue
		var t: String = c.get("text")
		if t.strip_edges() == "" or c.size.x < 4.0:
			continue
		if c.get_global_rect().end.x > ancho + 2.0 and c.get_global_rect().position.x < ancho:
			if _en_desplazable(c):
				continue   ## dentro de un ScrollContainer con desplazamiento horizontal: se llega con el dedo, no se sale
			sale += 1
			ej.append("«%s» se sale %d px" % [t.left(30), int(c.get_global_rect().end.x - ancho)])
			continue
		var corta: bool = c.get("clip_text") or int(c.get("text_overrun_behavior")) != TextServer.OVERRUN_NO_TRIMMING
		var envuelve: bool = int(c.get("autowrap_mode")) != TextServer.AUTOWRAP_OFF
		if corta and not envuelve and not t.contains("\n"):
			var f := c.get_theme_font("font")
			var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, c.get_theme_font_size("font_size")).x
			var hueco := c.size.x - (c.get_theme_stylebox("normal").get_minimum_size().x if c is Button else 0.0)
			if w > hueco + 2.0:
				cort += 1
				ej.append("«%s» cortado %d/%d" % [t.left(30), int(w), int(hueco)])
	return [cort, sale, ej]

## (D) El tutorial entero: cada paso cabe en pantalla, su texto no se corta y su objetivo está a la vista.
func _tutorial() -> void:
	var antes := Idiomas.idioma
	var vp := get_viewport().get_visible_rect()
	var pasos_total := 0
	var fuera: Array[String] = []
	var cortado: Array[String] = []
	var sin_objetivo: Array[String] = []
	var tapa: Array[String] = []
	for config: Array in [[1.0, "es"], [1.6, "es"], [1.3, "de"], [1.6, "en"]]:
		_p._escala_texto = float(config[0])
		Idiomas.idioma = String(config[1])
		for modo: String in ["dt", "dir", "ayudante", "interino", "cantera", "imperio", "jeque", "creador"]:
			_p._guia.abrir(modo)
			await _frames(4)
			var t: Variant = _p._guia._tutorial
			if not is_instance_valid(t):
				fuera.append("%s: no abre" % modo)
				continue
			var tut: Tutorial = t
			for intento in 4:
				if tut.fase() != "prologo":
					break
				tut.pulsar_prologo()   ## la primera pulsación solo completa la escritura
				await _frames(3)
			if tut.fase() == "prologo" or not tut._tarjeta.is_visible_in_tree():
				fuera.append("%s: no sale del prólogo" % modo)
				tut._terminar(false)
				continue
			var pasos: Array = tut.guion_actual()["pasos"]
			for i in pasos.size():
				tut._mostrar(i)
				tut._completar_escritura()
				await _frames(3)
				pasos_total += 1
				var donde := "%s/%s %.1f %s #%d" % [modo, config[1], config[0], pasos[i].get("titulo", ""), i]
				var r: Rect2 = tut._tarjeta.get_global_rect()
				if not vp.grow(2.0).encloses(r):
					fuera.append("%s (%s)" % [donde, str(r)])
				var lbl := tut._lbl_texto
				if lbl != null and lbl.get_content_height() > lbl.size.y + 3.0 and lbl.get_v_scroll_bar() != null and not lbl.get_v_scroll_bar().visible and not lbl.scroll_active:
					cortado.append("%s (%d > %d)" % [donde, lbl.get_content_height(), int(lbl.size.y)])
				if pasos[i].has("objetivo"):
					var obj: Control = tut._objetivo()
					if obj == null:
						sin_objetivo.append(donde + " → " + String(pasos[i]["objetivo"]))
					elif tut._tarjeta.get_global_rect().intersects(obj.get_global_rect().grow(-4.0)) and obj.get_global_rect().size.x < vp.size.x * 0.9:
						tapa.append(donde)
			tut._terminar(false)
			await _frames(3)
	Idiomas.idioma = antes
	_p._escala_texto = 1.0
	_linea("  %d pasos del tutorial recorridos (8 modos × 4 configuraciones)" % pasos_total)
	_comprobar(pasos_total >= 8 * 4 * 8, "se recorrieron %d pasos (≥ 256)" % pasos_total)
	_comprobar(fuera.is_empty(), "la tarjeta del tutorial cabe siempre en pantalla (también al 160 %% y en alemán) %s" % str(fuera.slice(0, 3)))
	_comprobar(cortado.is_empty(), "el texto de cada paso cabe en su tarjeta %s" % str(cortado.slice(0, 3)))
	_comprobar(sin_objetivo.is_empty(), "cada paso con objetivo lo tiene a la vista %s" % str(sin_objetivo.slice(0, 3)))
	_comprobar(tapa.size() <= 6, "la tarjeta casi nunca tapa el control que señala (%d, tope 6) %s" % [tapa.size(), str(tapa.slice(0, 3))])

## (E) Lector de pantalla y avisos visuales de sonido.
func _lector_y_avisos() -> void:
	var l_antes := LectorPantalla.activo()
	var a_antes := AvisosSonido.activo()
	LectorPantalla.fijar(false)
	_comprobar(not LectorPantalla.activo(), "el lector de pantalla se apaga")
	LectorPantalla.fijar(true)
	_comprobar(LectorPantalla.activo(), "y se enciende")
	var b := Button.new()
	b.text = "[b]Plantel[/b] 👥"
	b.tooltip_text = "Tus jugadores"
	_p.add_child(b)
	var dicho := LectorPantalla.texto_de(b)
	_comprobar(dicho.contains("Plantel") and not dicho.contains("[b]"), "el lector dice «%s» (sin etiquetas BBCode)" % dicho)
	var le := Label.new()
	le.text = "Marcador 2-1"
	_p.add_child(le)
	_comprobar(LectorPantalla.texto_de(le).contains("Marcador 2-1"), "el lector lee una etiqueta")
	b.queue_free()
	le.queue_free()
	LectorPantalla.fijar(l_antes)
	AvisosSonido.fijar(true)
	_comprobar(AvisosSonido.activo(), "los avisos visuales de sonido se encienden")
	for nombre: String in ["silbato", "gol", "roja", "ovacion", "trofeo", "fichaje"]:
		var texto := AvisosSonido.texto(nombre)
		_comprobar(texto.begins_with("🔊 ") and texto.length() > 4, "aviso de sonido «%s»: %s" % [nombre, texto])
	_comprobar(AvisosSonido.texto("sonido_que_no_existe") == "", "un sonido sin aviso no escribe nada")
	var vacios: Array[String] = []
	for k: String in AvisosSonido.TEXTOS:
		if String(AvisosSonido.TEXTOS[k]).strip_edges() == "":
			vacios.append(k)
	_comprobar(AvisosSonido.TEXTOS.size() >= 30 and vacios.is_empty(), "los %d avisos de sonido tienen texto %s" % [AvisosSonido.TEXTOS.size(), str(vacios)])
	Idiomas._asegurar_todos()
	var sin_trad := {}
	for l: String in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
		Idiomas.idioma = l
		var n := 0
		for k: String in AvisosSonido.TEXTOS:
			if Idiomas.t(String(AvisosSonido.TEXTOS[k])) == String(AvisosSonido.TEXTOS[k]):
				n += 1
		sin_trad[l] = n
		_comprobar(n <= 6, "%s: los avisos de sonido salen traducidos (%d iguales al castellano, tope 6)" % [l, n])
	Idiomas.idioma = "es"
	AvisosSonido.fijar(a_antes)

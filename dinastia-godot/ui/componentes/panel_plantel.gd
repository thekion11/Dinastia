class_name PanelPlantel
extends RefCounted
## La pestaña "Mi plantel": la rejilla de 24 fichas con cabeceras que ordenan
## al pulsarlas. Medida antes de tocarla (26-9-2026, misma disciplina del día):
## resultó bastante más chica que el resto -57 líneas más el comparador-, pero
## con una coupling que no tienen `TablaCompeticion`/`FichaJugadorInfo`: pintar
## una fila de jugador (`Principal._fila_jugador()`) navega DIRECTO a la ficha
## y cambia de pestaña (`_ver_ficha()`/`_ir_a_pestana()`), y el color de las
## cabeceras pasa por `Principal._color_de_paleta()` -la traducción de tema,
## distinta de `_color_accesible()`/`_pal_*()` que ya usan los demás
## componentes, con su propio salto de contraste (`_con_contraste()`)-.
##
## Duplicar esas dos cosas aquí habría creado una segunda fuente de verdad
## sobre cómo se navega a una ficha y sobre cómo se traduce un color de tema.
## En vez de eso, igual que `FichaJugadorAcciones` recibe la mutación como
## `Callable`, esta clase recibe **la propia pintura de una fila** y **la
## propia traducción de color** como `Callable` -`principal.gd` sigue siendo
## la única fuente de verdad de las dos, esta clase solo decide EN QUÉ ORDEN
## y CON QUÉ DATOS llamarlas.
##
## El orden de la tabla (`orden`/`orden_desc`) sigue viviendo en `principal.gd`
## -es preferencia de pantalla, se guarda entre repintados- y se lee aquí como
## parámetro; `al_pulsar_columna` avisa a Principal de qué columna se pulsó
## para que decida el nuevo orden y refresque.

## Las líneas del campo, en el orden en que se lee un plantel (de atrás hacia
## delante). La clave es el grupo `g` de la tabla POSD.
const LINEAS := [["todos", "Todos"], ["POR", "Porteros"], ["DEF", "Defensas"],
	["MED", "Centrocampistas"], ["DEL", "Delanteros"]]
## Cabeceras: rótulo, clave de orden y la ayuda que explica la abreviatura
## (MED/POT no se adivinan la primera vez que se abre la pestaña).
const COLUMNAS := [["NOMBRE", "nombre", "Ordenar por nombre"], ["POS", "pos", "Puesto natural"],
	["EDAD", "edad", "Edad"], ["MEDIA", "ovr", "Media actual: lo que rinde hoy"],
	["POT", "pot", "Potencial: hasta dónde puede llegar"], ["VALOR", "valor", "Valor de mercado"]]
## El filtro de línea es preferencia de la pantalla, como el orden; se guarda en
## la propia lista (que no se destruye entre repintados) y no en el guardado.
const META_LINEA := "uipl_linea"
## (2-11, M-293) El segundo filtro: por estado. [clave, rótulo, ayuda].
const META_ESTADO := "uipl_estado"
## (2-11, rendimiento) Las filas de filtros y la leyenda llevan emojis, y darles forma cuesta ~3 ms por botón y ~17 ms la leyenda
## (fuente de respaldo): se crean UNA vez y cada repintado solo les cambia el texto (igual = sin coste).
const META_FIJO := "uipl_fijo"
const META_REPINTAR := "uipl_repintar"
const META_COL := "uipl_col"
## Nodos de OTRO panel puestos en la misma lista (`PanelPlanificacion`): `pintar` los deja donde están.
const META_AJENO := "uipl_ajeno"
const META_FILAS := "uipl_filas"
const ESTADOS := [["todos", "Todos", "Sin filtro de estado"], ["disponibles", "✅ Disponibles", "Pueden jugar el próximo partido"],
	["bajas", "🩹 Bajas", "Lesionados o sancionados"], ["riesgo", "⚠ En riesgo", "Riesgo de lesión alto o medio: dales descanso"],
	["transferibles", "🔻 Transferibles", "Los que pusiste en venta"], ["jovenes", "↗ Jóvenes", "21 años o menos"],
	["contrato", "📝 Fin de contrato", "Les queda un año o menos: renueva o véndelos"]]

static func _estado_ok(mundo: Mundo, j: Jugador, estado: String) -> bool:
	match estado:
		"disponibles": return j.disponible()
		"bajas": return j.lesion > 0 or j.suspension > 0
		"riesgo": return _riesgo(mundo, j) != ""
		"transferibles": return j.transferible
		"jovenes": return j.edad <= 21
		"contrato": return j.anios_contrato <= 1
	return true

static func pintar(lista: VBoxContainer, c: Club, mundo: Mundo, orden: String, orden_desc: bool,
		col_acento: Color, color_de_paleta: Callable, fila_jugador: Callable,
		al_pulsar_columna: Callable) -> void:
	var fijos := _vaciar(lista)
	## ESTADO VACÍO: sin esto la pestaña quedaba con seis cabeceras sueltas y
	## ninguna pista de qué hacer.
	if c == null or c.plantilla.is_empty():
		var vacio := _texto(13, color_de_paleta.call(COL_SUAVE))
		vacio.text = Idiomas.t("Tu plantel está vacío. Ficha jugadores en el Mercado o sube canteranos desde la Cantera.")
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(vacio)
		_soltar(fijos)
		return
	var n_resumen := _resumen(lista, c, color_de_paleta)
	var linea := String(lista.get_meta(META_LINEA, "todos"))
	lista.set_meta(META_REPINTAR, func() -> void:
		pintar(lista, c, mundo, orden, orden_desc, col_acento, color_de_paleta, fila_jugador, al_pulsar_columna))
	var n_filtros := _filtros(lista, c, linea, fijos)
	var estado := String(lista.get_meta(META_ESTADO, "todos"))
	var n_estado := _filtros_estado(lista, c, mundo, estado, fijos)

	lista.set_meta(META_COL, al_pulsar_columna)
	var g := _rejilla(lista, fijos, orden, orden_desc, col_acento, color_de_paleta)
	var lista_ordenada := c.plantilla.filter(func(j: Jugador) -> bool:
		return (linea == "todos" or _linea_de(j) == linea) and _estado_ok(mundo, j, estado))
	lista_ordenada.sort_custom(func(a: Jugador, b: Jugador) -> bool:
		return _comparar(a, b, orden, orden_desc))
	_filas(g, c, mundo, lista_ordenada, fila_jugador, color_de_paleta)
	var n_nadie: Control = null
	if lista_ordenada.is_empty():
		var nadie := _texto(12, color_de_paleta.call(COL_SUAVE))
		nadie.text = Idiomas.t("Nadie en esa línea ahora mismo.") if estado == "todos" else Idiomas.t("Nadie cumple ese filtro ahora mismo.")
		lista.add_child(nadie)
		n_nadie = nadie
	var n_leyenda := _leyenda(lista, color_de_paleta, fijos)
	_soltar(fijos)
	## Las filas fijas siguen en su sitio y lo nuevo se añadió al final: se deja el orden de siempre.
	var orden_nodos: Array = [n_resumen, n_filtros, n_estado, g, n_nadie, n_leyenda]
	var pos := 0
	for n: Variant in orden_nodos:
		if n != null:
			lista.move_child(n, pos)
			pos += 1

## La rejilla (cabeceras + una fila por jugador) es FIJA: se reusa entre repintados. Cada fila de jugador (cara, nombre con marcas y cinco celdas)
## se rehace solo si cambió algo de lo que se ve (`_firma`); si no, se queda como estaba y solo se recoloca. Sin esto, cada repintado
## daba forma otra vez al nombre de los 25 jugadores (con símbolos de fuente de respaldo) y creaba ~200 nodos.
static func _rejilla(lista: VBoxContainer, fijos: Dictionary, orden: String, orden_desc: bool, col_acento: Color, color_de_paleta: Callable) -> GridContainer:
	var g := fijos.get("rejilla") as GridContainer
	if g != null:
		fijos.erase("rejilla")
	else:
		g = GridContainer.new()
		g.columns = 6
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 10)
		g.add_theme_constant_override("v_separation", 3)
		CebraRejilla.poner(g)
		g.set_meta(META_FIJO, "rejilla")
		lista.add_child(g)
		for i in COLUMNAS.size():
			var clave := String((COLUMNAS[i] as Array)[1])
			var b := Button.new()
			b.flat = true
			## Los números se alinean a la derecha en sus celdas: la cabecera también,
			## o «EDAD» queda a un lado y las edades al otro.
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT if i < 2 else HORIZONTAL_ALIGNMENT_RIGHT
			b.add_theme_font_size_override("font_size", 11)
			b.pressed.connect(func() -> void: (lista.get_meta(META_COL) as Callable).call(clave))
			g.add_child(b)
	for i in COLUMNAS.size():
		var par: Array = COLUMNAS[i]
		var clave := String(par[1])
		var b := g.get_child(i) as Button
		b.text = Idiomas.t(String(par[0])) + ("  ▾" if orden == clave and orden_desc else ("  ▴" if orden == clave else ""))
		b.tooltip_text = Idiomas.t(String(par[2]))
		b.add_theme_color_override("font_color", color_de_paleta.call(col_acento if orden == clave else COL_SUAVE))
	return g

## Todo lo que cambia lo que se ve de una fila: textos, colores ya pasados por la paleta, accesibilidad, idioma, caras y el kit del club.
static func _firma(c: Club, textos: Array, colores: Array, ayuda: String, color_de_paleta: Callable) -> String:
	var cs := PackedStringArray()
	for col: Color in colores:
		cs.append((color_de_paleta.call(col) as Color).to_html())
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [";".join(PackedStringArray(textos)), ",".join(cs), ayuda, c.color1, c.color2,
		Tema.escala_texto, Tema.daltonico, Tema.contraste, Idiomas.idioma, "%s%s%s" % [Cara.usar_fotos, Cara.modo_streamer, Datos.base_real]]

static func _filas(g: GridContainer, c: Club, mundo: Mundo, orden_jugadores: Array, fila_jugador: Callable, color_de_paleta: Callable) -> void:
	var cache: Dictionary = g.get_meta(META_FILAS, {})
	var vivos := {}
	var nodos_en_orden: Array = []
	for j: Jugador in orden_jugadores:
		var color := COL_TEXTO
		if not j.disponible():
			color = COL_ROJO
		elif j.edad <= 22 and j.pot >= j.ovr + 6:
			color = COL_VERDE
		var marcas := ""
		if j.capitan:
			marcas += " Ⓒ"
		if j.transferible:
			marcas += " 🔻"
		if j.lesion > 0:
			marcas += " 🩹"
		elif j.suspension > 0:
			marcas += " 🚫"
		if mundo.entrenamiento != null and not mundo.entrenamiento.habilidades(j).is_empty():
			marcas += " ✦"
		## El verde de «joven con margen» lleva también su marca (s3, accesibilidad:
		## ningún dato solo con color; lo rojo ya lleva 🩹 o 🚫).
		if color == COL_VERDE:
			marcas += " ↗"
		## M-235 (2-11): la PREVENCIÓN a la vista. ⚠ riesgo alto de lesión (historial, rasgo frágil o físico bajo), △ medio;
		## la ayuda del nombre dice por qué y qué hacer (descanso, menos carga).
		var riesgo := _riesgo(mundo, j)
		if riesgo == "alto":
			marcas += " ⚠"
		elif riesgo == "medio":
			marcas += " △"
		## U6 (3-11): 🟨 = a una amarilla de la sanción (`Disciplina`); su ayuda explica cuántas lleva.
		var ayuda := _texto_riesgo(mundo, j, riesgo) if riesgo != "" else ""
		if Disciplina.a_una(j):
			marcas += " 🟨"
			ayuda += ("\n" if ayuda != "" else "") + Disciplina.frase_borde(j)
		var textos := [j.nombre + marcas, j.pos_e, str(j.edad), str(j.ovr), str(j.pot), _dinero(j.valor)]
		var colores := [color, COL_SUAVE, color, color, COL_SUAVE, color]
		var firma := _firma(c, textos, colores, ayuda, color_de_paleta)
		var id := j.get_instance_id()
		var fila: Dictionary = cache.get(id, {})
		if fila.is_empty() or String(fila["firma"]) != firma:
			for n: Node in fila.get("nodos", []):
				g.remove_child(n)
				n.queue_free()
			var antes := g.get_child_count()
			fila_jugador.call(g, j, textos, colores)
			_ajustar_nombre(g, antes, j)
			if ayuda != "" and antes < g.get_child_count():
				var celda := g.get_child(antes) as Control
				celda.tooltip_text = ayuda
				celda.mouse_filter = Control.MOUSE_FILTER_PASS
			fila = {"firma": firma, "nodos": g.get_children().slice(antes)}
			cache[id] = fila
		vivos[id] = true
		nodos_en_orden.append_array(fila["nodos"])
	for id: int in cache.keys():
		if not vivos.has(id):
			for n: Node in (cache[id] as Dictionary)["nodos"]:
				g.remove_child(n)
				n.queue_free()
			cache.erase(id)
	g.set_meta(META_FILAS, cache)
	var pos := COLUMNAS.size()
	for n: Node in nodos_en_orden:
		g.move_child(n, pos)
		pos += 1

## Riesgo de lesión de un jugador sano: "alto", "medio" o "" (bajo). Junta el informe del médico (historial y rasgo)
## con el físico que le queda; lesionado no se marca (ya lleva 🩹).
static func _riesgo(mundo: Mundo, j: Jugador) -> String:
	if j.lesion > 0 or mundo == null or mundo.medico == null:
		return ""
	var decl := mundo.medico.riesgo_declarado(j)
	if decl == "alto" or (decl == "medio-alto" and j.fisico < 70) or j.fisico < 50:
		return "alto"
	if decl in ["medio", "medio-alto"] or j.fisico < 62:
		return "medio"
	return ""

static func _texto_riesgo(mundo: Mundo, j: Jugador, riesgo: String) -> String:
	var graves := mundo.medico.lesiones_graves(j)
	var por: Array[String] = []
	if graves > 0:
		por.append(Idiomas.t("%d lesión(es) grave(s)") % graves)
	if j.rasgo == "fragil":
		por.append(Idiomas.t("rasgo frágil"))
	if j.fisico < 62:
		por.append(Idiomas.t("físico %d") % j.fisico)
	return Idiomas.t("Riesgo de lesión %s: %s. Dale descanso o bájale la carga en Entrenar.") % [Idiomas.t(riesgo), ", ".join(por)]

## La línea del campo de un jugador (POR, DEF, MED o DEL).
static func _linea_de(j: Jugador) -> String:
	return String((Datos.posd().get(j.pos_e, {}) as Dictionary).get("g", ""))

## Una línea con el plantel de un vistazo: cuántos, qué media, qué edad y
## cuántos no están para jugar. Es lo que se viene a mirar antes de la tabla.
static func _resumen(lista: VBoxContainer, c: Club, color_de_paleta: Callable) -> Control:
	var n := c.plantilla.size()
	var suma_ovr := 0
	var suma_edad := 0
	var fuera := 0
	for j: Jugador in c.plantilla:
		suma_ovr += j.ovr
		suma_edad += j.edad
		if not j.disponible():
			fuera += 1
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 14)
	lista.add_child(fila)
	var t := _texto(12, color_de_paleta.call(COL_TEXTO))
	t.text = Idiomas.t("%d jugadores  ·  media %.1f  ·  edad media %.1f") % [n, float(suma_ovr) / n, float(suma_edad) / n]
	fila.add_child(t)
	var f := _texto(12, color_de_paleta.call(COL_ROJO if fuera > 0 else COL_VERDE))
	f.text = Idiomas.t("%d no disponibles") % fuera if fuera > 0 else Idiomas.t("todos disponibles")
	fila.add_child(f)
	return fila

## Los botones de línea, con cuántos hay en cada una. Conmutables: el pulsado
## se ve encendido, y con el mando se recorren como cualquier botón.
static func _filtros(lista: VBoxContainer, c: Club, linea: String, fijos: Dictionary) -> Control:
	var cuenta := {"todos": c.plantilla.size()}
	for j: Jugador in c.plantilla:
		var l := _linea_de(j)
		cuenta[l] = int(cuenta.get(l, 0)) + 1
	var fila := _fila_fija(lista, "filtros", fijos)
	var nuevo := fila.get_child_count() == 0
	for i in LINEAS.size():
		var par: Array = LINEAS[i]
		var clave := String(par[0])
		var b: Button
		if nuevo:
			b = Button.new()
			b.toggle_mode = true
			b.add_theme_font_size_override("font_size", 11)
			b.pressed.connect(func() -> void:
				lista.set_meta(META_LINEA, clave)
				(lista.get_meta(META_REPINTAR) as Callable).call())
			fila.add_child(b)
		else:
			b = fila.get_child(i) as Button
		b.text = "%s  %d" % [Idiomas.t(String(par[1])), int(cuenta.get(clave, 0))]
		b.set_pressed_no_signal(linea == clave)
	return fila

## La fila de filtros por estado (M-293), con cuántos cumple cada uno dentro de la línea elegida.
static func _filtros_estado(lista: VBoxContainer, c: Club, mundo: Mundo, estado: String, fijos: Dictionary) -> Control:
	var linea := String(lista.get_meta(META_LINEA, "todos"))
	var fila := _fila_fija(lista, "estado", fijos)
	var nuevo := fila.get_child_count() == 0
	for i in ESTADOS.size():
		var par: Array = ESTADOS[i]
		var clave := String(par[0])
		var n := 0
		for j: Jugador in c.plantilla:
			if (linea == "todos" or _linea_de(j) == linea) and _estado_ok(mundo, j, clave):
				n += 1
		var b: Button
		if nuevo:
			b = Button.new()
			b.toggle_mode = true
			b.add_theme_font_size_override("font_size", 11)
			b.pressed.connect(func() -> void:
				lista.set_meta(META_ESTADO, clave)
				(lista.get_meta(META_REPINTAR) as Callable).call())
			fila.add_child(b)
		else:
			b = fila.get_child(i) as Button
		b.text = "%s  %d" % [Idiomas.t(String(par[1])), n]
		b.tooltip_text = Idiomas.t(String(par[2]))
		b.set_pressed_no_signal(estado == clave)
	return fila

## Libera lo que no es fijo; las filas fijas SE QUEDAN dentro de `lista` (sacarlas y volver a ponerlas rehace la forma de
## todo su texto: el tema se notifica al entrar en el árbol). Devuelve las fijas por nombre.
static func _vaciar(lista: Node) -> Dictionary:
	var fijos := {}
	for h in lista.get_children():
		if h.has_meta(META_AJENO):
			continue
		if h.has_meta(META_FIJO):
			fijos[String(h.get_meta(META_FIJO))] = h
		else:
			lista.remove_child(h)
			h.queue_free()
	return fijos

## Lo que no se volvió a usar (p. ej. el plantel quedó vacío) se libera.
static func _soltar(fijos: Dictionary) -> void:
	for h: Node in fijos.values():
		h.get_parent().remove_child(h)
		h.queue_free()
	fijos.clear()

## La fila fija `nombre`: la guardada si la hay, o una HFlow nueva; ya puesta en `lista`.
static func _fila_fija(lista: VBoxContainer, nombre: String, fijos: Dictionary) -> HFlowContainer:
	var fila := fijos.get(nombre) as HFlowContainer
	if fila != null:
		fijos.erase(nombre)
	else:
		fila = HFlowContainer.new()
		fila.add_theme_constant_override("h_separation", 6)
		fila.add_theme_constant_override("v_separation", 6)
		fila.set_meta(META_FIJO, nombre)
		lista.add_child(fila)
	return fila

## El botón del nombre lo crea `Principal._fila_jugador()` sin `clip_text`, y un
## Button sin recorte pide de ancho todo su texto: con un nombre largo y sus
## marcas, la rejilla no cabía a 1280×720 y la columna VALOR se cortaba detrás
## de la barra de desplazamiento. Aquí se le deja encoger (con un mínimo para
## que siempre se lea algo) y el nombre entero queda en la ayuda.
static func _ajustar_nombre(g: GridContainer, desde: int, j: Jugador) -> void:
	if desde >= g.get_child_count():
		return
	var celda := g.get_child(desde) as Control
	## La columna del nombre se queda con todo el sobrante y las de números
	## (que `_celda()` crea expandibles) se ciñen a su ancho: si no, el reparto
	## era a partes iguales y a 1920×1080 los apellidos seguían cortados
	## mientras «EDAD» tenía 100 píxeles de aire.
	celda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for k in range(desde + 1, g.get_child_count()):
		(g.get_child(k) as Control).size_flags_horizontal = Control.SIZE_FILL
	## (13-11) La última celda (el valor) deja 10 px a su derecha: quedaba pegada a la barra de desplazamiento.
	var ultima := g.get_child(g.get_child_count() - 1) as Label
	if ultima != null:
		var aire := StyleBoxEmpty.new()
		aire.content_margin_right = 10
		ultima.add_theme_stylebox_override("normal", aire)
	for h in celda.get_children():
		if h is Button:
			var b := h as Button
			b.clip_text = true
			b.custom_minimum_size.x = 96
			b.tooltip_text = "%s  ·  %s  ·  %d/%d" % [j.nombre, j.pos_e, j.ovr, j.pot]

## Qué quiere decir cada marca y cada color: sin esto, el verde de los jóvenes
## y los iconos solo los entendía quien había leído el código.
static func _leyenda(lista: VBoxContainer, color_de_paleta: Callable, fijos: Dictionary) -> Control:
	var l := fijos.get("leyenda") as Label
	if l != null:
		fijos.erase("leyenda")
		l.add_theme_color_override("font_color", color_de_paleta.call(COL_SUAVE))
	else:
		l = _texto(10, color_de_paleta.call(COL_SUAVE))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.set_meta(META_FIJO, "leyenda")
		lista.add_child(l)
	l.text = Idiomas.t("Ⓒ capitán  ·  🔻 transferible  ·  🩹 lesionado  ·  🚫 sancionado  ·  ✦ habilidad especial  ·  ↗ (verde): joven con margen  ·  ⚠/△ riesgo de lesión alto/medio  ·  rojo: no disponible")
	return l

## Calcado de `Principal._comparar_plantel()`, con `orden`/`orden_desc` como
## parámetros en vez de leídos de estado propio -pura del todo-. Mismo cuidado
## que ya costó un bug real el 11-9: con empate, ninguna combinación de `a`/`b`
## puede devolver `true`, o Godot rompe el orden con "bad comparison function".
static func _comparar(a: Jugador, b: Jugador, orden: String, orden_desc: bool) -> bool:
	var x := b if orden_desc else a
	var y := a if orden_desc else b
	match orden:
		"nombre": return x.nombre.naturalnocasecmp_to(y.nombre) < 0
		"pos": return x.pos_e < y.pos_e
		"edad": return x.edad < y.edad
		"pot": return x.pot < y.pot
		"valor": return x.valor < y.valor
		_: return x.ovr < y.ovr

# ── HELPERS DE UI, duplicados a propósito de `principal.gd` ────────────────
# Colores en crudo (COL_*): no pasan por daltónico ni tema aquí, calcado del
# original -`_celda()`/`_texto()` en `principal.gd` tampoco los traducen para
# las columnas que no son el nombre-. `COL_ACENTO` NO está aquí: en Principal
# es `var`, no `const` -cambia cada refresco al color del club (`_acento_de`)-,
# así que llega como parámetro (`col_acento`) en vez de duplicarse mal.
const COL_SUAVE := Tema.SUAVE
const COL_TEXTO := Tema.TEXTO
const COL_ROJO := Tema.MAL
const COL_VERDE := Tema.BIEN

static func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

static func _limpiar(n: Node) -> void:
	for h in n.get_children():
		n.remove_child(h)
		h.queue_free()

## Calcado de `Principal._dinero()`, con el mismo factor `Eco.ECO`.
static func _dinero(monto: int) -> String:
	return Eco.dinero(monto)

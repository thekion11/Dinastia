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
	["EDAD", "edad", "Edad"], ["MED", "ovr", "Media actual: lo que rinde hoy"],
	["POT", "pot", "Potencial: hasta dónde puede llegar"], ["VALOR", "valor", "Valor de mercado"]]
## El filtro de línea es preferencia de la pantalla, como el orden; se guarda en
## la propia lista (que no se destruye entre repintados) y no en el guardado.
const META_LINEA := "uipl_linea"

static func pintar(lista: VBoxContainer, c: Club, mundo: Mundo, orden: String, orden_desc: bool,
		col_acento: Color, color_de_paleta: Callable, fila_jugador: Callable,
		al_pulsar_columna: Callable) -> void:
	_limpiar(lista)
	## ESTADO VACÍO: sin esto la pestaña quedaba con seis cabeceras sueltas y
	## ninguna pista de qué hacer.
	if c == null or c.plantilla.is_empty():
		var vacio := _texto(13, color_de_paleta.call(COL_SUAVE))
		vacio.text = Idiomas.t("Tu plantel está vacío. Ficha jugadores en el Mercado o sube canteranos desde la Cantera.")
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(vacio)
		return
	_resumen(lista, c, color_de_paleta)
	var linea := String(lista.get_meta(META_LINEA, "todos"))
	var repintar := func() -> void:
		pintar(lista, c, mundo, orden, orden_desc, col_acento, color_de_paleta, fila_jugador, al_pulsar_columna)
	_filtros(lista, c, linea, repintar)

	var g := GridContainer.new()
	g.columns = 6
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 3)
	lista.add_child(g)
	for i in COLUMNAS.size():
		var par: Array = COLUMNAS[i]
		var clave := String(par[1])
		var b := Button.new()
		b.text = Idiomas.t(String(par[0])) + ("  ▾" if orden == clave and orden_desc else ("  ▴" if orden == clave else ""))
		b.tooltip_text = Idiomas.t(String(par[2]))
		b.flat = true
		## Los números se alinean a la derecha en sus celdas: la cabecera también,
		## o «EDAD» queda a un lado y las edades al otro.
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT if i < 2 else HORIZONTAL_ALIGNMENT_RIGHT
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color",
			color_de_paleta.call(col_acento if orden == clave else COL_SUAVE))
		b.pressed.connect(func() -> void: al_pulsar_columna.call(clave))
		g.add_child(b)

	var lista_ordenada := c.plantilla.filter(func(j: Jugador) -> bool:
		return linea == "todos" or _linea_de(j) == linea)
	lista_ordenada.sort_custom(func(a: Jugador, b: Jugador) -> bool:
		return _comparar(a, b, orden, orden_desc))
	for j: Jugador in lista_ordenada:
		var color := COL_TEXTO
		if not j.disponible():
			color = COL_ROJO
		elif j.edad <= 22 and j.pot >= j.ovr + 6:
			color = COL_VERDE
		var marcas := ""
		if j.capitan:
			marcas += "  Ⓒ"
		if j.transferible:
			marcas += "  🔻"
		if j.lesion > 0:
			marcas += "  🩹"
		elif j.suspension > 0:
			marcas += "  🚫"
		if mundo.entrenamiento != null and not mundo.entrenamiento.habilidades(j).is_empty():
			marcas += "  ✦"
		var antes := g.get_child_count()
		fila_jugador.call(g, j,
			[j.nombre + marcas, j.pos_e, str(j.edad), str(j.ovr), str(j.pot), _dinero(j.valor)],
			[color, COL_SUAVE, color, color, COL_SUAVE, color])
		_ajustar_nombre(g, antes, j)
	if lista_ordenada.is_empty():
		var nadie := _texto(12, color_de_paleta.call(COL_SUAVE))
		nadie.text = Idiomas.t("Nadie en esa línea ahora mismo.")
		lista.add_child(nadie)
	_leyenda(lista, color_de_paleta)

## La línea del campo de un jugador (POR, DEF, MED o DEL).
static func _linea_de(j: Jugador) -> String:
	return String((Datos.posd().get(j.pos_e, {}) as Dictionary).get("g", ""))

## Una línea con el plantel de un vistazo: cuántos, qué media, qué edad y
## cuántos no están para jugar. Es lo que se viene a mirar antes de la tabla.
static func _resumen(lista: VBoxContainer, c: Club, color_de_paleta: Callable) -> void:
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

## Los botones de línea, con cuántos hay en cada una. Conmutables: el pulsado
## se ve encendido, y con el mando se recorren como cualquier botón.
static func _filtros(lista: VBoxContainer, c: Club, linea: String, repintar: Callable) -> void:
	var cuenta := {"todos": c.plantilla.size()}
	for j: Jugador in c.plantilla:
		var l := _linea_de(j)
		cuenta[l] = int(cuenta.get(l, 0)) + 1
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 6)
	fila.add_theme_constant_override("v_separation", 6)
	lista.add_child(fila)
	for par: Array in LINEAS:
		var clave := String(par[0])
		var b := Button.new()
		b.text = "%s  %d" % [Idiomas.t(String(par[1])), int(cuenta.get(clave, 0))]
		b.toggle_mode = true
		b.button_pressed = linea == clave
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(func() -> void:
			lista.set_meta(META_LINEA, clave)
			repintar.call())
		fila.add_child(b)

## El botón del nombre lo crea `Principal._fila_jugador()` sin `clip_text`, y un
## Button sin recorte pide de ancho todo su texto: con un nombre largo y sus
## marcas, la rejilla no cabía a 1280×720 y la columna VALOR se cortaba detrás
## de la barra de desplazamiento. Aquí se le deja encoger (con un mínimo para
## que siempre se lea algo) y el nombre entero queda en la ayuda.
static func _ajustar_nombre(g: GridContainer, desde: int, j: Jugador) -> void:
	if desde >= g.get_child_count():
		return
	var celda := g.get_child(desde)
	for h in celda.get_children():
		if h is Button:
			var b := h as Button
			b.clip_text = true
			b.custom_minimum_size.x = 96
			b.tooltip_text = "%s  ·  %s  ·  %d/%d" % [j.nombre, j.pos_e, j.ovr, j.pot]

## Qué quiere decir cada marca y cada color: sin esto, el verde de los jóvenes
## y los iconos solo los entendía quien había leído el código.
static func _leyenda(lista: VBoxContainer, color_de_paleta: Callable) -> void:
	var l := _texto(10, color_de_paleta.call(COL_SUAVE))
	l.text = Idiomas.t("Ⓒ capitán  ·  🔻 transferible  ·  🩹 lesionado  ·  🚫 sancionado  ·  ✦ habilidad especial  ·  verde: joven con margen  ·  rojo: no disponible")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(l)

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

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

static func pintar(lista: VBoxContainer, c: Club, mundo: Mundo, orden: String, orden_desc: bool,
		col_acento: Color, color_de_paleta: Callable, fila_jugador: Callable,
		al_pulsar_columna: Callable) -> void:
	var g := _rejilla(lista)
	for par in [["NOMBRE", "nombre"], ["POS", "pos"], ["EDAD", "edad"],
			["MED", "ovr"], ["POT", "pot"], ["VALOR", "valor"]]:
		var clave := String(par[1])
		var b := Button.new()
		b.text = String(par[0]) + ("  ▾" if orden == clave and orden_desc else ("  ▴" if orden == clave else ""))
		b.flat = true
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color",
			color_de_paleta.call(col_acento if orden == clave else COL_SUAVE))
		b.pressed.connect(func() -> void: al_pulsar_columna.call(clave))
		g.add_child(b)

	var lista_ordenada := c.plantilla.duplicate()
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
		fila_jugador.call(g, j,
			[j.nombre + marcas, j.pos_e, str(j.edad), str(j.ovr), str(j.pot), _dinero(j.valor)],
			[color, COL_SUAVE, color, color, COL_SUAVE, color])

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

static func _rejilla(lista: VBoxContainer) -> GridContainer:
	_limpiar(lista)
	var g := GridContainer.new()
	g.columns = 6
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 3)
	lista.add_child(g)
	return g

## Calcado de `Principal._dinero()`, con el mismo factor `Eco.ECO`.
static func _dinero(monto: int) -> String:
	return Eco.dinero(monto)

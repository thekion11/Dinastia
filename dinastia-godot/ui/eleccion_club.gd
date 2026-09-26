class_name EleccionClub
extends Control
## Dónde empiezas: país y club, el paso 4 del asistente del HTML
## (`renderPortada()`, "DÓNDE EMPIEZAS"). Sin el globo interactivo -sigue en
## el HTML, es su propia pieza- pero con la misma idea: el mundo se genera
## ENTERO (`Mundo.generar([], ...)`, las 24 ligas, como hace `crear()` en el
## HTML siempre) y aquí solo se elige a cuál de sus 384 clubes tomarle el
## mando. Antes de esto no había ningún paso así: `_nuevo_mundo()` tomaba
## siempre al primero de Chile, sin preguntar.

const COL_FONDO := Tema.FONDO
const COL_PANEL := Tema.PANEL
const COL_BORDE := Tema.BORDE
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE
const COL_ACENTO := Tema.ACENTO

var _mundo: Mundo
var _pais_actual := "CHI"
var _fila_paises: HBoxContainer
var _lista_clubes: VBoxContainer
var _titulo_liga: Label
var _desafios: Array[String] = []
var _col1: ColorPickerButton
var _col2: ColorPickerButton
var _campo_estadio: LineEdit
var _fila_desafios: HFlowContainer
var _etiqueta_mult: Label
## El globo interactivo de verdad, idea de Gemini: reemplaza el mapa plano que
## nunca llegó a construirse. Arrastrarlo lo gira; elegir un país lo hace viajar
## hasta ahí solo, como `globoIr()` en el HTML.
var _globo: Globo3D
var _ficha_pais: Label

func _ready() -> void:
	Escudo.limpiar_cache()
	Cara.limpiar_cache()
	_mundo = Mundo.new()
	_mundo.generar([], 0)
	## UN RETO (26-9-2026): el club lo elige el propio reto, y a jugar.
	if Principal.reto_pedido != "":
		var id := Principal.reto_pedido
		Principal.reto_pedido = ""
		if Retos.montar(_mundo, id) != null:
			Principal.mundo_pregenerado = _mundo
			Principal.desafios_elegidos = []
			get_tree().change_scene_to_file.call_deferred("res://escenas/principal.tscn")
			return
	_construir()
	_elegir_pais("CHI")

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 12)
	raiz.offset_left = 24; raiz.offset_top = 20
	raiz.offset_right = -24; raiz.offset_bottom = -20
	add_child(raiz)

	var t := _texto(20, COL_TEXTO)
	t.text = "¿DÓNDE EMPIEZAS?"
	raiz.add_child(t)
	var sub := _texto(12, COL_SUAVE)
	sub.text = "El mundo ya está generado entero -las 24 ligas-, esto solo elige a quién diriges."
	raiz.add_child(sub)

	## El globo: "Arrastra el globo con el dedo para girarlo", igual que en el
	## HTML. Va antes de los chips de país -que se quedan, son el atajo rápido
	## y accesible- porque el globo es quien anima el viaje cuando se toca uno.
	_globo = Globo3D.new()
	_globo.custom_minimum_size = Vector2(0, 250)
	raiz.add_child(_globo)
	var pista := _texto(11, COL_SUAVE)
	pista.text = "Arrastra el globo para girarlo, o haz clic en el pin de un país."
	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(pista)
	_globo.pais_tocado.connect(_elegir_pais)
	## C14: la ficha del país elegido, con sus datos.
	_ficha_pais = _texto(12, COL_TEXTO)
	_ficha_pais.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ficha_pais.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(_ficha_pais)

	## Los países: uno por cada liga distinta que trajo el mundo, ordenados con
	## Chile primero -es donde vive el juego- y el resto tal como los devuelve
	## el mundo, que es el mismo orden que PAISES_LIGAS.
	var scroll_paises := ScrollContainer.new()
	scroll_paises.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_paises.custom_minimum_size = Vector2(0, 40)
	raiz.add_child(scroll_paises)
	_fila_paises = HBoxContainer.new()
	_fila_paises.add_theme_constant_override("separation", 6)
	scroll_paises.add_child(_fila_paises)
	var paises: Array[String] = []
	for l: Liga in _mundo.ligas:
		if not paises.has(l.pais):
			paises.append(l.pais)
	paises.sort_custom(func(a: String, b: String) -> bool:
		if a == "CHI": return true
		if b == "CHI": return false
		return a < b)
	for p: String in paises:
		var b := Button.new()
		b.text = p
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(64, 32)
		b.pressed.connect(func() -> void: _elegir_pais(p))
		_fila_paises.add_child(b)

	_construir_fundar(raiz)
	_construir_desafios(raiz)

	_titulo_liga = _texto(13, COL_ACENTO)
	raiz.add_child(_titulo_liga)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	raiz.add_child(scroll)
	_lista_clubes = VBoxContainer.new()
	_lista_clubes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista_clubes.add_theme_constant_override("separation", 6)
	scroll.add_child(_lista_clubes)

## "Crear tu Club" (`crearClubPortada()` del HTML): fundas un club de cero,
## tomando el puesto del colista del país que tengas elegido arriba -en Chile,
## el colista de Ascenso-. Reemplaza al club, no crea uno nuevo: es la misma
## regla que ya usaba el HTML y evita tener que inflar el mundo con un club
## 385 a mitad de partida.
var _campo_nombre_club: LineEdit

func _construir_fundar(raiz: VBoxContainer) -> void:
	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = COL_PANEL
	e.border_color = COL_BORDE
	e.set_border_width_all(1)
	e.set_corner_radius_all(8)
	e.content_margin_left = 12; e.content_margin_right = 12
	e.content_margin_top = 8; e.content_margin_bottom = 8
	caja.add_theme_stylebox_override("panel", e)
	raiz.add_child(caja)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	var t := _texto(11, COL_SUAVE)
	t.text = "FUNDAR TU CLUB"
	t.custom_minimum_size = Vector2(110, 0)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(t)
	_campo_nombre_club = LineEdit.new()
	_campo_nombre_club.placeholder_text = "Nombre de tu club"
	_campo_nombre_club.custom_minimum_size = Vector2(220, 32)
	fila.add_child(_campo_nombre_club)
	## Colores y estadio del club nuevo (26-9-2026).
	_col1 = ColorPickerButton.new()
	_col1.color = Color("1e4030")
	_col1.custom_minimum_size = Vector2(40, 32)
	_col1.tooltip_text = "Color principal"
	fila.add_child(_col1)
	_col2 = ColorPickerButton.new()
	_col2.color = Color("c9a227")
	_col2.custom_minimum_size = Vector2(40, 32)
	_col2.tooltip_text = "Color secundario"
	fila.add_child(_col2)
	_campo_estadio = LineEdit.new()
	_campo_estadio.placeholder_text = "Nombre del estadio"
	_campo_estadio.custom_minimum_size = Vector2(170, 32)
	fila.add_child(_campo_estadio)
	if Principal.fundar_pedido:
		e.border_color = COL_ACENTO
		e.set_border_width_all(2)
		t.text = "🛠️ FUNDA TU CLUB"
		t.add_theme_color_override("font_color", COL_ACENTO)
		_campo_nombre_club.call_deferred("grab_focus")
	var b := Button.new()
	b.text = "Fundar en el país elegido"
	b.custom_minimum_size = Vector2(0, 32)
	b.pressed.connect(_fundar)
	fila.add_child(b)
	var nota := _texto(11, COL_SUAVE)
	nota.text = "Reemplaza al colista de Ascenso (o de su única división fuera de Chile). Reputación 58, plantel nuevo."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(nota)
	nota.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _fundar() -> void:
	var nombre := _campo_nombre_club.text.strip_edges()
	if nombre == "":
		return
	Principal.fundar_pedido = false
	var club := _mundo.fundar_club(nombre, _pais_actual, "#" + _col1.color.to_html(false), "#" + _col2.color.to_html(false), _campo_estadio.text.strip_edges())
	if club == null:
		return
	Principal.mundo_pregenerado = _mundo
	Principal.desafios_elegidos = _desafios.duplicate()
	get_tree().change_scene_to_file("res://escenas/principal.tscn")

## Los desafíos: reglas extra, opcionales, que multiplican el puntaje final
## de la carrera. Paso 5 del asistente del HTML -optativo ahí también-, tal
## cual: se eligen, quedan guardados con la partida (`Mundo.desafios`), y los
## que se pueden hacer cumplir de verdad (no todos: "leyenda30" y "sinRecarga"
## son solo un aviso también en el HTML) actúan desde `Mundo.aplicar_desafios()`
## o mientras se juega.
func _construir_desafios(raiz: VBoxContainer) -> void:
	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = COL_PANEL
	e.border_color = COL_BORDE
	e.set_border_width_all(1)
	e.set_corner_radius_all(8)
	e.content_margin_left = 12; e.content_margin_right = 12
	e.content_margin_top = 8; e.content_margin_bottom = 8
	caja.add_theme_stylebox_override("panel", e)
	raiz.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	var t := _texto(11, COL_SUAVE)
	t.text = "DESAFÍOS (OPCIONAL)  ·  reglas extra que multiplican el puntaje final"
	v.add_child(t)
	_fila_desafios = HFlowContainer.new()
	_fila_desafios.add_theme_constant_override("h_separation", 6)
	_fila_desafios.add_theme_constant_override("v_separation", 6)
	v.add_child(_fila_desafios)
	var tabla: Variant = Datos.tabla("DESAFIOS")
	if tabla is Array:
		for fila: Array in (tabla as Array):
			var k := String(fila[0])
			var b := Button.new()
			b.text = "%s %s  ×%s" % [String(fila[1]), String(fila[2]), str(fila[4])]
			b.tooltip_text = String(fila[3])
			b.toggle_mode = true
			b.add_theme_font_size_override("font_size", 11)
			b.pressed.connect(func() -> void: _alternar_desafio(k))
			_fila_desafios.add_child(b)
	_etiqueta_mult = _texto(11, COL_ACENTO)
	_etiqueta_mult.text = "Multiplicador total: ×1"
	v.add_child(_etiqueta_mult)

func _alternar_desafio(k: String) -> void:
	if _desafios.has(k):
		_desafios.erase(k)
	else:
		_desafios.append(k)
	var mult := 1.0
	var tabla: Variant = Datos.tabla("DESAFIOS")
	if tabla is Array:
		for fila: Array in (tabla as Array):
			if _desafios.has(String(fila[0])):
				mult *= float(fila[4])
	_etiqueta_mult.text = "Multiplicador total: ×%.2f" % mult

func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

func _elegir_pais(p: String) -> void:
	_pais_actual = p
	for b: Button in _fila_paises.get_children():
		b.button_pressed = (b.text == p)
	if _globo != null and Globo3D.GLOBO_PAIS.has(p):
		_globo.ir_a(p)
	## Chile trae dos ligas -Primera y Primera B-; el resto de países, una sola.
	## Se juntan aquí en vez de obligar a un segundo selector de división: son
	## pocos clubes de más y se distinguen igual por el nombre de la liga.
	var ligas_del_pais: Array[Liga] = []
	for l: Liga in _mundo.ligas:
		if l.pais == p:
			ligas_del_pais.append(l)
	var total_clubes := 0
	for l: Liga in ligas_del_pais:
		total_clubes += l.clubes.size()
	if _ficha_pais != null:
		_ficha_pais.text = ficha_pais(p, ligas_del_pais, total_clubes)
	_titulo_liga.text = "%s  ·  %d clubes" % [
		", ".join(ligas_del_pais.map(func(l: Liga) -> String: return l.nombre)), total_clubes]
	_limpiar(_lista_clubes)
	for l: Liga in ligas_del_pais:
		var orden := l.clubes.duplicate()
		orden.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
		for c: Club in orden:
			_lista_clubes.add_child(_fila_club(c, l))

func _fila_club(c: Club, l: Liga) -> Control:
	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = COL_PANEL
	e.border_color = COL_BORDE
	e.set_border_width_all(1)
	e.set_corner_radius_all(8)
	e.content_margin_left = 10; e.content_margin_right = 10
	e.content_margin_top = 6; e.content_margin_bottom = 6
	caja.add_theme_stylebox_override("panel", e)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	caja.add_child(fila)

	var escudo_caja := Control.new()
	escudo_caja.custom_minimum_size = Vector2(30, 30)
	var tex := TextureRect.new()
	tex.texture = Escudo.textura(c, 30)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	escudo_caja.add_child(tex)
	fila.add_child(escudo_caja)

	var nom := _texto(13, COL_TEXTO)
	nom.text = "%s%s" % [c.nombre, "  ·  Ascenso" if l.division() == 2 else ""]
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(nom)

	var rep := _texto(12, COL_SUAVE)
	rep.text = "rep %d" % c.rep
	rep.custom_minimum_size = Vector2(60, 0)
	rep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(rep)

	var b := Button.new()
	b.text = "Dirigir"
	b.custom_minimum_size = Vector2(80, 30)
	b.pressed.connect(func() -> void: _elegir_club(c))
	fila.add_child(b)
	return caja

func _limpiar(n: Node) -> void:
	for h in n.get_children():
		n.remove_child(h)
		h.queue_free()

func _elegir_club(c: Club) -> void:
	_mundo.tomar_el_mando(c.id)
	Principal.mundo_pregenerado = _mundo
	Principal.desafios_elegidos = _desafios.duplicate()
	get_tree().change_scene_to_file("res://escenas/principal.tscn")

## C14: la ficha del país en una línea -capital, ligas, nivel del fútbol en el
## ranking del juego, el mejor club, el tiempo de esta semana y la próxima
## fecha señalada del calendario-.
func ficha_pais(p: String, ligas_del_pais: Array[Liga], total_clubes: int) -> String:
	var tiers: Variant = Datos.tabla("TIER_PAIS")
	var ranking := 0
	if tiers is Dictionary:
		var orden: Array = (tiers as Dictionary).keys()
		orden.sort_custom(func(a: String, b: String) -> bool: return float(tiers[a]) > float(tiers[b]))
		ranking = orden.find(p) + 1
	var mejor: Club = null
	for l: Liga in ligas_del_pais:
		for c: Club in l.clubes:
			if mejor == null or c.rep > mejor.rep:
				mejor = c
	var clima := Clima.del_partido(p, _mundo.semana, _mundo.anio, "globo")
	var prox := Calendario.proximas(p, _mundo.anio, _mundo.semana, 1)
	var partes: Array[String] = ["📍 %s · capital %s" % [p, String(Globo3D.CAPITAL.get(p, "?"))],
		"%d liga%s, %d clubes" % [ligas_del_pais.size(), "" if ligas_del_pais.size() == 1 else "s", total_clubes]]
	if ranking > 0:
		partes.append("n.º %d del ranking de ligas" % ranking)
	if mejor != null:
		partes.append("el grande: %s" % mejor.nombre)
	partes.append("%s %s" % [Clima.icono(clima), String(clima.get("texto", ""))])
	if not prox.is_empty():
		partes.append("%s %s (%d/%d)" % [Calendario.icono(String(prox[0]["tipo"])), String(prox[0]["nombre"]), int(prox[0]["dia"]), int(prox[0]["mes"])])
	return "  ·  ".join(partes)

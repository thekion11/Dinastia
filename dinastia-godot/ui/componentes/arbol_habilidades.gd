class_name ArbolHabilidades
extends Control
## EL ÁRBOL DE HABILIDADES DEL ENTRENADOR, COMO ESQUEMA (26-9-2026). Pedido:
## *"mejora la rama de habilidades, que tenga su esquema: se ve en poca
## calidad"*. Antes era una lista de texto dentro de Legado; ahora es un árbol:
##   - una columna por rama (Gestión, Camarín, Táctica, Cantera, Medios), con su
##     color y su cabecera;
##   - cada habilidad es un nodo redondo con su icono, en la fila de su nivel
##     (el nivel es la profundidad en la cadena de requisitos);
##   - las líneas van del requisito a la habilidad que abre, doradas si ya está
##     aprendida;
##   - estados: aprendida (dorado y brillo), disponible (borde del color de la
##     rama y latido), bloqueada (apagada, con candado);
##   - al tocar un nodo, abajo sale su ficha con el botón para aprenderla.
## La lógica es de `Entrenamiento` (`dt_*`); esto solo dibuja y llama.

signal aprendida(clave: String)

const COLOR_RAMA := {
	"Gestión": Color("d9a400"), "Camarín": Color("e07b2a"), "Táctica": Color("2f7fd0"),
	"Cantera": Color("3fa06a"), "Medios": Color("b05cd6"),
}
const ICONO_RAMA := {"Gestión": "💼", "Camarín": "🫂", "Táctica": "📋", "Cantera": "🌱", "Medios": "🎤"}
const RADIO_NODO := 30.0
const ALTO_CABECERA := 64.0
const PASO_FILA := 118.0

var _e: Entrenamiento
var _nodos: Dictionary = {}      ## clave -> Button
var _centros: Dictionary = {}    ## clave -> Vector2 (local)
var _elegida: String = ""
var _ficha: PanelContainer
var _t := 0.0

static func crear(e: Entrenamiento) -> ArbolHabilidades:
	var a := ArbolHabilidades.new()
	a._e = e
	a.custom_minimum_size = Vector2(0, ALTO_CABECERA + PASO_FILA * 3.0 + 40.0)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.mouse_filter = Control.MOUSE_FILTER_PASS
	return a

func _ready() -> void:
	resized.connect(_colocar)
	_construir()
	set_process(true)

## Profundidad de una habilidad: cuántos requisitos tiene encadenados.
func _nivel(clave: String) -> int:
	var n := 0
	var r := _e.dt_requisito(clave)
	while r != "" and n < 6:
		n += 1
		r = _e.dt_requisito(r)
	return n

func _construir() -> void:
	for h in get_children():
		h.queue_free()
	_nodos.clear()
	for rama: String in _e.dt_ramas():
		for clave: String in (_e.dt_ramas()[rama] as Array):
			var b := Button.new()
			b.flat = true
			b.custom_minimum_size = Vector2(RADIO_NODO * 2.0, RADIO_NODO * 2.0)
			b.size = b.custom_minimum_size
			b.focus_mode = Control.FOCUS_NONE
			b.tooltip_text = "%s — %s" % [_e.dt_nombre(clave), _e.dt_descripcion(clave)]
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			b.pivot_offset = b.size / 2.0
			var k := clave
			b.pressed.connect(func() -> void: _elegir(k))
			b.mouse_entered.connect(func() -> void: _hover(b, true))
			b.mouse_exited.connect(func() -> void: _hover(b, false))
			add_child(b)
			_nodos[clave] = b
	_colocar()

func _hover(b: Button, dentro: bool) -> void:
	if Animar.reducidas():
		return
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2.ONE * (1.12 if dentro else 1.0), 0.12).set_trans(Tween.TRANS_BACK)

## En una columna angosta (el panel central, con las laterales abiertas) los
## hermanos del mismo nivel no caben lado a lado: cada habilidad va en su propia
## fila, alternando un poco a izquierda y derecha para que las líneas no crucen
## los nodos. En ancho, los hermanos se reparten a lo ancho de la columna.
var _estrecho := false
var _ancho_nombre: Dictionary = {}
var _radio := RADIO_NODO

func _colocar() -> void:
	var ramas: Array = _e.dt_ramas().keys()
	if ramas.is_empty() or size.x <= 0.0:
		return
	var ancho_col := size.x / float(ramas.size())
	_estrecho = ancho_col < 200.0
	_radio = 24.0 if _estrecho else RADIO_NODO
	_centros.clear()
	var alto_max := 0.0
	for i in ramas.size():
		var rama: String = ramas[i]
		var por_nivel := {}
		for clave: String in (_e.dt_ramas()[rama] as Array):
			var n := _nivel(clave)
			if not por_nivel.has(n):
				por_nivel[n] = []
			(por_nivel[n] as Array).append(clave)
		var niveles: Array = por_nivel.keys()
		niveles.sort()
		var fila := 0
		for n: int in niveles:
			var lista: Array = por_nivel[n]
			for j in lista.size():
				var x: float
				var y: float
				if _estrecho:
					var desvio := 0.0 if lista.size() == 1 else (-0.17 if j % 2 == 0 else 0.17) * ancho_col
					x = ancho_col * (float(i) + 0.5) + desvio
					y = ALTO_CABECERA + 40.0 + 96.0 * float(fila)
					_ancho_nombre[lista[j]] = ancho_col - 12.0
					fila += 1
				else:
					x = ancho_col * float(i) + ancho_col * float(j + 1) / float(lista.size() + 1)
					y = ALTO_CABECERA + 44.0 + PASO_FILA * float(n)
					## El nombre puede ocupar como mucho su hueco: si no cabe, se
					## parte en dos líneas.
					_ancho_nombre[lista[j]] = ancho_col / float(lista.size() + 1) - 6.0 if lista.size() > 1 else ancho_col - 16.0
				_centros[lista[j]] = Vector2(x, y)
				alto_max = maxf(alto_max, y)
				var b: Button = _nodos[lista[j]]
				b.custom_minimum_size = Vector2(_radio * 2.0, _radio * 2.0)
				b.size = b.custom_minimum_size
				b.pivot_offset = b.size / 2.0
				b.position = Vector2(x, y) - b.size / 2.0
			if not _estrecho:
				fila += 1
	custom_minimum_size.y = alto_max + 60.0
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _estado(clave: String) -> String:
	if _e.dt_tiene(clave):
		return "tiene"
	var req := _e.dt_requisito(clave)
	if req != "" and not _e.dt_tiene(req):
		return "bloqueada"
	return "disponible" if _e.dt_puntos >= _e.dt_coste(clave) else "cara"

func _draw() -> void:
	var ramas: Array = _e.dt_ramas().keys()
	if ramas.is_empty():
		return
	var ancho_col := size.x / float(ramas.size())
	var fuente := get_theme_default_font()
	## Columnas con su color y su cabecera.
	for i in ramas.size():
		var rama: String = ramas[i]
		var col: Color = COLOR_RAMA.get(rama, Tema.ACENTO)
		var r := Rect2(ancho_col * float(i) + 4.0, 0.0, ancho_col - 8.0, size.y)
		draw_style_box(Tema.caja(Color(col, 0.07), Tema.RADIO, Color(col, 0.25)), r)
		var cab := "%s  %s" % [String(ICONO_RAMA.get(rama, "")), rama.to_upper()]
		var ancho_t := fuente.get_string_size(cab, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(fuente, Vector2(r.position.x + (r.size.x - ancho_t) / 2.0, 30.0), cab, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
		## Cuántas tiene de esa rama.
		var total := (_e.dt_ramas()[rama] as Array).size()
		var tiene := 0
		for k: String in (_e.dt_ramas()[rama] as Array):
			if _e.dt_tiene(k):
				tiene += 1
		var prog := "%d / %d" % [tiene, total]
		var ap := fuente.get_string_size(prog, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(fuente, Vector2(r.position.x + (r.size.x - ap) / 2.0, 48.0), prog, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tema.SUAVE)
	## Las líneas de requisito, debajo de los nodos.
	for clave: String in _centros:
		var req := _e.dt_requisito(clave)
		if req == "" or not _centros.has(req):
			continue
		var a: Vector2 = _centros[req] + Vector2(0, _radio)
		var b: Vector2 = _centros[clave] - Vector2(0, _radio)
		var hecho := _e.dt_tiene(clave)
		var abierta := _e.dt_tiene(req)
		var col := Tema.ORO if hecho else (Color(Tema.TEXTO, 0.55) if abierta else Color(Tema.SUAVE, 0.25))
		var puntos := PackedVector2Array()
		for s in 17:
			var u := float(s) / 16.0
			var c1 := a + Vector2(0, 40)
			var c2 := b - Vector2(0, 40)
			var w := 1.0 - u
			puntos.append(a * w * w * w + c1 * 3.0 * w * w * u + c2 * 3.0 * w * u * u + b * u * u * u)
		draw_polyline(puntos, col, 3.0 if hecho else 2.0, true)
		## La que se puede aprender ahora: una chispa que recorre la línea.
		if abierta and not hecho and not Animar.reducidas():
			var idx := int(fmod(_t * 10.0, 16.0))
			draw_circle(puntos[idx], 3.5, Tema.ORO)
	## Los nodos.
	for clave: String in _centros:
		var c: Vector2 = _centros[clave]
		var rama := String(_e._dt_tabla()[clave][0])
		var col: Color = COLOR_RAMA.get(rama, Tema.ACENTO)
		var est := _estado(clave)
		var b: Button = _nodos[clave]
		var esc := b.scale.x
		var rad := _radio * esc
		match est:
			"tiene":
				draw_circle(c, rad + 7.0 + sin(_t * 2.0) * 1.5, Color(Tema.ORO, 0.18))
				draw_circle(c, rad, Color(Tema.ORO, 0.95))
				draw_arc(c, rad, 0, TAU, 40, Color.WHITE, 2.0, true)
			"disponible":
				var latido := 0.5 + 0.5 * sin(_t * 4.0)
				draw_circle(c, rad + 5.0 + latido * 4.0, Color(col, 0.22 * latido))
				draw_circle(c, rad, Color(Tema.PANEL, 1.0))
				draw_arc(c, rad, 0, TAU, 40, col, 3.0, true)
			"cara":
				draw_circle(c, rad, Color(Tema.PANEL, 1.0))
				draw_arc(c, rad, 0, TAU, 40, Color(col, 0.6), 2.0, true)
			_:
				draw_circle(c, rad, Color(Tema.PANEL, 0.8))
				draw_arc(c, rad, 0, TAU, 40, Color(Tema.SUAVE, 0.35), 1.5, true)
		if clave == _elegida:
			draw_arc(c, rad + 6.0, 0, TAU, 48, Color.WHITE, 2.0, true)
		## Icono dentro, nombre y coste debajo.
		var icono := _e.dt_icono(clave)
		var ic_col := Color(1, 1, 1, 1.0 if est != "bloqueada" else 0.35)
		var t_ic := 26 if not _estrecho else 20
		var ai := fuente.get_string_size(icono, HORIZONTAL_ALIGNMENT_LEFT, -1, t_ic).x
		draw_string(fuente, c + Vector2(-ai / 2.0, t_ic * 0.35), icono, HORIZONTAL_ALIGNMENT_LEFT, -1, t_ic, ic_col)
		if est == "bloqueada":
			draw_string(fuente, c + Vector2(rad - 12.0, -rad + 10.0), "🔒", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		var nom := _e.dt_nombre(clave)
		var t_nom := 13 if not _estrecho else 11
		var ancho: float = _ancho_nombre.get(clave, 120.0)
		var lineas := 1 if fuente.get_string_size(nom, HORIZONTAL_ALIGNMENT_LEFT, -1, t_nom).x <= ancho else 2
		draw_multiline_string(fuente, c + Vector2(-ancho / 2.0, rad + 16.0), nom, HORIZONTAL_ALIGNMENT_CENTER, ancho, t_nom, 2,
			Tema.ORO if est == "tiene" else (Tema.TEXTO if est != "bloqueada" else Tema.SUAVE))
		var coste := "✔" if est == "tiene" else "%d pto%s" % [_e.dt_coste(clave), "" if _e.dt_coste(clave) == 1 else "s"]
		var ac := fuente.get_string_size(coste, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(fuente, c + Vector2(-ac / 2.0, rad + 16.0 + float(lineas) * (t_nom + 2.0) + 1.0), coste, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tema.SUAVE)

## La ficha de la habilidad elegida: se la pide el panel que contiene el árbol.
func _elegir(clave: String) -> void:
	_elegida = clave
	Sonido.toca("clic" if Sonido.NOMBRES.has("clic") else "cambio", Sonido.Bus.INTERFAZ)
	if _ficha != null:
		_pintar_ficha()
	queue_redraw()

## El panel de detalle vive fuera del árbol (debajo), para no taparlo.
func ficha() -> PanelContainer:
	_ficha = PanelContainer.new()
	var sb := Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.BORDE)
	sb.content_margin_left = Tema.MARGEN
	sb.content_margin_right = Tema.MARGEN
	sb.content_margin_top = Tema.MARGEN
	sb.content_margin_bottom = Tema.MARGEN
	_ficha.add_theme_stylebox_override("panel", sb)
	_pintar_ficha()
	return _ficha

func _pintar_ficha() -> void:
	for h in _ficha.get_children():
		h.queue_free()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	_ficha.add_child(hb)
	if _elegida == "":
		hb.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Toca una habilidad para ver qué hace y aprenderla. Ganas un punto cada %d semanas; las licencias y cursos de tu vida dan más." % Entrenamiento.SEMANAS_POR_PUNTO_DT))
		return
	var rama := String(_e._dt_tabla()[_elegida][0])
	var col: Color = COLOR_RAMA.get(rama, Tema.ACENTO)
	hb.add_child(Tema.etiqueta(44, Tema.TEXTO, _e.dt_icono(_elegida)))
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)
	vb.add_child(Tema.etiqueta(Tema.TAM_DESTACADO + 2, col, _e.dt_nombre(_elegida)))
	var d := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, _e.dt_descripcion(_elegida))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(d)
	var req := _e.dt_requisito(_elegida)
	vb.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "Rama %s · cuesta %d punto(s)%s" % [rama, _e.dt_coste(_elegida),
		(" · requiere %s" % _e.dt_nombre(req)) if req != "" else ""]))
	if _e.dt_tiene(_elegida):
		hb.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.ORO, "✔ Aprendida"))
		return
	var motivo := _e.dt_motivo(_elegida)
	var b := Button.new()
	b.text = "Aprender" if motivo == "" else motivo
	b.disabled = motivo != ""
	b.custom_minimum_size = Vector2(180, 44)
	var k := _elegida
	b.pressed.connect(func() -> void:
		var problema := _e.dt_aprender(k)
		if problema == "":
			aprendida.emit(k)
		_pintar_ficha()
		queue_redraw())
	hb.add_child(b)

## EL ÁRBOL EN GRANDE: una capa a pantalla completa, con el árbol a todo lo
## ancho y la ficha debajo. `al_cerrar` repinta lo que haya detrás.
static func abrir_en_grande(padre: Control, e: Entrenamiento, al_cerrar: Callable) -> Control:
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(capa)
	var velo := ColorRect.new()
	velo.color = Tema.FONDO
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(velo)
	var marco := MarginContainer.new()
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		marco.add_theme_constant_override("margin_" + lado, 36)
	capa.add_child(marco)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", Tema.ESPACIO + 4)
	marco.add_child(vb)
	var cab := HBoxContainer.new()
	vb.add_child(cab)
	var tit := Tema.etiqueta(Tema.TAM_TITULO + 6, Tema.ORO, "🎓 TUS HABILIDADES DE ENTRENADOR")
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(tit)
	var pts := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.ORO if e.dt_puntos > 0 else Tema.SUAVE, "")
	cab.add_child(pts)
	var cerrar := Button.new()
	cerrar.text = "✕ Cerrar"
	cerrar.custom_minimum_size = Vector2(120, 40)
	cab.add_child(cerrar)
	var arbol := ArbolHabilidades.crear(e)
	arbol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(arbol)
	vb.add_child(arbol.ficha())
	var poner_puntos := func() -> void:
		pts.text = "%d punto%s por gastar   " % [e.dt_puntos, "" if e.dt_puntos == 1 else "s"]
	poner_puntos.call()
	arbol.aprendida.connect(func(_k: String) -> void:
		poner_puntos.call()
		Animar.pulso(pts, 1.2))
	cerrar.pressed.connect(func() -> void:
		capa.queue_free()
		al_cerrar.call())
	Animar.aparecer(marco)
	return capa

class_name Sorteo
extends Control
## LA CINEMÁTICA DEL SORTEO: el bombo, las bolas y el cuadro final.
##
## El usuario la pidió con dos referencias muy concretas: la foto del bombo de
## la UEFA con la mano sacando una bola y el cartel de "QUARTER-FINALS", y el
## cuadro de cruces con los escudos y la copa en medio. Va en fase de grupos y
## **en cada eliminatoria**, no solo al principio.
##
## POR QUÉ ES UNA PANTALLA Y NO UN AVISO. Sortear es el único momento del año en
## que el juego decide algo grande por ti y no puedes hacer nada. Un cartelito
## en la esquina lo convertiría en trámite; ocupando la pantalla entera durante
## un minuto, se siente lo que es: el día que te toca el rival.
##
## Y SIEMPRE SE PUEDE SALTAR. Una cinemática que no se puede saltar es una
## cinemática que se odia a la tercera temporada. `ESC` o el botón, en cualquier
## momento: se salta al cuadro final, que es lo que de verdad hay que leer.

signal terminado

const COL_TEXTO := Color("e9eeea")
const COL_SUAVE := Color("8ea595")

## El color de cada competición, que es lo que hace que un sorteo de Libertadores
## no se vea igual que uno de Champions. `fondo` pinta la sala, `acento` los
## rótulos y las líneas del cuadro.
const COLORES := {
	"ucl": {"fondo": "#1b1464", "acento": "#4fc3f7", "nombre": "COPA CONTINENTAL"},
	"uel": {"fondo": "#2b1a08", "acento": "#ff8f00", "nombre": "COPA CONTINENTAL"},
	"lib": {"fondo": "#0d2818", "acento": "#f5c518", "nombre": "COPA CONTINENTAL"},
	"sud": {"fondo": "#1a1006", "acento": "#ff7043", "nombre": "COPA CONTINENTAL"},
	"copa": {"fondo": "#14202b", "acento": "#4caf6d", "nombre": "COPA NACIONAL"},
}

## Cuánto dura cada bola en salir. Doce bolas a 1,4 s son unos 17 segundos de
## bombo; con los rótulos y el cuadro final, la cinemática entera ronda el minuto
## y medio. El usuario pidió "unos 2 minutos": esto se queda por debajo a
## propósito, porque el tope de lo que se aguanta sin saltar es más corto de lo
## que uno cree cuando la escribe.
const SEG_POR_BOLA := 1.4
const SEG_ROTULO := 2.2

var _clave: String = "lib"
var _titulo_ronda: String = ""
var _parejas: Array = []          ## Array de [Club, Club] -o de grupos, ver abajo
var _grupos: Array = []           ## Array de Array[Club]; si no está vacío, manda
var _mio: Club = null

var _capa: Control
var _bombo: Control
var _rotulo: Label
var _pie: Label
var _saltado := false
## El plató en 3D y su contenedor. Ver `_construir()`.
var _vista3d: SubViewportContainer
var _escena: SorteoEscena3D
var _bolas_sacadas := 0

# ---------------------------------------------------------------------------
#  ENTRADA
# ---------------------------------------------------------------------------

## Sorteo de fase de grupos. `grupos` es un Array de Array[Club].
func abrir_grupos(clave: String, grupos: Array, mio: Club) -> void:
	_clave = clave
	_grupos = grupos
	_mio = mio
	_titulo_ronda = "FASE DE GRUPOS"
	_construir()
	_correr()

## Sorteo de una eliminatoria. `parejas` es un Array de [Club, Club].
func abrir_eliminatoria(clave: String, ronda: String, parejas: Array, mio: Club) -> void:
	_clave = clave
	_parejas = parejas
	_mio = mio
	_titulo_ronda = ronda.to_upper()
	_construir()
	_correr()

## El rótulo NO se escribe aquí: sale de `CONFED`, igual que el nombre que ve el
## jugador en el resto del juego. Antes iban "CHAMPIONS LEAGUE" y "COPA
## LIBERTADORES" escritos a fuego, y se veían aunque la partida usara la base
## ficticia (ver `Datos`).
func _paleta() -> Dictionary:
	var p: Dictionary = (COLORES.get(_clave, COLORES["copa"]) as Dictionary).duplicate()
	var confed: Variant = Datos.tabla("CONFED")
	if confed is Dictionary and (confed as Dictionary).has(_clave):
		p["nombre"] = Nombres.de_tabla(String(((confed as Dictionary)[_clave] as Dictionary).get("n", p["nombre"]))).to_upper()
	return p

# ---------------------------------------------------------------------------
#  CONSTRUCCIÓN
# ---------------------------------------------------------------------------

func _construir() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var p := _paleta()
	var fondo := ColorRect.new()
	fondo.color = Color(String(p["fondo"]))
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	## EL PLATÓ EN 3D. Va dentro de un `SubViewport` con su propio mundo: si
	## compartiera el del juego, el estadio 3D y el sorteo se verían el uno al
	## otro. El resto de la cinemática -rótulos, botón de saltar, cuadro final-
	## sigue siendo interfaz 2D encima, que es donde el texto se lee nítido.
	_vista3d = SubViewportContainer.new()
	_vista3d.stretch = true
	_vista3d.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vista3d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vista3d)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	## UPDATE_ALWAYS y no el "cuando sea visible" por defecto: la física de las
	## bolas y el barrido de los focos tienen que correr aunque el contenedor
	## todavía no haya terminado de colocarse, o el primer segundo sale negro.
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	## Tamaño de arranque: sin esto el SubViewport nace de 512×512 y hasta que el
	## contenedor no le pasa el suyo se ve una franja recortada.
	vp.size = Vector2i(1600, 900)
	_vista3d.add_child(vp)
	_escena = SorteoEscena3D.new()
	vp.add_child(_escena)
	_escena.montar(Color(String(p["acento"])), Color(String(p["fondo"])))
	_escena.rotular(String(p["nombre"]), _titulo_ronda)

	## El degradado de sala por encima del 3D: hunde los bordes y deja el centro
	## limpio, para que los rótulos se lean sobre cualquier fotograma.
	var luz := TextureRect.new()
	luz.texture = _textura_luz(String(p["acento"]))
	luz.set_anchors_preset(Control.PRESET_FULL_RECT)
	luz.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	luz.stretch_mode = TextureRect.STRETCH_SCALE
	luz.modulate.a = 0.55
	luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(luz)

	_capa = Control.new()
	_capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_capa)

	## El rótulo de la ronda: es el cartel blanco de la foto de la UEFA, el que
	## cuelga del bombo y dice "QUARTER-FINALS".
	_rotulo = Label.new()
	## VACÍO al empezar. La pantalla gigante del fondo ya canta la competición y
	## la ronda; repetirlo aquí encima la tapaba y se leían las dos cosas a la
	## vez, una sobre otra. Este rótulo queda libre para el club de cada bola.
	_rotulo.text = ""
	_rotulo.add_theme_font_size_override("font_size", 34)
	_rotulo.add_theme_color_override("font_color", COL_TEXTO)
	## Sombra dura detrás del texto. Encima de una escena 3D que se mueve, un
	## rótulo sin sombra se pierde en cuanto pasa un foco por detrás: el color
	## del fondo cambia fotograma a fotograma y el contraste no se puede fijar.
	_rotulo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_rotulo.add_theme_constant_override("shadow_offset_x", 0)
	_rotulo.add_theme_constant_override("shadow_offset_y", 3)
	_rotulo.add_theme_constant_override("shadow_outline_size", 10)
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_rotulo.offset_left = -520; _rotulo.offset_right = 520; _rotulo.offset_top = 60
	_capa.add_child(_rotulo)

	_pie = Label.new()
	_pie.text = "ESC o «Saltar» para ir directo al cuadro"
	_pie.add_theme_font_size_override("font_size", 12)
	_pie.add_theme_color_override("font_color", COL_SUAVE)
	_pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pie.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_pie.offset_left = -400; _pie.offset_right = 400; _pie.offset_top = -48
	_capa.add_child(_pie)

	var saltar := Button.new()
	saltar.text = "Saltar  ▸"
	saltar.custom_minimum_size = Vector2(130, 34)
	saltar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	saltar.offset_left = -160; saltar.offset_top = 24; saltar.offset_right = -30
	saltar.pressed.connect(_saltar)
	add_child(saltar)

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_saltar()
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------------------
#  LA CINEMÁTICA
# ---------------------------------------------------------------------------

func _correr() -> void:
	## El bombo ya no se pinta en 2D: lo es la escena 3D de `_construir()`.
	await _esperar(SEG_ROTULO)
	if _saltado:
		return
	## Las bolas salen de una en una. Lo que se saca es el ORDEN del sorteo, no
	## el resultado: el resultado ya lo decidió el motor: esto solo lo cuenta.
	var tandas := _tandas()
	for t: Dictionary in tandas:
		if _saltado:
			return
		await _sacar_bola(t)
	if _saltado:
		return
	await _esperar(0.6)
	_mostrar_cuadro()

## Qué se saca del bombo, en orden. En grupos, cada club con su letra; en
## eliminatoria, cada cruce entero.
func _tandas() -> Array:
	var salida: Array = []
	if not _grupos.is_empty():
		for i in _grupos.size():
			var letra := char(65 + i)
			for c: Club in _grupos[i]:
				salida.append({"club": c, "texto": "Grupo %s" % letra})
		return salida
	for par: Array in _parejas:
		salida.append({"club": par[0], "rival": par[1], "texto": "se cruza con"})
	return salida

## Una bola: se agita el bombo, sube una en 3D, se abre y aparece el escudo.
##
## La bola, el giro y el escudo los hace la escena 3D; aquí solo queda el NOMBRE,
## que sigue siendo una etiqueta 2D porque el texto plano se lee nítido y una
## malla con texto en 3D se ve borrosa en cuanto la cámara se mueve.
func _sacar_bola(t: Dictionary) -> void:
	var c: Club = t["club"]
	## Tipo explícito: `t["rival"]` es Variant y `:=` no puede inferir el bool.
	var propio: bool = c == _mio or (t.has("rival") and t["rival"] == _mio)

	if _escena != null:
		## 1 · corte de plano y agitada del bombo.
		_escena.cortar_plano(_bolas_sacadas % 3)
		_escena.agitar()
		Sonido.toca("clic", Sonido.Bus.INTERFAZ)
		## 2 · el presentador mete la mano. La bola empieza a subir A MITAD del
		## gesto, no al final: si esperase a que el brazo termine, se vería el
		## brazo salir vacío y la bola aparecer después, y el truco se rompe.
		_escena.gesto_sacar()
		await _esperar(0.5)
		if _saltado:
			return
		await _escena.sacar_bola().finished
		if _saltado:
			return
		## 3 · se abre y la pantalla gigante del fondo canta el club.
		_escena.revelar(Escudo.textura(c, 220))
		_escena.anunciar(Escudo.textura(c, 220), c.nombre, String(t["texto"]))
		## 4 · y se cierra sobre la pantalla, que es donde está la información.
		await _esperar(0.45)
		if _saltado:
			return
		_escena.cortar_plano(3)

	var nom := Label.new()
	var texto := c.nombre
	if t.has("rival"):
		texto = "%s   vs   %s" % [c.nombre, (t["rival"] as Club).nombre]
	nom.text = "%s\n%s" % [String(t["texto"]), texto]
	nom.add_theme_font_size_override("font_size", 30)
	## Tu club sale con el color de la competición: en un sorteo lo único que de
	## verdad se busca con la vista es dónde caíste tú.
	nom.add_theme_color_override("font_color",
		Color(String(_paleta()["acento"])) if propio else COL_TEXTO)
	nom.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	nom.add_theme_constant_override("shadow_offset_y", 3)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	nom.offset_left = -560; nom.offset_right = 560
	nom.offset_top = -150; nom.offset_bottom = -60
	nom.modulate.a = 0.0
	_capa.add_child(nom)
	var tw := create_tween()
	tw.tween_property(nom, "modulate:a", 1.0, 0.3)

	if propio:
		## Solo tu club se celebra: confeti y ovación. Si cayera en cada bola
		## dejaría de significar nada.
		if _escena != null:
			_escena.celebrar()
		Sonido.toca("ovacion", Sonido.Bus.AMBIENTE)
	await _esperar(SEG_POR_BOLA)
	if is_instance_valid(nom):
		nom.queue_free()
	_bolas_sacadas += 1

func _saltar() -> void:
	if _saltado:
		return
	_saltado = true
	_mostrar_cuadro()

# ---------------------------------------------------------------------------
#  EL CUADRO FINAL
# ---------------------------------------------------------------------------

## Lo que queda en pantalla al terminar: los grupos o los cruces, con los colores
## de la competición. Es la segunda referencia que mandó el usuario -el panel
## azul de la UEFA con los "vs"- y es lo único que de verdad hay que leerse.
func _mostrar_cuadro() -> void:
	for n in _capa.get_children():
		n.queue_free()
	## El plató se apaga en cuanto sale el cuadro: el 3D ya cumplió, y dejarlo
	## corriendo detrás de una lista de escudos solo gasta gráfica y distrae de
	## lo único que hay que leer.
	if _vista3d != null:
		_vista3d.visible = false
	var p := _paleta()
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 60; raiz.offset_top = 40
	raiz.offset_right = -60; raiz.offset_bottom = -80
	raiz.add_theme_constant_override("separation", 8)
	_capa.add_child(raiz)

	var t := Label.new()
	t.text = "%s  ·  %s" % [String(p["nombre"]), _titulo_ronda]
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(String(p["acento"])))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(t)

	if not _grupos.is_empty():
		_cuadro_de_grupos(raiz)
	else:
		_cuadro_de_cruces(raiz)

	var seguir := Button.new()
	seguir.text = "Continuar"
	seguir.custom_minimum_size = Vector2(0, 38)
	seguir.pressed.connect(func() -> void: terminado.emit())
	raiz.add_child(seguir)
	Sonido.toca("trofeo")

func _cuadro_de_grupos(raiz: VBoxContainer) -> void:
	var rej := GridContainer.new()
	rej.columns = 4
	## SIN EXPAND_FILL la rejilla solo ocupaba lo mínimo de sus hijos y quedaba
	## pegada a la izquierda con dos tercios de pantalla vacíos -y ESE es el
	## motivo real de por qué los nombres salían cortados ("Sao P", "Olimp",
	## "U. Ca"): `clip_text` en cada fila hacía su trabajo, recortar lo que no
	## cabe, pero la columna nunca tuvo más ancho disponible para no tener que
	## recortar. Repartiendo el ancho real de la pantalla entre las 4 columnas
	## el nombre completo entra casi siempre.
	rej.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rej.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rej.add_theme_constant_override("h_separation", 22)
	rej.add_theme_constant_override("v_separation", 16)
	raiz.add_child(rej)
	for i in _grupos.size():
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		rej.add_child(col)
		var et := Label.new()
		et.text = "GRUPO %s" % char(65 + i)
		et.add_theme_font_size_override("font_size", 14)
		et.add_theme_color_override("font_color", Color(String(_paleta()["acento"])))
		col.add_child(et)
		for c: Club in _grupos[i]:
			col.add_child(_fila_club(c))

## Los cruces, con la copa en medio: mitad de las llaves a la izquierda y mitad a
## la derecha, como en el cuadro que mandó el usuario.
func _cuadro_de_cruces(raiz: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_theme_constant_override("separation", 24)
	raiz.add_child(fila)
	var izq := VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izq.size_flags_vertical = Control.SIZE_EXPAND_FILL
	izq.alignment = BoxContainer.ALIGNMENT_CENTER
	izq.add_theme_constant_override("separation", 14)
	fila.add_child(izq)
	var copa := TextureRect.new()
	copa.texture = _textura_copa(String(_paleta()["acento"]))
	copa.custom_minimum_size = Vector2(190, 260)
	copa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	copa.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	copa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(copa)
	var der := VBoxContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.size_flags_vertical = Control.SIZE_EXPAND_FILL
	der.alignment = BoxContainer.ALIGNMENT_CENTER
	der.add_theme_constant_override("separation", 14)
	fila.add_child(der)
	var mitad := int(ceil(float(_parejas.size()) / 2.0))
	for i in _parejas.size():
		var par: Array = _parejas[i]
		(izq if i < mitad else der).add_child(_fila_cruce(par[0], par[1]))

func _fila_cruce(a: Club, b: Club) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var propio := a == _mio or b == _mio
	h.add_child(_escudo(a, 34))
	var na := Label.new()
	na.text = a.nombre
	na.add_theme_font_size_override("font_size", 15)
	na.add_theme_color_override("font_color", Color(String(_paleta()["acento"])) if propio else COL_TEXTO)
	na.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	na.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	na.clip_text = true
	h.add_child(na)
	var vs := Label.new()
	vs.text = "vs"
	vs.add_theme_font_size_override("font_size", 13)
	vs.add_theme_color_override("font_color", COL_SUAVE)
	vs.custom_minimum_size = Vector2(34, 0)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(vs)
	var nb := Label.new()
	nb.text = b.nombre
	nb.add_theme_font_size_override("font_size", 15)
	nb.add_theme_color_override("font_color", Color(String(_paleta()["acento"])) if propio else COL_TEXTO)
	nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nb.clip_text = true
	h.add_child(nb)
	h.add_child(_escudo(b, 34))
	return h

func _fila_club(c: Club) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	h.add_child(_escudo(c, 24))
	var n := Label.new()
	n.text = c.nombre
	n.add_theme_font_size_override("font_size", 13)
	n.add_theme_color_override("font_color",
		Color(String(_paleta()["acento"])) if c == _mio else COL_TEXTO)
	n.clip_text = true
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	return h

func _escudo(c: Club, tam: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Escudo.textura(c, tam)
	r.custom_minimum_size = Vector2(tam, tam)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

# ---------------------------------------------------------------------------
#  DIBUJO
# ---------------------------------------------------------------------------

## El bombo: la pecera de metacrilato con las bolas dentro. Va quieto en el
## centro-abajo, y las bolas salen de él hacia arriba.
func _pintar_bombo() -> void:
	_bombo = TextureRect.new()
	var t := TextureRect.new()
	t.texture = _textura_bombo()
	t.custom_minimum_size = Vector2(420, 340)
	t.set_anchors_preset(Control.PRESET_CENTER)
	t.offset_left = -210; t.offset_right = 210
	t.offset_top = 40; t.offset_bottom = 380
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(t)
	_bombo = t

static var _cache: Dictionary = {}

static func _svg(clave: String, texto: String, escala: float = 1.0) -> Texture2D:
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(texto, escala) != OK:
		return null
	var tx := ImageTexture.create_from_image(img)
	_cache[clave] = tx
	return tx

## Una bola de sorteo: blanca, con los pentágonos oscuros del balón clásico.
static func _textura_bola() -> Texture2D:
	var c := '<svg width="150" height="150" viewBox="0 0 150 150" xmlns="http://www.w3.org/2000/svg">'
	c += '<defs><radialGradient id="b" cx="0.36" cy="0.3" r="0.75">'
	c += '<stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#c3c8cc"/></radialGradient></defs>'
	c += '<circle cx="75" cy="75" r="72" fill="url(#b)"/>'
	## Las estrellas negras del balón de la Champions, que es lo que se ve en la
	## foto del bombo que mandó el usuario.
	for i in 6:
		var ang := float(i) * TAU / 6.0
		var x := 75.0 + cos(ang) * 46.0
		var y := 75.0 + sin(ang) * 46.0
		c += '<circle cx="%.1f" cy="%.1f" r="13" fill="#12161a" opacity=".82"/>' % [x, y]
	c += '<circle cx="75" cy="75" r="15" fill="#12161a" opacity=".82"/>'
	c += '<circle cx="75" cy="75" r="72" fill="none" stroke="#8d949a" stroke-width="2"/>'
	c += '</svg>'
	return _svg("bola", c)

## El bombo de metacrilato con las bolas dentro y la peana.
static func _textura_bombo() -> Texture2D:
	var c := '<svg width="420" height="340" viewBox="0 0 420 340" xmlns="http://www.w3.org/2000/svg">'
	c += '<defs><linearGradient id="cr" x1="0" y1="0" x2="0" y2="1">'
	c += '<stop offset="0" stop-color="#ffffff" stop-opacity=".22"/>'
	c += '<stop offset="1" stop-color="#ffffff" stop-opacity=".07"/></linearGradient></defs>'
	## Las bolas amontonadas en el fondo del cuenco.
	var pos := [[150, 200], [206, 214], [262, 200], [124, 168], [180, 176], [236, 176],
		[292, 168], [152, 144], [210, 150], [268, 144]]
	for p: Array in pos:
		c += '<circle cx="%d" cy="%d" r="27" fill="#eef1f3"/>' % [int(p[0]), int(p[1])]
		c += '<circle cx="%d" cy="%d" r="8" fill="#12161a" opacity=".75"/>' % [int(p[0]) - 8, int(p[1]) - 6]
		c += '<circle cx="%d" cy="%d" r="6" fill="#12161a" opacity=".6"/>' % [int(p[0]) + 12, int(p[1]) + 8]
	## El cuenco por delante, translúcido: es lo que hace que se lea "bombo" y
	## no "montón de pelotas".
	c += '<path d="M60 96 A150 150 0 0 0 360 96 Z" fill="url(#cr)" stroke="#dfe6ea" stroke-width="4"/>'
	c += '<ellipse cx="210" cy="96" rx="150" ry="26" fill="none" stroke="#dfe6ea" stroke-width="5"/>'
	## Tallo y peana.
	c += '<rect x="196" y="238" width="28" height="46" fill="#cdd6db" opacity=".8"/>'
	c += '<ellipse cx="210" cy="292" rx="86" ry="18" fill="#cdd6db" opacity=".75"/>'
	c += '</svg>'
	return _svg("bombo", c)

## El foco de sala: un halo del color de la competición sobre el fondo.
static func _textura_luz(acento: String) -> Texture2D:
	var c := '<svg width="1600" height="900" viewBox="0 0 1600 900" xmlns="http://www.w3.org/2000/svg">'
	c += '<defs><radialGradient id="l" cx="0.5" cy="0.42" r="0.62">'
	c += '<stop offset="0" stop-color="%s" stop-opacity=".26"/>' % acento
	c += '<stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>' % acento
	c += '<radialGradient id="v" cx="0.5" cy="0.45" r="0.75">'
	c += '<stop offset="0.4" stop-color="#000000" stop-opacity="0"/>'
	c += '<stop offset="1" stop-color="#000000" stop-opacity=".7"/></radialGradient></defs>'
	c += '<rect width="1600" height="900" fill="url(#l)"/>'
	c += '<rect width="1600" height="900" fill="url(#v)"/>'
	c += '</svg>'
	return _svg("luz_" + acento, c)

## La copa del centro del cuadro final.
static func _textura_copa(acento: String) -> Texture2D:
	var c := '<svg width="190" height="260" viewBox="0 0 190 260" xmlns="http://www.w3.org/2000/svg">'
	c += '<defs><linearGradient id="p" x1="0" y1="0" x2="1" y2="1">'
	c += '<stop offset="0" stop-color="#ffffff"/><stop offset="0.5" stop-color="%s"/>' % acento
	c += '<stop offset="1" stop-color="#6b7a85"/></linearGradient></defs>'
	c += '<path d="M56 24 L134 24 L126 128 Q95 158 64 128 Z" fill="url(#p)"/>'
	c += '<path d="M56 34 Q20 34 20 68 Q20 96 58 102" fill="none" stroke="url(#p)" stroke-width="11"/>'
	c += '<path d="M134 34 Q170 34 170 68 Q170 96 132 102" fill="none" stroke="url(#p)" stroke-width="11"/>'
	c += '<rect x="83" y="150" width="24" height="42" fill="url(#p)"/>'
	c += '<rect x="56" y="192" width="78" height="18" rx="4" fill="url(#p)"/>'
	c += '<rect x="42" y="210" width="106" height="26" rx="4" fill="#2a3138"/>'
	c += '</svg>'
	return _svg("copa_" + acento, c)

## Espera que se puede cortar: si alguien pulsa "Saltar" a mitad, la cinemática
## no se queda esperando su turno antes de reaccionar.
func _esperar(seg: float) -> void:
	var t := 0.0
	while t < seg and not _saltado:
		await get_tree().process_frame
		t += get_process_delta_time()

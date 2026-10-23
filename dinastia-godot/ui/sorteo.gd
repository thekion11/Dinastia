class_name Sorteo
extends "res://ui/sorteo_p1.gd"
## (Parte 2 de 2 de `sorteo.gd`.)

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

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_saltar()
		get_viewport().set_input_as_handled()

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

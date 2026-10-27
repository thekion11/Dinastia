extends "res://ui/principal_p12.gd"
## [Capa 13/17 de `principal.gd`] _nueva_temporada, _al_elegir_calendario, _buscar_global, _textura_brillo_panel, _panel … (+4); los hubs están en `Hubs`

## Puentes (fase 6, paso 7): viven en `AccionesTemporada`.
func _nueva_temporada() -> void: _acciones_temporada._nueva_temporada()
func _al_elegir_calendario(id: int) -> void: _acciones_temporada._al_elegir_calendario(id)
func _buscar_global(texto: String) -> void: _acciones_temporada._buscar_global(texto)
func _responder_oferta_mercado(indice: int, aceptar: bool) -> void: _acciones_temporada._responder_oferta_mercado(indice, aceptar)



static func _textura_brillo_panel() -> Texture2D:
	if _brillo_panel != null:
		return _brillo_panel
	## OJO: `Gradient.set_color(i, ...)` indexa por PUNTO, no por offset -y
	## `add_point()` desplaza los índices de los puntos que venían después-.
	## `set_color(1, ...)` tras un `add_point()` de en medio no toca el punto
	## final: se queda en su blanco opaco de fábrica, y el "brillo" salía
	## opaco de arriba abajo en vez de apagarse a los 2/5. Se fijan las tres
	## paradas de una vez, sin el índice cambiante de por medio.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_LINEAR
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	t.width = 4
	t.height = 128
	_brillo_panel = t
	return t

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var e := StyleBoxFlat.new()
	## La paleta y la forma elegidas en Ajustes. Se leen aqui, en el unico sitio
	## por el que pasan todas las tarjetas del juego, para que cambiarlas repinte
	## la interfaz entera sin tocar ni una pantalla.
	e.bg_color = _pal_panel()
	e.border_color = _ui_ajustes._pal_borde()
	var forma: Array = FORMAS_TARJETA.get(_forma_tarjeta, ["", 8, 1])
	e.set_border_width_all(int(forma[2]))
	e.set_corner_radius_all(int(forma[1]))
	p.add_theme_stylebox_override("panel", e)
	## Marcada como tarjeta del juego. Media interfaz -las columnas, la cabecera,
	## la ficha- se construye UNA vez y luego solo se le cambia el contenido, asi
	## que cambiar de paleta no la tocaba: se queda esta marca para poder ir a
	## buscarlas y repintarlas sin reconstruir la pantalla entera.
	p.set_meta("tarjeta", true)
	## El adorno del borde -escuadras, filete, cinta-. Va aqui y no en el
	## StyleBox porque un StyleBox solo sabe pintar un borde entero y uniforme.
	if _marca_tarjeta != "ninguno":
		var mk := MarcaPanel.new()
		mk.poner(_marca_tarjeta, COL_ACENTO)
		p.add_child(mk)
	if not _brillo_tarjetas:
		return p
	var brillo := TextureRect.new()
	brillo.texture = _textura_brillo_panel()
	brillo.set_anchors_preset(Control.PRESET_FULL_RECT)
	brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## SIN esto, TextureRect pide como mínimo el tamaño NATIVO de la textura
	## (128px de alto) y estira el panel entero para dárselo -el brillo
	## crecía la tarjeta en vez de solo pintarla-.
	brillo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brillo.stretch_mode = TextureRect.STRETCH_SCALE
	p.add_child(brillo)
	return p

func _con_scroll(padre: VBoxContainer) -> VBoxContainer:
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	## AUTO y no DISABLED (etapa 1, 2.ª pasada): desactivado, una fila más ancha
	## que la columna AGRANDABA la columna entera y sacaba la ficha del jugador
	## de la pantalla (Editor, Libres). Ahora lo que no cabe se desplaza dentro.
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	padre.add_child(s)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 2)
	s.add_child(lista)
	return lista

func _columna(padre: HBoxContainer, titulo: String, ratio: float) -> VBoxContainer:
	var caja := _panel()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.size_flags_stretch_ratio = ratio
	padre.add_child(caja)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12; v.offset_top = 10; v.offset_right = -12; v.offset_bottom = -10
	caja.add_child(v)
	var t := _texto(11, COL_SUAVE); t.text = titulo
	t.clip_text = true
	v.add_child(t)
	## Se deja a mano el último título creado para las columnas cuyo encabezado
	## cambia solo -la de la izquierda dice "PRIMERA DIVISION" o "COPA
	## LIBERTADORES · CUARTOS" según lo que se juegue el domingo-.
	_ultimo_titulo_columna = t
	## `v` es la caja entera de la columna, por debajo del scroll: quien quiera
	## poner algo FIJO al pie -un botón que no se vaya con el desplazamiento-
	## lo cuelga de aquí.
	_ultima_caja_columna = v
	return _con_scroll(v)

## La ficha completa de la competición, encima de todo. Sale de `principal.gd`
## para no engordar más este archivo, que ya pasa de las cinco mil líneas.
func _abrir_competicion() -> void:
	var v := Competicion.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(v)
	v.abrir(mundo, _liga_de(mundo.mi_club()))
	v.cerrado.connect(func() -> void:
		v.queue_free()
		_refrescar())

func _hoja(tabs: TabContainer, titulo: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = titulo
	tabs.add_child(v)
	return _con_scroll(v)


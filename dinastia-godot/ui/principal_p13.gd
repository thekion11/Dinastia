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

## Puentes (fase 6, paso 7): viven en `ui/principal/tema_menu.gd`.
func _panel() -> PanelContainer: return _tema_menu._panel()
func _con_scroll(padre: VBoxContainer) -> VBoxContainer: return _tema_menu._con_scroll(padre)
func _columna(padre: HBoxContainer, titulo: String, ratio: float) -> VBoxContainer: return _tema_menu._columna(padre, titulo, ratio)




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


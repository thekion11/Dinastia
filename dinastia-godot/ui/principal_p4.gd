extends "res://ui/principal_p3.gd"
## [Capa 4/17 de `principal.gd`] _fuente_de, _caja, _pal_fondo, _aplicar_tema, _tinta, _escudo … (+9)

## Puente: la fuente de cada tipografía la resuelve `PantallaAjustes.fuente_de`.
func _fuente_de(clave: String) -> Font:
	return _ui_ajustes.fuente_de(clave)

## Puentes (fase 6, paso 7): viven en `ui/principal/piezas_ui.gd`.
func _caja(fondo: Color, borde: Color, radio: int, grosor: int) -> StyleBoxFlat: return _piezas._caja(fondo, borde, radio, grosor)
func _boton(texto: String, accion: Callable, padre: Node = null) -> Button: return _piezas._boton(texto, accion, padre)


## Los cuatro colores del lienzo. Se leen a través de estas funciones y no de la
## constante para que cambiar de paleta repinte todo de una vez.
func _pal_fondo() -> Color: return _ui_ajustes._color_pal(1, COL_FONDO)

## Puentes (fase 6, paso 7): viven en `TemaMenu`.
func _aplicar_tema() -> void: _tema_menu._aplicar_tema()
func _escudo(c: Club, alto: int = 22) -> Control: return _tema_menu._escudo(c, alto)
func _fundido_entrada() -> void: _tema_menu._fundido_entrada()
func _goleadores_de(clubes: Array) -> Array: return _tema_menu._goleadores_de(clubes)
func _datos_pantalla_estadio(local: Club, comp: String = "liga") -> Dictionary: return _tema_menu._datos_pantalla_estadio(local, comp)


## Blanco o negro sobre el color del escudo, según su luminosidad. Es el `lumTx`
## del HTML: sin esto, las iniciales de un club amarillo se leen en blanco y
## desaparecen.
func _tinta(fondo: Color) -> Color:
	var lum := 0.299 * fondo.r + 0.587 * fondo.g + 0.114 * fondo.b
	return Color("0c130e") if lum > 0.59 else Color("ffffff")


func _color_accesible(c: Color) -> Color:
	if not _daltonico:
		return c
	if c == COL_VERDE:
		return COL_VERDE_DALT
	if c == COL_ROJO:
		return COL_ROJO_DALT
	if c == COL_ORO:
		return COL_ORO_DALT
	return c

func _perezoso(cont: Control, pintar: Callable) -> void:
	if pintar_todo or cont == null or not cont.is_inside_tree() or cont.is_visible_in_tree():
		_pendientes.erase(cont)
		pintar.call()
	else:
		_pendientes[cont] = pintar

## TODA la interfaz pasa por aqui, y por eso los dos ajustes de accesibilidad
## -el tamano del texto y la paleta para daltonismo- se aplican en este punto y
## no en las mil y pico llamadas repartidas por el archivo.
func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", maxi(8, int(round(float(tam) * _escala_texto))))
	l.add_theme_color_override("font_color", _color_accesible(_color_de_paleta(color)))
	return l


## Puentes (fase 6, paso 7): viven en `FederacionMenu`.
func _votar(opcion: String) -> void: _federacion._votar(opcion)
func _pintar_federacion(c: Club) -> void: _federacion._pintar_federacion(c)






extends "res://ui/principal_p4.gd"
## [Capa 5/17 de `principal.gd`] _ver_estadio_propio, _ver_estadio_con_carga, _dato, _aire_cifra, _miles, _pintar_estadio

## Puentes (fase 6, paso 7): viven en `ui/principal/vistas_menu.gd`.
func _ver_estadio_propio() -> void: _vistas._ver_estadio_propio()
func _ver_estadio_con_carga() -> void: await _vistas._ver_estadio_con_carga()



## `padre` por defecto es `_ficha` -de ahí salió esta función, para la ficha
## del jugador-, pero cualquier otra pestaña con la misma "etiqueta … valor"
## puede pasar la suya. Pasarlo mal es un bug silencioso: sin error, la fila
## sale dibujada en el sitio equivocado y desaparece en el próximo repintado.
## Una fila "etiqueta ......... valor".
##
## La etiqueta se RECORTA si no cabe, y esa línea no es cosmética: sin ella un
## Label pide de ancho mínimo lo que mida su texto, ese mínimo sube por el
## HBoxContainer de columnas, y la tercera columna se sale de la ventana entera
## -el contrato y el sueldo del jugador salían cortados por el borde derecho-.
## El valor NO se recorta a propósito: es el dato, y un dato a medias engaña
## más que un dato que no cabe.
func _dato(etiqueta: String, valor: String, color: Color, padre: Node = null) -> void:
	var h := HBoxContainer.new()
	var a := _texto(12, COL_SUAVE)
	a.text = etiqueta
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.clip_text = true
	a.tooltip_text = etiqueta
	h.add_child(a)
	var b := _texto(12, color)
	b.text = valor
	## Aire a la derecha (s3; petición 6 de la sesión 2): la barra de
	## desplazamiento de la columna tapaba el final de la cifra.
	b.add_theme_stylebox_override("normal", AIRE_CIFRA)
	h.add_child(b)
	## Hueco a la derecha del ancho de la barra de desplazamiento: las columnas
	## van dentro de un ScrollContainer y su barra vertical tapaba el final del
	## valor («Rol actual» en Legado, cifras de finanzas).
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(14, 0)
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(hueco)
	(padre if padre != null else _ficha).add_child(h)

static var AIRE_CIFRA := _aire_cifra()
static func _aire_cifra() -> StyleBoxEmpty:
	var sb := StyleBoxEmpty.new()
	sb.content_margin_right = 14
	return sb

func _miles(n: int) -> String:
	var s := str(n)
	var salida := ""
	var cuenta := 0
	for i in range(s.length() - 1, -1, -1):
		salida = s[i] + salida
		cuenta += 1
		if cuenta % 3 == 0 and i > 0:
			salida = "." + salida
	return salida

## Puente (fase 6, paso 6): la pestaña Estadio la pinta `PantallaClubEstadio`.
func _pintar_estadio(c: Club) -> void: _ui_club_estadio._pintar_estadio(c)

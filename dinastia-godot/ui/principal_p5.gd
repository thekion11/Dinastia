extends "res://ui/principal_p4.gd"
## [Capa 5/17 de `principal.gd`] _ver_estadio_propio, _ver_estadio_con_carga, _dato, _aire_cifra, _miles, _pintar_estadio

## Puentes (fase 6, paso 7): viven en `ui/principal/vistas_menu.gd`.
func _ver_estadio_propio(por_partes := false) -> void: await _vistas._ver_estadio_propio(por_partes)
func _ver_estadio_con_carga() -> void: await _vistas._ver_estadio_con_carga()



## Puentes (fase 6, paso 7): viven en `ui/principal/piezas_ui.gd`.
func _dato(etiqueta: String, valor: String, color: Color, padre: Node = null) -> void: _piezas._dato(etiqueta, valor, color, padre)


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
func _pintar_estadio(c: Club) -> void: _ui_club_estadio.abrir("estadio", {"club": c})

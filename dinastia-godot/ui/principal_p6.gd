extends "res://ui/principal_p5.gd"
## [Capa 6/17 de `principal.gd`] _pintar_porque_moral (y los puentes a `PantallaFinanzas`: finanzas y camarín)

## Puente (fase 6, paso 6): la pestaña Finanzas la pinta `PantallaFinanzas`.
func _pintar_finanzas(c: Club) -> void: _ui_finanzas.abrir("finanzas", {"club": c})

## Puentes (fase 6, paso 7): viven en `ui/principal/paneles_club.gd`.
func _pintar_porque_moral(c: Club) -> void: _paneles_club._pintar_porque_moral(c)


## Puente (fase 6, paso 6): la pestaña Camarín la pinta `PantallaFinanzas`.
func _pintar_camarin(c: Club) -> void: _ui_finanzas.abrir("camarin", {"club": c})

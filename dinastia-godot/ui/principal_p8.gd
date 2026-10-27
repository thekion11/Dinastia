extends "res://ui/principal_p7.gd"
## [Capa 8/17 de `principal.gd`] _jugador_de_la_semana (y el puente de `_ver_ficha` a `PantallaFicha`)

## Puente (fase 6, paso 7): la ficha del jugador la pinta `PantallaFicha`.
func _ver_ficha(j: Jugador) -> void: _ui_ficha._ver_ficha(j)

## Puentes (fase 6, paso 7): viven en `ui/principal/avance_semana.gd`.
func _jugador_de_la_semana(c: Club) -> Jugador: return _avance._jugador_de_la_semana(c)


extends "res://ui/principal_p14.gd"
## [Capa 14/17 de `principal.gd`] _construir, abrir_tutorial, tutorial_objetivo, tutorial_hecho, tutorial_accion

# --- construcción -----------------------------------------------------------

## Puentes (fase 6, paso 7): viven en `ConstruirMenu`.
func _construir() -> void: _construccion._construir()


## EL TUTORIAL vive en `ui/principal/guia_tutorial.gd` (fase 0). Estos cuatro
## puentes son el contrato con `ui/componentes/tutorial.gd`, que los llama por
## nombre (con `has_method` delante), y con Ajustes y el panel de objetivos.
func abrir_tutorial(modo: String = "") -> void:
	_guia.abrir(modo)

func tutorial_objetivo(clave: String) -> Control:
	return _guia.objetivo(clave)

func tutorial_hecho(clave: String) -> bool:
	return _guia.hecho(clave)

func tutorial_accion(clave: String) -> void:
	_guia.accion(clave)

extends "res://ui/principal_p8.gd"
## [Capa 9/17 de `principal.gd`] _origen_de, _traducir_pantalla, _refrescar, _avanzar_semana, _avanzar_dia, _pintar_dias … (+2)

## Puentes (fase 6, paso 7): viven en `TraduccionMenu`.
func _origen_de(texto: String) -> String: return _traduccion._origen_de(texto)
func _traducir_pantalla(n: Node) -> void: _traduccion._traducir_pantalla(n)



## Puentes (fase 6, paso 7): viven en `AvanceSemana`.
func _refrescar() -> void: _avance._refrescar()
func _avanzar_semana() -> void: _avance._avanzar_semana()
func _avanzar_dia() -> void: _avance._avanzar_dia()
func _avanzar_hasta_hito() -> void: _avance._avanzar_hasta_hito()
func _pintar_dias() -> void: _avance._pintar_dias()





## AL CERRAR (etapa 1, 8-10-2026): las referencias estáticas a la partida
## (el contexto del edificio del club, la Carrera de Jugador, el último mundo)
## sobrevivían al cierre y el motor avisaba de objetos sin liberar.
func _exit_tree() -> void:
	load("res://visor/edificio_club.gd").ctx = {}
	load("res://visor/edificio_club.gd").mundo_ref = null
	if ResourceLoader.has_cached("res://ui/carrera_jugador_ui.gd"):   ## (A4 memoria) solo si se llegó a cargar
		(load("res://ui/carrera_jugador_ui.gd") as GDScript).mundo = null
	Trabajadores.actual = null
	Partido.ctx_medico = null
	PedidoPartida.mundo_a_cargar = null
	PedidoPartida.mundo_pregenerado = null

## Puentes (fase 6, paso 7): viven en `ui/principal/acciones_temporada.gd`.
func _preparar_mando() -> void: _acciones_temporada._preparar_mando()


extends "res://ui/principal_p13.gd"
## [Capa 14/17 de `principal.gd`] _enviar_oferta_negociacion, _al_ajustar_rol_neg, _al_ajustar_campo_neg y los puentes a `Hubs` (carril y hubs)

## Puentes (fase 6, paso 7): viven en `ui/principal/acciones_fichaje.gd`.
func _enviar_oferta_negociacion() -> void: _acciones_fichaje._enviar_oferta_negociacion()
func _al_ajustar_rol_neg(rol: String) -> void: _acciones_fichaje._al_ajustar_rol_neg(rol)
func _al_ajustar_campo_neg(campo: String, delta: int) -> void: _acciones_fichaje._al_ajustar_campo_neg(campo, delta)




func _animar_pestana() -> void:
	var pag := _pestanas.get_current_tab_control()
	if pag == null:
		return
	## Cada hoja es VBox > ScrollContainer > VBox (la lista): se anima la lista.
	for h in pag.get_children():
		if h is ScrollContainer and h.get_child_count() > 0:
			Animar.escalonar(h.get_child(0))
			return
	Animar.escalonar(pag)

func _al_cambiar_pestana(_idx: int) -> void:
	vista_cambiada.emit()
	var titulo := _pestanas.get_tab_title(_pestanas.current_tab)
	var gid := _grupo_de_pestana(titulo)
	## "" = pestaña de hub contextual (Táctica, Mercado, Copa...). No pertenece
	## a ningún bloque maestro, así que la barra de arriba se queda donde
	## estaba en vez de saltar a un bloque que no tiene nada que ver.
	if gid != "" and gid != _grupo_actual:
		_grupo_actual = gid
		_actualizar_fila_grupos()
	_reconstruir_fila_sub()
	## El contenido de la pestaña entra escalonado (plan maestro B11).
	_animar_pestana.call_deferred()

## Puentes (fase 6, paso 7): viven en `ui/principal/piezas_ui.gd`.
func _bloque(padre: VBoxContainer, titulo: String, ratio: float) -> VBoxContainer: return _piezas._bloque(padre, titulo, ratio)


## Repinta el lienzo. Solo hace falta al cambiar de paleta: el resto se aplica
## solo al reconstruir las pantallas.
func _aplicar_aspecto() -> void:
	if _fondo_raiz != null:
		_fondo_raiz.color = _pal_fondo()
	_aplicar_tema()
	_ui_ajustes._repintar_tarjetas(self)

## Vuelve a montar la fila de bloques con el estilo actual. Hace falta porque
## `_construir_grupos()` corre UNA vez al armar la escena, y cambiar de
## estilo de menú tiene que verse sin reiniciar la partida.
func _reconstruir_grupos() -> void:
	_limpiar(_fila_grupos)
	_construir_grupos()
	_actualizar_fila_grupos()
	_reconstruir_fila_sub()
	_pintar_dias()

## Puentes (fase 6, paso 5): hubs y carril viven en `Hubs` (`ui/menu/hubs.gd`).
func _abrir_hub(clave: String) -> void: _hubs.abrir(clave)
func _indice_grupo(gid: String) -> int: return _hubs.indice_grupo(gid)
func _animar_pagina(direccion: int) -> void: _hubs.animar_pagina(direccion)
func _actualizar_fila_grupos() -> void: _hubs.actualizar_fila_grupos()
func _grupo_por_id(gid: String) -> Dictionary: return _hubs.grupo_por_id(gid)
func _seccion_activa(chip: Dictionary) -> bool: return _hubs.seccion_activa(chip)
func _ir_a_chip(chip: Dictionary) -> void: _hubs.ir_a_chip(chip)
func _reconstruir_fila_sub() -> void: _hubs.reconstruir_fila_sub()
func _chips_del_carril(titulo: String) -> Array: return _hubs.chips_del_carril(titulo)
func _elegir_grupo(gid: String) -> void: _hubs.elegir_grupo(gid)
func _construir_grupos() -> void: _hubs.construir_grupos()
func _grupo_de_pestana(titulo: String) -> String: return _hubs.grupo_de_pestana(titulo)

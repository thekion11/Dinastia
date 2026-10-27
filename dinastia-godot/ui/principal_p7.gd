extends "res://ui/principal_p6.gd"
## [Capa 7/17 de `principal.gd`] _idolo_del_club, _ir_a_pestana, _ver_ciudad_propia, _ver_ciudad_con_carga, _celda, _pintar_clubes … (+9)

## Puentes (fase 6, paso 7): viven en `VistasMenu`.
func _idolo_del_club(c: Club) -> String: return _vistas._idolo_del_club(c)
func _ver_ciudad_propia() -> void: _vistas._ver_ciudad_propia()
func _ver_ciudad_con_carga() -> void: _vistas._ver_ciudad_con_carga()
func _pintar_clubes() -> void: _vistas._pintar_clubes()
func _pendientes_de_grupo(gid: String) -> int: return _vistas._pendientes_de_grupo(gid)
func _actualizar_badges() -> void: _vistas._actualizar_badges()


func _ir_a_pestana(titulo: String) -> void:
	for i in _pestanas.get_tab_count():
		if _pestanas.get_tab_title(i) == titulo:
			_pestanas.current_tab = i
			return



## Puente (fase 6, paso 6): la pestaña Ciudad la pinta `PantallaCiudad`.
func _pintar_ciudad(c: Club) -> void: _ui_ciudad._pintar_ciudad(c)

func _celda(g: GridContainer, texto: String, color: Color, derecha: bool = false, tam: int = 12) -> Label:
	var l := _texto(tam, color)
	l.text = texto
	if derecha:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(l)
	return l





## Puentes (fase 6, paso 7): viven en `AccionesFichaje`.
func _reconvertir(j: Jugador, pe: String) -> void: _acciones_fichaje._reconvertir(j, pe)
func _listar_transferible(j: Jugador) -> void: _acciones_fichaje._listar_transferible(j)
func _rescindir(j: Jugador, total: int) -> void: _acciones_fichaje._rescindir(j, total)
func _motivo_fichaje_bloqueado(j: Jugador) -> String: return _acciones_fichaje._motivo_fichaje_bloqueado(j)
func _intentar_fichar(j: Jugador, monto: int, sueldo: int) -> void: _acciones_fichaje._intentar_fichar(j, monto, sueldo)
func _pedir_informe_medico(j: Jugador) -> void: _acciones_fichaje._pedir_informe_medico(j)








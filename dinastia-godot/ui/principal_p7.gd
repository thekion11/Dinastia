extends "res://ui/principal_p6.gd"
## [Capa 7/17 de `principal.gd`] _idolo_del_club, _ir_a_pestana, _ver_ciudad_propia, _ver_ciudad_con_carga, _celda, _pintar_clubes … (+9)

## Puentes (fase 6, paso 7): viven en `VistasMenu`.
func _idolo_del_club(c: Club) -> String: return _vistas._idolo_del_club(c)
func _ver_ciudad_propia(por_partes := false) -> void: await _vistas._ver_ciudad_propia(por_partes)
func _ver_ciudad_con_carga() -> void: await _vistas._ver_ciudad_con_carga()
func _pintar_clubes() -> void: _vistas._pintar_clubes()
func _pendientes_de_grupo(gid: String) -> int: return _vistas._pendientes_de_grupo(gid)
func _actualizar_badges() -> void: _vistas._actualizar_badges()


func _ir_a_pestana(titulo: String) -> void:
	## (3-11, rediseño del menú central) Desde el central, cualquier sección que no sea Inicio se abre en su menú del
	## panel lateral, a pantalla completa (el central ya no tiene fila de pestañas).
	if _abrir_en_lateral(titulo):
		return
	for i in _pestanas.get_tab_count():
		if _pestanas.get_tab_title(i) == titulo:
			_pestanas.current_tab = i
			return



## Puente (fase 6, paso 6): la pestaña Ciudad la pinta `PantallaCiudad`.
func _pintar_ciudad(c: Club) -> void: _ui_ciudad.abrir("ciudad", {"club": c})

## Puentes (fase 6, paso 7): viven en `ui/principal/piezas_ui.gd`.
func _celda(g: GridContainer, texto: String, color: Color, derecha: bool = false, tam: int = 12) -> Label: return _piezas._celda(g, texto, color, derecha, tam)






## Puentes (fase 6, paso 7): viven en `AccionesFichaje`.
func _reconvertir(j: Jugador, pe: String) -> void: _acciones_fichaje._reconvertir(j, pe)
func _listar_transferible(j: Jugador) -> void: _acciones_fichaje._listar_transferible(j)
func _rescindir(j: Jugador, total: int) -> void: _acciones_fichaje._rescindir(j, total)
func _motivo_fichaje_bloqueado(j: Jugador) -> String: return _acciones_fichaje._motivo_fichaje_bloqueado(j)
func _intentar_fichar(j: Jugador, monto: int, sueldo: int) -> void: _acciones_fichaje._intentar_fichar(j, monto, sueldo)
func _pedir_informe_medico(j: Jugador) -> void: _acciones_fichaje._pedir_informe_medico(j)








## La sección de una pestaña vive en su menú lateral: lo busca (si hay varios submenús con la misma pestaña, el de la
## sección elegida) y lo abre. No redirige mientras un menú lateral ya está abierto (él mismo cambia de pestaña así).
var _redirigiendo := false
const _SECC_DE_PESTANA := {"Club": "_secc_club", "Gente": "_secc_gente", "Ajustes": "_secc_ajustes",
	"Récords": "_secc_records", "Redes": "_secc_redes", "Vida": "_secc_vida"}
## (12-11, nota del dueño: «subdividir menús en más pantallas completas», como el PES 2020) Secciones de las pestañas que antes eran una sola
## página larga: pestaña -> sección elegida. Cada sección es un submenú con su tarjeta en la portada (`MenusLaterales`, campo `secc`).
## «todo» pinta la página entera como antes (capturas y herramientas viejas).
var _secc_extra := {"Finanzas": "cuentas", "Partido": "previa", "Táctica": "pizarra"}
func secc_de(titulo: String) -> String:
	if _SECC_DE_PESTANA.has(titulo):
		return String(get(_SECC_DE_PESTANA[titulo]))
	return String(_secc_extra.get(titulo, ""))

func _abrir_en_lateral(titulo: String) -> bool:
	if _redirigiendo or titulo == "Inicio" or _menu_lateral == null or not _menu_lateral.is_inside_tree():
		return false
	var secc := secc_de(titulo)
	## Con un menú ya abierto: si la sección es suya, la elige él (cambia también el título); si no, se abre el suyo.
	var abierta: PantallaMenu = _menu_lateral.pantalla_abierta if is_instance_valid(_menu_lateral.pantalla_abierta) else null
	if abierta != null and not abierta.cerrando():
		var propio := _sub_de(abierta.menu(), titulo, secc)
		if propio >= 0:
			_redirigiendo = true
			abierta.elegir(propio)
			_redirigiendo = false
			return true
	var elegido := []
	for m: Dictionary in MenusLaterales.MENUS:
		var subs: Array = m["subs"]
		for i in subs.size():
			var sub: Dictionary = subs[i]
			if String(sub.get("tab", "")) != titulo:
				continue
			if elegido.is_empty() or (secc != "" and String(sub.get("secc", "")) == secc):
				elegido = [String(m["id"]), i]
	if elegido.is_empty():
		return false
	_redirigiendo = true
	_menu_lateral.abrir_menu(String(elegido[0]), int(elegido[1]))
	_redirigiendo = false
	return true

## El índice del submenú de `menu` que abre la pestaña `titulo` (el de la sección `secc` si hay varios), o -1.
func _sub_de(menu: Dictionary, titulo: String, secc: String) -> int:
	var subs: Array = menu.get("subs", [])
	var idx := -1
	for i in subs.size():
		var sub: Dictionary = subs[i]
		if String(sub.get("tab", "")) != titulo:
			continue
		if idx < 0 or (secc != "" and String(sub.get("secc", "")) == secc):
			idx = i
	return idx

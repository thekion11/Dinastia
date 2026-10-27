extends "res://ui/principal_p16.gd"
## [Capa 16/17 de `principal.gd`] _abrir_rueda_pantalla_completa, _repintar_posturas, _responder, _pintar_museo, _marca, _ver_ciudad_explorando … (+3)

## LA RUEDA DE PRENSA, DE PANTALLA COMPLETA, vive en `ui/principal/rueda_prensa.gd`
## (fase 0, paso 6b). Principal solo la abre; estos tres son puentes.

## Puente: cuándo salió la pregunta de la rueda abierta (lo ajustan capturas).
var _rueda_desde: int:
	get:
		return (_rueda_pop as _PrincipalRuedaPrensa).desde if is_instance_valid(_rueda_pop) else 0
	set(v):
		if is_instance_valid(_rueda_pop):
			(_rueda_pop as _PrincipalRuedaPrensa).desde = v

func _abrir_rueda_pantalla_completa(e: Dictionary) -> void:
	var r := _PrincipalRuedaPrensa.new(self)
	add_child(r)
	_rueda_pop = r
	r.abrir(e)

func _repintar_posturas() -> void:
	if is_instance_valid(_rueda_pop):
		(_rueda_pop as _PrincipalRuedaPrensa).repintar_posturas()

func _responder(i: int) -> void:
	if is_instance_valid(_rueda_pop):
		(_rueda_pop as _PrincipalRuedaPrensa).responder(i)

# --- las tres pestañas nuevas ----------------------------------------------

## Puentes (fase 6, paso 7): viven en `ui/principal/vistas_menu.gd`.
func _pintar_museo(lg: Logros) -> void: _vistas._pintar_museo(lg)
func _marca(nombre: String, color_hex: String, alto: int = 28) -> Control: return _vistas._marca(nombre, color_hex, alto)
func _ver_ciudad_explorando(modo: String) -> void: _vistas._ver_ciudad_explorando(modo)




func _aplicar_vista_compacta() -> void:
	var sep := SEPARACION_COMPACTA if _vista_compacta else SEPARACION_NORMAL
	var t := theme if theme != null else Theme.new()
	for clase: String in ["BoxContainer", "VBoxContainer", "HBoxContainer"]:
		t.set_constant("separation", clase, sep)
	t.set_constant("margin_top", "MarginContainer", sep)
	t.set_constant("margin_bottom", "MarginContainer", sep)
	theme = t

func _alternar_favorito(tab: String) -> void:
	if _favoritos.has(tab):
		_favoritos.erase(tab)
	elif _favoritos.size() < FAVORITOS_MAX:
		_favoritos.append(tab)
	_refrescar()

## Salta al chip de al lado dentro del bloque actual (los gatillos de
## siempre). Ahora los chips son diccionarios {tab, secc, label}, así que la
## posición se busca comparando pestaña Y sección, no el título a secas.
func _saltar_pestana(d: int) -> void:
	var chips: Array = _grupo_por_id(_grupo_actual).get("tabs", [])
	if chips.is_empty():
		return
	var titulo := _pestanas.get_tab_title(_pestanas.current_tab)
	var i := 0
	for k in chips.size():
		var chip: Dictionary = chips[k]
		if String(chip["tab"]) == titulo and _seccion_activa(chip):
			i = k
			break
	_ir_a_chip(chips[(i + d + chips.size()) % chips.size()])

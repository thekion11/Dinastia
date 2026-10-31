class_name Principal
extends "res://ui/principal_p17.gd"
## [Capa 17/17 de `principal.gd`] _ready, _capa_modal_encima, _input, _pintar_identidad, _al_paso_nuevo, _portada_nueva

## Los hijos que ya estaban al terminar `_ready()` (el menú, el riel, el reloj…).
## Todo Control a pantalla completa que se añada DESPUÉS y pare el ratón es una
## capa modal (móvil, diseñador, diálogos): ver `_capa_modal_encima()`.
var _hijos_base: Dictionary = {}

func _ready() -> void:
	super()
	for h: Node in get_children():
		_hijos_base[h.get_instance_id()] = true

## Puentes (fase 6, paso 7): viven en `AtajosMenu`.
func _input(evento: InputEvent) -> void: _atajos._input(evento)
func _capa_modal_encima() -> bool: return _atajos._capa_modal_encima()



## Puente (fase 6, paso 6): la sección Identidad la pinta `PantallaIdentidad`.
func _pintar_identidad(c: Club) -> void: _ui_identidad.abrir("identidad", {"club": c})

func _al_paso_nuevo() -> void:
	if mundo == null or mundo.prensa == null or mundo.prensa.al_paso.is_empty():
		return
	## Si hay un periódico abierto (de esta semana o de otra que pasó de
	## corrido), la entrevista espera a que se cierre.
	for h in get_children():
		if h is PortadaPeriodico and not h.is_queued_for_deletion():
			if not h.cerrado.is_connected(_al_paso_nuevo):
				h.cerrado.connect(_al_paso_nuevo)
			return
	for h in get_children():
		if h is PieDeCampo and not h.is_queued_for_deletion():
			return
	var n := PieDeCampo.mostrar_al_paso(self, mundo.prensa)
	if n != null:
		n.cerrado.connect(_refrescar)

func _portada_nueva() -> void:
	if mundo == null or mundo.prensa == null or mundo.prensa.portadas.is_empty():
		_al_paso_nuevo()
		return
	var d: Dictionary = mundo.prensa.portadas[0]
	var nueva := bool(d.get("nueva", false))
	for x: Dictionary in mundo.prensa.portadas:
		x.erase("nueva")
	if nueva and PortadaPeriodico.auto():
		PortadaPeriodico.mostrar(self, mundo, d)
	_al_paso_nuevo()

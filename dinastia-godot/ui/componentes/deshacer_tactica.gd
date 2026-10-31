class_name DeshacerTactica
extends RefCounted
## M-300 (28-10-2026): DESHACER EN LA PIZARRA. Cada cambio de la pestaña Táctica (dibujo, perillas, interruptores, el once
## elegido) apunta antes cómo estaba; «↶ Deshacer» vuelve atrás de uno en uno, hasta `MAX` pasos. La pila es de la sesión
## (no se guarda en la partida) y de cada club por separado.

const MAX := 20
static var _pilas: Dictionary = {}   ## club.id → Array de fotos {tactica: Tactica, once: Array[String]}

## Antes de cambiar algo: guarda la foto de ahora.
static func apuntar(c: Club) -> void:
	var pila: Array = _pilas.get(c.id, [])
	pila.append({"tactica": c.tactica.duplicar(), "once": c.once_elegido.duplicate()})
	while pila.size() > MAX:
		pila.pop_front()
	_pilas[c.id] = pila

static func hay(c: Club) -> bool:
	return not (_pilas.get(c.id, []) as Array).is_empty()

static func pasos(c: Club) -> int:
	return (_pilas.get(c.id, []) as Array).size()

## Vuelve a la última foto. Copia campo a campo sobre la MISMA `Tactica` (otros la tienen agarrada: presets, partido).
static func deshacer(c: Club) -> bool:
	var pila: Array = _pilas.get(c.id, [])
	if pila.is_empty():
		return false
	var foto: Dictionary = pila.pop_back()
	var t: Tactica = foto["tactica"]
	for prop: Dictionary in t.get_property_list():
		if int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var v: Variant = t.get(String(prop["name"]))
			c.tactica.set(String(prop["name"]), v.duplicate(true) if v is Dictionary or v is Array else v)
	c.once_elegido.assign(foto["once"])
	return true

static func olvidar() -> void:
	_pilas.clear()

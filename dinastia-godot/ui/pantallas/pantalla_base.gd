class_name PantallaBase
extends RefCounted
## EL CONTRATO DE LAS PANTALLAS DEL MENÚ CENTRAL (fase 0, plan §7.2; 31-10-2026): «un contrato por pantalla:
## `abrir(contexto)`, `cerrar()` y una señal». Cada pantalla de `ui/pantallas/` declara sus SECCIONES (las
## listas que pinta: «plantel», «tactica», «finanzas»…) en `secciones()` y se abre SIEMPRE por `abrir`;
## `Principal` ya no llama a sus `_pintar_*` sueltos. `contexto`: {"club": Club} (si falta, tu club).
##
## Lo que queda (honesto): por dentro las pantallas siguen pintando en los contenedores de `Principal`
## (`p._lista_*`) y leyendo `p.mundo`; separarlas del todo (cada una con su nodo y su estado) es el paso
## siguiente, y con este contrato ya se puede hacer pantalla a pantalla sin tocar a quien las abre.

## La pantalla dejó de verse (la emite `cerrar`).
signal cerrada

var p: Principal

func _init(principal: Principal = null) -> void:
	p = principal

## nombre de sección → Callable que la pinta (con el club como argumento si lo pide). Cada pantalla la da.
func secciones() -> Dictionary:
	return {}

## Pinta la sección pedida. Devuelve false si la pantalla no la tiene.
func abrir(seccion: String, contexto: Dictionary = {}) -> bool:
	var f: Variant = secciones().get(seccion, null)
	if not (f is Callable) or not (f as Callable).is_valid():
		push_warning("%s: no hay sección «%s»" % [get_script().get_global_name(), seccion])
		return false
	var club: Club = contexto.get("club", p.mundo.mi_club() if p != null and p.mundo != null else null)
	if (f as Callable).get_argument_count() > 0:
		(f as Callable).call(club)
	else:
		(f as Callable).call()
	return true

## Cierra la pantalla (las que guardan algo al salir lo sobrescriben y llaman a `super`).
func cerrar() -> void:
	cerrada.emit()

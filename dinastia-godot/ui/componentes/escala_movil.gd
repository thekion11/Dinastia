class_name EscalaMovil
extends RefCounted
## LA INTERFAZ EN EL MÓVIL (2-11-2026, queja del dueño: «el tamaño del texto y de las pantallas es muy pequeño, cuesta leer y rellenar los cuadros»).
## La interfaz está pensada para 1280 × 720: en un móvil (2000 × 900 a ~400 ppp) un texto de 14 px mide ~1 mm. La primera vez, en Android, iOS o la web en una
## pantalla táctil, se aplica un zoom de interfaz de `ZOOM_MOVIL` (el de Ajustes → «Tamaño de la interfaz», que se puede cambiar o volver a 100 %); si el
## jugador ya eligió uno, se respeta. Los cuadros de texto (`campo_alto`) pasan a medir al menos `ALTO_CAMPO_MOVIL` px para poder tocarlos y escribir.
const ZOOM_MOVIL := 1.5
const ALTO_CAMPO_MOVIL := 56

static func es_movil() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())

## El zoom que toca: el guardado en las preferencias, o el del móvil si no hay y es un móvil, o 1.
static func zoom(guardado: Variant) -> float:
	if guardado != null:
		return clampf(float(guardado), 0.7, 1.8)
	return ZOOM_MOVIL if es_movil() else 1.0

## Lo llama la primera escena: pone el zoom de interfaz de esta máquina (sin tocar nada guardado).
static func aplicar(arbol: SceneTree, prefs_ruta: String) -> void:
	var cf := ConfigFile.new()
	var guardado: Variant = null
	if cf.load(prefs_ruta) == OK and cf.has_section_key("pantalla", "zoom"):
		guardado = cf.get_value("pantalla", "zoom")
	arbol.root.content_scale_factor = zoom(guardado)

## Alto mínimo de un cuadro de texto: el normal en escritorio, mayor en el móvil.
static func campo_alto(normal: int) -> int:
	return maxi(normal, ALTO_CAMPO_MOVIL) if es_movil() else normal

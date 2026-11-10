class_name ModoRendimiento
extends RefCounted
## MODO RENDIMIENTO (10-11-2026, orden del líder; informe `rendimiento_movil_2026-11-10.md`, propuestas E1 y E2): un interruptor de Ajustes, APAGADO por defecto en todas las plataformas, que de MEDIA hacia abajo quita
## el resplandor (glow: −7…−12 % de fotograma relativo), la sombra del sol (−17…−21 %) y simplifica el shader del césped (E4). Cambia el aspecto, por eso lo decide el jugador; ALTA y ULTRA no se tocan. Lo guarda `Calidad` en grafica.cfg (`modo_rendimiento`).

## ¿Este nivel pierde la sombra del sol con el modo encendido?
static func sin_sol(nivel: int) -> bool:
	return Calidad.modo_rendimiento and nivel <= Calidad.MEDIO

## (E4) ¿El campo usa el shader barato (`cesped_barato.gdshader`: sin brizna fina, mechones ni relieve)?
static func cesped_barato(nivel: int) -> bool:
	return Calidad.modo_rendimiento and nivel <= Calidad.MEDIO

## ¿Lleva resplandor? (sin el modo: de BAJA hacia arriba, como siempre; con el modo, solo por encima de MEDIA).
static func glow(nivel: int) -> bool:
	return nivel > Calidad.MINIMO and not (Calidad.modo_rendimiento and nivel <= Calidad.MEDIO)

## El interruptor de Ajustes (se ve en todas las calidades).
static func crear(p: Object) -> void:
	var cb := CheckButton.new()
	cb.text = Idiomas.t("Modo rendimiento (sin brillo ni sombra del sol)")
	cb.tooltip_text = Idiomas.t("Quita el resplandor y la sombra del sol y simplifica el césped en calidad Media y menores para ganar fluidez. Cambia el aspecto; se aplica al abrir el estadio.")
	cb.button_pressed = Calidad.modo_rendimiento
	cb.add_theme_font_size_override("font_size", 11)
	cb.toggled.connect(func(si: bool) -> void:
		Calidad.modo_rendimiento = si
		Calidad.guardar())
	p._lista_ajustes.add_child(cb)

## (10-11, pregunta 7 del dueño) El interruptor del menú: en MEDIA el menú también repinta solo cuando algo cambia y deja los fondos quietos (como ya hacen BAJA y MEDIA BAJA). Apagado por defecto.
static func crear_menu(p: Object) -> void:
	var cb := CheckButton.new()
	cb.text = Idiomas.t("Ahorro en los menús también en Media")
	cb.tooltip_text = Idiomas.t("Los menús solo se repintan cuando algo cambia y los fondos animados quedan quietos. Cambia el aspecto del menú; se aplica al volver al menú.")
	cb.button_pressed = Calidad.ahorro_menu_media
	cb.add_theme_font_size_override("font_size", 11)
	cb.toggled.connect(func(si: bool) -> void:
		Calidad.ahorro_menu_media = si
		Calidad.guardar())
	p._lista_ajustes.add_child(cb)

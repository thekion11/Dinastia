class_name HabitantesCasa
extends RefCounted
## LOS HABITANTES DE UNA VIVIENDA SEGÚN LA HORA (M-187, 28-10-2026): la familia no está siempre en el salón. Por la noche duerme (nadie a la vista), por la mañana
## y a mediodía se cocina y se desayuna/come, por la tarde alguien anda por casa y de las 18:00 a las 23:30 se ve la tele en el sofá. Solo datos y horas; el interior
## (`InteriorInstalacion._vivienda`) pone o quita a la gente con esto. La hora es la del reloj de la ciudad (`PersonalEstadio.hora`; 12 h si no hay).

## La hora del reloj de la ciudad (0-24).
static func hora_actual() -> float:
	return load("res://visor/personal_estadio.gd").hora if load("res://visor/personal_estadio.gd").hora >= 0.0 else 12.0

static func _en(h: float, desde: float, hasta: float) -> bool:
	return h >= desde and h < hasta

## Qué se ve en casa a la hora `h`: {cocina, mesa (0-1: probabilidad de silla ocupada), sofa, pasea, estado (texto del cartel)}.
static func plan(h: float) -> Dictionary:
	var noche := h >= 23.5 or h < 6.5
	if noche:
		return {"cocina": false, "mesa": 0.0, "sofa": false, "pasea": false, "estado": "Duermen"}
	var comida := _en(h, 7.0, 9.0) or _en(h, 13.0, 15.0) or _en(h, 19.5, 21.5)
	var sofa := _en(h, 18.0, 23.5)
	var estado := "Cocinando" if comida else ("Viendo la tele" if sofa else ("Tareas de casa" if _en(h, 9.0, 18.0) else "Despertando"))
	return {"cocina": comida or _en(h, 6.5, 7.0), "mesa": 0.85 if comida else 0.0, "sofa": sofa, "pasea": _en(h, 9.0, 18.0), "estado": estado}

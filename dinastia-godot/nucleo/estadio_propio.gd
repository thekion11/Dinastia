class_name EstadioPropio
extends "res://nucleo/estadio_propio_p2.gd"
## (Parte 3 de 3 de `estadio_propio.gd`.)

func desde_dic(d: Dictionary) -> void:
	nombre = String(d.get("nombre", ""))
	## Guardados viejos: se marca como ya tomado para no pisar lo que hubiera.
	real_de = String(d.get("real_de", "(guardado)"))
	var guardado: Dictionary = d.get("ajustes", {})
	## Se rellenan las claves que falten con las de fábrica, exactamente como
	## hace `initEst()` en el HTML. Un guardado de una versión anterior no tiene
	## las opciones nuevas, y sin este paso el visor recibiría un diccionario con
	## agujeros y dibujaría medio estadio con los valores por defecto sin avisar.
	_sembrar()
	for k: String in guardado:
		if ajustes.has(k):
			ajustes[k] = guardado[k]
	obra = (d.get("obra", {}) as Dictionary).duplicate(true)
	if not obra.is_empty():
		## Lo construido también con todas las claves de hoy.
		var antes: Dictionary = ajustes.duplicate(true)
		for k2: String in (obra.get("antes", {}) as Dictionary):
			if antes.has(k2):
				antes[k2] = obra["antes"][k2]
		obra["antes"] = antes

## Cuánto multiplica tu superficie la probabilidad de lesión en casa (B6.5).
func factor_lesion() -> float:
	return float(LESION_POR_SUPERFICIE.get(String(hecho().get("superficie", "natural")), 1.0))

## Qué parte del desgaste del césped llega al juego (B6.5).
func factor_desgaste_cesped() -> float:
	return float(DESGASTE_POR_SUPERFICIE.get(String(hecho().get("superficie", "natural")), 1.0))

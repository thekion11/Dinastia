class_name Expendedora
extends RefCounted
## LA MÁQUINA EXPENDEDORA (27-10-2026, semana 6 del plan): sin pantalla, E ante la máquina compra lo que toca según cómo está el DT y lo cobra `CarteraDT.cobrar`.
## Cansado (energía < 60): bebida energética (+15 de energía). Con hambre (≥ 40): bocadillo envasado (−10 de hambre). Si no, una botella de agua.
const BEBIDA := {"id": "bebida", "nombre": "Bebida energética", "precio": 3, "energia": 15, "hambre": 0}
const SNACK := {"id": "snack", "nombre": "Bocadillo envasado", "precio": 2, "energia": 3, "hambre": 10}
const AGUA := {"id": "agua", "nombre": "Botella de agua", "precio": 1, "energia": 1, "hambre": 0}

static func elegir(energia: int, hambre: int) -> Dictionary:
	var nat := Nativo.de("nuc_elegir_expendedora")
	if nat != null:
		return nat.nuc_elegir_expendedora(energia, hambre)
	return elegir_gd(energia, hambre)

## Gemela GDScript de `nuc_elegir_expendedora` (extensión C++, orden 63): respaldo sin binario y comparación en `pruebas/probar_nativo_puras.gd`.
static func elegir_gd(energia: int, hambre: int) -> Dictionary:
	if energia < 60:
		return BEBIDA
	if hambre >= 40:
		return SNACK
	return AGUA

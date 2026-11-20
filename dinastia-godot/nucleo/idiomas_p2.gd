extends "res://nucleo/idiomas_p1.gd"
## [Capa intermedia de `idiomas.gd`, entre `idiomas_p1.gd` y `idiomas.gd`] _es_letra y su gemela _es_letra_gd (20-11, orden 63: C++).
## (Sin `class_name`: el autoload `Idiomas` es el último eslabón de la cadena.)

static func _es_letra(c: int) -> bool:
	var nat := Nativo.de("nuc_es_letra")
	if nat != null:
		return nat.nuc_es_letra(c)
	return _es_letra_gd(c)

## Gemela GDScript de `nuc_es_letra` (extensión C++, orden 63): respaldo sin binario y comparación en `pruebas/probar_nativo_puras.gd`.
static func _es_letra_gd(c: int) -> bool:
	return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 192 and c <= 687) or (c >= 48 and c <= 57) or c == 191 or c == 161

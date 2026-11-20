extends "res://nucleo/partida_p1.gd"
## [Capa intermedia de `partida.gd`, entre `partida_p1.gd` y `partida.gd`] _seq_de y su gemela _seq_de_gd (20-11, orden 63: C++).

## El número de un id «j123» / «c45»; `defecto` si no tiene esa forma.
static func _seq_de(id: String, prefijo: String, defecto: int) -> int:
	var nat := Nativo.de("nuc_seq_de")
	if nat != null:
		return nat.nuc_seq_de(id, prefijo, defecto)
	return _seq_de_gd(id, prefijo, defecto)

## Gemela GDScript de `nuc_seq_de` (extensión C++, orden 63): respaldo sin binario y comparación en `pruebas/probar_nativo_puras.gd`.
static func _seq_de_gd(id: String, prefijo: String, defecto: int) -> int:
	var n := id.trim_prefix(prefijo)
	return int(n) if id.begins_with(prefijo) and n.is_valid_int() else defecto

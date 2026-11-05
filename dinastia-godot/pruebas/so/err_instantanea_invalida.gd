extends BaseSO
## ERRORES · datos de partida inválidos que llegan "bien formados" (de una importación, un mod o una versión rara): diccionario vacío,
## versión del futuro, tipos cambiados, listas vacías, ids repetidos. `Partida.desde_instantanea` no revienta: devuelve null o un mundo usable.
func _nombre() -> String:
	return "err_instantanea_invalida"

func _probar() -> void:
	_titulo("ERRORES · instantáneas inválidas [%s]" % sistema())
	_comprobar(Partida.desde_instantanea({}) == null, "{} → null")
	_comprobar(Partida.desde_instantanea({"version": Partida.VERSION + 5}) == null, "versión del futuro → null (no se carga una partida de un juego más nuevo)")
	var m := _mundo(20261105)
	var base: Dictionary = Partida.instantanea(m)
	_comprobar(not base.is_empty(), "instantánea sana (%d claves)" % base.size())
	## Un guardado antiguo SIN «azar» sigue cargando (regresión vigilada: la clave es opcional).
	var sin_azar := base.duplicate(true)
	sin_azar.erase("azar")
	var viejo := Partida.desde_instantanea(sin_azar)
	_comprobar(viejo is Mundo and viejo.mi_club() != null, "un guardado sin «azar» (como los viejos) sigue cargando y da un Mundo")
	var sana := Partida.desde_instantanea(base)
	_comprobar(sana != null and sana.mi_club() != null, "la sana se reconstruye")
	## …y el guardado viejo REAL del repositorio (sin «azar») también.
	var bruto := FileAccess.get_file_as_bytes("res://pruebas/partidas_viejas/v2_2026-10-27.json.gz")
	if bruto.size() > 0:
		var txt := bruto.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8()
		var d_real: Variant = JSON.parse_string(txt)
		_comprobar(d_real is Dictionary and not (d_real as Dictionary).has("azar"), "la muestra v2 del repositorio no trae «azar»")
		_comprobar(Partida.desde_instantanea(d_real) is Mundo, "…y se carga")
	## Quitar de a una cada clave de primer nivel: nada debe reventar el intérprete (SCRIPT ERROR lo detecta el lanzador).
	var sin_club := 0
	var claves: Array = base.keys()
	for k: String in claves:
		var d := base.duplicate(true)
		d.erase(k)
		var n := Partida.desde_instantanea(d)
		if n == null or n.mi_club() == null:
			sin_club += 1
	print("  (sin la clave X, %d de %d guardados quedan sin club: esperado para las imprescindibles)" % [sin_club, claves.size()])
	_comprobar(sin_club < claves.size(), "no todas las claves son imprescindibles: los guardados viejos sin campos nuevos abren")
	## Tipos cambiados en las claves imprescindibles: se rechaza el guardado, no revienta el intérprete.
	for k: String in ["clubes", "ligas", "mi_club"]:
		var d := base.duplicate(true)
		d[k] = 12345
		_comprobar(Partida.desde_instantanea(d) == null, "«%s» con otro tipo → null" % k)
	## Un club sin id y una liga que cita un club que no existe: no revienta.
	var d2 := base.duplicate(true)
	(d2["ligas"] as Array)[0]["clubes"] = ["c_que_no_existe", "otro_que_tampoco"]
	var n2 := Partida.desde_instantanea(d2)
	_comprobar(n2 == null or n2 is Mundo, "una liga con clubes inexistentes no revienta")

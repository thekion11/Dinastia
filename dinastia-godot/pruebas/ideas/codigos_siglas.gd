extends BaseIdea
## SIGLAS Y CÓDIGOS CORTOS (3-11, hallazgo del líder en «Clubes → Ligas del mundo»): las siglas de las tablas (PJ, G, E, P…) se traducen por su prefijo «Sigla de tabla: X»
## (`CompeticionFilas.sigla`), porque «G», «E» y «P» sueltas chocarían con otras cosas (la «E» es la tecla de acción); los códigos de país (GER, USA…) no se tocan nunca.
## Lo que se comprueba: (1) la sigla sale como dice el parche de traducciones en los 8 idiomas; (2) `Idiomas.t` no cambia ni G/E/P sueltas ni un código de país; (3) ninguna tabla del juego
## pinta «G», «E», «P» en crudo (la de «Ligas del mundo» lo hacía y en inglés salía «P G E P PTS»).
func _ready() -> void:
	await get_tree().process_frame
	_titulo("SIGLAS Y CÓDIGOS CORTOS")
	var parche := (JSON.parse_string(FileAccess.get_file_as_string("res://datos/trad_parches/s2_uico.json")) as Dictionary)["exactas"] as Dictionary
	var antes := Idiomas.idioma
	for l: String in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
		Idiomas.idioma = l
		var mal: Array[String] = []
		for t: String in ["PJ", "G", "E", "P", "GF", "GC", "DG", "PTS"]:
			var esperado := String((parche.get("Sigla de tabla: " + t, {}) as Dictionary).get(l, t))
			if CompeticionFilas.sigla(t) != esperado:
				mal.append("%s→%s (debía ser %s)" % [t, CompeticionFilas.sigla(t), esperado])
		_comprobar(mal.is_empty(), "%s: las siglas de la tabla salen como el parche %s" % [l, str(mal)])
		var tocados: Array[String] = []
		for c: String in ["G", "E", "P"] + Array(Globo3D.GLOBO_PAIS.keys()):
			if Idiomas.t(c) != c:
				tocados.append("%s→%s" % [c, Idiomas.t(c)])
		_comprobar(tocados.is_empty(), "%s: G/E/P sueltas y los códigos de país no se traducen %s" % [l, str(tocados)])
	Idiomas.idioma = antes
	## (3) Ninguna lista de cabeceras con «G», «E», «P» en crudo: en la misma línea o en las dos siguientes tiene que pasar por `sigla(`.
	var crudas: Array[String] = []
	for ruta: String in _gds("res://ui"):
		var lineas := FileAccess.get_file_as_string(ruta).split("\n")
		for i in lineas.size():
			if lineas[i].contains('"G", "E", "P"') and not lineas[i].contains("sigla(") and not lineas[i].contains("CompeticionFilas.cabecera("):   ## `cabecera` traduce con `sigla` por dentro
				var ok := false
				for k in range(i, mini(i + 3, lineas.size())):
					ok = ok or lineas[k].contains("sigla(")
				if not ok:
					crudas.append("%s:%d" % [ruta.get_file(), i + 1])
	_comprobar(crudas.is_empty(), "ninguna tabla pinta G/E/P en crudo %s" % str(crudas))
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _gds(dir: String) -> Array[String]:
	var r: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			r.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		r.append_array(_gds(dir.path_join(d)))
	return r

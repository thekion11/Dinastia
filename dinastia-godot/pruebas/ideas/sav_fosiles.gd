extends BaseIdea
## 1094 · LAS PARTIDAS SOBREVIVEN A LAS ACTUALIZACIONES (27-10-2026). En `pruebas/partidas_viejas/` se guarda una
## partida de cada versión del guardado (`vN_fecha.json.gz`, instantánea de `Partida` comprimida). Esta prueba las
## abre TODAS con el código de hoy: migran, el mundo se reconstruye con su club, su caja y su plantilla, y avanza
## una semana sin errores. Al subir `Partida.VERSION`, guardar una nueva aquí (ver el final del archivo).

const CARPETA := "res://pruebas/partidas_viejas"

func _probar() -> void:
	_titulo("1094: LAS PARTIDAS GUARDADAS DE VERSIONES VIEJAS SIGUEN ABRIENDO")
	var d := DirAccess.open(CARPETA)
	_comprobar(d != null, "existe la carpeta de partidas viejas")
	if d == null:
		return
	var vistas := 0
	var version_maxima := 0
	for f: String in d.get_files():
		if not f.ends_with(".json.gz"):
			continue
		vistas += 1
		var bruto := FileAccess.get_file_as_bytes(CARPETA + "/" + f)
		var txt := bruto.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8()
		var datos: Variant = JSON.parse_string(txt)
		_comprobar(datos is Dictionary, "%s: se lee" % f)
		if not (datos is Dictionary):
			continue
		version_maxima = maxi(version_maxima, int((datos as Dictionary).get("version", 0)))
		var m := Partida.desde_instantanea(datos)
		_comprobar(m != null and m.mi_club() != null, "%s: el mundo se reconstruye con su club" % f)
		if m == null or m.mi_club() == null:
			continue
		var c := m.mi_club()
		_comprobar(c.plantilla.size() >= 11, "%s: con su plantilla (%d jugadores)" % [f, c.plantilla.size()])
		var semana := m.semana
		m.avanzar_semana()
		_comprobar(m.semana == semana + 1 or m.anio > 0, "%s: y avanza una semana (%d → %d)" % [f, semana, m.semana])
		## Lo de hoy también sale de una partida vieja: el mentor y los retos con valores por defecto.
		_comprobar(m.retos_semana != null and m.mentor_mes != null, "%s: con los sistemas de hoy (retos, mentor)" % f)
	_comprobar(vistas >= 1, "hay al menos una partida guardada de muestra (%d)" % vistas)
	_comprobar(version_maxima == Partida.VERSION, "hay una de la versión actual del guardado (v%d): al subir la versión, guarda otra" % Partida.VERSION)

## PARA GUARDAR UNA NUEVA (al subir `Partida.VERSION`): un mundo CHI+ARG con semilla fija, tres semanas jugadas,
##   var d := Partida.instantanea(m); FileAccess.open(CARPETA + "/v%d_<fecha>.json.gz" % Partida.VERSION, WRITE)
##   .store_buffer(JSON.stringify(d).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))

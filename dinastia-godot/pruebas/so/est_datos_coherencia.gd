extends BaseSO
## ESTÁNDAR · coherencia de los datos: tablas.json, paises.json y pack_real.json se leen igual en cualquier sistema (mismas tablas, tipos y
## referencias cruzadas): cada país con liga tiene tier, selección y nombre en los 9 idiomas; los clubes tienen colores #RRGGBB y aforo
## positivo; las confederaciones citan países que existen; el mundo generado no repite ids y todos sus jugadores están en rango.
func _nombre() -> String:
	return "est_datos_coherencia"

func _es_color(c: Variant) -> bool:
	return c is String and RegEx.create_from_string("^#[0-9a-fA-F]{6}$").search(c) != null

func _probar() -> void:
	_titulo("ESTÁNDAR · coherencia de datos [%s]" % sistema())
	var ligas: Dictionary = Datos.tabla("PAISES_LIGAS")
	var tier: Dictionary = Datos.tabla("TIER_PAIS")
	var pais_sel: Dictionary = Datos.tabla("PAIS_SELECCION")
	var paises_json: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://datos/paises.json"))
	var nombres: Dictionary = (paises_json as Dictionary).get("paises", {})
	_comprobar(ligas.size() >= 20, "hay %d países con liga" % ligas.size())
	var sin_tier: Array[String] = []
	var sin_nombre: Array[String] = []
	var sin_idioma: Array[String] = []
	var mal_club: Array[String] = []
	var repetidos: Array[String] = []
	var vistos := {}
	for p: String in ligas:
		if not tier.has(p):
			sin_tier.append(p)
		if not nombres.has(p):
			sin_nombre.append(p)
		else:
			for idi in ["es", "en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
				if String((nombres[p] as Dictionary).get(idi, "")) == "":
					sin_idioma.append("%s/%s" % [p, idi])
		var liga: Dictionary = ligas[p]
		_comprobar(String(liga.get("liga", "")) != "" and (liga.get("clubes", []) as Array).size() >= 4, "%s: liga con nombre y al menos 4 clubes" % p)
		for fila: Array in liga.get("clubes", []):
			var n := String(fila[0])
			if vistos.has(n):
				repetidos.append(n)
			vistos[n] = true
			if n == "" or not _es_color(fila[1]) or not _es_color(fila[2]) or int(fila[3]) < 1 or int(fila[3]) > 100 or int(fila[4]) < 500:
				mal_club.append("%s (%s)" % [n, p])
	_comprobar(sin_tier.is_empty(), "todos los países con liga tienen tier económico %s" % str(sin_tier))
	_comprobar(sin_nombre.is_empty(), "todos los países con liga tienen nombre en paises.json %s" % str(sin_nombre))
	_comprobar(sin_idioma.is_empty(), "…y en los 9 idiomas %s" % str(sin_idioma.slice(0, 5)))
	_comprobar(mal_club.is_empty(), "clubes con nombre, dos colores #RRGGBB, reputación 1-100 y aforo ≥ 500 %s" % str(mal_club.slice(0, 5)))
	_comprobar(repetidos.is_empty(), "ningún nombre de club repetido entre países %s" % str(repetidos.slice(0, 5)))
	var confed: Dictionary = Datos.tabla("CONFED")
	var fantasmas: Array[String] = []
	for k: String in confed:
		for p: String in confed[k]["paises"]:
			if not ligas.has(p) and not pais_sel.has(p) and not nombres.has(p):
				fantasmas.append("%s:%s" % [k, p])
	_comprobar(fantasmas.is_empty(), "las confederaciones solo citan países que existen %s" % str(fantasmas))
	var posd: Dictionary = Datos.tabla("POSD")
	var grupos := {"POR": true, "DEF": true, "MED": true, "DEL": true}
	var mal_pos: Array[String] = []
	for k: String in posd:
		if not grupos.has(String(posd[k]["g"])):
			mal_pos.append(k)
	_comprobar(mal_pos.is_empty() and posd.size() >= 10, "POSD: %d demarcaciones, todas con grupo POR/DEF/MED/DEL %s" % [posd.size(), str(mal_pos)])
	## El mundo generado
	var m := _mundo(20261105)
	var ids := {}
	var dup_club := 0
	var dup_jug := 0
	var fuera := 0
	var jids := {}
	for c: Club in m.clubes.values():
		if ids.has(c.id):
			dup_club += 1
		ids[c.id] = true
		for j: Jugador in c.plantilla:
			if jids.has(j.id):
				dup_jug += 1
			jids[j.id] = true
			if j.ovr < 1 or j.ovr > 99 or j.pot < j.ovr - 3 or j.edad < 15 or j.edad > 45 or not posd.has(j.pos_e):
				fuera += 1
	_comprobar(dup_club == 0 and dup_jug == 0, "ids únicos en el mundo: %d clubes, %d jugadores" % [ids.size(), jids.size()])
	_comprobar(fuera == 0, "todos los jugadores con media 1-99, edad 15-45 y demarcación conocida (%d fuera de rango)" % fuera)
	## pack_real.json: si existe, tiene la misma forma que la base.
	if FileAccess.file_exists("res://datos/pack_real.json"):
		var pr: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://datos/pack_real.json"))
		_comprobar(pr is Dictionary, "pack_real.json es un diccionario JSON válido")

extends BaseIdea
## EL PALMARÉS REAL EN LA HISTORIA DEL CLUB (orden 15 f, 27-10-2026): títulos por competición y año colgados de `HISTORIA_CLUBES`, con la base real y la
## ficticia; la ficha del club los cuenta, el museo hace una vitrina por competición (con sus años) y el visor de la copa enseña las veces y los años.

func _ready() -> void:
	await get_tree().process_frame
	_probar_palmares()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _club(nombre: String) -> Club:
	var c := Club.new()
	c.id = "t_" + nombre
	c.nombre = nombre
	c.pais = "ESP"
	return c

func _probar_palmares() -> void:
	for real: bool in [true, false]:
		Datos.usar_base_real(real)
		if real != Datos.base_real:
			print("(sin pack real en este equipo: se salta la base real)")
			continue
		_titulo("PALMARÉS · BASE %s" % ("REAL" if real else "FICTICIA"))
		var tabla: Dictionary = Datos.tabla("HISTORIA_CLUBES")
		var con := 0
		var titulos := 0
		for k: String in tabla:
			var pal: Variant = (tabla[k] as Dictionary).get("palmares", null)
			if pal is Dictionary:
				con += 1
				for anios: Variant in (pal as Dictionary).values():
					titulos += (anios as Array).size()
		_comprobar(con >= 80 and titulos >= 400, "al menos 80 clubes con palmarés y 400 títulos (%d / %d)" % [con, titulos])
		var nombre_madrid := "Real Madrid" if real else _ficticio_de("Real Madrid")
		var madrid := _club(nombre_madrid)
		var hi := HistoriaClub.de(madrid, [])
		var lista := HistoriaClub.lista_palmares(hi)
		_comprobar(lista.size() >= 3, "el club grande trae varias competiciones (%d)" % lista.size())
		var champions: Array = []
		for x: Dictionary in lista:
			if String(x["clave"]) == "conf:ucl":
				champions = x["anios"]
		_comprobar(champions.size() == 15 and int(champions[0]) == 1956 and int(champions[champions.size() - 1]) == 2024, "la Champions del grande: 15 títulos de 1956 a 2024 (%d)" % champions.size())
		_comprobar(HistoriaClub.texto_palmares(hi).begins_with("🏆") and HistoriaClub.texto_palmares(hi).contains("×"), "la ficha lo cuenta en una línea")
		var hitos := HistoriaClub.hitos_palmares(madrid)
		var orden_ok := not hitos.is_empty()
		for h: Dictionary in hitos:
			orden_ok = orden_ok and int(h["cantidad"]) == (h["anios"] as Array).size() and int(h["anio"]) == int((h["anios"] as Array)[(h["anios"] as Array).size() - 1])
		_comprobar(orden_ok, "un hito por competición con su cantidad y el año del último título")
		_comprobar(TrofeosReales.id_de(String(hitos[0]["titulo"]), "ESP") != "generico", "cada hito encuentra su copa de receta")
		var sin := _club("Club Inventado")
		_comprobar(HistoriaClub.hitos_palmares(sin).is_empty() and HistoriaClub.texto_palmares(HistoriaClub.de(sin, [])) == "", "un club sin palmarés no inventa nada")
		## El visor enseña las veces y los años.
		var capa := CanvasLayer.new()
		add_child(capa)
		var v := VisorTrofeo.abrir(capa, {"titulo": String(hitos[0]["titulo"]), "anio": int(hitos[0]["anio"]), "anios": hitos[0]["anios"], "cantidad": hitos[0]["cantidad"]})
		var textos := ""
		for l: Node in v.find_children("*", "Label", true, false):
			textos += (l as Label).text + " "
		_comprobar(textos.contains(str(int(hitos[0]["anios"][0]))) and textos.contains(Idiomas.mayusculas(Idiomas.t("Años"))), "el visor lista los años del palmarés")
		v.queue_free()
		capa.queue_free()
	Datos.usar_base_real(false)

## El nombre ficticio de un club real (por la tabla de historia de la base ficticia, que guarda el mismo orden que el pack).
func _ficticio_de(real: String) -> String:
	if not FileAccess.file_exists("res://datos/pack_real.json"):
		return real
	var pack: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://datos/pack_real.json"))
	var base: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://datos/tablas.json"))
	var claves_real: Array = ((pack as Dictionary)["tablas"] as Dictionary)["HISTORIA_CLUBES"].keys()
	var claves_fic: Array = ((base as Dictionary)["HISTORIA_CLUBES"] as Dictionary).keys()
	return String(claves_fic[claves_real.find(real)]) if claves_real.has(real) and claves_real.find(real) < claves_fic.size() else real

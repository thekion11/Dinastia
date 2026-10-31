extends BaseIdea
## JUGADORES PRECALENTADOS EN EL MENÚ (M-348, 28-10-2026): qué se pone en cola (el once y la banca de cada club, sin repetir), que no hace nada sin pantalla y que
## `detener()` es seguro. El ahorro real (primera apertura del estadio 5,0 s → 2,8 s) lo mide `medir_carga_estadio.tscn` con CARAS=1 (necesita pantalla).

func _ready() -> void:
	await get_tree().process_frame
	_titulo("PRECALENTAR JUGADORES")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var items := PrecalentarCaras._items([a, b])
	_comprobar(items.size() >= 30 and items.size() <= 48, "dos clubes: los dos onces y las dos bancas (%d jugadores)" % items.size())
	var claves := {}
	for it: Dictionary in items:
		claves[it["clave"]] = true
	_comprobar(claves.size() == items.size(), "sin repetidos")
	var propios := 0
	for it: Dictionary in items:
		if String(it["clave"]).ends_with("|" + a.id):
			propios += 1
	_comprobar(propios >= 15 and propios <= 24, "el club propio: once + hasta 12 de banca (%d)" % propios)
	PrecalentarCaras._hechos[items[0]["clave"]] = true
	_comprobar(PrecalentarCaras._items([a, b]).size() == items.size() - 1, "lo ya hecho no se vuelve a poner en cola")
	PrecalentarCaras._hechos.clear()
	PrecalentarCaras.club(a)
	PrecalentarCaras.del_mundo(m)
	_comprobar(not is_instance_valid(PrecalentarCaras._activa), "sin pantalla no se lanza nada")
	PrecalentarCaras.detener()
	_comprobar(true, "detener() sin nada en marcha no falla")
	_comprobar(PrecalentarCaras.MS_POR_FOTOGRAMA <= 1.0, "el presupuesto de la pantalla de menú no pasa de 1 ms por fotograma")
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

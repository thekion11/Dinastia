extends BaseIdea
## M-290 (28-10-2026): el dato vivo de las tarjetas del menú (`DatoTarjeta`).
##   herramientas/ideas.sh men_datos

func _ready() -> void:
	await get_tree().process_frame
	_titulo("M-290: DATOS VIVOS DE LAS TARJETAS")
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	var idioma_antes := Idiomas.idioma
	Idiomas.idioma = "es"
	pr._bandeja.clear()
	pr._bandeja.append({"titulo": "a", "cuerpo": "", "semana": 1, "anio": 2026, "leida": true})
	pr._bandeja.append({"titulo": "b", "cuerpo": "", "semana": 1, "anio": 2026, "leida": false})
	_comprobar(DatoTarjeta.de(pr, "Correo") == "1 sin leer", "el correo cuenta solo los no leídos (%s)" % DatoTarjeta.de(pr, "Correo"))
	var con := 0
	for et: String in ["Mi plantel", "Táctica", "Finanzas", "Mercado", "Contratos", "Calendario", "Logros", "Récords", "Rivales", "Premios",
			"Vitrina", "Hinchada y Socios", "Estadio", "Feed de Redes"]:
		if DatoTarjeta.de(pr, et) != "":
			con += 1
	_comprobar(con == 14, "las 14 tarjetas de gestión llevan dato (%d)" % con)
	## (12-11) Con los nombres REALES de las tarjetas del menú (al renombrarlas, «Cuentas del club» y «Mercado de fichajes» perdieron su dato).
	var reales: Array[String] = []
	for men: Dictionary in MenusLaterales.MENUS:
		for sub: Dictionary in men["subs"]:
			reales.append(String(sub["label"]))
	for et: String in ["Cuentas del club", "Mercado de fichajes", "Personal del club", "La gente del club", "Enfermería", "Pizarra y dibujo", "Ligas y clubes", "Próximo partido"]:
		_comprobar(reales.has(et) and DatoTarjeta.de(pr, et) != "", "«%s» existe en el menú y lleva dato (%s)" % [et, DatoTarjeta.de(pr, et)])
	_comprobar(DatoTarjeta.de(pr, "Personal del club").contains("puestos"), "el personal cuenta puestos, no jugadores")
	_comprobar(DatoTarjeta.de(pr, "Glosario") == "", "las que no tienen cifra, no")
	Idiomas.idioma = "en"
	_comprobar(DatoTarjeta.de(pr, "Correo") == "1 unread", "traducido (%s)" % DatoTarjeta.de(pr, "Correo"))
	Idiomas.idioma = idioma_antes
	pr.queue_free()
	await get_tree().process_frame
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

extends BaseIdea
## OBRAS SIN MAPA (6-11-2026, el jugador ya no usa la vista aérea): paseando por la ciudad, la tecla E sobre una instalación o solar del club emite `interactuar`
## del explorador y abre la ficha de obras; su botón «Construir / Mejorar» llama al constructor del juego (el que en la partida es `_empezar_obra`).
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")

func _probar() -> void:
	_titulo("OBRAS A PIE: E sobre un solar abre la ficha y el botón construye")
	var c: Dictionary = await Comun.abrir(self)
	var vc: VistaCiudad = c["vc"]
	var cb: Node = c["cb"]
	var pedidas: Array = []
	vc.construir = func(k: String) -> String:
		pedidas.append(k)
		return ""
	vc.club.saldo = 2000000000
	await vc.explorar("pie")
	var ex: ExploradorCiudad = vc.get("_explorador")
	_comprobar(ex != null, "se puede pasear sin pasar por el mapa (explorar(\"pie\"))")
	if ex == null:
		vc.free()
		return
	var clave := ""
	for pc: Dictionary in cb.get("puntos_clic"):
		if Instalaciones.CATALOGO.has(String(pc["k"])) and vc._obras.coste(String(pc["k"]), vc.club.rep) > 0 and not vc._obras.en_obra(String(pc["k"])):
			clave = String(pc["k"])
			break
	_comprobar(clave != "", "la ciudad trae al menos un solar o instalación que se puede construir o mejorar")
	if clave != "":
		ex.interactuar.emit(clave)
		_comprobar(vc.get("_ficha") != null, "E sobre «%s» abre la ficha de obras a pie" % clave)
		var boton: Button = null
		if vc.get("_ficha") != null:
			for b in (vc.get("_ficha") as Node).find_children("*", "Button", true, false):
				if not (b as Button).disabled and String((b as Button).text).contains(" sem"):
					boton = b
					break
		_comprobar(boton != null, "la ficha trae el botón de construir o mejorar, activo")
		if boton != null:
			boton.pressed.emit()
			_comprobar(pedidas == [clave], "pulsarlo pide la obra correcta al constructor del juego (%s)" % str(pedidas))
	vc.free()

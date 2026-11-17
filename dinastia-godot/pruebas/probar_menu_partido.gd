extends Node
## El menú del partido (avance por días): se monta con clubes de países distintos, abre todas sus pestañas, sus ajustes escriben las mismas preferencias que
## leía el estadio, jugar / importantes / simular devuelven lo mismo que `EleccionPartido`, y el partido ya NO guarda ajustes en su cajón (solo la arena de pruebas).

var fallos := 0
var _el: Dictionary = {}

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func _frames(n := 3) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	var antes := ConfigFile.new()
	antes.load(CajonAjustes.RUTA)
	var copia := {}
	for k in ["motor_real", "ritmo_partido", "dificultad_cpu8", "pro_camara", "radar", "preguntar_partido"]:
		copia[k] = antes.get_value(CajonAjustes.SECCION, k) if antes.has_section_key(CajonAjustes.SECCION, k) else null
	for cfg: Array in [["ARG", 3], ["ENG", 5], ["JPN", 7]]:
		var m := Mundo.new()
		var ps: Array[String] = [String(cfg[0])]
		m.generar(ps, 300 + int(cfg[1]))
		var liga: Liga = m.ligas[0]
		m.tomar_el_mando(liga.clubes[int(cfg[1])].id)
		var mio := m.mi_club()
		var rival: Club = liga.clubes[(int(cfg[1]) + 4) % liga.clubes.size()]
		var p := Partido.new(rival, mio)
		var menu := MenuPartido.mostrar(self, p, mio, liga, Clima.del_partido(rival.pais, m.semana, m.anio, rival.id + mio.id))
		await _frames(3)
		for tab: Array in MenuPartido.PESTANAS:
			(menu._botones[String(tab[0])] as Button).button_pressed = true
			menu._abrir(String(tab[0]))
			await _frames(2)
			_ok(menu._cuerpo.get_child_count() > 0 or String(tab[0]) == "x", "%s: la pestaña %s tiene contenido" % [cfg[0], tab[0]])
		menu.elegido.connect(func(e: Dictionary) -> void: _el = e)
		menu._elegir("jugar")
		_ok(String(_el.get("modo", "")) == "completo" and bool(_el.get("control", false)), "%s: «Jugar» = partido completo con control" % cfg[0])
		menu._elegir("importantes")
		_ok(String(_el.get("modo", "")) == "destacados" and bool(_el.get("ocasiones", false)), "%s: «Solo las importantes» = destacados" % cfg[0])
		menu._sim = "vivo"
		menu._elegir("simular")
		_ok(String(_el.get("modo", "")) == "vivo" and not bool(_el.get("control", true)), "%s: «Simular» respeta el modo elegido" % cfg[0])
		menu.queue_free()
		await _frames(2)
	## los ajustes escriben las preferencias de siempre
	OpcionesPartido.guardar("motor_real", false)
	_ok(OpcionesPartido.leer("motor_real", true) == false, "motor_real se guarda y se lee")
	OpcionesPartido.guardar("ritmo_partido", "largo")
	_ok(String(OpcionesPartido.leer("ritmo_partido", "normal")) == "largo", "ritmo_partido se guarda y se lee")
	var caja := VBoxContainer.new()
	add_child(caja)
	OpcionesPartido.construir(caja)
	OpcionesPartido.construir_camara(caja)
	await _frames(2)
	_ok(caja.get_child_count() > 20, "las opciones y la cámara montan todos sus controles (%d)" % caja.get_child_count())
	var seg_cpu := 0
	for n in caja.find_children("*", "Button", true, false):
		if (n as Button).toggle_mode:
			seg_cpu += 1
	_ok(seg_cpu >= 8 + 2 + 3 + 3, "hay botones de dificultad, estilo, ritmo y cámara (%d)" % seg_cpu)
	## restaurar las preferencias del usuario
	var cfg2 := ConfigFile.new()
	cfg2.load(CajonAjustes.RUTA)
	for k: String in copia.keys():
		if copia[k] == null:
			if cfg2.has_section_key(CajonAjustes.SECCION, k):
				cfg2.erase_section_key(CajonAjustes.SECCION, k)
		else:
			cfg2.set_value(CajonAjustes.SECCION, k, copia[k])
	cfg2.save(CajonAjustes.RUTA)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()

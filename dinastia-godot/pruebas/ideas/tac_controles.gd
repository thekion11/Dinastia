extends BaseIdea
## CONTROLES TÁCTILES DEL PARTIDO (M-433, 27-10-2026; rehechos al estilo FC Mobile el 11-11): con eventos de pantalla simulados, el stick mueve con fuerza analógica y cada botón
## (SP, PA, AH, TI) pulsa y suelta su acción del InputMap, con varios dedos a la vez. Los gestos de cada botón y las medidas en mm están en el banco (`_probar_mando_tactil_fc`).

func _ready() -> void:
	await get_tree().process_frame
	_probar_tactil()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _toque(c: ControlesTactiles, dedo: int, pos: Vector2, pulsa: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = dedo
	e.position = pos
	e.pressed = pulsa
	c._input(e)

func _arrastre(c: ControlesTactiles, dedo: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = dedo
	e.position = pos
	c._input(e)

func _probar_tactil() -> void:
	_titulo("PARTIDO · CONTROLES TÁCTILES")
	ControlesTactiles.forzar = false
	_comprobar(ControlesTactiles.poner(self) == null or ExploradorCiudad.es_tactil(), "en PC (sin pantalla táctil) no aparecen")
	ControlesTactiles.forzar = true
	Mando.registrar()
	var c := ControlesTactiles.poner(self)
	_comprobar(c != null, "con pantalla táctil aparecen")
	c.size = Vector2(1280, 720)
	## Stick: tocar a la izquierda y arrastrar hacia la derecha y arriba.
	var ini := Vector2(200, 500)
	_toque(c, 0, ini, true)
	_arrastre(c, 0, ini + Vector2(60, -60))
	var mv := Mando.movimiento()
	_comprobar(mv.x > 0.2 and mv.y < -0.2, "el stick manda dirección arriba-derecha (%.2f, %.2f)" % [mv.x, mv.y])
	_arrastre(c, 0, ini + Vector2(400, 0))
	_comprobar(absf(Mando.movimiento().length() - 1.0) < 0.05, "más allá del radio la fuerza se queda en 1")
	_arrastre(c, 0, ini + Vector2(30, 0))
	_comprobar(Mando.movimiento().x > 0.0 and Mando.movimiento().x < 0.5, "a medio stick, medio paso (analógico)")
	## Botones con otro dedo a la vez que el stick.
	var nombres := {"SP": "jugar_sprint", "PA": "jugar_pase", "AH": "jugar_filtrado", "TI": "jugar_tiro", "Pausa": "jugar_pausa"}
	var dedo := 1
	c._modo_mando = "botones"
	for n: String in nombres:
		c._con_balon = true       ## con balón y en el modo «Botones»: cada botón hace solo su función básica
		c._en_banda = true
		_toque(c, dedo, c.centro_de(n), true)
		_comprobar(Input.is_action_pressed(String(nombres[n])), "el botón %s pulsa «%s»" % [n, nombres[n]])
		_comprobar(Mando.movimiento().x > 0.0, "…y el stick sigue moviendo")
		_toque(c, dedo, c.centro_de(n), false)
		_comprobar(not Input.is_action_pressed(String(nombres[n])), "soltar %s suelta «%s»" % [n, nombres[n]])
		dedo += 1
	## Pase y sprint a la vez (correr y pasar).
	_toque(c, 5, c.centro_de("SP"), true)
	_toque(c, 6, c.centro_de("PA"), true)
	_comprobar(Input.is_action_pressed("jugar_sprint") and Input.is_action_pressed("jugar_pase"), "sprint y pase a la vez")
	_toque(c, 6, c.centro_de("PA"), false)
	_comprobar(Input.is_action_pressed("jugar_sprint") and not Input.is_action_pressed("jugar_pase"), "soltar el pase no suelta el sprint")
	## Un dedo que empezó en un botón y se sale no arrastra el stick.
	_arrastre(c, 5, Vector2(100, 300))
	_toque(c, 5, Vector2(100, 300), false)
	_comprobar(not Input.is_action_pressed("jugar_sprint"), "soltar fuera del botón también lo suelta")
	_toque(c, 0, ini, false)
	_comprobar(Mando.movimiento() == Vector2.ZERO, "levantar el dedo del stick lo deja quieto")
	## Tocar la mitad derecha en vacío no crea stick.
	_toque(c, 7, Vector2(900, 100), true)
	_arrastre(c, 7, Vector2(1000, 100))
	_comprobar(Mando.movimiento() == Vector2.ZERO, "un dedo en la mitad derecha, fuera de los botones, no mueve")
	_toque(c, 7, Vector2(900, 100), false)
	## Todos los botones caben en pantalla de 1280×720, de 1600×720 (móvil 20:9) y de móvil pequeño (960×480), sin pisarse (≥ 4 px entre ellos), en el pulgar (mitad inferior) y sin tapar el marcador (nada en el 45 % de arriba).
	for tam: Vector2 in [Vector2(1280, 720), Vector2(1600, 720), Vector2(960, 480)]:
		c.size = tam
		var ok := true
		var ns: Array = nombres.keys()
		for i in ns.size():
			var p := c.centro_de(String(ns[i]))
			var ri := c.radio_de(String(ns[i]))
			if p.x < ri or (p.y < tam.y * 0.45 and ns[i] != "Pausa") or p.x > tam.x - ri or p.y > tam.y - ri:
				ok = false
			for j in range(i + 1, ns.size()):
				if p.distance_to(c.centro_de(String(ns[j]))) < ri + c.radio_de(String(ns[j])) + 4.0:
					ok = false
		_comprobar(ok, "en %d×%d los botones caben, no se pisan (≥ 4 px) y quedan en la zona del pulgar" % [int(tam.x), int(tam.y)])
		_comprobar(c.radio_de("SP") * 2.0 >= 0.1 * tam.y, "en %d×%d el botón grande es del tamaño de un dedo (≥ 10 %% de la altura)" % [int(tam.x), int(tam.y)])
	## El stick no nace arriba (donde va el marcador) ni en la mitad de los botones.
	c.size = Vector2(1280, 720)
	_toque(c, 8, Vector2(200, 60), true)
	_arrastre(c, 8, Vector2(260, 60))
	_comprobar(Mando.movimiento() == Vector2.ZERO, "un dedo arriba a la izquierda (marcador) no crea stick")
	_toque(c, 8, Vector2(200, 60), false)
	## Zurdo: todo espejado (botones a la izquierda, stick a la derecha).
	ControlesTactiles.zurdo = true
	_comprobar(c.centro_de("SP").x < 640.0 and c.centro_reposo().x > 640.0, "zurdo: botones a la izquierda y stick a la derecha")
	_toque(c, 9, Vector2(1100, 500), true)
	_arrastre(c, 9, Vector2(1160, 500))
	_comprobar(Mando.movimiento().x > 0.2, "zurdo: el stick nace a la derecha")
	_toque(c, 9, Vector2(1100, 500), false)
	_toque(c, 10, c.centro_de("TI"), true)
	_comprobar(Input.is_action_pressed("jugar_tiro"), "zurdo: el botón TI pulsa «jugar_tiro»")
	_toque(c, 10, c.centro_de("TI"), false)
	_comprobar(c.centro_de("Pausa").x > 640.0, "zurdo: el botón de pausa sigue arriba a la derecha")
	ControlesTactiles.zurdo = false
	## Ajustes: el modo zurdo se guarda y llega a los controles.
	AjustesTactil.restaurar()
	_comprobar(not AjustesTactil.zurdo(), "por defecto no es zurdo")
	AjustesTactil.poner_zurdo(true)
	var gz := ControlesTactiles.poner(self)
	gz.size = Vector2(1280, 720)
	_comprobar(gz.centro_de("SP").x < 640.0 and gz.centro_reposo().x > 640.0, "el zurdo elegido en Ajustes espeja los controles")
	gz.free()
	AjustesTactil.restaurar()
	## Etiquetas por contexto: siempre los mismos 4 botones; con balón Sprint y regate / Pase / Al hueco / Tiro; sin balón Sprint y entrada / Cambiar / 2.º defensor / Barrida.
	_comprobar(c.etiqueta_de("SP", true) == "Sprint\ny regate" and c.etiqueta_de("SP", false) == "Sprint\ny entrada", "etiqueta de SP: Sprint y regate con balón, Sprint y entrada sin balón")
	_comprobar(c.etiqueta_de("PA", true) == "Pase" and c.etiqueta_de("PA", false) == "Cambiar", "etiqueta de PA: Pase con balón, Cambiar sin balón")
	_comprobar(c.etiqueta_de("AH", true) == "Al hueco" and c.etiqueta_de("AH", false) == "2.º\ndefensor", "etiqueta de AH: Al hueco con balón, 2.º defensor sin balón")
	_comprobar(c.etiqueta_de("TI", true) == "Tiro" and c.etiqueta_de("TI", false) == "Barrida", "etiqueta de TI: Tiro con balón, Barrida sin balón")
	## SIEMPRE 4 botones (más el II): cuántos se ven en cada contexto y modo.
	var cuenta := func(cb: bool, banda: bool, modo: String) -> int:
		var k := 0
		for n2: String in ControlesTactiles.BOTONES:
			if c.visible_en(n2, cb, banda, modo):
				k += 1
		return k
	_comprobar(int(cuenta.call(true, false, "ambos")) == 5 and int(cuenta.call(false, false, "ambos")) == 5 and int(cuenta.call(true, true, "botones")) == 5, "con y sin balón se ven siempre los 4 botones y el II")
	_comprobar(int(cuenta.call(true, false, "gestos")) == 2 and int(cuenta.call(false, false, "gestos")) == 3 and c.visible_en("PA", false, false, "gestos"), "en el modo «Gestos» quedan Sprint y II (y Cambiar sin balón)")
	## GESTOS: deslizar desde Tiro = rosca (abajo) o vaselina (arriba), desde Pase = pase elevado (arriba), tocar Sprint = regate; el resto, en el banco.
	c._modo_mando = "ambos"
	c._con_balon = true
	c._en_banda = false
	var cb_ := c.centro_de("TI")
	_toque(c, 20, cb_, true)
	_comprobar(Input.is_action_pressed("jugar_tiro") and not Input.is_action_pressed("jugar_mod"), "tocar Tiro solo pulsa Tiro")
	_arrastre(c, 20, cb_ + Vector2(0, c.radio_de("TI") * 1.3))
	_comprobar(Input.is_action_pressed("jugar_tiro") and Input.is_action_pressed("jugar_mod"), "deslizar hacia abajo desde Tiro pulsa también Mod (rosca)")
	_toque(c, 20, cb_, false)
	_comprobar(not Input.is_action_pressed("jugar_tiro") and not Input.is_action_pressed("jugar_mod"), "soltar suelta Tiro y Mod")
	var ca_ := c.centro_de("PA")
	_toque(c, 21, ca_, true)
	_arrastre(c, 21, ca_ + Vector2(0, -c.radio_de("PA") * 1.3))
	_comprobar(Input.is_action_pressed("jugar_pase_largo") and not Input.is_action_pressed("jugar_pase"), "deslizar hacia arriba desde Pase da el pase elevado")
	_toque(c, 21, ca_, false)
	Input.action_release("jugar_pase_largo")
	_toque(c, 22, Vector2(700, 300), true)
	_toque(c, 22, Vector2(700, 300), false)
	_comprobar(Input.is_action_pressed("jugar_pase"), "tocar la zona libre de la derecha da un pase")
	Input.action_release("jugar_pase")
	_toque(c, 23, Vector2(700, 520), true)
	_arrastre(c, 23, Vector2(715, 300))
	_toque(c, 23, Vector2(715, 300), false)
	_comprobar(Input.is_action_pressed("jugar_tiro"), "deslizar hacia arriba en la zona libre tira")
	Input.action_release("jugar_tiro")
	_toque(c, 24, c.centro_de("SP"), true)
	_toque(c, 24, c.centro_de("SP"), false)
	_comprobar(Input.is_action_pressed("jugar_regate"), "un toque corto en Sprint hace el regate")
	Input.action_release("jugar_regate")
	_toque(c, 25, c.centro_de("SP"), true)
	(c._gesto[25] as Dictionary)["t"] = int((c._gesto[25] as Dictionary)["t"]) - 600   ## lo mantiene un rato
	_comprobar(Input.is_action_pressed("jugar_sprint"), "mantener Sprint corre")
	_toque(c, 25, c.centro_de("SP"), false)
	_comprobar(not Input.is_action_pressed("jugar_regate") and not Input.is_action_pressed("jugar_sprint"), "mantener Sprint no hace regate")
	## Un segundo dedo en la zona del stick, con el stick ya en uso, NO es un gesto (antes, al levantarlo daba un pase).
	_toque(c, 28, Vector2(150, 500), true)            ## el stick
	_toque(c, 29, Vector2(220, 420), true)            ## un segundo dedo en la misma zona (p. ej. la palma)
	_toque(c, 29, Vector2(220, 420), false)
	_comprobar(not Input.is_action_pressed("jugar_pase"), "un segundo dedo en la zona del stick no da un pase al levantarlo")
	_toque(c, 28, Vector2(150, 500), false)
	c._modo_mando = "botones"
	_toque(c, 26, Vector2(700, 300), true)
	_toque(c, 26, Vector2(700, 300), false)
	_comprobar(not Input.is_action_pressed("jugar_pase"), "en el modo «Botones» la zona libre no da pases")
	c._modo_mando = "gestos"
	_toque(c, 27, Vector2(700, 300), true)
	_toque(c, 27, Vector2(700, 300), false)
	_comprobar(Input.is_action_pressed("jugar_pase"), "en el modo «Gestos» el toque en la zona libre da el pase")
	Input.action_release("jugar_pase")
	c.soltar_todo()
	## Separación entre botones: a 1,3 caben y no se pisan; el modo y la separación se guardan en Ajustes.
	AjustesTactil.restaurar()
	_comprobar(AjustesTactil.mando() == "ambos" and absf(AjustesTactil.separacion() - 1.0) < 0.001, "por defecto: modo «Ambos» y separación 100 %")
	AjustesTactil.poner_mando("gestos")
	AjustesTactil.poner_separacion(1.3)
	var gs := ControlesTactiles.poner(self)
	gs.size = Vector2(1280, 720)
	_comprobar(gs._modo_mando == "gestos" and absf(gs._sep - 1.3) < 0.001, "el modo de control y la separación elegidos llegan a los controles")
	var ok_sep := true
	for n3: String in nombres:
		var p3 := gs.centro_de(n3)
		var r3 := gs.radio_de(n3)
		if p3.x < r3 or p3.x > 1280.0 - r3 or p3.y > 720.0 - r3 or (n3 != "Pausa" and p3.y < 720.0 * 0.3):
			ok_sep = false
	_comprobar(ok_sep, "con la separación al 130 % los botones siguen cabiendo en pantalla")
	gs.free()
	AjustesTactil.poner_mando("zzz")
	_comprobar(AjustesTactil.mando() == "ambos", "un modo de control desconocido vuelve a «Ambos»")
	AjustesTactil.restaurar()
	## Ajustes: tamaño y opacidad (se leen al crear el control) y cuándo salen.
	c.soltar_todo()
	c.queue_free()
	AjustesTactil.restaurar()
	_comprobar(AjustesTactil.modo() == "auto" and absf(AjustesTactil.tamano() - 1.0) < 0.001 and absf(AjustesTactil.opacidad() - 0.6) < 0.001, "por defecto: automático, tamaño 100 %, opacidad 60 %")
	AjustesTactil.poner_tamano(1.4)
	AjustesTactil.poner_opacidad(0.4)
	var g := ControlesTactiles.poner(self)
	_comprobar(g != null and absf(g.esc - 1.4) < 0.001 and absf(g.opac - 0.4) < 0.001, "el tamaño (140 %) y la opacidad (40 %) elegidos llegan a los controles")
	g.size = Vector2(1280, 720)
	_comprobar(g.radio_de("PA") * 2.0 >= 64.0, "los botones miden más de 64 px (%d)" % int(g.radio_de("PA") * 2.0))
	g.size = Vector2(960, 480)
	_comprobar(g.radio_de("PA") <= MandoFC.radio("PA") + 0.01, "en una pantalla baja el tamaño no pasa de lo que cabe (radio %d)" % int(g.radio_de("PA")))
	g.free()
	AjustesTactil.poner_tamano(0.1)
	AjustesTactil.poner_opacidad(5.0)
	_comprobar(absf(AjustesTactil.tamano() - AjustesTactil.TAM_MIN) < 0.001 and absf(AjustesTactil.opacidad() - 1.0) < 0.001, "los valores se acotan (70–140 %, 20–100 %)")
	AjustesTactil.restaurar()
	ControlesTactiles.forzar = false
	AjustesTactil.poner_modo("no")
	ControlesTactiles.forzar = true
	_comprobar(ControlesTactiles.poner(self) == null, "con «Nunca» no salen, ni siquiera forzados por la pantalla")
	AjustesTactil.poner_modo("si")
	ControlesTactiles.forzar = false
	var h := ControlesTactiles.poner(self)
	_comprobar(h != null, "con «Siempre» salen aunque el aparato no sea táctil")
	if h != null:
		h.free()
	AjustesTactil.restaurar()

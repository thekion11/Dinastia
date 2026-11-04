extends BaseIdea
## CONTROLES TÁCTILES DEL PARTIDO (M-433, 27-10-2026): con eventos de pantalla simulados, el stick mueve con fuerza analógica y cada botón
## pulsa y suelta su acción del InputMap, con varios dedos a la vez.

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
	var nombres := {"A": "jugar_pase", "B": "jugar_tiro", "X": "jugar_centro", "Y": "jugar_filtrado", "Cambiar": "jugar_cambiar", "Sprint": "jugar_sprint", "Mod": "jugar_mod", "Pausa": "jugar_pausa"}
	var dedo := 1
	for n: String in nombres:
		_toque(c, dedo, c.centro_de(n), true)
		_comprobar(Input.is_action_pressed(String(nombres[n])), "el botón %s pulsa «%s»" % [n, nombres[n]])
		_comprobar(Mando.movimiento().x > 0.0, "…y el stick sigue moviendo")
		_toque(c, dedo, c.centro_de(n), false)
		_comprobar(not Input.is_action_pressed(String(nombres[n])), "soltar %s suelta «%s»" % [n, nombres[n]])
		dedo += 1
	## Pase y sprint a la vez (correr y pasar).
	_toque(c, 5, c.centro_de("Sprint"), true)
	_toque(c, 6, c.centro_de("A"), true)
	_comprobar(Input.is_action_pressed("jugar_sprint") and Input.is_action_pressed("jugar_pase"), "sprint y pase a la vez")
	_toque(c, 6, c.centro_de("A"), false)
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
		_comprobar(c.radio_de("A") * 2.0 >= 0.1 * tam.y, "en %d×%d el botón grande es del tamaño de un dedo (≥ 10 %% de la altura)" % [int(tam.x), int(tam.y)])
	## El stick no nace arriba (donde va el marcador) ni en la mitad de los botones.
	c.size = Vector2(1280, 720)
	_toque(c, 8, Vector2(200, 60), true)
	_arrastre(c, 8, Vector2(260, 60))
	_comprobar(Mando.movimiento() == Vector2.ZERO, "un dedo arriba a la izquierda (marcador) no crea stick")
	_toque(c, 8, Vector2(200, 60), false)
	## Zurdo: todo espejado (botones a la izquierda, stick a la derecha).
	ControlesTactiles.zurdo = true
	_comprobar(c.centro_de("A").x < 640.0 and c.centro_reposo().x > 640.0, "zurdo: botones a la izquierda y stick a la derecha")
	_toque(c, 9, Vector2(1100, 500), true)
	_arrastre(c, 9, Vector2(1160, 500))
	_comprobar(Mando.movimiento().x > 0.2, "zurdo: el stick nace a la derecha")
	_toque(c, 9, Vector2(1100, 500), false)
	_toque(c, 10, c.centro_de("B"), true)
	_comprobar(Input.is_action_pressed("jugar_tiro"), "zurdo: el botón B pulsa «jugar_tiro»")
	_toque(c, 10, c.centro_de("B"), false)
	_comprobar(c.centro_de("Pausa").x > 640.0, "zurdo: el botón de pausa sigue arriba a la derecha")
	ControlesTactiles.zurdo = false
	## Ajustes: el modo zurdo se guarda y llega a los controles.
	AjustesTactil.restaurar()
	_comprobar(not AjustesTactil.zurdo(), "por defecto no es zurdo")
	AjustesTactil.poner_zurdo(true)
	var gz := ControlesTactiles.poner(self)
	gz.size = Vector2(1280, 720)
	_comprobar(gz.centro_de("A").x < 640.0 and gz.centro_reposo().x > 640.0, "el zurdo elegido en Ajustes espeja los controles")
	gz.free()
	AjustesTactil.restaurar()
	## Etiquetas por contexto: con balón Pase/Tiro/Centro; sin balón Presión/Entrada/Barrida; «Al hueco» se apaga sin balón.
	_comprobar(c.etiqueta_de("A", true) == "Pase" and c.etiqueta_de("A", false) == "Presión", "etiqueta de A: Pase con balón, Presión sin balón")
	_comprobar(c.etiqueta_de("B", true) == "Tiro" and c.etiqueta_de("B", false) == "Entrada", "etiqueta de B: Tiro con balón, Entrada sin balón")
	_comprobar(c.etiqueta_de("X", true) == "Centro" and c.etiqueta_de("X", false) == "Barrida", "etiqueta de X: Centro con balón, Barrida sin balón")
	_comprobar(c.etiqueta_de("Y", true) == "Al hueco" and c.etiqueta_de("Y", false) == "", "«Al hueco» sin balón se apaga")
	_comprobar(c.etiqueta_de("Sprint", true) == "Sprint", "los botones sin contexto conservan su etiqueta")
	## Ajustes: tamaño y opacidad (se leen al crear el control) y cuándo salen.
	c.soltar_todo()
	c.queue_free()
	AjustesTactil.restaurar()
	_comprobar(AjustesTactil.modo() == "auto" and absf(AjustesTactil.tamano() - 1.0) < 0.001 and absf(AjustesTactil.opacidad() - 1.0) < 0.001, "por defecto: automático, tamaño 100 %, opacidad 100 %")
	AjustesTactil.poner_tamano(1.4)
	AjustesTactil.poner_opacidad(0.4)
	var g := ControlesTactiles.poner(self)
	_comprobar(g != null and absf(g.esc - 1.4) < 0.001 and absf(g.opac - 0.4) < 0.001, "el tamaño (140 %) y la opacidad (40 %) elegidos llegan a los controles")
	g.size = Vector2(1280, 720)
	_comprobar(g.radio_boton() * 2.0 >= 64.0, "los botones miden más de 64 px (%d)" % int(g.radio_boton() * 2.0))
	g.size = Vector2(960, 480)
	_comprobar(g.radio_boton() <= ControlesTactiles.RADIO_BOTON + 0.01, "en una pantalla baja el tamaño no pasa de lo que cabe (radio %d)" % int(g.radio_boton()))
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

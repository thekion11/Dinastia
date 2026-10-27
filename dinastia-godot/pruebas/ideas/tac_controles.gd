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
	var nombres := {"A": "jugar_pase", "B": "jugar_tiro", "X": "jugar_centro", "Y": "jugar_filtrado", "Cambiar": "jugar_cambiar", "Sprint": "jugar_sprint"}
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
	## Todos los botones caben en pantalla de 1280×720 y de móvil (800×360) sin pisarse.
	for tam: Vector2 in [Vector2(1280, 720), Vector2(960, 480)]:
		c.size = tam
		var ok := true
		var ns: Array = nombres.keys()
		for i in ns.size():
			var p := c.centro_de(String(ns[i]))
			if p.x < ControlesTactiles.RADIO_BOTON or p.y < ControlesTactiles.RADIO_BOTON or p.x > tam.x or p.y > tam.y:
				ok = false
			for j in range(i + 1, ns.size()):
				if p.distance_to(c.centro_de(String(ns[j]))) < ControlesTactiles.RADIO_BOTON * 1.9:
					ok = false
		_comprobar(ok, "en %d×%d los botones caben y no se pisan" % [int(tam.x), int(tam.y)])
	c.soltar_todo()
	c.queue_free()
	ControlesTactiles.forzar = false

class_name RutaGala
extends RefCounted
## LA ENTREGA EN 3D DENTRO DEL CIERRE DE TEMPORADA (13-11-2026): una ventana con la ceremonia del premio elegido
## (`GalaPremio3D`) o el festejo del título (`FestejoCampo3D`), y debajo un botón por cada premio y cada trofeo del
## año para verlos de uno en uno. Solo hay UNA escena 3D viva. Las clases 3D se cargan con `load` (no se nombran:
## así el menú no las compila). Se ve en TODAS las calidades (en la mínima: sin sombras, menos
## compañeros y, para los títulos, tú solo con la copa); sin pantalla no se monta nada (devuelve null).

const E := preload("res://ui/carrera/ruta_estilo.gd")
const FESTEJO_DE := {"liga": "escenario", "copa": "palco", "continental": "fuegos", "otro": "foto"}

static func vista(ui: Variant, t: Dictionary) -> Control:
	var festejo: Variant = load("res://visor/festejo_campo3d.gd")
	var premios: Array = t.get("premios", []) if t.get("premios") is Array else []
	var copas: Array = t.get("trofeos", []) if t.get("trofeos") is Array else []
	var c: CarreraJugador = ui.carrera
	var m: Mundo = ui.mundo
	var club := c.club(m)
	var j := c.jugador(m)
	if DisplayServer.get_name() == "headless" or club == null or j == null or (premios.is_empty() and copas.is_empty()):
		return null
	var liga := CarreraRuta._liga_de(m, club)
	var datos := {"jugador": j, "club": club, "liga": liga.nombre if liga != null else "", "pais": liga.pais if liga != null else club.pais, "mundo": m}
	var v := E.columna(6)
	var marco := PanelContainer.new()
	marco.add_theme_stylebox_override("panel", E.caja(Color(0.01, 0.01, 0.03), 14, Color(E.ORO, 0.5), 2))
	marco.custom_minimum_size = Vector2(0, 220 if E.estrecho(ui) else 320)
	marco.clip_contents = true
	v.add_child(marco)
	var botones := E.flujo(6)
	v.add_child(botones)
	var grupo := ButtonGroup.new()
	## Lo más grande primero: los títulos, y los premios por la experiencia que dan.
	var orden: Array = premios.duplicate()
	orden.sort_custom(func(x: Variant, y: Variant) -> bool:
		return int(CarreraPremios.PREMIOS.get(String(x), ["", "", 0])[2]) > int(CarreraPremios.PREMIOS.get(String(y), ["", "", 0])[2]))
	var primero := true
	for tr: Variant in copas:
		var nombre := String((tr as Dictionary).get("nombre", ""))
		var modo := String(FESTEJO_DE.get(String((tr as Dictionary).get("clase", "otro")), "escenario"))
		var clase := String((tr as Dictionary).get("clase", "otro"))
		## Con calidad para ello, el festejo del equipo entero; en la mínima, tú con la copa (más ligero).
		var poner_t := func() -> void: _poner(marco, festejo.crear(modo, club, nombre) if festejo.con_3d() else
			load("res://visor/gala_premio3d.gd").crear_gala("trofeo_" + clase, datos.merged({"titulo": nombre})))
		botones.add_child(E.opcion("🏆 " + Nombres.visible(nombre), E.ORO, grupo, primero, poner_t, 32))
		if primero:
			poner_t.call()
		primero = false
	for id: Variant in orden:
		if not CarreraPremios.PREMIOS.has(String(id)):
			continue
		var poner_p := func() -> void: _poner(marco, load("res://visor/gala_premio3d.gd").crear_gala(String(id), datos))
		botones.add_child(E.opcion("🏅 " + Idiomas.t(String(CarreraPremios.PREMIOS[String(id)][0])), E.ORO, grupo, primero, poner_p, 32))
		if primero:
			poner_p.call()
		primero = false
	return v

## Cambia la escena de la ventana (la anterior se libera).
static func _poner(marco: PanelContainer, escena: Variant) -> void:
	for h: Node in marco.get_children():
		h.queue_free()
	if escena is Control:
		(escena as Control).custom_minimum_size = Vector2(0, marco.custom_minimum_size.y)
		(escena as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		marco.add_child(escena)
		E.son("premio_individual")

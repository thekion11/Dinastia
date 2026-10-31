extends BaseIdea
## s3 (26-10-2026): PRESUPUESTO DE CLICS Y ATAJOS DEL MENÚ CENTRAL (plan §11 filas 1-2).
## Las diez tareas más frecuentes de un manager tienen que estar a ≤ 2 clics desde la pantalla de
## inicio O a una tecla. Los clics se cuentan con la estructura real de los menús: un chip del bloque
## abierto = 1; un chip de otro bloque (barra de arriba o riel lateral) = 2; una pestaña de hub
## (⚽ 💰 de la cabecera o el enlace de la columna) = 2. Y cada atajo se pulsa de verdad.
var _p: Principal
## [tarea, pestaña, sección, acción del atajo]
const TAREAS := [
	["Ver el plantel", "Mi plantel", "", "dinastia_ir_plantel"],
	["Poner el once", "Táctica", "", "dinastia_ir_tactica"],
	["Entrenar", "Entrenar", "", "dinastia_ir_entrenar"],
	["Fichar", "Mercado", "", "dinastia_ir_mercado"],
	["Renovar", "Contratos", "", "dinastia_ir_contratos"],
	["Mirar las cuentas", "Finanzas", "", "dinastia_ir_finanzas"],
	["Ver el calendario", "Calendario", "", "dinastia_ir_calendario"],
	["Leer el correo", "Correo", "", "dinastia_ir_correo"],
	["Atender a la prensa", "Redes", "prensa", "dinastia_ir_prensa"],
	["Volver al inicio", "Inicio", "", "dinastia_ir_inicio"],
]

func _ready() -> void:
	await get_tree().process_frame
	_titulo("S3: PRESUPUESTO DE CLICS Y ATAJOS DEL MENÚ CENTRAL")
	var m := Mundo.new()
	m.generar([], 20261026)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	PedidoPartida.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 4:
		await get_tree().process_frame
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	TeclasInterfaz.restaurar()
	var caras: Array[String] = []
	for t: Array in TAREAS:
		var c := _clics(String(t[1]), String(t[2]))
		caras.append("%s %d" % [t[0], c])
		_comprobar(c <= 2, "«%s» a %d clic%s desde el inicio" % [t[0], c, "" if c == 1 else "s"])
	_linea("  clics: " + ", ".join(caras))
	for t: Array in TAREAS:
		_p._ir_a_chip({"tab": "Glosario", "label": "Glosario"})
		await get_tree().process_frame
		var ev := _tecla(String(t[3]))
		var hizo := AtajosCentrales.manejar(_p, ev)
		await get_tree().process_frame
		var titulo := _p._pestanas.get_tab_title(_p._pestanas.current_tab)
		var ok := hizo and titulo == String(t[1]) and (String(t[2]) == "" or _p._seccion_activa({"tab": t[1], "secc": t[2]}))
		_comprobar(ok, "la tecla %s lleva a «%s» (%s)" % [TeclasInterfaz.texto_de(String(t[3])), t[0], titulo])
	## N pasa un día.
	var dia_antes: int = _p.get("_dia_semana")
	var sem_antes := _p.mundo.semana
	AtajosCentrales.manejar(_p, _tecla("dinastia_un_dia"))
	_comprobar(int(_p.get("_dia_semana")) != dia_antes or _p.mundo.semana != sem_antes, "N pasa un día")
	## F3 lleva al buscador, y escribiendo en él los números son números, no atajos.
	AtajosCentrales.manejar(_p, _tecla("dinastia_buscar"))
	await get_tree().process_frame
	var b: LineEdit = _p.get("_buscador")
	_comprobar(b.has_focus(), "F3 pone el cursor en el buscador")
	_comprobar(not AtajosCentrales.manejar(_p, _tecla("dinastia_ir_plantel")), "con el cursor en un campo de texto, «2» se escribe y no salta de pestaña")
	b.release_focus()
	## Se reasignan como las demás teclas de la interfaz.
	var f8 := InputEventKey.new()
	f8.physical_keycode = KEY_F8
	f8.pressed = true
	TeclasInterfaz.reasignar("dinastia_ir_mercado", f8)
	_p._ir_a_chip({"tab": "Glosario", "label": "Glosario"})
	_comprobar(AtajosCentrales.manejar(_p, f8) and _p._pestanas.get_tab_title(_p._pestanas.current_tab) == "Mercado",
		"reasignado a F8, el atajo del mercado responde a F8")
	TeclasInterfaz.restaurar()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _tecla(accion: String) -> InputEventKey:
	var ev := InputEventKey.new()
	for e: InputEvent in InputMap.action_get_events(accion):
		if e is InputEventKey:
			ev.physical_keycode = (e as InputEventKey).physical_keycode
			ev.keycode = (e as InputEventKey).keycode
	ev.pressed = true
	return ev

## Clics desde el inicio (bloque central abierto) hasta la pestaña `tab` (sección `secc`).
func _clics(tab: String, secc: String) -> int:
	for g: Dictionary in Principal.GRUPOS:
		for ch: Dictionary in g["tabs"]:
			if String(ch["tab"]) == tab and String(ch.get("secc", "")) == secc:
				## Del bloque abierto: un chip. De otro: su bloque (barra o riel) y el chip.
				return 1 if String(g["id"]) == "central" else 2
	for h: String in Principal.HUBS:
		if (Principal.HUBS[h]["tabs"] as Array).has(tab):
			return 2
	return 99

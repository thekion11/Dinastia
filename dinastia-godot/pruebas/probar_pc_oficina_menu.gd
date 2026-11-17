extends Node
## EL MENÚ CENTRAL DENTRO DEL PC DE LA OFICINA (17-11-2026, guion filas 6 y 9): `PcOficina.encender` abre el menú como capa sobre el mundo 3D congelado; la barra nueva deja el extremo derecho libre
## para «Levantarse del PC» (la caja y los botones no quedan tapados) y NO enseña «Entrar al club» (ni el riel lo abre: desde el PC no se abre otro estadio); se navega por la barra lateral;
## Esc (o el botón) levanta: el mundo 3D se descongela, vuelve el explorador, y la partida se AUTOGUARDA al levantarse. Con pantalla (xvfb, `herramientas/especiales.sh`).

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func _frames(n := 4) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	AvanceDiasUI.sin_pantalla = true
	JornadaEventos._abierto = true
	var m := Mundo.new()
	var ps: Array[String] = ["ESP"]
	m.generar(ps, 20261117)
	m.tomar_el_mando(m.ligas[0].clubes[4].id)
	PedidoPartida.mundo_pregenerado = m
	PedidoPartida.modo_elegido = "dt"
	PedidoPartida.dt_nombre_elegido = "Prueba"
	PedidoPartida.dificultad_elegida = "normal"
	PedidoPartida.aplicado_a = 0
	var mundo3d := Node3D.new()
	add_child(mundo3d)
	var explorador := Node3D.new()
	add_child(explorador)
	var pc := PcOficina.new()
	pc.mundo = m
	pc.mundo_3d = mundo3d
	pc.explorador = explorador
	add_child(pc)
	pc.encender()
	await _frames(12)
	var pr: Principal = pc.principal() as Principal
	_ok(pr != null and pc.abierto, "el PC enciende el menú central como capa")
	if pr == null:
		print("FIN. %d fallos" % fallos)
		get_tree().quit()
		return
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	await _frames(6)
	_ok(not mundo3d.visible and explorador.process_mode == Node.PROCESS_MODE_DISABLED, "con el PC encendido el mundo 3D está escondido y el explorador congelado")
	var pant := pr.get_meta("escaparate") as EscaparatePantalla
	var barra: Node = pant.find_child("Botones", true, false)
	_ok(EscaparateBarra.pc_de(pr) == pc, "el menú sabe que es la capa del PC")
	_ok(barra.find_child("HuecoLevantarse", true, false) != null, "la barra deja el hueco fijo del extremo derecho para «Levantarse del PC»")
	_ok(barra.find_child("BotonEntrarClub", true, false) == null, "dentro del PC no hay «Entrar al club» (no se abre otro estadio)")
	_ok(not (pr._menu_lateral.find_children("*", "Button", true, false).any(func(b: Node) -> bool: return (b as Button).tooltip_text == Idiomas.t("Entrar al club") and (b as Button).visible)), "el riel tampoco ofrece «Entrar al club» desde el PC")
	var levantarse: Button = null
	for b in pc.find_children("*", "Button", true, false):
		if (b as Button).text == Idiomas.t("Levantarse del PC"):
			levantarse = b as Button
	_ok(levantarse != null and levantarse.icon != null, "«Levantarse del PC» existe con icono dibujado (no emoji)")
	if levantarse != null:
		var caja: Button = null
		for b in barra.find_children("*", "Button", true, false):
			if (b as Button).tooltip_text == Idiomas.t("Cuentas del club"):
				caja = b as Button
		_ok(caja != null and not caja.get_global_rect().intersects(levantarse.get_global_rect()), "la capa nueva no se tapa con «Levantarse del PC» (la caja queda libre)")
		_ok(levantarse.focus_mode == Control.FOCUS_ALL, "«Levantarse del PC» recibe el foco del mando")
	## navegar: un menú del riel y de vuelta
	pr._menu_lateral.abrir_menu("plantel", 0)
	await _frames(6)
	_ok(pr._menu_lateral.pantalla_abierta != null, "se navega por la barra lateral dentro del PC")
	pr._menu_lateral.pantalla_abierta.cerrar()
	await _frames(6)
	## guardado al levantarse
	pr._partida.ranura_prueba = "prueba_pc_guardado"
	pr._autoguardado = true
	var ruta := Partida.ruta_de(Partida.ranura_para(pr.mundo, "prueba_pc_guardado"))
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ruta)
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(4)
	_ok(not pc.abierto, "Esc levanta del PC")
	_ok(mundo3d.visible and explorador.process_mode == Node.PROCESS_MODE_INHERIT, "al levantarse el mundo 3D se descongela y el explorador vuelve a moverse")
	var espera := 0
	while not FileAccess.file_exists(ruta) and espera < 120:
		await _frames(5)
		espera += 1
	_ok(FileAccess.file_exists(ruta), "al levantarse la partida queda AUTOGUARDADA (%s)" % ruta)
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ruta)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()

extends Control
## CAPTURAS Y CLICS REALES de crear personaje / crear partida (2-11-2026).
##   QUE=personaje  herramientas/captura.sh res://pruebas/fcp_captura.tscn
##   QUE=mascota | equipacion | prologo
## Los clics se mandan como eventos de ratón al viewport (el mismo camino que un jugador).
var _que := "personaje"
var _m: Mundo
var _nodo: Control

func _ready() -> void:
	_que = OS.get_environment("QUE") if OS.get_environment("QUE") != "" else "personaje"
	_m = Mundo.new()
	_m.generar(["CHI"], 77)
	_m.tomar_el_mando(_m.ligas[0].clubes[0].id)
	_correr.call_deferred()

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/fcp_%s_%s.png" % [_que, nombre])

func _esperar_s(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame

func _clic(c: Control) -> void:
	var p := get_window().get_final_transform() * c.get_global_rect().get_center()
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	Input.parse_input_event(mv)
	await get_tree().process_frame
	for abajo in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = abajo
		ev.position = p
		ev.global_position = p
		Input.parse_input_event(ev)
		await get_tree().process_frame

func _boton(raiz: Node, texto: String) -> Button:
	for n in raiz.find_children("*", "Button", true, false):
		var b := n as Button
		if b.text == texto and b.is_visible_in_tree():
			return b
	return null

func _correr() -> void:
	match _que:
		"personaje": await _personaje()
		"mascota": await _mascota()
		"equipacion": await _equipacion()
		"carga": await _carga()
		"escudo": await _escudos()
	get_tree().quit()

func _personaje() -> void:
	var tb := Button.new()
	tb.text = "prueba"
	tb.position = Vector2(700, 800)
	tb.size = Vector2(100, 40)
	tb.z_index = 100
	var cuenta := [0]
	tb.pressed.connect(func() -> void: cuenta[0] += 1)
	add_child(tb)
	await _esperar_s(0.3)
	await _clic(tb)
	print("botón de control pulsado: ", cuenta[0])
	tb.queue_free()
	var p := PantallaPersonaje.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.configurar({"modo": "dt", "pais": "ARG", "club": _m.mi_club(), "paso": 6})
	add_child(p)
	_nodo = p
	await _esperar_s(1.0)
	var hojas: HojasPersonaje = p.get("_hojas")
	var sig := _boton(p, Idiomas.t("Siguiente: datos →"))
	await _clic(sig)
	await _esperar_s(0.3)
	print("sección tras clic en Siguiente: ", p.get("_seccion"))
	await _clic(_boton(p, "1  ·  " + Idiomas.t("Aspecto")))
	await _esperar_s(0.3)
	print("sección tras clic en Aspecto: ", p.get("_seccion"))
	hojas.current_tab = 1
	await _esperar_s(0.4)
	for k in 4:
		var b := _boton(hojas, "▶")
		print("clic ▶ cara/corte ", k, " -> ", b)
		if b != null:
			await _clic(b)
		await _esperar_s(0.8)
		print("  cara=", hojas.asp.get("cara"), " corte=", hojas.asp.get("corte_med"))
	await _foto("cara")
	for ped in ["Rizado", "Afro", "Largo suelto", "Calvo"]:
		var b := _boton(hojas, ped)
		print("  chip ", ped, " -> ", b, " disabled=", b.disabled if b else "-", " rect=", b.get_global_rect() if b else "-")
		if b != null:
			await _clic(b)
		await _esperar_s(0.8)
		print("  peinado ", ped, " -> ", hojas.asp.get("pelo"))
	hojas.current_tab = 2
	await _esperar_s(0.4)
	for r in PersonajeDT.ROPAS:
		var b := _boton(hojas, Idiomas.t(String(r[1])))
		if b != null:
			await _clic(b)
		await _esperar_s(0.8)
		print("  ropa ", r[0], " -> ", hojas.asp.get("ropa"))
	await _foto("ropa")

func _mascota() -> void:
	var p := PantallaConfigClub.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.configurar({"mundo": _m, "modo": "creador"})
	add_child(p)
	await _esperar_s(0.6)
	p.ir_a(3)
	await _esperar_s(1.5)
	for an in ["oso", "gato", "aguila", "dragon"]:
		p.datos.mascota = an
		p._vista_mascota.call("mostrar", p.datos.club, an)
		await _esperar_s(1.5)
		var mv = p._vista_mascota
		var mm: Node3D = mv._masc
		var esq := mm.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		print(an, " masc=", mm.global_position, " escala=", mm.scale, " pivote_rot=", mv._pivote.rotation, " cabeza=", (esq.global_transform * esq.get_bone_global_pose(esq.find_bone("Head"))).origin, " size=", mv.size)
		await _foto(an)

func _equipacion() -> void:
	var p := PantallaConfigClub.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.configurar({"mundo": _m, "modo": "creador"})
	add_child(p)
	await _esperar_s(0.6)
	p.ir_a(2)
	await _esperar_s(2.0)
	await _foto("paso_equipacion")
	var dz: DisenadorKit = null
	for n in p.find_children("*", "Control", true, false):
		if n is DisenadorKit:
			dz = n
	print("diseñador incrustado: ", dz)
	if dz != null:
		for r in 3:
			dz._aleatorio()
			await _esperar_s(1.5)
			await _foto("aleatorio%d" % r)
		print("kit_x del club tras Aleatorio: ", p.datos.club.kit_x.keys())
		await _foto("paso_equipacion_aleatorio")

func _carga() -> void:
	PantallaCarga.club = _m.mi_club()
	PantallaCarga.mostrar(self, Idiomas.t("Construyendo la ciudad…"))
	await _esperar_s(1.2)
	await _foto("a")
	await _esperar_s(5.0)
	await _foto("b")

func _escudos() -> void:
	var x := 20.0
	for sim in ["", "🦅", "⚽", "⭐", "🔱"]:
		var c := _m.mi_club()
		c.esc_simbolo = sim
		c.esc_forma = "clasico"
		Escudo.limpiar_cache()
		var t := TextureRect.new()
		t.texture = EscudoTexto.textura(c, 160)
		t.position = Vector2(x, 20)
		t.custom_minimum_size = Vector2(160, 160)
		add_child(t)
		x += 190.0
	await _esperar_s(0.5)
	await _foto("simbolos")

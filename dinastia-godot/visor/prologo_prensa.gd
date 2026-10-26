class_name PrologoPrensa
extends CanvasLayer
## LA RUEDA DE PRENSA DE PRESENTACIÓN (fase 2 del plan del lunes, 26-10-2026).
##
## Tres preguntas al DT recién llegado, en el plató 3D de siempre
## (`RuedaPrensaEscena3D`), y tres TONOS para contestar: seguro, evasivo o
## humilde. No inventa reglas nuevas de prensa: cada tono mueve la relación con
## los cinco periodistas (`Prensa._mover_relacion`) como ya hace la rueda de
## prensa semanal, y el DT gesticula en el plató al responder. Al terminar,
## `terminado` con el resumen (cuántas veces cada tono).

signal terminado(resumen: Dictionary)

var mundo: Mundo
var _escena: RuedaPrensaEscena3D
var _panel: PanelContainer
var _medio: Label
var _pregunta: Label
var _botones: VBoxContainer
var _i := 0
var _tonos: Array[String] = []

func montar(m: Mundo, club: Club, acento: Color, look_dt: Dictionary) -> void:
	mundo = m
	layer = 48
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(raiz)
	var vpc := SubViewportContainer.new()
	vpc.stretch = true
	vpc.set_anchors_preset(Control.PRESET_FULL_RECT)
	vpc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(vpc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vpc.add_child(vp)
	_escena = RuedaPrensaEscena3D.new()
	vp.add_child(_escena)
	var clubes: Array = []
	var liga := m.liga_de(club) if m != null and club != null else null
	if liga != null:
		clubes = liga.clubes
	_escena.montar(club, acento, Calidad.ALTO, look_dt, clubes, {"presentacion": true})
	## Cabecera: qué es esto.
	var cab := CuadroDialogo.placa(Idiomas.t("RUEDA DE PRENSA DE PRESENTACIÓN"), acento)
	cab.set_anchors_preset(Control.PRESET_TOP_LEFT)
	cab.offset_left = 24
	cab.offset_top = 18
	raiz.add_child(cab)
	## El cuadro de abajo: medio, pregunta y los tres tonos.
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 120
	_panel.offset_right = -120
	_panel.offset_top = -300
	_panel.offset_bottom = -28
	raiz.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_panel.add_child(v)
	_medio = Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, "")
	v.add_child(_medio)
	_pregunta = Tema.etiqueta(Tema.TAM_TITULO, Tema.TEXTO, "")
	_pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_pregunta)
	_botones = VBoxContainer.new()
	_botones.add_theme_constant_override("separation", 6)
	v.add_child(_botones)
	_pintar()

func _pintar() -> void:
	for h in _botones.get_children():
		_botones.remove_child(h)
		h.queue_free()
	if _i >= PrologoPasos.PREGUNTAS_PRENSA.size():
		_resumen()
		return
	var q: Dictionary = PrologoPasos.PREGUNTAS_PRENSA[_i]
	_medio.text = "%s · %d/%d" % [String(q["medio"]), _i + 1, PrologoPasos.PREGUNTAS_PRENSA.size()]
	_pregunta.text = Idiomas.t(String(q["pregunta"]))
	_escena.enfocar_periodista(String(q["medio"]))
	var primero: Button = null
	for t: Dictionary in PrologoPasos.TONOS:
		var clave := String(t["clave"])
		var b := Button.new()
		b.text = "%s  ·  %s" % [Idiomas.t(String(t["nombre"])), Idiomas.t(String((q["respuestas"] as Dictionary)[clave]))]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 40)
		CuadroDialogo.respuesta(b)
		b.pressed.connect(_responder.bind(clave, int(t["relacion"])))
		_botones.add_child(b)
		if primero == null:
			primero = b
	if primero != null:
		FocoSeguro.dar(primero)

func _responder(tono: String, d: int) -> void:
	_tonos.append(tono)
	## El DT gesticula ahora mismo en el plató (el reloj del gesto salta a cero).
	_escena._t_gesto_dt = 0.0
	## Lo que opina la prensa: el mismo mecanismo que la rueda semanal.
	if mundo != null and mundo.prensa != null:
		for f: Array in Prensa.PERIODISTAS:
			mundo.prensa._mover_relacion(String(f[0]), d)
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	_i += 1
	_pintar()

func _resumen() -> void:
	var cuenta := {}
	for t: String in _tonos:
		cuenta[t] = int(cuenta.get(t, 0)) + 1
	var dominante := ""
	for k: String in cuenta:
		if dominante == "" or int(cuenta[k]) > int(cuenta[dominante]):
			dominante = k
	_medio.text = Idiomas.t("FIN DE LA PRESENTACIÓN")
	var textos := {
		"seguro": "Titulares de mañana: «Llega con hambre». La prensa te concede el beneficio de la duda.",
		"evasivo": "Titulares de mañana: «Mucho ruido y pocas respuestas». Te costará ganártelos.",
		"humilde": "Titulares de mañana: «Perfil bajo y los pies en el suelo». Les caíste bien; ahora toca ganar.",
	}
	var texto: String = String(textos.get(dominante, "La prensa toma nota. Mañana lo leerás."))
	_pregunta.text = Idiomas.t(texto)
	var b := Button.new()
	b.text = Idiomas.t("Salir de la sala de prensa")
	b.custom_minimum_size = Vector2(0, 44)
	CuadroDialogo.respuesta(b)
	b.pressed.connect(func() -> void:
		terminado.emit({"tonos": cuenta, "dominante": dominante})
		queue_free())
	_botones.add_child(b)
	FocoSeguro.dar(b)

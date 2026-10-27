extends "res://ui/principal_p8.gd"
## [Capa 9/17 de `principal.gd`] _origen_de, _traducir_pantalla, _refrescar, _avanzar_semana, _avanzar_dia, _pintar_dias … (+2)

## LA MÚSICA. Seis piezas sintetizadas, como todo el audio del juego: ni un solo
## fichero, ni una licencia de terceros que arrastrar en el paquete.
##
## Va aparte del mezclador de efectos a propósito. La música se apaga entera
## mucho más a menudo que los efectos —hay gente que juega a esto con un podcast
## de fondo—, y tenerla en el mismo grupo obligaba a bajar el silbato para no oír
## el arpegio.
## RECORRE LA PANTALLA Y TRADUCE. Ver la explicación larga en `nucleo/idiomas.gd`.
##
## Solo toca `Label`, `Button` y `OptionButton`, que es donde vive el esqueleto
## de la interfaz. NO toca `RichTextLabel` -ahí va la narración, que sigue en
## castellano- ni `LineEdit` -ahí escribe el usuario-.
##
## Guarda en metadatos del propio nodo el texto castellano original (`_i18n_src`)
## y lo último que ESTA función escribió (`_i18n_out`): si el texto actual
## coincide con lo último que ella misma puso, nadie lo tocó desde entonces y
## usa el castellano guardado como fuente; si NO coincide, es que un repintado
## puso texto castellano fresco (nombre de jugador, cifra...) y lo adopta como
## la nueva fuente. SIN esto, un nodo que se construye UNA sola vez y nunca se
## repinta -"Guardar"/"Cargar"/"Otro mundo" de la fila de acciones, tooltips-
## se quedaba pegado en el último idioma elegido para siempre, sin volver al
## castellano al cambiar de vuelta: bug real, sospechado el 10-9-2026 en una
## captura ("Save"/"Load"/"New world" seguían en inglés tras forzar `idioma="es"`)
## y confirmado y corregido aquí el 12-9-2026.
## Un texto sin castellano guardado: si es la traducción de una clave (se pintó ya
## traducido en otro idioma), su clave; si no, tal cual (s3, cambio de idioma).
func _origen_de(texto: String) -> String:
	var o := Idiomas.origen(texto)
	return o if o != "" else texto

func _traducir_pantalla(n: Node) -> void:
	if n == self:
		if Idiomas.idioma == "es" and not _traduccion_activa:
			return
		if Idiomas.idioma != "es":
			_traduccion_activa = true
	if n is Label:
		var l := n as Label
		var actual := l.text
		var fue_mio: bool = l.has_meta("_i18n_out") and String(l.get_meta("_i18n_out")) == actual
		var base: String = String(l.get_meta("_i18n_src")) if fue_mio else _origen_de(actual)
		var nuevo := base if Idiomas.idioma == "es" else Idiomas.t(base)
		l.set_meta("_i18n_src", base)
		l.set_meta("_i18n_out", nuevo)
		l.text = nuevo
	elif n is OptionButton:
		## El desplegable, por dentro: cada entrada por separado. El texto del
		## botón lo pinta Godot con la entrada elegida, así que no hay que tocarlo.
		var ob := n as OptionButton
		var outs: Array = ob.get_meta("_i18n_out") if ob.has_meta("_i18n_out") else []
		var srcs: Array = ob.get_meta("_i18n_src") if ob.has_meta("_i18n_src") else []
		var nuevos_src: Array = []
		var nuevos_out: Array = []
		for i in ob.item_count:
			var actual_i := ob.get_item_text(i)
			var fue_mio_i: bool = i < outs.size() and String(outs[i]) == actual_i
			var base_i: String = String(srcs[i]) if (fue_mio_i and i < srcs.size()) else actual_i
			var nuevo_i := base_i if Idiomas.idioma == "es" else Idiomas.t(base_i)
			ob.set_item_text(i, nuevo_i)
			nuevos_src.append(base_i)
			nuevos_out.append(nuevo_i)
		ob.set_meta("_i18n_src", nuevos_src)
		ob.set_meta("_i18n_out", nuevos_out)
	elif n is Button:
		var b := n as Button
		var actual2 := b.text
		var fue_mio2: bool = b.has_meta("_i18n_out") and String(b.get_meta("_i18n_out")) == actual2
		var base2: String = String(b.get_meta("_i18n_src")) if fue_mio2 else _origen_de(actual2)
		var nuevo2 := base2 if Idiomas.idioma == "es" else Idiomas.t(base2)
		b.set_meta("_i18n_src", base2)
		b.set_meta("_i18n_out", nuevo2)
		## Si el boton repartia ancho por el largo de su rotulo -la fila de
		## acciones-, el reparto se rehace con el rotulo NUEVO: "Temporada
		## siguiente" y "Next season" no piden lo mismo.
		if nuevo2 != actual2 and b.size_flags_stretch_ratio != 1.0:
			b.size_flags_stretch_ratio = clampf(float(nuevo2.length()) / 12.0, 0.95, 1.9)
		b.text = nuevo2
	elif n is LineEdit:
		## El texto de ayuda del campo ("🔎 Buscar..."), no lo que escribe el jugador.
		var le := n as LineEdit
		var actual_ph := le.placeholder_text
		if actual_ph != "":
			var fue_mio_ph: bool = le.has_meta("_i18n_ph_out") and String(le.get_meta("_i18n_ph_out")) == actual_ph
			var base_ph: String = String(le.get_meta("_i18n_ph_src")) if fue_mio_ph else actual_ph
			var nuevo_ph := base_ph if Idiomas.idioma == "es" else Idiomas.t(base_ph)
			le.set_meta("_i18n_ph_src", base_ph)
			le.set_meta("_i18n_ph_out", nuevo_ph)
			le.placeholder_text = nuevo_ph
	if n.has_method("get_tooltip_text") and n is Control:
		var ctrl := n as Control
		var actual_tip := ctrl.tooltip_text
		if actual_tip != "":
			var fue_mio_tip: bool = ctrl.has_meta("_i18n_tip_out") and String(ctrl.get_meta("_i18n_tip_out")) == actual_tip
			var base_tip: String = String(ctrl.get_meta("_i18n_tip_src")) if fue_mio_tip else _origen_de(actual_tip)
			var nuevo_tip := base_tip if Idiomas.idioma == "es" else Idiomas.t(base_tip)
			ctrl.set_meta("_i18n_tip_src", base_tip)
			ctrl.set_meta("_i18n_tip_out", nuevo_tip)
			ctrl.tooltip_text = nuevo_tip
	for h in n.get_children():
		_traducir_pantalla(h)

## Puentes (fase 6, paso 7): viven en `AvanceSemana`.
func _refrescar() -> void: _avance._refrescar()
func _avanzar_semana() -> void: _avance._avanzar_semana()
func _avanzar_dia() -> void: _avance._avanzar_dia()
func _pintar_dias() -> void: _avance._pintar_dias()





## AL CERRAR (etapa 1, 8-10-2026): las referencias estáticas a la partida
## (el contexto del edificio del club, la Carrera de Jugador, el último mundo)
## sobrevivían al cierre y el motor avisaba de objetos sin liberar.
func _exit_tree() -> void:
	EdificioClub.ctx = {}
	EdificioClub.mundo_ref = null
	CarreraJugadorUI.mundo = null
	Trabajadores.actual = null
	Partido.ctx_medico = null
	mundo_a_cargar = null
	mundo_pregenerado = null

func _preparar_mando() -> void:
	for par: Array in MANDO_BOTONES:
		var accion := String(par[0])
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		var ev := InputEventJoypadButton.new()
		ev.button_index = par[1]
		if not InputMap.action_has_event(accion, ev):
			InputMap.action_add_event(accion, ev)
	## El stick izquierdo, además de la cruceta: en un mando moderno la gente
	## usa el stick y se queda mirando por qué no pasa nada.
	for eje: Array in [["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0],
			["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0]]:
		var ev2 := InputEventJoypadMotion.new()
		ev2.axis = eje[1]
		ev2.axis_value = eje[2]
		if not InputMap.action_has_event(String(eje[0]), ev2):
			InputMap.action_add_event(String(eje[0]), ev2)
	for par2: Array in MANDO_PESTANAS:
		var accion2 := String(par2[0])
		if not InputMap.has_action(accion2):
			InputMap.add_action(accion2)
		var eb := InputEventJoypadButton.new()
		eb.button_index = par2[1]
		if not InputMap.action_has_event(accion2, eb):
			InputMap.action_add_event(accion2, eb)
		var et := InputEventKey.new()
		et.keycode = par2[2]
		if not InputMap.action_has_event(accion2, et):
			InputMap.action_add_event(accion2, et)
	for par3: Array in MANDO_BLOQUES:
		var accion3 := String(par3[0])
		if not InputMap.has_action(accion3):
			InputMap.add_action(accion3)
		var ea := InputEventJoypadMotion.new()
		ea.axis = par3[1]
		ea.axis_value = 1.0
		if not InputMap.action_has_event(accion3, ea):
			InputMap.action_add_event(accion3, ea)
	## Los atajos del menú central y las teclas que el jugador reasignó en
	## Ajustes → Accesibilidad (s3).
	AtajosCentrales.registrar()
	TeclasInterfaz.aplicar()

extends RefCounted
## (Parte 1 de 2 de `pantalla_despacho.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `pantalla_despacho.gd`, conserva la clase.)

## EL DESPACHO: lo que hay que resolver ahora (asuntos, decisiones, la junta, el agente) y la rueda de prensa a pantalla completa.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _marco_aviso(color: Color) -> VBoxContainer:
	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	## EL AVISO, CON MÁS VIDA (10-9-2026, pedido del usuario: "las
	## notificaciones deben ser mejores visualmente"). Tres cambios sobre el
	## marco plano de antes:
	##  · el fondo se tiñe UN POCO del color del aviso -un 8%-, así una
	##    decisión urgente se distingue de una rueda de prensa sin leer nada;
	##  · la barra lateral pasa de 4 a 6 px y las esquinas se redondean más,
	##    para que combine con las píldoras del menú nuevo;
	##  · entra con un desliz corto desde la izquierda, que es lo que hace
	##    que se note que ACABA de aparecer y no que estaba ahí desde antes.
	e.bg_color = p._mezcla(p._pal_panel(), color, 0.08)
	e.border_color = color
	e.set_border_width_all(1)
	e.border_width_left = 6
	e.set_corner_radius_all(10)
	e.content_margin_left = 14
	e.content_margin_right = 14
	e.content_margin_top = 10
	e.content_margin_bottom = 10
	e.shadow_color = Color(0, 0, 0, 0.25)
	e.shadow_size = 4
	caja.add_theme_stylebox_override("panel", e)
	p._despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	caja.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(caja, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	## Las respuestas del aviso, con el estilo de los diálogos (13-10-2026);
	## diferido: los botones se añaden después de este marco.
	(func() -> void:
		if is_instance_valid(caja):
			for b in caja.find_children("*", "Button", true, false):
				CuadroDialogo.respuesta(b as Button)).call_deferred()
	return v

func _aceptar_trabajo(club_id: String) -> void:
	var problema := p.mundo.roles.aceptar_trabajo(club_id)
	if problema != "":
		p._escribir("[color=#e05555]%s.[/color]" % problema)
	p._refrescar()

## Los clubes que te quieren después de un despido. `ofertas_trabajo()` garantiza
## que SIEMPRE haya al menos uno -por hundido que esté tu prestigio-, así que
## esta pantalla nunca deja al jugador sin salida; por eso puede permitirse ser
## la que tapa a todas las demás.
func _pintar_sin_banco() -> void:
	var r := p.mundo.roles
	var v := _marco_aviso(Principal.COL_ROJO)
	var t := p._texto(11, Principal.COL_ROJO)
	t.text = Idiomas.t("ESTÁS SIN BANCO")
	v.add_child(t)
	var txt := p._texto(13, Principal.COL_TEXTO)
	txt.text = Idiomas.t("Te quedaste sin club. Elige dónde seguir tu carrera: el prestigio y la vitrina te acompañan, lo que construiste en el club anterior se queda allí.")
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(txt)
	for c in r.ofertas_trabajo():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		v.add_child(fila)
		var esc := p._escudo(c, 26)
		esc.custom_minimum_size = Vector2(26, 26)
		fila.add_child(esc)
		var nom := p._texto(12, Principal.COL_TEXTO)
		## La reputación del club contra la tuya es LA decisión: firmar por
		## encima de tu prestigio es un salto, por debajo es un refugio.
		var salto := "  ·  por encima de tu prestigio" if c.rep > r.prestigio else ""
		nom.text = Idiomas.t("%s  ·  división %d  ·  reputación %d%s") % [c.nombre, c.division, c.rep, salto]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		var b := Button.new()
		b.text = Idiomas.t("Firmar")
		b.add_theme_font_size_override("font_size", 11)
		var id := c.id
		b.pressed.connect(func() -> void: _aceptar_trabajo(id))
		fila.add_child(b)

func _resolver_agente(op: String) -> void:
	var r := p.mundo.cantera.resolver_agente(op)
	p._escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [
		String(r.get("titulo", "Resuelto")), String(r.get("cuerpo", ""))])
	p._refrescar()

func _abrir_mesa(e: Dictionary) -> void:
	var c := p.mundo.cantera
	var bono := p.mundo.entrenamiento.bono_agentes() if p.mundo.entrenamiento != null else 0.0
	var mesa := MesaAgente.new(e, c.confianza_de(String(e.get("agente", ""))), bono, Azar.ent(1, 1 << 30))
	p.add_child(MesaAgenteUI.new(mesa, func(m: MesaAgente) -> void:
		var r: Dictionary
		match m.estado:
			"acuerdo":
				r = c.resolver_agente("a", m.fraccion())
			"se_fue":
				r = c.resolver_agente("b", 1.0, true)
			_:
				r = c.resolver_agente("b")
		p._escribir("[color=#4caf6d][b]%s[/b][/color] %s" % [
			String(r.get("titulo", "Resuelto")), String(r.get("cuerpo", ""))])
		p._refrescar()))

## Un representante presiona por varios de sus clientes a la vez. Va en el
## despacho y no en la pestaña Cantera porque, como la decisión de prensa, es
## algo que hay que resolver AHORA -escondida en una pestaña, la semana pasa
## sin que el jugador la vea y el sistema deja de existir para él.
func _pintar_exigencia_agente(e: Dictionary) -> void:
	var v := _marco_aviso(Principal.COL_VERDE)
	var t := p._texto(11, Principal.COL_VERDE)
	t.text = Idiomas.t("UN REPRESENTANTE PRESIONA")
	v.add_child(t)
	var txt := p._texto(13, Principal.COL_TEXTO)
	txt.text = String(e.get("txt", ""))
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(txt)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	p._boton(String(e.get("opcion_a", "Sí")), func() -> void: _resolver_agente("a"), fila)
	p._boton(String(e.get("opcion_b", "No")), func() -> void: _resolver_agente("b"), fila)
	## El mini-juego (fase 4): regatearle en la mesa en vez de un sí o un no.
	p._boton("🤝 Sentarse a negociar", func() -> void: _abrir_mesa(e), fila)

func _resolver_solicitud(si: bool) -> void:
	var r := p.mundo.vestuario.resolver_solicitud(si)
	if r.is_empty():
		return
	## "compa": `Vestuario` no conoce `Cantera` -son dos clases del motor sin
	## relación entre sí-, así que el llamado cruzado se hace aquí, que es
	## quien tiene acceso a las dos.
	if si and String(r.get("clave", "")) == "compa" and p.mundo.cantera != null:
		p.mundo.cantera.prometer_compatriota(r["jugador"] as Jugador)
	p._escribir("[color=#c9a227][b]%s[/b][/color] %s" % [
		String(r.get("titulo", "")), String(r.get("cuerpo", ""))])
	p._refrescar()

## `SOLICITUDES` del HTML: un jugador te viene a pedir algo -más minutos, un
## sueldo mejor, la cinta de capitán...- y hay que decirle que sí o que no. El
## motor (`Vestuario.sortear_solicitud`/`resolver_solicitud`) llevaba tiempo
## escrito sin que ninguna pantalla lo mostrara nunca.
func _pintar_solicitud_plantel() -> void:
	var v := p.mundo.vestuario
	var j := v.jugador_de_solicitud()
	if j == null:
		return
	var d := v.def_solicitud(String(v.solicitud.get("k", "")))
	if d.is_empty():
		return
	var marco := _marco_aviso(Principal.COL_VERDE)
	var t := p._texto(11, Principal.COL_VERDE)
	t.text = Idiomas.t("TE BUSCA UN JUGADOR")
	marco.add_child(t)
	var txt := p._texto(13, Principal.COL_TEXTO)
	txt.text = Idiomas.t("%s (%d años, media %d) %s") % [j.nombre, j.edad, j.ovr, String(d[1]).to_lower()]
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	marco.add_child(txt)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	marco.add_child(fila)
	p._boton("✅  %s" % String(d[2]), func() -> void: _resolver_solicitud(true), fila)
	p._boton("❌  %s" % String(d[3]), func() -> void: _resolver_solicitud(false), fila)

## LA JUNTA DE ACCIONISTAS (plan maestro C5): quién habla, cuánto pesa, qué pide
## y las dos salidas. Debajo, la mesa entera con el humor de cada uno.
func _pintar_junta() -> void:
	var jt := p.mundo.junta
	var p_local := jt.pendiente
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.ORO))
	p._despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	v.add_child(Tema.rotulo("Junta de accionistas · preside %s (%s)" % [String(jt.presidente.get("nombre", "")), String(jt.presidente.get("estilo", ""))]))
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "%s %s" % [String(p_local["quien"]), String(p_local["tema"])])
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for op: String in ["a", "b"]:
		var b := Button.new()
		b.text = String(p_local[op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(func() -> void:
			var r := p.mundo.junta.resolver(op, p.mundo.mi_club(), p.mundo.directiva, p.mundo.prensa)
			Aviso.mostrar(p, "contrato", "🏛️", String(r.get("titulo", "")), String(r.get("cuerpo", "")))
			p._refrescar())
		CuadroDialogo.respuesta(b)
		b.add_theme_font_size_override("font_size", 16)
		fila.add_child(b)
	var partes: PackedStringArray = []
	for a: Dictionary in jt.accionistas:
		var cara: String = "🙂" if int(a["humor"]) >= 60 else ("😠" if int(a["humor"]) < 35 else "😐")
		partes.append("%s %s %d%% (%s)" % [cara, String(a["nombre"]), int(a["pct"]), String(Junta.EXIGENCIAS.get(String(a["exige"]), ""))])
	var mesa := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "  ·  ".join(partes))
	mesa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(mesa)

func _resolver_cantera(op: String) -> void:
	var r := p.mundo.eventos_cantera.resolver(op, p.mundo.academia, p.mundo.mi_club())
	Aviso.mostrar(p, "nivel", "🌱", String(r.get("titulo", "")), String(r.get("cuerpo", "")))
	p._refrescar()

## UN ASUNTO DE LA ACADEMIA (C11): el tema y las dos salidas.
func _pintar_asunto_cantera() -> void:
	var p_local := p.mundo.eventos_cantera.pendiente
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.BIEN))
	p._despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	v.add_child(Tema.rotulo("Academia · %s" % String(p_local["nombre"])))
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(p_local["tema"]))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for op: String in ["a", "b"]:
		var b := Button.new()
		b.text = String(p_local[op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(_resolver_cantera.bind(op))
		fila.add_child(b)

func _resolver_personal(op: String) -> void:
	var r := p.mundo.trabajadores.resolver(op, p.mundo.mi_club(), p.mundo.obras, p.mundo.prensa)
	Aviso.mostrar(p, "nivel", "🏢", String(r.get("titulo", "")), String(r.get("cuerpo", "")))
	p._refrescar()

## UN ASUNTO DEL PERSONAL DE UNA INSTALACIÓN (26-9-2026): quién, qué pasa y
## las dos salidas. Debajo, cómo está su equipo.
func _pintar_asunto_personal() -> void:
	var p_local := p.mundo.trabajadores.pendiente
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.ORO))
	p._despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	var inst := String(Instalaciones.CATALOGO.get(String(p_local["inst"]), ["Instalación"])[0])
	v.add_child(Tema.rotulo("%s · %s" % [inst, String(p_local["nombre"])]))
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(p_local["texto"]))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var eq := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "👥 " + p.mundo.trabajadores.texto_equipo(p.mundo.mi_club(), p.mundo.obras, String(p_local["inst"])).replace("\n", "\n👥 "))
	eq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(eq)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for op: String in ["a", "b"]:
		var b := Button.new()
		b.text = String(p_local[op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(_resolver_personal.bind(op))
		fila.add_child(b)

## UN ASUNTO DE ZONA GRIS (28-9-2026, `MercadoAvanzado`): superagente,
## fichaje impuesto, apuestas o transparencia, con sus dos salidas.
func _pintar_asunto_mercado_av() -> void:
	var p_local := p.mundo.mercado_av.pendiente
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.ORO))
	p._despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	var titulos := {"superagente": "EL SUPERAGENTE", "impuesto": "UN FICHAJE QUE NO PEDISTE", "apuestas": "APUESTAS EN EL VESTUARIO", "transparencia": "TRANSPARENCIA", "corrupcion": "CORRUPCIÓN EN LA FEDERACIÓN"}
	v.add_child(Tema.rotulo(String(titulos.get(String(p_local["id"]), "ZONA GRIS"))))
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(p_local["texto"]))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for op: String in ["a", "b"]:
		var b := Button.new()
		b.text = String(p_local[op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(func() -> void:
			var r := p.mundo.mercado_av.resolver(p.mundo, op)
			Aviso.mostrar(p, "nivel", "🕶️", String(r.get("titulo", "")), String(r.get("cuerpo", "")))
			p._refrescar())
		fila.add_child(b)

## LA CRISIS ECONÓMICA (28-9-2026, `Insolvencia`): tu cláusula de salida o
## la refundación del club.
func _pintar_asunto_insolvencia() -> void:
	var p_local := p.mundo.insolvencia.pendiente
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Principal.COL_ROJO))
	p._despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	v.add_child(Tema.rotulo("REFUNDACIÓN" if String(p_local["id"]) == "refundacion" else "TU CLÁUSULA DE SALIDA"))
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(p_local["texto"]))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for op: String in ["a", "b"]:
		var b := Button.new()
		b.text = String(p_local[op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(func() -> void:
			var r := p.mundo.insolvencia.resolver(p.mundo, op)
			Aviso.mostrar(p, "alerta", "💸", String(r.get("titulo", "")), String(r.get("cuerpo", "")))
			p._refrescar())
		fila.add_child(b)

func _resolver_vida(op: String) -> void:
	var r := p.mundo.vida.resolver(op, p.mundo.roles, p.mundo.mi_club(), p.mundo.prensa, p.mundo.anio, p.mundo.semana)
	Aviso.mostrar(p, "vida", "🏠", "Mi vida", r)
	p._refrescar()

## MI VIDA: lo que pasa en casa, con sus dos salidas.
func _pintar_asunto_vida() -> void:
	var p_local := p.mundo.vida.pendiente
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.TARJETA, Tema.RADIO, Tema.ORO))
	p._despacho.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	v.add_child(Tema.rotulo("Mi vida"))
	var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(p_local["texto"]))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	for op: String in ["a", "b"]:
		var b := Button.new()
		b.text = String(p_local[op])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(_resolver_vida.bind(op))
		fila.add_child(b)

func _pintar_despacho() -> void:
	p._limpiar(p._despacho)
	if p.mundo.roles != null and p.mundo.roles.sin_club:
		_pintar_sin_banco()
		return
	## LA RUEDA DE PRENSA YA NO ES UN "ASUNTO" MÁS DE LA LISTA -el usuario lo
	## pidió explícitamente: "eso debería tener su propio lugar", comparándolo
	## con la conferencia de prensa de FC26, que ocupa la pantalla entera-.
	## Antes vivía encogida dentro de esta tarjeta compartiendo espacio con la
	## barra superior y la tabla de posiciones; ahora se abre como cinemática
	## de pantalla completa, mismo patrón que `Sorteo` (`_siguiente_sorteo()`
	## más arriba): un `Control` de pantalla completa colgado directo de
	## `self`, por encima de todo, y nada más se dibuja mientras está abierta.
	if p.mundo.prensa != null and p.mundo.prensa.hay_rueda() and p._rueda_pop == null:
		p._abrir_rueda_pantalla_completa(p.mundo.prensa.entrevista)
	var asuntos: Array = []
	if p.mundo.cantera != null and p.mundo.cantera.hay_exigencia():
		asuntos.append({"et": "🦈 Un representante presiona", "col": Principal.COL_VERDE, "id": "agente"})
	if p.mundo.prensa != null and p.mundo.prensa.hay_evento():
		asuntos.append({"et": "📌 Hay que decidir", "col": Principal.COL_ORO, "id": "decision"})
	if p.mundo.vestuario != null and not p.mundo.vestuario.solicitud.is_empty():
		asuntos.append({"et": "🗣️ Te busca un jugador", "col": Principal.COL_VERDE, "id": "solicitud"})
	if p.mundo.junta != null and not p.mundo.junta.pendiente.is_empty():
		asuntos.append({"et": "🏛️ Junta de accionistas", "col": Principal.COL_ORO, "id": "junta"})
	if p.mundo.eventos_cantera != null and not p.mundo.eventos_cantera.pendiente.is_empty():
		asuntos.append({"et": "🌱 Asunto de la academia", "col": Principal.COL_VERDE, "id": "cantera"})
	if p.mundo.trabajadores != null and not p.mundo.trabajadores.pendiente.is_empty():
		asuntos.append({"et": "🏢 Asunto del personal", "col": Principal.COL_ORO, "id": "personal"})
	if p.mundo.mercado_av != null and not p.mundo.mercado_av.pendiente.is_empty():
		asuntos.append({"et": "🕶️ Zona gris", "col": Principal.COL_ORO, "id": "mercado_av"})
	if p.mundo.insolvencia != null and not p.mundo.insolvencia.pendiente.is_empty():
		asuntos.append({"et": "💸 Crisis económica", "col": Principal.COL_ROJO, "id": "insolvencia"})
	if p.mundo.vida != null and not p.mundo.vida.pendiente.is_empty():
		asuntos.append({"et": "🏠 Pasa en casa", "col": Principal.COL_ORO, "id": "vida"})
	if asuntos.is_empty():
		return
	p._aviso_abierto = clampi(p._aviso_abierto, 0, asuntos.size() - 1)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._despacho.add_child(fila)
	var cab := p._texto(11, Principal.COL_SUAVE)
	cab.text = (Idiomas.t("🔔 %d asunto") if asuntos.size() == 1 else Idiomas.t("🔔 %d asuntos")) % asuntos.size()
	fila.add_child(cab)
	for i in asuntos.size():
		var a: Dictionary = asuntos[i]
		var b := p._pildora(String(a["et"]), 11, 26)
		b.button_pressed = (i == p._aviso_abierto)
		var idx := i
		b.pressed.connect(func() -> void:
			p._aviso_abierto = idx
			_pintar_despacho())
		fila.add_child(b)

	match String((asuntos[p._aviso_abierto] as Dictionary)["id"]):
		"agente": _pintar_exigencia_agente(p.mundo.cantera.exigencia)
		"decision": p._pintar_decision(p.mundo.prensa.pendiente)
		"solicitud": _pintar_solicitud_plantel()
		"junta": _pintar_junta()
		"cantera": _pintar_asunto_cantera()
		"personal": _pintar_asunto_personal()
		"mercado_av": _pintar_asunto_mercado_av()
		"insolvencia": _pintar_asunto_insolvencia()
		"vida": _pintar_asunto_vida()

extends "res://ui/entrada/config_club_pasos.gd"
## [Capa 3/4 de `config_club.gd`] los pasos del club y del juego: mascota, estadio, casa y gráficos.

var _vista_mascota: Control = null

# -------------------------------------------------------------------- MASCOTA

func _paso_mascota() -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	_contenido.add_child(fila)
	var izq := VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izq.add_theme_constant_override("separation", 8)
	fila.add_child(izq)
	izq.add_child(Tema.etiqueta(13, Tema.ORO, Idiomas.mayusculas(Idiomas.t("El animal del club"))))
	var ay := Tema.etiqueta(12, Tema.SUAVE, Idiomas.t("Sale a la banda en cada partido de local, anima a la hinchada y lleva la camiseta del club."))
	ay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	izq.add_child(ay)
	var rej := GridContainer.new()
	rej.columns = 3
	rej.add_theme_constant_override("h_separation", 6)
	rej.add_theme_constant_override("v_separation", 6)
	izq.add_child(rej)
	var botones: Array = []
	for k: String in MascotaQ.ANIMALES:
		var animal := k
		var fila_a: Array = ConfigClubDatos.ANIMALES.get(k, [k, "🐾"])
		var b := _opcion("%s  %s" % [String(fila_a[1]), Idiomas.t(String(fila_a[0]))], datos.mascota == k, func() -> void:
			datos.mascota = animal
			if is_instance_valid(_vista_mascota):
				_vista_mascota.call("mostrar", datos.club, animal)
			_cambio(), Vector2(128, 38))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rej.add_child(b)
		botones.append(b)
	_grupo(botones)
	## La mascota en 3D, a la derecha, girando sobre un disco de césped.
	var marco := PanelContainer.new()
	marco.custom_minimum_size = Vector2(250, 330)
	marco.add_theme_stylebox_override("panel", _caja(Color(0, 0, 0, 0.3), Tema.RADIO_GRANDE, Color(1, 1, 1, 0.08)))
	fila.add_child(marco)
	_vista_mascota = VistaMascota.new()
	_vista_mascota.custom_minimum_size = Vector2(230, 310)
	marco.add_child(_vista_mascota)
	_vista_mascota.call("mostrar", datos.club, datos.mascota)

# -------------------------------------------------------------------- ESTADIO

func _paso_estadio() -> void:
	_seccion(Idiomas.t("Estilo de las instalaciones"), Idiomas.t("El aspecto del estadio con el que se funda el club: forma, techo, fachada, luces y césped. No cuesta nada ahora; después cada reforma se paga y tarda semanas de obra."))
	var rej := GridContainer.new()
	rej.columns = 2
	rej.add_theme_constant_override("h_separation", 8)
	rej.add_theme_constant_override("v_separation", 8)
	_contenido.add_child(rej)
	var botones: Array = [_tarjeta("🏟️", Idiomas.t("El estadio que ya tiene"), Idiomas.t("Se queda como está (o con la arquitectura de su estadio real, si lo tiene)."), datos.estilo_estadio == "", "")]
	rej.add_child(botones[0])
	for p: Dictionary in ConfigClubDatos.presets():
		var b := _tarjeta("", Idiomas.t(String(p["nombre"])), Idiomas.t(String(p["desc"])), datos.estilo_estadio == String(p["clave"]), String(p["clave"]))
		rej.add_child(b)
		botones.append(b)
	_grupo(botones)

## Una tarjeta-botón: icono y nombre arriba, la descripción debajo.
func _tarjeta(icono: String, titulo: String, desc: String, elegido: bool, clave: String) -> Button:
	var b := _opcion("", elegido, func() -> void:
		datos.estilo_estadio = clave
		_cambio(), Vector2(0, 74))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)
	var t := Tema.etiqueta(15, Tema.TEXTO, (icono + "  " if icono != "" else "") + titulo)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.clip_text = true
	v.add_child(t)
	var d := Tema.etiqueta(11, Tema.SUAVE, desc)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.max_lines_visible = 2
	v.add_child(d)
	return b

# ----------------------------------------------------------------------- CASA

func _paso_casa() -> void:
	_seccion(Idiomas.t("Dónde vives"), Idiomas.t("Tu casa es donde descansas del fútbol: cuanto mejor, más estrés te quita cada semana, y más cuesta. Se paga de tu bolsillo, no de la caja del club."))
	var botones: Array = []
	for k: String in VidaDT.ORDEN_VIVIENDA:
		var clave := k
		var f: Array = VidaDT.VIVIENDAS[k]
		var precio := int(f[1])
		if datos.mundo != null and datos.mundo.vida != null:
			precio = datos.mundo.vida.precio(precio)
		var desc := Idiomas.t("%s por semana  ·  descanso %s") % [Cesiones.dinero(precio),
			"●".repeat(int(f[2])) + "○".repeat(4 - int(f[2]))]
		var b := _opcion("", datos.vivienda == k, func() -> void:
			datos.vivienda = clave
			_cambio(), Vector2(0, 58))
		var fila := HBoxContainer.new()
		fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_theme_constant_override("separation", 12)
		b.add_child(fila)
		var ic := Tema.etiqueta(28, Tema.TEXTO, String(f[3]))
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(ic)
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 0)
		fila.add_child(v)
		for par: Array in [[16, Tema.TEXTO, Idiomas.t(String(f[0]))], [12, Tema.SUAVE, desc]]:
			var l := Tema.etiqueta(int(par[0]), par[1] as Color, String(par[2]))
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(l)
		_contenido.add_child(b)
		botones.append(b)
	_grupo(botones)

# ---------------------------------------------------------- JUEGO Y GRÁFICOS

func _paso_juego() -> void:
	var reco := ConfigClubDatos.calidad_recomendada()
	_seccion(Idiomas.t("Calidad gráfica del estadio en 3D"), Idiomas.t("Recomendada para este equipo: %s.") % Idiomas.t(_nombre_calidad(reco)))
	var f := _flujo()
	var bc: Array = []
	for n: Array in [[Calidad.MEDIO, "Sin efectos pesados: máxima fluidez"], [Calidad.ALTO, "El equilibrio: sombras sí, lo más caro no"],
			[Calidad.ULTRA, "Todos los efectos, sombras y reflejos"]]:
		var nivel := int(n[0])
		var b := _opcion(Idiomas.t(_nombre_calidad(nivel)) + ("  ★" if nivel == reco else ""), datos.calidad == nivel, func() -> void:
			datos.calidad = nivel
			_cambio(), Vector2(150, 40), Idiomas.t(String(n[1])))
		f.add_child(b)
		bc.append(b)
	_grupo(bc)
	_interruptor(Idiomas.t("Ajustar sola para mantener 40 FPS en el partido"), datos.adaptativa, func(si: bool) -> void:
		datos.adaptativa = si)
	var ml := _interruptor(Idiomas.t("Motor gráfico ligero (para equipos modestos; reinicia el juego)"), datos.motor_ligero, func(si: bool) -> void:
		datos.motor_ligero = si)
	ml.tooltip_text = Idiomas.t("Usa el renderizador de compatibilidad (OpenGL). En gráficas integradas antiguas va más fluido; se pierden algunos efectos de luz.")
	_seccion(Idiomas.t("Fotogramas por segundo"), Idiomas.t("Bajarlo alarga la batería del portátil y baja la temperatura. Para una interfaz, 30 se ve igual de bien; el estadio en 3D agradece 60."))
	var ff := _flujo()
	var bf: Array = []
	for v: int in ConfigClubDatos.FPS:
		var valor := v
		var b := _opcion(Idiomas.t("Sin límite") if v == 0 else "%d FPS" % v, datos.fps == v, func() -> void:
			datos.fps = valor
			_cambio(), Vector2(110, 38))
		ff.add_child(b)
		bf.append(b)
	_grupo(bf)
	_interruptor(Idiomas.t("Mostrar contador de FPS"), datos.contador_fps, func(si: bool) -> void:
		datos.contador_fps = si)
	_seccion(Idiomas.t("Gente por la calle"), Idiomas.t("Cuántos peatones hay en la ciudad 3D. Más gente da más vida y pide más equipo."))
	var fd := _flujo()
	var bd: Array = []
	for k: String in ConfigClubDatos.ORDEN_DENSIDAD:
		var clave := k
		var d: Array = ConfigClubDatos.DENSIDADES[k]
		var b := _opcion("%s  %s" % [String(d[3]), Idiomas.t(String(d[0]))], datos.densidad == k, func() -> void:
			datos.densidad = clave
			_cambio(), Vector2(160, 40), Idiomas.t(String(d[1])))
		fd.add_child(b)
		bd.append(b)
	_grupo(bd)
	var nota := Tema.etiqueta(12, Tema.SUAVE, Idiomas.t("Esto es de esta máquina, no de la partida: vale para todos tus clubes."))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenido.add_child(nota)

func _nombre_calidad(n: int) -> String:
	return "Media" if n == Calidad.MEDIO else ("Alta" if n == Calidad.ALTO else "Ultra")

func _interruptor(texto: String, valor: bool, al_cambiar: Callable) -> CheckButton:
	var cb := CheckButton.new()
	cb.text = texto
	cb.button_pressed = valor
	cb.add_theme_font_size_override("font_size", 14)
	cb.toggled.connect(func(si: bool) -> void:
		al_cambiar.call(si)
		_cambio())
	_contenido.add_child(cb)
	return cb

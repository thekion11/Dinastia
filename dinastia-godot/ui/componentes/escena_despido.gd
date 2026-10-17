class_name EscenaDespido
extends Control
## EL DESPIDO, EN PERSONA (17-10-2026, M-238). Hasta hoy `Directiva.despedido`
## solo dejaba un aviso y una línea en el despacho. Ahora el presidente te recibe
## en su despacho: su cara (el busto 3D del mismo motor que los mentores,
## `Tutorial._cara_mentor`, con el nombre de `Junta.presidente`), tres frases en
## el cuadro de diálogo del juego (`CuadroDialogo`), el resumen de tu etapa
## (temporadas, partidos y balance de esta temporada, puesto y títulos) y la
## salida que ya existía: las ofertas de otros clubes (`Roles.quedar_sin_banco`,
## que llama quien la abre). Clic, E, Intro o Espacio pasan la frase; Esc va al
## final.
##   EscenaDespido.mostrar(padre, mundo, motivo) -> señal `cerrado`

signal cerrado

const ROJO := Color(0.88, 0.33, 0.33)

var _mundo: Mundo
var _club: Club
var _motivo := ""
var _frases: Array = []
var _i := -1
var _dialogo: CuadroDialogo
var _resumen: Control
var _boton: Button
var _nombre_pres := ""
var _t := 0.0
var _fondo: ColorRect

static func mostrar(padre: Control, mundo: Mundo, motivo: String) -> EscenaDespido:
	var e := EscenaDespido.new()
	e._mundo = mundo
	e._club = mundo.mi_club() if mundo != null else null
	e._motivo = motivo
	e.set_anchors_preset(Control.PRESET_FULL_RECT)
	e.mouse_filter = Control.MOUSE_FILTER_STOP
	e.z_index = 90
	padre.add_child(e)
	e._montar()
	return e

func _montar() -> void:
	var c1 := Color(_club.color1) if _club != null else Color(0.2, 0.2, 0.3)
	var c2 := Color(_club.color2) if _club != null else Color(0.8, 0.8, 0.8)
	_nombre_pres = Idiomas.t("El presidente")
	if _mundo != null and _mundo.junta != null and String(_mundo.junta.presidente.get("nombre", "")) != "":
		_nombre_pres = String(_mundo.junta.presidente["nombre"])
	## El despacho a oscuras: fondo con el color del club apagado y una franja
	## diagonal que respira despacio.
	_fondo = ColorRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform vec4 c1 : source_color;
uniform vec4 c2 : source_color;
void fragment() {
	vec2 uv = UV;
	float franja = smoothstep(0.02, 0.0, abs(uv.x * 0.8 + uv.y * 0.5 - 0.62 - 0.02 * sin(TIME * 0.6)) - 0.07);
	vec3 base = mix(vec3(0.02, 0.025, 0.04), c1.rgb * 0.22, 0.55 - uv.y * 0.35);
	base = mix(base, c2.rgb * 0.35, franja * 0.35);
	float vin = smoothstep(1.1, 0.25, length(uv - vec2(0.45, 0.45)));
	COLOR = vec4(base * (0.45 + 0.55 * vin), 0.97);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("c1", c1)
	mat.set_shader_parameter("c2", c2)
	_fondo.material = mat
	add_child(_fondo)
	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.offset_left = 90
	fila.offset_right = -90
	fila.offset_top = 70
	fila.offset_bottom = -260
	fila.add_theme_constant_override("separation", 60)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(fila)
	## El presidente.
	var izq := VBoxContainer.new()
	izq.alignment = BoxContainer.ALIGNMENT_CENTER
	izq.add_theme_constant_override("separation", 8)
	fila.add_child(izq)
	var marco := PanelContainer.new()
	marco.add_theme_stylebox_override("panel", Tema.caja(Color(0, 0, 0, 0.35), Tema.RADIO_GRANDE, Color(c2, 0.6)))
	izq.add_child(marco)
	var cara := TextureRect.new()
	cara.name = "CaraPresidente"
	cara.custom_minimum_size = Vector2(280, 280)
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cara.texture = Tutorial._cara_mentor({"semilla": "presidente_" + _nombre_pres, "nombre": _nombre_pres, "canas": true},
		{"c1": c1.to_html(false), "c2": c2.to_html(false)})
	marco.add_child(cara)
	var nom := Tema.etiqueta(22, Tema.TEXTO, _nombre_pres)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	izq.add_child(nom)
	var cargo := Tema.etiqueta(14, Tema.SUAVE, "%s · %s" % [Idiomas.t("Presidente"), Nombres.visible(_club.nombre) if _club != null else ""])
	cargo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	izq.add_child(cargo)
	## La etapa (aparece tras la última frase).
	_resumen = _panel_resumen()
	_resumen.modulate.a = 0.0
	fila.add_child(_resumen)
	_boton = Button.new()
	_boton.text = Idiomas.t("Ver ofertas de otros clubes ▶")
	_boton.custom_minimum_size = Vector2(320, 46)
	_boton.add_theme_font_size_override("font_size", 18)
	_boton.visible = false
	_boton.pressed.connect(_cerrar)
	add_child(_boton)
	_boton.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_boton.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boton.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_boton.offset_bottom = -70
	var motivo := _motivo if _motivo != "" else Idiomas.t("mala racha")
	_frases = [
		Idiomas.t("Míster, siéntese. No hay una forma fácil de decir esto."),
		Idiomas.t("Tras la %s, la directiva ha perdido la paciencia. Queda destituido con efecto inmediato.") % motivo,
		Idiomas.t("Gracias por su trabajo. Le deseo suerte en su próximo club."),
	]
	_dialogo = CuadroDialogo.new()
	add_child(_dialogo)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.45)
	Sonido.toca("despido")
	_siguiente()

func _panel_resumen() -> Control:
	var caja := PanelContainer.new()
	caja.name = "ResumenEtapa"
	caja.add_theme_stylebox_override("panel", Tema.caja(Color(0.03, 0.04, 0.07, 0.85), Tema.RADIO_GRANDE, Color(ROJO, 0.55)))
	caja.custom_minimum_size = Vector2(440, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	caja.add_child(v)
	var tit := Tema.etiqueta(34, ROJO, Idiomas.t("DESTITUIDO"))
	v.add_child(tit)
	var sub := Tema.etiqueta(15, Tema.ORO, Idiomas.t("TU ETAPA EN %s") % (Nombres.visible(_club.nombre).to_upper() if _club != null else ""))
	v.add_child(sub)
	v.add_child(HSeparator.new())
	for f: Array in datos_etapa(_mundo):
		var h := HBoxContainer.new()
		var k := Tema.etiqueta(16, Tema.SUAVE, Idiomas.t(String(f[0])))
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(k)
		h.add_child(Tema.etiqueta(18, Tema.TEXTO, String(f[1])))
		v.add_child(h)
	return caja

## Las cifras de la etapa: [[rótulo, valor]]. Estática para las pruebas.
static func datos_etapa(mundo: Mundo) -> Array:
	var r: Array = []
	if mundo == null or mundo.mi_club() == null:
		return r
	var club := mundo.mi_club()
	var dir := mundo.directiva
	r.append(["Temporadas", str(maxi(1, dir.temporadas + 1) if dir != null else 1)])
	var liga := mundo.liga_de(club)
	if liga != null and liga.tabla_puntos.has(club.id):
		var d: Dictionary = liga.tabla_puntos[club.id]
		r.append(["Partidos esta temporada", str(int(d["pj"]))])
		r.append(["Balance (G-E-P)", "%d-%d-%d" % [int(d["g"]), int(d["e"]), int(d["p"])]])
		var tabla := liga.tabla()
		for i in tabla.size():
			if tabla[i]["club"] == club:
				r.append(["Puesto en liga", "%d.º" % (i + 1)])
				break
	var titulos: Array = dir.trofeos if dir != null else []
	r.append(["Títulos", str(titulos.size()) + ("  (%s)" % ", ".join(titulos.slice(0, 3)) if not titulos.is_empty() else "")])
	if dir != null:
		r.append(["Confianza final", "%d" % dir.confianza])
	return r

func _siguiente() -> void:
	_i += 1
	if _i < _frases.size():
		_dialogo.decir(_nombre_pres, String(_frases[_i]), Tema.ORO, _i, _frases.size())
		return
	_final()

## La última frase se queda y aparecen la etapa y la salida.
func _final() -> void:
	_i = _frases.size()
	if _dialogo.visible and _dialogo.escribiendo():
		_dialogo.completar()
	create_tween().tween_property(_resumen, "modulate:a", 1.0, 0.4)
	_boton.visible = true
	_boton.grab_focus()

func _cerrar() -> void:
	if is_queued_for_deletion():
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		cerrado.emit()
		queue_free())

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_avanzar()
		accept_event()

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not (e as InputEventKey).pressed or (e as InputEventKey).echo:
		return
	var k := (e as InputEventKey).keycode
	if k == KEY_ESCAPE:
		if _i < _frases.size():
			_final()
		else:
			_cerrar()
		get_viewport().set_input_as_handled()
	elif k in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if _i >= _frases.size():
			_cerrar()
		else:
			_avanzar()
		get_viewport().set_input_as_handled()

func _avanzar() -> void:
	if _i >= _frases.size():
		return
	if _dialogo.escribiendo():
		_dialogo.completar()
		return
	_siguiente()

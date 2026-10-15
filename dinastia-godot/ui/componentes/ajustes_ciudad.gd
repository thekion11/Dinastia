class_name AjustesCiudad
extends PanelContainer
## AJUSTES DE LA CIUDAD 3D (13-10-2026): los controles ya no van escritos en la
## pantalla; están aquí, junto a las opciones del paseo, y en el TUTORIAL DE LA
## CIUDAD (se abre solo la primera vez y se puede repetir desde aquí).

signal cerrado

const ARCHIVO := "user://ajustes.cfg"
const SECCION := "ciudad"

const CONTROLES := [
	["Moverse", "W A S D · flechas · stick izquierdo · cruceta táctil"],
	["Correr", "Mayús · botón A del mando"],
	["Vista (tercera / primera persona)", "V"],
	["Hablar, entrar, subir, usar", "E · botón E táctil"],
	["Mirar por la ventana del metro", "C"],
	["Volver al mapa", "Esc · botón Salir"],
]

const PASOS := [
	["Bienvenido a tu ciudad", "Puedes recorrerla a pie, en coche o en metro. Todo lo que ves está vivo: la gente camina, los semáforos cambian y el tráfico para en rojo."],
	["Moverse", "W A S D o el stick para andar. Mantén Mayús (o A en el mando) para correr: al correr sacas el móvil y ves tu velocidad y la calle."],
	["Mirar", "V cambia entre tercera y primera persona. En primera persona mueves la vista con el ratón."],
	["Interactuar", "Cuando el botón E brilla en dorado hay algo cerca: un vecino para charlar, una puerta para entrar o una boca de metro."],
	["Tus ajustes", "Todo esto lo tienes siempre en ⚙ arriba a la derecha: los controles, este tutorial y si quieres ayudas en pantalla."],
]

static func valor(clave: String, por_defecto: Variant) -> Variant:
	var cf := ConfigFile.new()
	if cf.load(ARCHIVO) != OK:
		return por_defecto
	return cf.get_value(SECCION, clave, por_defecto)

static func guardar(clave: String, v: Variant) -> void:
	var cf := ConfigFile.new()
	cf.load(ARCHIVO)
	cf.set_value(SECCION, clave, v)
	cf.save(ARCHIVO)

var _al_cambiar: Callable

static func crear(al_cambiar: Callable) -> AjustesCiudad:
	var a := AjustesCiudad.new()
	a._al_cambiar = al_cambiar
	a._montar()
	return a

func _montar() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -320
	offset_right = 320
	offset_top = -200
	offset_bottom = 250
	add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var cab := HBoxContainer.new()
	v.add_child(cab)
	var t := Label.new()
	t.text = "⚙ " + Idiomas.t("Ajustes de la ciudad")
	t.add_theme_font_size_override("font_size", 22)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	var x := CuadroDialogo.respuesta(Button.new())
	x.text = "✕"
	x.pressed.connect(func() -> void:
		cerrado.emit()
		queue_free())
	cab.add_child(x)
	v.add_child(CuadroDialogo.placa(Idiomas.t("Controles")))
	var rej := GridContainer.new()
	rej.columns = 2
	rej.add_theme_constant_override("h_separation", 18)
	rej.add_theme_constant_override("v_separation", 4)
	v.add_child(rej)
	for c: Array in CONTROLES:
		var a := Label.new()
		a.text = Idiomas.t(String(c[0]))
		a.modulate = Color(1, 1, 1, 0.7)
		rej.add_child(a)
		var b := Label.new()
		b.text = String(c[1])
		rej.add_child(b)
	v.add_child(CuadroDialogo.placa(Idiomas.t("Opciones")))
	for o: Array in [["ayudas", "Mostrar ayudas en pantalla (calle y controles)", false],
			["movil", "Sacar el móvil con la velocidad al correr o conducir", true]]:
		var cb := CheckButton.new()
		cb.text = Idiomas.t(String(o[1]))
		cb.button_pressed = bool(valor(String(o[0]), o[2]))
		var clave := String(o[0])
		cb.toggled.connect(func(si: bool) -> void:
			guardar(clave, si)
			if _al_cambiar.is_valid():
				_al_cambiar.call())
		v.add_child(cb)
	v.add_child(CuadroDialogo.placa(Idiomas.t("Mi caminata")))
	var sel := OptionButton.new()
	var estilos := ["formal", "normal", "animado", "cansado", "agachado", "trote"]
	var nombres := ["Formal (erguido)", "Normal", "Animado", "Cansado", "Agachado", "A trote"]
	for i in estilos.size():
		sel.add_item(Idiomas.t(nombres[i]), i)
	sel.select(maxi(0, estilos.find(String(valor("caminata", "formal")))))
	sel.item_selected.connect(func(i: int) -> void:
		guardar("caminata", estilos[i])
		if _al_cambiar.is_valid():
			_al_cambiar.call())
	v.add_child(sel)
	var tut := CuadroDialogo.respuesta(Button.new())
	tut.text = "🎓 " + Idiomas.t("Ver el tutorial de la ciudad")
	tut.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tut.pressed.connect(func() -> void:
		get_parent().add_child(TutorialCiudad.new())
		cerrado.emit()
		queue_free())
	v.add_child(tut)

## El tutorial de la ciudad: tarjetas abajo, una por paso.
class TutorialCiudad extends PanelContainer:
	var _i := 0
	var _titulo: Label
	var _texto: Label
	var _boton: Button

	func _init() -> void:
		set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		offset_left = -340
		offset_right = 340
		offset_top = -260
		offset_bottom = -120
		add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		add_child(v)
		_titulo = Label.new()
		_titulo.add_theme_font_size_override("font_size", 20)
		_titulo.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
		v.add_child(_titulo)
		_texto = Label.new()
		_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_texto.custom_minimum_size = Vector2(630, 0)
		_texto.add_theme_font_size_override("font_size", 17)
		v.add_child(_texto)
		var fila := HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_END
		v.add_child(fila)
		var saltar := CuadroDialogo.respuesta(Button.new())
		saltar.text = Idiomas.t("Saltar")
		saltar.pressed.connect(_fin)
		fila.add_child(saltar)
		_boton = CuadroDialogo.respuesta(Button.new())
		_boton.pressed.connect(_siguiente)
		fila.add_child(_boton)
		_pintar()

	func _pintar() -> void:
		var p: Array = PASOS[_i]
		_titulo.text = "%s   %d/%d" % [Idiomas.t(String(p[0])), _i + 1, PASOS.size()]
		CuadroDialogo.escribir(_texto, Idiomas.t(String(p[1])))
		_boton.text = Idiomas.t("Siguiente ▸") if _i < PASOS.size() - 1 else Idiomas.t("¡A pasear!")

	func _siguiente() -> void:
		_i += 1
		if _i >= PASOS.size():
			_fin()
		else:
			_pintar()

	func _fin() -> void:
		AjustesCiudad.guardar("tutorial_visto", true)
		queue_free()

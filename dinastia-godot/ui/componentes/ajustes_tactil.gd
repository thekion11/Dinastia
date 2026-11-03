class_name AjustesTactil
extends RefCounted
## LOS AJUSTES DE LOS CONTROLES TÁCTILES DEL PARTIDO (3-11-2026): cuándo salen (automático = solo con pantalla táctil; siempre; nunca),
## de qué tamaño y con cuánta opacidad. Del JUGADOR, no de la partida: `user://ajustes.cfg`, sección `tactil`. Se pintan en Ajustes → Dispositivo.
const ARCHIVO := "user://ajustes.cfg"
const SECCION := "tactil"
const MODOS := ["auto", "si", "no"]
const TAM_MIN := 0.7
const TAM_MAX := 1.4
const OP_MIN := 0.2
const OP_MAX := 1.0

static func _cargar() -> ConfigFile:
	var cf := ConfigFile.new()
	cf.load(ARCHIVO)
	return cf

static func _poner(clave: String, valor: Variant) -> void:
	var cf := _cargar()
	cf.set_value(SECCION, clave, valor)
	cf.save(ARCHIVO)

static func modo() -> String:
	var m := String(_cargar().get_value(SECCION, "modo", "auto"))
	return m if MODOS.has(m) else "auto"

static func tamano() -> float:
	return clampf(float(_cargar().get_value(SECCION, "tamano", 1.0)), TAM_MIN, TAM_MAX)

static func opacidad() -> float:
	return clampf(float(_cargar().get_value(SECCION, "opacidad", 1.0)), OP_MIN, OP_MAX)

static func poner_modo(m: String) -> void:
	_poner("modo", m if MODOS.has(m) else "auto")

static func poner_tamano(v: float) -> void:
	_poner("tamano", clampf(v, TAM_MIN, TAM_MAX))

static func poner_opacidad(v: float) -> void:
	_poner("opacidad", clampf(v, OP_MIN, OP_MAX))

static func restaurar() -> void:
	var cf := _cargar()
	if cf.has_section(SECCION):
		cf.erase_section(SECCION)
		cf.save(ARCHIVO)

## Las tres filas de Ajustes → Dispositivo. `p` es la pantalla principal (`_lista_ajustes`, `_texto`).
static func pintar(p: Principal) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila)
	var et := p._texto(12, Principal.COL_TEXTO)
	et.text = Idiomas.t("Controles táctiles del partido")
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.tooltip_text = Idiomas.t("Stick y botones en pantalla. Automático: solo en aparatos con pantalla táctil.")
	fila.add_child(et)
	var nombres := {"auto": "Automático", "si": "Siempre", "no": "Nunca"}
	var botones := {}
	for m: String in MODOS:
		var b := Button.new()
		b.text = Idiomas.t(String(nombres[m]))
		b.toggle_mode = true
		b.button_pressed = modo() == m
		b.pressed.connect(func() -> void:
			poner_modo(m)
			for k: String in botones:
				(botones[k] as Button).set_pressed_no_signal(k == m))
		botones[m] = b
		fila.add_child(b)
	_deslizador(p, "Tamaño de los botones", TAM_MIN, TAM_MAX, tamano(), poner_tamano)
	_deslizador(p, "Opacidad de los botones", OP_MIN, OP_MAX, opacidad(), poner_opacidad)

static func _deslizador(p: Principal, titulo: String, mn: float, mx: float, valor: float, al_cambiar: Callable) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila)
	var et := p._texto(12, Principal.COL_TEXTO)
	et.text = Idiomas.t(titulo)
	et.custom_minimum_size = Vector2(150, 0)
	fila.add_child(et)
	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = 0.05
	sl.value = valor
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pct := p._texto(11, Principal.COL_SUAVE)
	pct.text = "%d%%" % int(round(valor * 100.0))
	pct.custom_minimum_size = Vector2(44, 0)
	sl.value_changed.connect(func(v: float) -> void:
		al_cambiar.call(v)
		pct.text = "%d%%" % int(round(v * 100.0)))
	fila.add_child(sl)
	fila.add_child(pct)

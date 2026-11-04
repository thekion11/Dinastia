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
const OP_DEF := 0.6                    ## opacidad por defecto (FC Mobile y DLS dejan los botones translúcidos)
const SEP_MIN := 1.0
const SEP_MAX := 1.3
const MODOS_MANDO := ["ambos", "botones", "gestos"]

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
	return clampf(float(_cargar().get_value(SECCION, "opacidad", OP_DEF)), OP_MIN, OP_MAX)

## Modo de control del partido (4-11-2026): «ambos» = botones y gestos; «botones» = solo botones (sale también Mod); «gestos» = tocar para pasar, deslizar para tirar.
static func mando() -> String:
	var m := String(_cargar().get_value(SECCION, "mando", "ambos"))
	return m if MODOS_MANDO.has(m) else "ambos"

static func poner_mando(m: String) -> void:
	_poner("mando", m if MODOS_MANDO.has(m) else "ambos")

## Separación entre los botones (1 = la de siempre, 1,3 = más separados).
static func separacion() -> float:
	return clampf(float(_cargar().get_value(SECCION, "separacion", 1.0)), SEP_MIN, SEP_MAX)

static func poner_separacion(v: float) -> void:
	_poner("separacion", clampf(v, SEP_MIN, SEP_MAX))

## Cámara cercana del partido (4-11-2026): «auto» = cercana solo con controles táctiles; «si» siempre; «no» nunca (la de siempre).
static func camara() -> String:
	var m := String(_cargar().get_value(SECCION, "camara", "auto"))
	return m if MODOS.has(m) else "auto"

static func poner_camara(m: String) -> void:
	_poner("camara", m if MODOS.has(m) else "auto")

static func camara_cercana(tactil: bool) -> bool:
	var m := camara()
	return m == "si" or (m == "auto" and tactil)

## Modo zurdo (4-11-2026): el stick a la derecha y los botones a la izquierda.
static func zurdo() -> bool:
	return bool(_cargar().get_value(SECCION, "zurdo", false))

static func poner_zurdo(v: bool) -> void:
	_poner("zurdo", v)

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
	var fila_m := HBoxContainer.new()
	fila_m.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_m)
	var et_m := p._texto(12, Principal.COL_TEXTO)
	et_m.text = Idiomas.t("Modo de control del partido")
	et_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_m.tooltip_text = Idiomas.t("Botones: todo en pantalla. Gestos: toca para pasar y desliza hacia arriba para tirar. Ambos: las dos cosas.")
	fila_m.add_child(et_m)
	var nombres_m := {"ambos": "Ambos", "botones": "Botones", "gestos": "Gestos"}
	var botones_m := {}
	for m: String in MODOS_MANDO:
		var bm := Button.new()
		bm.text = Idiomas.t(String(nombres_m[m]))
		bm.toggle_mode = true
		bm.button_pressed = mando() == m
		bm.pressed.connect(func() -> void:
			poner_mando(m)
			for k: String in botones_m:
				(botones_m[k] as Button).set_pressed_no_signal(k == m))
		botones_m[m] = bm
		fila_m.add_child(bm)
	var fila_c := HBoxContainer.new()
	fila_c.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_c)
	var et_c := p._texto(12, Principal.COL_TEXTO)
	et_c.text = Idiomas.t("Cámara cercana del partido")
	et_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_c.tooltip_text = Idiomas.t("Acerca la cámara al jugador que llevas. Automático: solo con los controles táctiles.")
	fila_c.add_child(et_c)
	var botones_c := {}
	for m: String in MODOS:
		var bc := Button.new()
		bc.text = Idiomas.t(String(nombres[m]))
		bc.toggle_mode = true
		bc.button_pressed = camara() == m
		bc.pressed.connect(func() -> void:
			poner_camara(m)
			for k: String in botones_c:
				(botones_c[k] as Button).set_pressed_no_signal(k == m))
		botones_c[m] = bc
		fila_c.add_child(bc)
	var fila_z := HBoxContainer.new()
	fila_z.add_theme_constant_override("separation", 8)
	p._lista_ajustes.add_child(fila_z)
	var et_z := p._texto(12, Principal.COL_TEXTO)
	et_z.text = Idiomas.t("Modo zurdo (stick a la derecha)")
	et_z.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_z.add_child(et_z)
	var caja_z := CheckButton.new()
	caja_z.button_pressed = zurdo()
	caja_z.toggled.connect(func(v: bool) -> void: poner_zurdo(v))
	fila_z.add_child(caja_z)
	_deslizador(p, "Tamaño de los botones", TAM_MIN, TAM_MAX, tamano(), poner_tamano)
	_deslizador(p, "Opacidad de los botones", OP_MIN, OP_MAX, opacidad(), poner_opacidad)
	_deslizador(p, "Separación entre los botones", SEP_MIN, SEP_MAX, separacion(), poner_separacion)

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

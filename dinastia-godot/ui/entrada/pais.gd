class_name PantallaPais
extends Control
## ETAPA 3 DE LA ENTRADA: ELEGIR PAÍS (fase 1 del MEGAPLAN, `docs/PLAN_DEL_LUNES.md`
## §3.1, «Globo»). Pantalla propia a pantalla completa que monta `OrquestadorEntrada`:
##   · el globo 3D de siempre (`Globo3D`) para elegir girándolo o tocando un pin, y al
##     lado la lista por continentes (la vía rápida, y la accesible con teclado/mando);
##   · el NOMBRE COMPLETO del país en grande («Corea del Sur», no «KOR») con su nombre
##     oficial debajo;
##   · de fondo su bandera ondeando y CINCO MONUMENTOS que rotan cada 30 s (`PaisFondo`);
##   · a la derecha la ficha: liga, nivel, capital y sus clubes para elegir cuál dirigir.
##     Si el modo es CREAR CLUB, los clubes existentes no se muestran (`PaisFicha`).
## Al confirmar emite `terminado({"pais": código})` -más `"club_id"` si se eligió un club
## del mundo ya generado, que es lo que `OrquestadorMundo.club_elegido_id` busca-.
##
## CONTRATO (el de `OrquestadorEntrada`): `signal terminado(datos)`, `signal volver()`,
## `func configurar(estado)` -se llama ANTES de entrar al árbol-.

signal terminado(datos: Dictionary)
signal volver()

## El país marcado ahora mismo (código de tres letras).
var pais := ""
## ¿Se está creando un club? Entonces no se enseñan los clubes que ya existen.
var crear := false

var _estado: Dictionary = {}
var _mundo: Mundo = null
var _pais_inicial := "CHI"
var _fondo: PaisFondo
var _globo: Globo3D
var _lista: PaisLista
var _ficha: PaisFicha
var _conf: PaisConfirmacion
var _nombre: Label
var _oficial: Label
var _pista: Label
var _subtitulo: Label
var _rotulo_mon: Label
var _puntos: Array[ColorRect] = []
var _btn_confirmar: Button
var _texto_pista := ""

func configurar(estado: Dictionary) -> void:
	_estado = estado
	crear = PantallaPais.crea_club(estado)
	_mundo = estado.get("mundo") if estado.get("mundo") is Mundo else null
	var p := PantallaPais.pais_del_estado(estado)
	if PaisDatos.NOMBRE.has(p):
		_pais_inicial = p
	if is_node_ready():
		_subtitulo.text = _texto_subtitulo()
		pais = ""
		_elegir(_pais_inicial, true)

## Lee el modo venga como venga: «creador» (Crear tu Club) es el id de MODOS_JUEGO; los
## demás nombres son los que también acepta `OrquestadorMundo.crea_club`. Se lee aquí
## y no se llama a esa clase para que esta pantalla funcione sola (pruebas, capturas).
static func crea_club(estado: Dictionary) -> bool:
	var m: Variant = estado.get("modo")
	if m is Dictionary:
		if bool((m as Dictionary).get("crear", false)):
			return true
		m = (m as Dictionary).get("id", (m as Dictionary).get("modo", ""))
	var id := String(m) if (m is String or m is StringName) else ""
	if id in ["creador", "crear", "crear_club"]:
		return true
	if bool(estado.get("crear", false)) or bool(estado.get("crear_club", false)):
		return true
	var c: Variant = estado.get("config")
	return c is Dictionary and String((c as Dictionary).get("nombre_club", "")).strip_edges() != ""

static func pais_del_estado(estado: Dictionary) -> String:
	var p: Variant = estado.get("pais")
	if p is Dictionary:
		p = (p as Dictionary).get("pais", (p as Dictionary).get("codigo", ""))
	return String(p) if (p is String or p is StringName) else ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo = PaisFondo.new()
	add_child(_fondo)
	_fondo.monumento_cambiado.connect(_al_cambiar_monumento)
	_construir_cabecera()
	_globo = Globo3D.new()
	_colocar(_globo, 270, 112, -364, -250)
	add_child(_globo)
	_globo.pais_tocado.connect(func(p: String) -> void: _elegir(p))
	_globo.pais_sobre.connect(_al_pasar)
	_lista = PaisLista.new()
	_colocar(_lista, 20, 96, 0, -84, true, false)
	_lista.custom_minimum_size.x = 236
	add_child(_lista)
	_lista.elegido.connect(func(p: String) -> void: _elegir(p))
	_ficha = PaisFicha.new()
	_colocar(_ficha, -350, 96, -20, -84, false, true)
	add_child(_ficha)
	_construir_pie()
	_conf = PaisConfirmacion.new()
	add_child(_conf)
	_conf.aceptado.connect(_confirmado)
	resized.connect(_ajustar_zona)
	_ajustar_zona()
	_elegir(_pais_inicial, true)

## Ancla un control: los números positivos se miden desde la izquierda/arriba y los
## negativos desde la derecha/abajo (como los márgenes de CSS). `solo_izq`/`solo_der`
## lo pegan a un lado con ancho fijo.
func _colocar(c: Control, izq: float, arriba: float, der: float, abajo: float,
		solo_izq := false, solo_der := false) -> void:
	c.anchor_left = 1.0 if (izq < 0.0 or solo_der) else 0.0
	c.anchor_right = 0.0 if solo_izq else 1.0
	c.anchor_top = 1.0 if arriba < 0.0 else 0.0
	c.anchor_bottom = 1.0 if abajo <= 0.0 else 0.0
	c.offset_left = izq
	c.offset_right = izq + 236.0 if solo_izq else der
	c.offset_top = arriba
	c.offset_bottom = abajo

func _construir_cabecera() -> void:
	var izq := VBoxContainer.new()
	_colocar(izq, 22, 16, 0, 92, true)
	izq.add_theme_constant_override("separation", 2)
	add_child(izq)
	var r := Tema.rotulo(Idiomas.t("Elige tu país"))
	r.add_theme_color_override("font_color", Tema.ORO)
	izq.add_child(r)
	_subtitulo = Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, _texto_subtitulo())
	_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	izq.add_child(_subtitulo)
	_nombre = _etiqueta_grande(40)
	_colocar(_nombre, 270, 10, -364, 64)
	add_child(_nombre)
	_oficial = _etiqueta_grande(15)
	_oficial.add_theme_color_override("font_color", Color(Tema.TEXTO, 0.78))
	_colocar(_oficial, 270, 62, -364, 86)
	add_child(_oficial)

func _texto_subtitulo() -> String:
	return Idiomas.t("Fundarás un club nuevo: elige dónde nacerá.") if crear \
		else Idiomas.t("Elige el país donde empieza tu carrera.")

func _etiqueta_grande(tam: int) -> Label:
	var l := Tema.etiqueta(tam, Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("outline_size", maxi(4, tam / 6))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l

func _construir_pie() -> void:
	_texto_pista = Idiomas.t("Arrastra el globo para girarlo o toca un país.")
	_pista = Tema.etiqueta(Tema.TAM_ROTULO + 1, Color(Tema.TEXTO, 0.7), _texto_pista)
	_pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_colocar(_pista, 270, 88, -364, 106)
	add_child(_pista)
	## El monumento que se ve ahora y en cuál de los cinco va el ciclo.
	_rotulo_mon = _etiqueta_grande(15)
	_rotulo_mon.add_theme_color_override("font_color", Color("ffe2a6"))
	_colocar(_rotulo_mon, 270, -60, -364, -36)
	add_child(_rotulo_mon)
	var puntos := HBoxContainer.new()
	puntos.alignment = BoxContainer.ALIGNMENT_CENTER
	puntos.add_theme_constant_override("separation", 7)
	puntos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_colocar(puntos, 270, -32, -364, -24)
	add_child(puntos)
	for i in 5:
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(18, 4)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		puntos.add_child(d)
		_puntos.append(d)
	var volver_b := Button.new()
	volver_b.text = Idiomas.t("Volver")
	volver_b.custom_minimum_size = Vector2(150, 44)
	_colocar(volver_b, 20, -64, 0, -20, true)
	volver_b.offset_right = 170
	volver_b.pressed.connect(func() -> void: volver.emit())
	add_child(volver_b)
	_btn_confirmar = Button.new()
	_btn_confirmar.text = Idiomas.t("Confirmar país") + "  ▶"
	_btn_confirmar.add_theme_font_size_override("font_size", Tema.TAM_DESTACADO)
	_btn_confirmar.add_theme_stylebox_override("normal", Tema.caja(Tema.ACENTO, Tema.RADIO, Color(1, 1, 1, 0.2)))
	_btn_confirmar.add_theme_stylebox_override("hover", Tema.caja(Tema.ACENTO.lightened(0.15), Tema.RADIO, Color(1, 1, 1, 0.3)))
	_btn_confirmar.add_theme_stylebox_override("disabled", Tema.caja(Color(Tema.PANEL, 0.9), Tema.RADIO, Tema.BORDE))
	_btn_confirmar.add_theme_color_override("font_color", Color.WHITE)
	_colocar(_btn_confirmar, -350, -64, -20, -20, false, true)
	_btn_confirmar.pressed.connect(pedir_confirmacion)
	add_child(_btn_confirmar)

## El monumento es el horizonte sobre el que flota el globo: entre la lista y la ficha,
## de pie sobre su rótulo. NO va detrás del globo -se probó (captura 25-10): la Torre
## Eiffel quedaba tapada hasta las patas-; el globo termina justo donde empieza él.
func _ajustar_zona() -> void:
	if _fondo == null:
		return
	var x0 := 256.0
	var x1 := size.x - 350.0
	_fondo.fijar_zona(Rect2(x0, size.y - 246.0, maxf(100.0, x1 - x0), 246.0 - 66.0))

## Marca un país en todas partes: globo, lista, nombre, fondo y ficha.
func _elegir(p: String, instantaneo := false) -> void:
	if not PaisDatos.NOMBRE.has(p):
		return
	var antes := pais
	pais = p
	if antes != "" and antes != p:
		_globo.rotular(antes)
	_globo.rotular(p, PaisDatos.nombre(p))
	if _globo.pais_actual != p:
		_globo.ir_a(p, instantaneo)
	_lista.marcar(p)
	_fondo.poner_pais(p)
	_nombre.text = PaisDatos.nombre(p)
	_oficial.text = PaisDatos.oficial(p)
	if not instantaneo and antes != p:
		_nombre.modulate.a = 0.0
		create_tween().tween_property(_nombre, "modulate:a", 1.0, 0.35)
	_ficha.mostrar(p, crear, _mundo)
	_btn_confirmar.disabled = not PaisDatos.tiene_liga(p)

func _al_pasar(p: String) -> void:
	_pista.text = PaisDatos.nombre(p) if p != "" else _texto_pista

func _al_cambiar_monumento(indice: int, nombre: String) -> void:
	_rotulo_mon.text = Idiomas.t(nombre)
	for i in _puntos.size():
		_puntos[i].color = Color("ffd27a") if i == indice else Color(1, 1, 1, 0.25)

## Abre la confirmación (botón, Enter o A del mando). Sin liga no hay nada que confirmar.
func pedir_confirmacion() -> void:
	if pais == "" or not PaisDatos.tiene_liga(pais):
		return
	var detalle := ""
	if crear:
		detalle = Idiomas.t("Después decidirás cómo entra tu club al campeonato.")
	else:
		var c := _ficha.club_marcado()
		if c != null:
			detalle = Idiomas.t("Dirigirás a %s, de la %s.") % [c.nombre, PaisDatos.nombre_liga(pais)]
	_conf.abrir(pais, detalle)

func _confirmado() -> void:
	_conf.visible = false
	terminado.emit(datos())

## Lo que se emite al confirmar (también lo usa la prueba).
func datos() -> Dictionary:
	var d := {"pais": pais}
	if not crear and _ficha.club_id != "":
		d["club_id"] = _ficha.club_id
	return d

func _unhandled_input(event: InputEvent) -> void:
	if _conf.visible:
		if event.is_action_pressed("ui_cancel"):
			_conf.cerrar(true)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		volver.emit()
	elif event.is_action_pressed("ui_accept"):
		pedir_confirmacion()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
		_elegir(_lista.vecino(pais, -1))
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
		_elegir(_lista.vecino(pais, 1))
	else:
		return
	get_viewport().set_input_as_handled()

## Para pruebas y capturas: el fondo queda quieto y los cambios son instantáneos.
func sin_animaciones() -> void:
	_fondo.animar = false
	_globo.set("_giro_idle", 0.0)

func fondo() -> PaisFondo:
	return _fondo

func ficha() -> PaisFicha:
	return _ficha

func confirmacion() -> PaisConfirmacion:
	return _conf

func globo() -> Globo3D:
	return _globo

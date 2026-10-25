extends Control
## [Capa 1/2 de `personaje.gd`] el estado, `configurar` y la hoja de DATOS.

## LA ETAPA «PERSONAJE» (MEGAPLAN fase 1, etapa 6, 25-10-2026). Pantalla propia
## a pantalla completa y OBLIGATORIA del arranque: quién eres (aspecto y datos)
## con validación y una confirmación al final.
##   signal terminado({"personaje": dict})  ->  `PersonajeDatos.aplicar(dict, roles, anio)`
##   signal volver()                         ->  la etapa anterior
##   func configurar(estado)                 ->  lo elegido hasta aquí:
##       "personaje" (si se vuelve a esta etapa), "pais", "nombre", "modo",
##       "club" (un `Club`) o "color1"/"color2", "paso" (el número de etapa).

signal terminado(datos: Dictionary)
signal volver()

const SECCIONES := ["aspecto", "datos"]

var _p: Dictionary = PersonajeDatos.nuevo()
var _c1 := Color("1f5fa8")
var _c2 := Color.WHITE
var _paso := 6
var _modo := "dt"
var _seccion := "aspecto"
## Campos que el jugador ya tocó (sus errores se ven al momento; los demás,
## al intentar confirmar).
var _tocados := {}
var _intento := false
var _rng := RandomNumberGenerator.new()

var _hojas: HojasPersonaje
var _estudio: EstudioPersonaje
var _caja_datos: Control
var _errores_lbl := {}
var _campos := {}

func configurar(estado: Dictionary) -> void:
	_paso = int(estado.get("paso", _paso))
	_modo = String(estado.get("modo", _modo))
	## Los colores del club, de donde vengan: el `Club`, el del mundo ya
	## generado (`club_id`), o los del club que se funda en la configuración.
	var club: Variant = estado.get("club")
	var mundo: Variant = estado.get("mundo")
	if not (club is Club) and mundo is Mundo:
		club = (mundo as Mundo).clubes.get(String(estado.get("club_id", "")), (mundo as Mundo).mi_club())
	if club is Club:
		_c1 = Color((club as Club).color1)
		_c2 = Color((club as Club).color2)
	var conf: Variant = estado.get("config")
	for fuente: Variant in [conf, estado]:
		if fuente is Dictionary:
			if String((fuente as Dictionary).get("color1", "")) != "":
				_c1 = Color(String(fuente["color1"]))
			if String((fuente as Dictionary).get("color2", "")) != "":
				_c2 = Color(String(fuente["color2"]))
	var pais: Variant = estado.get("pais", "CHI")
	if pais is Dictionary:
		pais = (pais as Dictionary).get("pais", (pais as Dictionary).get("codigo", "CHI"))
	var previo: Variant = estado.get("personaje")
	if previo is Dictionary and not (previo as Dictionary).is_empty():
		_p = PersonajeDatos.nuevo()
		for k: String in previo:
			_p[k] = (previo as Dictionary)[k]
		_p["aspecto"] = PersonajeDT.aspecto(_p.get("aspecto", {}))
	else:
		_p = PersonajeDatos.nuevo(String(pais))
		var nombre := String(estado.get("nombre", "")).strip_edges()
		if nombre != "" and nombre != "Míster":
			var partes := nombre.split(" ", false, 1)
			_p["nombre"] = partes[0]
			_p["apellido"] = partes[1] if partes.size() > 1 else ""
		var asp: Variant = estado.get("aspecto")
		if asp is Dictionary:
			_p["aspecto"] = PersonajeDT.aspecto(asp)
	if is_inside_tree() and _hojas != null:
		_hojas.c1 = _c1
		_hojas.c2 = _c2
		_hojas.poner(_p["aspecto"], false)
		_estudio.colores(_c1, _c2)
		_pintar_datos()
		_refrescar()

## Lo que hay ahora mismo, cerrado (lo mismo que se emitiría).
func personaje() -> Dictionary:
	_p["aspecto"] = _hojas.asp.duplicate() if _hojas != null else _p["aspecto"]
	return PersonajeDatos.cerrar(_p)

func errores() -> Dictionary:
	return PersonajeDatos.validar(personaje())

## Para las pruebas y las capturas: rellena datos como si se escribieran.
func _poner_datos(d: Dictionary) -> void:
	for k: String in d:
		_p[k] = d[k]
		_tocados[k] = true
	_pintar_datos()
	_refrescar()

## Lo implementa la capa de arriba (la ficha, el paso, los botones).
func _refrescar() -> void:
	pass

# -----------------------------------------------------------------------------
#  LA HOJA DE DATOS
# -----------------------------------------------------------------------------

func _tarjeta(vb: VBoxContainer, titulo: String, campo: String) -> VBoxContainer:
	var pc := PanelContainer.new()
	var e := Tema.caja(Color("121b15"), Tema.RADIO, Color("ffffff10"))
	e.content_margin_left = 16
	e.content_margin_right = 16
	e.content_margin_top = 12
	e.content_margin_bottom = 12
	pc.add_theme_stylebox_override("panel", e)
	vb.add_child(pc)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 8)
	pc.add_child(dentro)
	ControlesPersonaje.rotulo(dentro, titulo)
	if campo != "":
		var err := Tema.etiqueta(Tema.TAM_ROTULO + 1, Tema.MAL, "")
		err.visible = false
		err.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_errores_lbl[campo] = err
		dentro.add_child(err)
	return dentro

func _linea(caja: BoxContainer, campo: String, sugerencia: String) -> LineEdit:
	var ln := LineEdit.new()
	ln.text = String(_p.get(campo, ""))
	ln.placeholder_text = Idiomas.t(sugerencia)
	ln.max_length = PersonajeDatos.LARGO_MAX
	ln.custom_minimum_size = Vector2(0, 40)
	ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ln.add_theme_font_size_override("font_size", Tema.TAM_DESTACADO)
	ln.text_changed.connect(func(t: String) -> void:
		_p[campo] = t
		_tocados[campo] = true
		_refrescar())
	_campos[campo] = ln
	caja.add_child(ln)
	return ln

func _pintar_datos() -> void:
	if _caja_datos == null:
		return
	for h in _caja_datos.get_children():
		_caja_datos.remove_child(h)
		h.queue_free()
	_errores_lbl.clear()
	_campos.clear()
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	_caja_datos.add_child(vb)
	## NOMBRE Y APELLIDO, con un dado que propone uno del país y del cuerpo elegidos.
	var cn := _tarjeta(vb, "Nombre y apellido", "")
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	cn.add_child(fila)
	var ln := _linea(fila, "nombre", "Nombre")
	var la := _linea(fila, "apellido", "Apellido")
	ln.text_submitted.connect(func(_t: String) -> void: la.grab_focus())
	var dado := ControlesPersonaje.chip("🎲", false, _nombre_al_azar)
	dado.toggle_mode = false
	dado.tooltip_text = Idiomas.t("Un nombre al azar de tu país")
	dado.custom_minimum_size = Vector2(44, 40)
	fila.add_child(dado)
	for campo: String in ["nombre", "apellido"]:
		var err := Tema.etiqueta(Tema.TAM_ROTULO + 1, Tema.MAL, "")
		err.visible = false
		_errores_lbl[campo] = err
		cn.add_child(err)
	## EDAD.
	var ce := _tarjeta(vb, "Edad", "edad")
	var fe := HBoxContainer.new()
	fe.add_theme_constant_override("separation", 12)
	ce.add_child(fe)
	var s := HSlider.new()
	s.min_value = PersonajeDatos.EDAD_MIN
	s.max_value = PersonajeDatos.EDAD_MAX
	s.step = 1
	s.value = int(_p.get("edad", PersonajeDatos.EDAD_DEFECTO))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fe.add_child(s)
	var ve := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.ORO, Idiomas.t("%d años") % int(s.value))
	ve.custom_minimum_size = Vector2(96, 0)
	ve.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fe.add_child(ve)
	s.value_changed.connect(func(v: float) -> void:
		_p["edad"] = int(v)
		ve.text = Idiomas.t("%d años") % int(v)
		_refrescar())
	_campos["edad"] = s
	## NACIONALIDAD: las banderas de los países del juego.
	var cp := _tarjeta(vb, "Nacionalidad", "nacionalidad")
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	cp.add_child(flow)
	var paises := PersonajeDatos.paises()
	for cod: String in paises:
		var codigo := cod
		var b := ControlesPersonaje.chip(PersonajeDatos.nombre_pais(codigo), String(_p["nacionalidad"]) == codigo,
			func() -> void:
				_p["nacionalidad"] = codigo
				_tocados["nacionalidad"] = true
				_pintar_datos()
				_refrescar())
		b.icon = Banderas.textura(codigo)
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 26)
		b.custom_minimum_size = Vector2(132, 34)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		flow.add_child(b)
	## ESTILO Y COMUNICACIÓN: tarjetas con su explicación.
	_eleccion(vb, "Tu idea de fútbol", "estilo", PersonajeDatos.ESTILOS)
	_eleccion(vb, "Cómo hablas ante la prensa", "comunicacion", PersonajeDatos.COMUNICACION)
	## Cada aviso de error, al pie de su tarjeta (debajo de lo que se elige).
	for campo: String in _errores_lbl:
		var l: Label = _errores_lbl[campo]
		l.get_parent().move_child(l, -1)
	_mostrar_errores()

func _eleccion(vb: VBoxContainer, titulo: String, campo: String, lista: Array) -> void:
	var c := _tarjeta(vb, titulo, campo)
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 8)
	rejilla.add_theme_constant_override("v_separation", 8)
	c.add_child(rejilla)
	for e: Array in lista:
		var clave := String(e[0])
		var b := ControlesPersonaje.chip("%s\n%s" % [Idiomas.t(String(e[1])), Idiomas.t(String(e[2]))],
			String(_p.get(campo, "")) == clave, func() -> void:
				_p[campo] = clave
				_tocados[campo] = true
				_pintar_datos()
				_refrescar())
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(200, 64)
		rejilla.add_child(b)

func _nombre_al_azar() -> void:
	var np := PersonajeDatos.nombre_al_azar(String(_p["nacionalidad"]), String(_hojas.asp["cuerpo"]) == "female", _rng)
	_p["nombre"] = np[0]
	_p["apellido"] = np[1]
	_tocados["nombre"] = true
	_tocados["apellido"] = true
	for campo: String in ["nombre", "apellido"]:
		if _campos.has(campo):
			(_campos[campo] as LineEdit).text = String(_p[campo])
	_refrescar()

## Los errores junto a su campo: los del campo tocado, o todos tras intentar
## confirmar. El campo con error se marca con el borde rojo.
func _mostrar_errores() -> Dictionary:
	var e := errores()
	for campo: String in _errores_lbl:
		var l: Label = _errores_lbl[campo]
		var ver := e.has(campo) and (_intento or _tocados.has(campo))
		l.visible = ver
		l.text = "⚠ " + String(e.get(campo, "")) if ver else ""
		if _campos.get(campo) is LineEdit:
			var ln: LineEdit = _campos[campo]
			var sb := Tema.caja(Color("0f1712"), Tema.RADIO_CHICO, Tema.MAL if ver else Color("ffffff24"))
			sb.set_border_width_all(2 if ver else 1)
			ln.add_theme_stylebox_override("normal", sb)
	return e

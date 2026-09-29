class_name PanelObjetivos
extends PanelContainer
## LOS OBJETIVOS, SIEMPRE A LA VISTA EN EL BORDE (29-9-2026). Pedido: *"déjame
## ver los objetivos en el borde de la pantalla como antes"*. El tutorial del
## mentor daba misiones solo mientras duraba la tarjeta; al cerrarla, no quedaba
## nada a la vista. Ahora hay una pestaña fija en el borde derecho con:
##   - lo que pide la directiva (el puesto) y dónde vas,
##   - la confianza del directorio,
##   - el próximo partido,
##   - las MISIONES DEL MENTOR de tu modo, que se tachan al hacerlas aunque el
##     tutorial ya esté cerrado (se guardan en `user://ajustes.cfg`).
## Se pliega con la pestaña 🎯 y recuerda si estaba plegado.

const AJUSTES := "user://ajustes.cfg"
## Para las pruebas: se puede apuntar a otro archivo.
static var ruta := AJUSTES
const SECCION := "objetivos"
const ANCHO := 270.0

var _principal: Node
var _modo := "dt"
var _cuerpo: VBoxContainer
var _lista: VBoxContainer
var _pestana: Button
var _plegado := false
var _t := 0.0
## MOVIBLE (29-9-2026, pedido del usuario): se arrastra desde cualquier parte
## que no sea un botón, y recuerda dónde lo dejaste.
var _arrastrando := false
var _agarre := Vector2.ZERO

static func crear(principal: Node, modo: String) -> PanelObjetivos:
	var p := PanelObjetivos.new()
	p._principal = principal
	p._modo = modo
	p._plegado = bool(_leer("plegado", false))
	p._montar()
	return p

static func _leer(clave: String, defecto: Variant) -> Variant:
	var c := ConfigFile.new()
	if c.load(ruta) != OK:
		return defecto
	return c.get_value(SECCION, clave, defecto)

static func _escribir(clave: String, valor: Variant) -> void:
	var c := ConfigFile.new()
	c.load(ruta)
	c.set_value(SECCION, clave, valor)
	c.save(ruta)

## Las misiones del mentor ya cumplidas en este modo (por su texto).
static func misiones_hechas(modo: String) -> Array:
	return _leer("hechas_" + modo, [])

static func marcar_mision(modo: String, mision: String) -> void:
	var h: Array = misiones_hechas(modo)
	if not h.has(mision):
		h.append(mision)
		_escribir("hechas_" + modo, h)

## La lista de objetivos, sin interfaz (el banco la comprueba).
## Cada uno: {icono, texto, hecho, clave?}.
static func lista(mundo: Mundo, modo: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if mundo == null or mundo.mi_club() == null:
		return out
	var c := mundo.mi_club()
	if mundo.directiva != null:
		var puesto := 0
		var jugados := 0
		for l in mundo.ligas:
			if l.clubes.has(c):
				var t := l.tabla()
				for i in t.size():
					if t[i]["club"] == c:
						puesto = i + 1
						jugados = int(t[i]["pj"])
		var meta := mundo.directiva.meta_puesto
		var obj := mundo.directiva.objetivo if mundo.directiva.objetivo != "" else "Terminar entre los %d primeros" % meta
		out.append({"icono": "🏆", "texto": "%s  ·  vas %dº (meta: %dº)" % [obj, puesto, meta], "hecho": jugados > 0 and puesto > 0 and puesto <= meta})
		var conf := mundo.directiva.confianza
		out.append({"icono": "🤝", "texto": "Confianza de la directiva: %d/100" % conf, "hecho": conf >= 50})
	var par := mundo.proximo_partido()
	if par.size() == 2:
		var local: bool = par[0] == c
		var rival: Club = par[1] if local else par[0]
		out.append({"icono": "⚽", "texto": "Próximo: %s %s" % ["vs" if local else "en casa de", Nombres.visible(rival.nombre)], "hecho": false})
	var hechas := misiones_hechas(modo)
	var guion := Tutorial.guion(modo, Tutorial.contexto(mundo, c.nombre))
	for p: Dictionary in guion["pasos"]:
		if not p.has("mision"):
			continue
		var m := String(p["mision"])
		out.append({"icono": "🧭", "texto": m, "hecho": hechas.has(m), "clave": String(p.get("hecho", "")), "mentor": true})
	return out

func _montar() -> void:
	name = "PanelObjetivos"
	set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", Tema.caja(Color(Tema.PANEL, 0.94), Tema.RADIO, Tema.ORO))
	var h := HBoxContainer.new()
	add_child(h)
	_pestana = Button.new()
	_pestana.flat = true
	_pestana.tooltip_text = "Mostrar u ocultar los objetivos"
	_pestana.pressed.connect(func() -> void:
		_plegado = not _plegado
		_escribir("plegado", _plegado)
		_aplicar_plegado())
	h.add_child(_pestana)
	_cuerpo = VBoxContainer.new()
	_cuerpo.custom_minimum_size = Vector2(ANCHO, 0)
	_cuerpo.add_theme_constant_override("separation", 6)
	h.add_child(_cuerpo)
	var cabeza := Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO, "🎯 OBJETIVOS   ✥")
	cabeza.tooltip_text = "Arrástralo para ponerlo donde quieras"
	cabeza.mouse_filter = Control.MOUSE_FILTER_PASS
	_cuerpo.add_child(cabeza)
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 4)
	_cuerpo.add_child(_lista)
	var tut := Button.new()
	tut.text = "🧭 Hablar con el mentor"
	tut.tooltip_text = "Vuelve a abrir el recorrido guiado de tu modo"
	tut.pressed.connect(func() -> void:
		if _principal != null and _principal.has_method("abrir_tutorial"):
			_principal.call("abrir_tutorial", _modo))
	_cuerpo.add_child(tut)
	_aplicar_plegado()
	gui_input.connect(_al_arrastrar)
	var guardada: Variant = _leer("posicion", Vector2(-1, -1))
	if guardada is Vector2 and (guardada as Vector2).x >= 0.0:
		_colocar_en.call_deferred(guardada)

func _colocar_en(pos: Vector2) -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	var vp := get_viewport_rect().size
	position = Vector2(clampf(pos.x, 0.0, maxf(0.0, vp.x - size.x)), clampf(pos.y, 0.0, maxf(0.0, vp.y - size.y)))

func _al_arrastrar(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := e as InputEventMouseButton
		if mb.pressed:
			_arrastrando = true
			_agarre = mb.position
			mouse_default_cursor_shape = Control.CURSOR_MOVE
		elif _arrastrando:
			_arrastrando = false
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			_escribir("posicion", position)
		accept_event()
	elif e is InputEventMouseMotion and _arrastrando:
		_colocar_en(position + (e as InputEventMouseMotion).position - _agarre)
		accept_event()
	elif e is InputEventScreenDrag:
		_colocar_en(position + (e as InputEventScreenDrag).relative)
		_escribir("posicion", position)
		accept_event()

func _aplicar_plegado() -> void:
	_cuerpo.visible = not _plegado
	_pestana.text = "🎯\n◂" if _plegado else "▸"
	reset_size()

func refrescar() -> void:
	if _lista == null or _principal == null:
		return
	var mundo: Mundo = _principal.get("mundo")
	for n in _lista.get_children():
		_lista.remove_child(n)
		n.queue_free()
	var pendientes := 0
	for o: Dictionary in lista(mundo, _modo):
		var hecho := bool(o["hecho"])
		if bool(o.get("mentor", false)) and hecho:
			continue
		if not hecho:
			pendientes += 1
		var l := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE if hecho else Tema.TEXTO,
			"%s %s %s" % ["✔" if hecho else "·", String(o["icono"]), String(o["texto"])])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(ANCHO, 0)
		_lista.add_child(l)
	_pestana.tooltip_text = "Objetivos (%d pendientes)" % pendientes
	reset_size()

## Las misiones del mentor se cumplen haciéndolas, con o sin tutorial abierto:
## se mira cada medio segundo si ya se hizo la pendiente.
func _process(delta: float) -> void:
	_t += delta
	if _t < 0.5 or _principal == null or not _principal.has_method("tutorial_hecho"):
		return
	_t = 0.0
	var mundo: Mundo = _principal.get("mundo")
	if mundo == null:
		return
	var hechas := misiones_hechas(_modo)
	var guion := Tutorial.guion(_modo, Tutorial.contexto(mundo, mundo.mi_club().nombre))
	for p: Dictionary in guion["pasos"]:
		if p.has("mision") and p.has("hecho") and not hechas.has(String(p["mision"])):
			if bool(_principal.call("tutorial_hecho", String(p["hecho"]))):
				marcar_mision(_modo, String(p["mision"]))
				if Sonido.NOMBRES.has("logro"):
					Sonido.toca("logro")
				refrescar()
			return

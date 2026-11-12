class_name PaginadorSubmenu
extends HBoxContainer
## EL PAGINADOR DE UN MENÚ (12-11, menús partidos en pantallas completas): en la fila de «Portada», a la derecha, «◂ anterior · 2 / 5 ·
## siguiente ▸» con el NOMBRE de la pantalla de cada lado. Con mando o teclado ya se pasaba con L1/R1 (`PantallaMenu.submenu_vecino`); con
## el dedo o el ratón había que volver a la portada cada vez. Solo cuenta las pantallas (los submenús que son una acción se saltan).
var _pm: Node
var _ant: Button
var _sig: Button
var _pos: Label
var _corto := false

static func crear(pm: Node, corto: bool) -> PaginadorSubmenu:
	var pg := PaginadorSubmenu.new()
	pg._pm = pm
	pg._corto = corto
	pg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pg.alignment = BoxContainer.ALIGNMENT_END
	pg.add_theme_constant_override("separation", 8)
	pg._ant = pm._boton_plano("◂", 13)
	pg._ant.pressed.connect(func() -> void: pm.submenu_vecino(-1))
	pg.add_child(pg._ant)
	pg._pos = Label.new()
	pg._pos.add_theme_font_size_override("font_size", 13)
	pg._pos.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	pg._pos.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pg.add_child(pg._pos)
	pg._sig = pm._boton_plano("▸", 13)
	pg._sig.pressed.connect(func() -> void: pm.submenu_vecino(1))
	pg.add_child(pg._sig)
	return pg

## El índice de la pantalla vecina (saltando las acciones), dando la vuelta; −1 si no hay otra.
static func vecino(subs: Array, activo: int, paso: int) -> int:
	var i := activo
	for _k in subs.size():
		i = (i + paso + subs.size()) % subs.size()
		if not (subs[i] as Dictionary).has("accion"):
			return i if i != activo else -1
	return -1

## «2 / 5»: el puesto de la pantalla activa entre las que son pantallas.
static func puesto(subs: Array, activo: int) -> Vector2i:
	var n := 0
	var mio := 0
	for i in subs.size():
		if not (subs[i] as Dictionary).has("accion"):
			n += 1
			if i == activo:
				mio = n
	return Vector2i(mio, n)

func actualizar() -> void:
	var subs: Array = _pm.menu()["subs"]
	var activo: int = _pm.submenu_activo()
	var a := vecino(subs, activo, -1)
	var s := vecino(subs, activo, 1)
	visible = activo >= 0 and s >= 0
	if not visible:
		return
	var p := puesto(subs, activo)
	_pos.text = "%d / %d" % [p.x, p.y]
	_ant.visible = p.y > 2   ## con dos pantallas, «anterior» y «siguiente» son la misma: sobra uno
	_ant.text = "◂" if _corto else "◂  %s" % Idiomas.t(String(subs[a]["label"]))
	_sig.text = "▸" if _corto else "%s  ▸" % Idiomas.t(String(subs[s]["label"]))
	_ant.tooltip_text = Idiomas.t(String(subs[a]["label"]))
	_sig.tooltip_text = Idiomas.t(String(subs[s]["label"]))

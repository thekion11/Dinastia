extends Control
## [Capa 1/2 de `creador_personaje.gd`] abrir, la hoja de Conjuntos y los botones.

## EL CREADOR DE PERSONAJE DEL MENÚ (26-9-2026; rehecho el 25-10-2026 sobre las
## piezas de la etapa de entrada). Pedido del usuario: *"ve por el modelo de
## nuestro personaje, el modificable"*.
##
## A la izquierda, tu personaje en 3D (`EstudioPersonaje`: gira, se arrastra,
## se acerca a la cara). A la derecha, las hojas del aspecto (`HojasPersonaje`:
## Cuerpo · Cara y pelo · Ropa · Accesorios) y aquí la de Conjuntos.
## Arriba: Al azar (coherente), Deshacer, Cancelar y Guardar. Guardar deja el
## aspecto en `Roles.look["p3d"]` (`PersonajeDatos.aplicar_aspecto`): el mismo
## que se ve en la banda de cada partido. La etapa «Personaje» del arranque
## (`PantallaPersonaje`) usa las mismas piezas: los dos se ven igual.

signal cerrado

const MAX_CONJUNTOS := 5

var _mundo: Mundo
var _original: Dictionary = {}
var _pestanas: HojasPersonaje
var _estudio: EstudioPersonaje
var _capa: CanvasLayer = null
var _menu: Control = null
var _aviso: Label
var _b_deshacer: Button
var _avisado_salir := false
var _c1 := Color("1f5fa8")
var _c2 := Color.WHITE
var _rng := RandomNumberGenerator.new()

static func abrir(padre: Control, mundo: Mundo) -> CreadorPersonaje:
	var n := CreadorPersonaje.new()
	n._mundo = mundo
	n._original = PersonajeDT.aspecto(mundo.roles.aspecto_3d())
	var club := mundo.mi_club()
	if club != null:
		n._c1 = Color(club.color1)
		n._c2 = Color(club.color2)
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	if padre.is_inside_tree():
		n._capa = CanvasLayer.new()
		n._capa.layer = 60
		n._capa.name = "CreadorPersonaje"
		padre.get_tree().root.add_child(n._capa)
		n._capa.add_child(n)
		n._menu = padre
		padre.visible = false
	else:
		padre.add_child(n)
	n._montar()
	return n

## El aspecto que se está editando.
func aspecto() -> Dictionary:
	return _pestanas.asp if _pestanas != null else _original

func _hay_cambios() -> bool:
	return PersonajeDT.aspecto(aspecto()) != _original

## Hasta cinco conjuntos guardados con nombre: para cambiar de traje de gala a
## chándal de entrenamiento sin rehacerlo todo.
func _hoja_conjuntos() -> Control:
	var vb := HojasPersonaje.hoja()
	ControlesPersonaje.rotulo(vb, "Guardar el aspecto actual")
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	vb.add_child(fila)
	var nombre := LineEdit.new()
	nombre.placeholder_text = Idiomas.t("Nombre (p. ej. Gala, Entrenamiento)")
	nombre.max_length = 24
	nombre.custom_minimum_size = Vector2(0, 36)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(nombre)
	var conjuntos: Array = _mundo.roles.look.get("p3d_conjuntos", [])
	var bg := ControlesPersonaje.chip(Idiomas.t("Guardar conjunto"), false, func() -> void:
		var n := nombre.text.strip_edges()
		if n == "":
			n = Idiomas.t("Conjunto %d") % (conjuntos.size() + 1)
		conjuntos.append({"n": n, "a": aspecto().duplicate()})
		while conjuntos.size() > MAX_CONJUNTOS:
			conjuntos.pop_front()
		_mundo.roles.look["p3d_conjuntos"] = conjuntos
		_pestanas.pintar())
	bg.toggle_mode = false
	fila.add_child(bg)
	ControlesPersonaje.rotulo(vb, "Tus conjuntos", "como mucho cinco: el más viejo deja sitio al nuevo")
	if conjuntos.is_empty():
		ControlesPersonaje.nota(vb, "Todavía no guardaste ninguno.")
	for i in conjuntos.size():
		var cj: Dictionary = conjuntos[i]
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 6)
		vb.add_child(f)
		var et := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "👔 " + String(cj.get("n", "")))
		et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f.add_child(et)
		var bp := ControlesPersonaje.chip(Idiomas.t("Ponérmelo"), false, func() -> void: _pestanas.poner(cj.get("a", {})))
		bp.toggle_mode = false
		f.add_child(bp)
		var idx := i
		var bb := ControlesPersonaje.chip("✕", false, func() -> void:
			conjuntos.remove_at(idx)
			_mundo.roles.look["p3d_conjuntos"] = conjuntos
			_pestanas.pintar())
		bb.toggle_mode = false
		bb.tooltip_text = Idiomas.t("Borrar")
		f.add_child(bb)
	return HojasPersonaje.raiz(vb)

## Al azar, pero con sentido (sin barba en una mujer, corbata solo con traje,
## canas según tu edad...). La edad sale de tu perfil si lo hay.
func _aleatorio() -> void:
	_rng.randomize()
	var edad := int((_mundo.roles.look.get("perfil", {}) as Dictionary).get("edad", _mundo.roles.look.get("edad", PersonajeDatos.EDAD_DEFECTO)))
	_pestanas.poner(PersonajeDatos.aspecto_coherente(_rng, -1, edad))

func _deshacer() -> void:
	_pestanas.deshacer()

## Cancelar con cambios sin guardar pide un segundo toque: un clic sin querer
## no tira media hora de vestir al personaje.
func _cancelar() -> void:
	if _hay_cambios() and not _avisado_salir:
		_avisado_salir = true
		_aviso.text = Idiomas.t("Tienes cambios sin guardar: pulsa otra vez «Cancelar» para descartarlos.")
		_aviso.visible = true
		Animar.pulso(_aviso)
		return
	_cerrar()

func _cerrar() -> void:
	if is_instance_valid(_menu):
		_menu.visible = true
	cerrado.emit()
	if _capa != null:
		_capa.queue_free()
	else:
		queue_free()

func _guardar() -> void:
	PersonajeDatos.aplicar_aspecto(_mundo.roles, aspecto())
	Aviso.mostrar(_menu if is_instance_valid(_menu) else get_parent() as Control, "logro", "🧍",
		Idiomas.t("Personaje guardado"), Idiomas.t("Así te verán en la banda"))
	_cerrar()

func _al_cambiar(a: Dictionary) -> void:
	_estudio.mostrar(a)
	_avisado_salir = false
	if _aviso != null:
		_aviso.visible = false
	if _b_deshacer != null:
		_b_deshacer.disabled = not _pestanas.puede_deshacer()

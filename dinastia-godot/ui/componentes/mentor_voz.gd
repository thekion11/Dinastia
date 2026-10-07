class_name MentorVoz
extends PanelContainer
## EL MENTOR, FUERA DEL TUTORIAL (26-9-2026, plan maestro C1). Pedido: *"integrando
## así los eventos a la rueda de prensa y a los diálogos del mentor"*. El mentor
## de tu modo -el presidente si entrenas, tu jefe si eres ayudante, el enviado
## del fondo si eres el jeque (`Tutorial.mentor_de`)- asoma abajo a la izquierda
## con su cara y dos frases cuando pasa algo que merece un consejo. Se va solo a
## los `DURA` segundos o con un clic. Uno a la vez: si llegan dos, el segundo
## espera.

const DURA := 9.0
const ANCHO := 420.0

static var _cola: Array[Dictionary] = []
static var _mostrando := false

static func decir(padre: Control, mundo: Mundo, titulo: String, texto: String) -> void:
	_cola.append({"padre": padre, "mundo": mundo, "titulo": titulo, "texto": texto})
	if not _mostrando:
		_siguiente()

static func _siguiente() -> void:
	if _cola.is_empty():
		_mostrando = false
		return
	var d: Dictionary = _cola.pop_front()
	var padre: Control = d["padre"]
	if padre == null or not is_instance_valid(padre) or not padre.is_inside_tree():
		_siguiente()
		return
	_mostrando = true
	var v := MentorVoz.new()
	padre.add_child(v)
	v._montar(d["mundo"], String(d["titulo"]), String(d["texto"]))

func _montar(mundo: Mundo, titulo: String, texto: String) -> void:
	var modo: String = mundo.roles.modo_actual() if mundo != null and mundo.roles != null else "dt"
	var ctx := Tutorial.contexto(mundo)
	var m := Tutorial.mentor_de(modo, ctx)
	add_theme_stylebox_override("panel", Tema.caja(Color(0.07, 0.10, 0.08, 0.96), Tema.RADIO_GRANDE, Tema.ACENTO))
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = 18.0
	offset_right = 18.0 + ANCHO
	offset_bottom = -18.0
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	custom_minimum_size = Vector2(ANCHO, 0)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	add_child(h)
	var cara := TextureRect.new()
	cara.texture = Tutorial._cara_mentor(m, ctx)
	cara.custom_minimum_size = Vector2(72, 72)
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(cara)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "%s · %s" % [String(m["nombre"]), String(m["cargo"])]))
	v.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.ORO, titulo))
	var t := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "«%s»" % texto)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(ANCHO - 110.0, 0)
	v.add_child(t)
	gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_cerrar())
	Animar.aparecer(self)
	Sonido.toca("notificacion" if Sonido.NOMBRES.has("notificacion") else "cambio", Sonido.Bus.INTERFAZ)
	get_tree().create_timer(DURA).timeout.connect(_cerrar)

var _cerrado := false

func _cerrar() -> void:
	if _cerrado or not is_inside_tree():
		return
	_cerrado = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		queue_free()
		MentorVoz._siguiente())

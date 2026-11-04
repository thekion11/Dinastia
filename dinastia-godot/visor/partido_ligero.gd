class_name PartidoLigero
extends Node
## PARTIDO LIGERO (4-11, orden 32 del dueño): un AGREGADO aparte de la calidad gráfica. Se enciende en Ajustes en CUALQUIER
## calidad y viene APAGADO en todas (también en Mínima). Encendido, el estadio 3D se dibuja sin el ajuste de color del
## entorno, sin los rótulos 3D (Label3D) y sin las luces de foco (todas menos el sol): medido en el contenedor (llvmpipe,
## `pruebas/inventario_partido_gpu.tscn`) −18 %, −15 % y −12 % de dibujo en MÍNIMA cada uno. Cambia el aspecto: por eso es opcional.
## Lo guarda `Calidad` en grafica.cfg (`partido_ligero`). Vigila también lo que se crea después (carteles perezosos, focos de la noche).

var _raiz: Node

## Lo monta el estadio 3D al construirse (`estadio_p3.gd`); sin la opción no hace nada.
static func montar(raiz: Node) -> void:
	if not Calidad.partido_ligero or raiz == null or raiz.get_node_or_null("PartidoLigero") != null:
		return
	var o := PartidoLigero.new()
	o.name = "PartidoLigero"
	o._raiz = raiz
	raiz.add_child(o)

func _ready() -> void:
	for n in _raiz.find_children("*", "", true, false):
		_aligerar(n)
	get_tree().node_added.connect(_al_crear)

func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_al_crear):
		get_tree().node_added.disconnect(_al_crear)

func _al_crear(n: Node) -> void:
	if is_instance_valid(_raiz) and _raiz.is_ancestor_of(n):
		_aligerar.call_deferred(n)

static func _aligerar(n: Node) -> void:
	if not is_instance_valid(n):
		return
	if n is WorldEnvironment and (n as WorldEnvironment).environment != null:
		(n as WorldEnvironment).environment.adjustment_enabled = false
	elif n is Label3D:
		(n as Label3D).visible = false
	elif n is Light3D and not n is DirectionalLight3D:
		(n as Light3D).visible = false

## El interruptor de Ajustes, separado de la calidad gráfica (se ve en todas).
static func crear(p: Object) -> void:
	var cb := CheckButton.new()
	cb.text = Idiomas.t("Partido ligero (extra, en cualquier calidad)")
	cb.tooltip_text = Idiomas.t("Quita el ajuste de color, los rótulos 3D y los focos del estadio para ganar fluidez. Cambia el aspecto; se aplica al abrir el estadio.")
	cb.button_pressed = Calidad.partido_ligero
	cb.add_theme_font_size_override("font_size", 11)
	cb.toggled.connect(func(si: bool) -> void:
		Calidad.partido_ligero = si
		Calidad.guardar())
	p._lista_ajustes.add_child(cb)

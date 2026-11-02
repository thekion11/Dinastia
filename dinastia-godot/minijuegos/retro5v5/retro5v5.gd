class_name Retro5v5
extends CanvasLayer
## EL MINIJUEGO RETRO 5 CONTRA 5 (01-11-2026, de github.com/Habeeb-Rahman-CA/soccer5v5-game-godot, MIT; orden del dueño: «agarrar
## todo»). Se abre ENCIMA de lo que haya (la recreativa de la ciudad), con el árbol en pausa: el juego original va a 280×180 con
## píxeles nítidos, así que corre en un SubViewport de ese tamaño que se escala a la pantalla sin suavizar. Esc lo cierra y
## devuelve el mundo como estaba. Controles: jugador 1 WASD + F (pase/entrada) + Espacio (tiro); jugador 2 flechas + K + L.
##   Retro5v5.abrir(get_tree())
signal cerrado
const MUNDO := "res://minijuegos/retro5v5/scenes/world.tscn"
const ANCHO := 280
const ALTO := 180

var _vista: SubViewport
var _pausa_antes := false

static func abrir(arbol: SceneTree) -> Retro5v5:
	var r := Retro5v5.new()
	r.layer = 120
	r.process_mode = Node.PROCESS_MODE_ALWAYS
	arbol.root.add_child.call_deferred(r)   ## diferido: se puede abrir desde el _ready de cualquiera
	return r

func _ready() -> void:
	_pausa_antes = get_tree().paused
	get_tree().paused = true
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_vista = SubViewport.new()
	_vista.size = Vector2i(ANCHO, ALTO)
	_vista.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vista.process_mode = Node.PROCESS_MODE_ALWAYS
	_vista.audio_listener_enable_2d = true
	add_child(_vista)
	var mundo := (load(MUNDO) as PackedScene).instantiate()
	mundo.process_mode = Node.PROCESS_MODE_ALWAYS
	_vista.add_child(mundo)
	var pantalla := TextureRect.new()
	pantalla.texture = _vista.get_texture()
	pantalla.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pantalla.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pantalla)
	for a: Node in [GameEvents, KeyUtils, DataLoader]:
		a.process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.iniciar()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and (e as InputEventKey).pressed and (e as InputEventKey).physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cerrar()

func cerrar() -> void:
	GameManager.detener()
	get_tree().paused = _pausa_antes
	cerrado.emit()
	queue_free()

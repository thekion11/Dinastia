class_name MenuModosFondo
extends Control
## EL FONDO QUE CAMBIA CON CADA MODO (fase 1 del megaplan, etapa 2: el menú
## inicial de modos). Al pasar el cursor o el foco por un modo, el fondo de
## TODA la pantalla funde hacia el «ambiente» de ese modo: el estadio con sus
## focos para el entrenador, la maquinaria del club para el director deportivo,
## el atardecer de las inferiores para la cantera, la ciudad de noche para el
## dueño…
##
## No hay un fondo nuevo dibujado para esto: cada ambiente es uno de los nueve
## estilos de `ui/fondo_menu.gdshader` (el mismo que ya usan los menús del panel
## lateral y la Carrera de Jugador) con tres colores propios. Así el jugador
## reconoce después, dentro de la partida, el aire del modo que eligió.
##
## POR QUÉ CADA CAPA VA DENTRO DE UN `CanvasGroup`: el shader escribe `COLOR`
## entero, y en Godot 4 eso pisa el `modulate` del nodo; un fundido con
## `modulate:a` sobre el `ColorRect` no se vería (saltaría de golpe). El
## `CanvasGroup` pinta su contenido a un búfer y lo dibuja él con su propio
## `self_modulate`, que sí se respeta: el fundido es real.

const SHADER := preload("res://ui/fondo_menu.gdshader")

## Lo que tarda el fundido de un ambiente al siguiente. Más corto parecía un
## parpadeo al bajar rápido por la lista; más largo, que el menú iba tarde.
const SEG_TRANSICION := 0.6
## Capas a la vez como mucho. Si se recorre la lista a toda velocidad cada modo
## abre su capa encima de la anterior; más de tres no se distinguen y cuestan
## tres pasadas de shader a pantalla completa.
const MAX_CAPAS := 3

## El ambiente de cada modo: estilo de `fondo_menu.gdshader` y sus tres colores
## (fondo de arriba, fondo de abajo, luz). Dos modos vecinos de la lista nunca
## comparten estilo: el cambio se tiene que notar de uno al siguiente.
const AMBIENTES := {
	"dt": {"estilo": 8, "c": ["07130c", "113a22", "9be7b4"]},         ## focos sobre el césped
	"dir": {"estilo": 6, "c": ["060b14", "0e1c30", "6fb2ff"]},        ## engranajes: la maquinaria del club
	"ayudante": {"estilo": 1, "c": ["0e1107", "1d2510", "c4dc6a"]},   ## el banco, la gente, de cerca
	"interino": {"estilo": 0, "c": ["170904", "2e140a", "ff8a50"]},   ## luz de emergencia y polvo
	"cantera": {"estilo": 4, "c": ["130b20", "0b0716", "b98cff"]},    ## atardecer en las inferiores
	"imperio": {"estilo": 7, "c": ["0e0b05", "231b0c", "e6c27a"]},    ## la ciudad que es tuya
	"jeque": {"estilo": 2, "c": ["05110d", "0b231c", "5fe0b8"]},      ## hilos de oro: sin límite
	"creador": {"estilo": 5, "c": ["0f0716", "1d0f2b", "d08cff"]},    ## el plano del club que vas a fundar
	"retos": {"estilo": 6, "c": ["170707", "2e0e0e", "ff6b6b"]},      ## anillos: una diana
	"tutorial": {"estilo": 1, "c": ["051214", "0b2427", "6fe3e3"]},   ## luces suaves para aprender
	"carrera-m": {"estilo": 3, "c": ["050608", "0e1218", "8fd62a"]},  ## el de la propia Carrera de Jugador
	"fondo": {"estilo": 3, "c": ["07090d", "121720", "9fb0c8"]},      ## los números de un fondo de inversión
}

var _capas: Array[CanvasGroup] = []
var _clave := ""
var _tween: Tween

## El ambiente de un modo. Uno que no esté en la tabla (un modo nuevo en
## `MODOS_JUEGO`) no se queda sin fondo: saca uno de sus propios colores de
## tarjeta y un estilo fijo según su id.
static func ambiente_de(m: Dictionary) -> Dictionary:
	var id := String(m.get("id", ""))
	if AMBIENTES.has(id):
		return AMBIENTES[id]
	var c1 := Color(String(m.get("c1", "#161b22")))
	var c2 := Color(String(m.get("c2", "#30363d")))
	return {"estilo": absi(id.hash()) % 9,
		"c": [c1.darkened(0.6).to_html(false), c1.darkened(0.25).to_html(false), c2.lightened(0.35).to_html(false)]}

## El color de la luz del modo: lo usan las partículas, el acento de la lista y
## la ficha, para que todo el menú cambie de tono a la vez.
static func luz_de(m: Dictionary) -> Color:
	return Color(String((ambiente_de(m)["c"] as Array)[2]))

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_al_redimensionar)

## Lleva el fondo al ambiente del modo. `al_instante`: sin fundido (la primera
## vez que se abre el menú no hay nada de lo que fundir).
func mostrar(m: Dictionary, al_instante: bool = false) -> void:
	var id := String(m.get("id", ""))
	if id == _clave and not _capas.is_empty():
		return
	_clave = id
	var capa := _nueva_capa(ambiente_de(m))
	add_child(capa)
	_capas.append(capa)
	while _capas.size() > MAX_CAPAS:
		_capas.pop_front().queue_free()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if al_instante or _capas.size() == 1:
		capa.self_modulate.a = 1.0
		_limpiar_debajo()
		return
	capa.self_modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(capa, "self_modulate:a", 1.0, SEG_TRANSICION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_limpiar_debajo)

## El id del ambiente que se ve (o al que se está fundiendo).
func clave() -> String:
	return _clave

func capas_vivas() -> int:
	return _capas.size()

func en_transicion() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()

## El estilo y los colores de la capa de arriba (para las pruebas).
func estilo_visible() -> int:
	if _capas.is_empty():
		return -1
	return int(_capas.back().get_meta("estilo", -1))

## Terminado el fundido, lo que queda debajo ya no se ve: se suelta.
func _limpiar_debajo() -> void:
	while _capas.size() > 1:
		_capas.pop_front().queue_free()

func _nueva_capa(a: Dictionary) -> CanvasGroup:
	var g := CanvasGroup.new()
	g.set_meta("estilo", int(a["estilo"]))
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size = size
	var cols: Array = a["c"]
	## Con el motor ligero (gama baja) va el color fijo, como en `PantallaMenu`:
	## el shader usa TIME y obliga a redibujar la pantalla en cada fotograma.
	if Calidad.motor_ligero:
		r.color = Color(String(cols[1]))
	else:
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter("estilo", int(a["estilo"]))
		mat.set_shader_parameter("c1", Color(String(cols[0])))
		mat.set_shader_parameter("c2", Color(String(cols[1])))
		mat.set_shader_parameter("c3", Color(String(cols[2])))
		mat.set_shader_parameter("aspecto", _aspecto())
		r.material = mat
	g.add_child(r)
	return g

func _aspecto() -> Vector2:
	return Vector2(size.x / maxf(size.y, 1.0), 1.0) if size.y > 0.0 else Vector2(1.777, 1.0)

func _al_redimensionar() -> void:
	for g in _capas:
		var r := g.get_child(0) as ColorRect
		r.size = size
		if r.material is ShaderMaterial:
			(r.material as ShaderMaterial).set_shader_parameter("aspecto", _aspecto())

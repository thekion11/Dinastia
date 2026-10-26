class_name MenuModosLogo
extends Control
## EL LOGO ANIMADO DEL MENÚ DE MODOS (fase 1, etapa 2). Arriba a la derecha,
## a los 20 s de estar en el menú (lo pone `PantallaModos`): el que entra con
## las cosas claras elige antes y no lo ve; el que se queda mirando los modos
## recibe el sello del juego sin que le tape nada.
##
## ES LA MISMA MARCA QUE LA INTRO (`intro_dibujo.gd`): el logo definitivo (26-10-2026,
## `assets/logo/logo_256.png`), y antes el escudo dibujado (medio
## contorno con el borde de arriba hundido hacia el centro y la curva hasta la
## punta), la misma corona, el monograma y la palabra en serif de rótulo. Aquí,
## en pequeño y en oro: el contorno se traza por los dos lados a la vez desde
## arriba, se rellena, cae la corona y las letras entran una a una; después un
## reflejo cruza el conjunto cada pocos segundos (`menu_modos_logo.gdshader`).
## Las proporciones se copian (no se leen de la intro) para no atar esta
## pantalla a otra que se puede rehacer.
## Se DIBUJA, no es una imagen: no pesa nada y queda nítido a cualquier tamaño.

const SHADER := preload("res://ui/entrada/menu_modos_logo.gdshader")
const TAM_LETRA := 34
const SEPARACION := 2.0
const SEG_DIBUJO := 2.6

## El escudo: ancho en píxeles (la unidad de la intro) y su centro.
const LOGO := "res://assets/logo/logo_256.png"
const ANCHO_ESCUDO := 72.0
const CENTRO_ESCUDO := Vector2(38, 43)
const X_PALABRA := 80.0
const Y_PALABRA := 60.0

var progreso := 0.0     ## 0 = nada dibujado; 1 = logo entero
var _palabra := ""
var _fuente: Font
var _ancho_palabra := 0.0
var _logo: Texture2D

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_palabra = Idiomas.t("DINASTÍA")
	_fuente = _serif()
	for i in _palabra.length():
		_ancho_palabra += _fuente.get_string_size(_palabra[i], HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_LETRA).x + SEPARACION
	custom_minimum_size = Vector2(X_PALABRA + _ancho_palabra + 8.0, 86.0)
	size = custom_minimum_size
	_logo = load(LOGO) as Texture2D
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("ancho", custom_minimum_size.x)
	material = mat

## La misma serif de rótulo que la intro: la primera que tenga el sistema, y si
## no hay ninguna, Cinzel propia (`Fuentes.serif`).
static func _serif() -> Font:
	return Fuentes.serif(Fuentes.SERIF_ROTULO, "Cinzel", 700)

func mostrado() -> bool:
	return visible and progreso > 0.0

## Entra: fundido y un pequeño rebote de escala desde su esquina, y en paralelo
## el dibujo se va completando. Llamarlo dos veces no lo repite.
func aparecer() -> void:
	if visible:
		return
	visible = true
	progreso = 0.0
	modulate.a = 0.0
	pivot_offset = Vector2(size.x, 0.0)
	scale = Vector2(0.86, 0.86)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(_poner_progreso, 0.0, 1.0, SEG_DIBUJO).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Lo deja dibujado del todo, sin animación (capturas y pruebas).
func completar() -> void:
	visible = true
	modulate.a = 1.0
	scale = Vector2.ONE
	_poner_progreso(1.0)

func _poner_progreso(p: float) -> void:
	progreso = p
	queue_redraw()

## Cuánto va de un tramo [a, b] del dibujo, de 0 a 1.
func _tramo(a: float, b: float) -> float:
	return clampf((progreso - a) / (b - a), 0.0, 1.0)

func _draw() -> void:
	if progreso <= 0.0:
		return
	var oro := Tema.ORO
	var oro_claro := oro.lightened(0.35)
	## 1) El logo: aparece creciendo un poco mientras se aclara.
	var pl := smoothstep(0.0, 1.0, _tramo(0.0, 0.4))
	if pl > 0.0 and _logo != null:
		var lado := ANCHO_ESCUDO * lerpf(0.9, 1.0, pl)
		draw_texture_rect(_logo, Rect2(CENTRO_ESCUDO - Vector2(lado, lado) * 0.5, Vector2(lado, lado)), false, Color(1, 1, 1, pl))
	## 2) Las letras, una a una, bajando un poco a su sitio.
	var x := X_PALABRA
	for i in _palabra.length():
		var letra := _palabra[i]
		var a := _tramo(0.45 + float(i) * 0.05, 0.6 + float(i) * 0.05)
		var w := _fuente.get_string_size(letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_LETRA).x
		if a > 0.0:
			var base := Vector2(x, Y_PALABRA - (1.0 - a) * 8.0)
			## Sombra corta: sobre los fondos claros (el atardecer de la cantera)
			## el claro solo se perdía.
			draw_string(_fuente, base + Vector2(0, 2), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_LETRA, Color(0, 0, 0, 0.5 * a))
			draw_string(_fuente, base, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_LETRA, Color(oro_claro.lerp(Color.WHITE, 0.4), a))
		x += w + SEPARACION
	## 3) La raya dorada bajo la palabra, de izquierda a derecha.
	var raya := _tramo(0.75, 1.0)
	if raya > 0.0:
		var y := Y_PALABRA + 9.0
		draw_line(Vector2(X_PALABRA, y), Vector2(X_PALABRA + (_ancho_palabra - SEPARACION) * raya, y), Color(oro, 0.85), 1.6, true)

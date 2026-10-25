class_name MenuModosLogo
extends Control
## EL LOGO ANIMADO DEL MENÚ DE MODOS (fase 1, etapa 2). Arriba a la derecha,
## a los 20 s de estar en el menú (lo pone `PantallaModos`): el que entra con
## las cosas claras elige antes y no lo ve; el que se queda mirando los modos
## recibe el sello del juego sin que le tape nada.
##
## ES LA MISMA MARCA QUE LA INTRO (`intro_dibujo.gd`): el mismo escudo (medio
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
const ANCHO_ESCUDO := 50.0
const CENTRO_ESCUDO := Vector2(36, 48)
const ESCUDO_ALTO := 1.18
const CORONA := [Vector2(-0.24, 0.0), Vector2(0.24, 0.0), Vector2(0.27, -0.14), Vector2(0.13, -0.065),
	Vector2(0.0, -0.20), Vector2(-0.13, -0.065), Vector2(-0.27, -0.14)]
const X_PALABRA := 80.0
const Y_PALABRA := 60.0

var progreso := 0.0     ## 0 = nada dibujado; 1 = logo entero
var _palabra := ""
var _fuente: Font
var _ancho_palabra := 0.0
var _medio: PackedVector2Array

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_palabra = Idiomas.t("DINASTÍA")
	_fuente = _serif()
	for i in _palabra.length():
		_ancho_palabra += _fuente.get_string_size(_palabra[i], HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_LETRA).x + SEPARACION
	custom_minimum_size = Vector2(X_PALABRA + _ancho_palabra + 8.0, 86.0)
	size = custom_minimum_size
	_medio = _medio_contorno()
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("ancho", custom_minimum_size.x)
	material = mat

## La misma serif de rótulo que la intro: la primera que tenga el sistema.
static func _serif() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Cinzel", "Trajan Pro", "Palatino Linotype", "Book Antiqua",
		"Palatino", "Georgia", "Times New Roman", "Liberation Serif", "DejaVu Serif", "serif"])
	f.font_weight = 700
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	return f

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

## Medio escudo (el lado derecho) en unidades del ancho, como en la intro: del
## centro de arriba a la esquina, el costado y la curva hasta la punta.
static func _medio_contorno() -> PackedVector2Array:
	var h := ESCUDO_ALTO
	var p := PackedVector2Array()
	for i in 13:
		p.append(_bezier(Vector2(0.0, -0.46 * h), Vector2(0.28, -0.46 * h), Vector2(0.5, -0.5 * h), float(i) / 12.0))
	for i in range(1, 9):
		p.append(Vector2(0.5, lerpf(-0.5 * h, 0.02 * h, float(i) / 8.0)))
	for i in range(1, 29):
		p.append(_bezier(Vector2(0.5, 0.02 * h), Vector2(0.5, 0.33 * h), Vector2(0.0, 0.5 * h), float(i) / 28.0))
	return p

static func _bezier(a: Vector2, c: Vector2, b: Vector2, u: float) -> Vector2:
	return a.lerp(c, u).lerp(c.lerp(b, u), u)

## El medio contorno ya trazado (fracción `f` de su largo), en píxeles, por el
## lado `lado` (1 derecha, -1 izquierda).
func _medio_parcial(f: float, lado: float, escala: float = 1.0) -> PackedVector2Array:
	var total := 0.0
	for i in range(1, _medio.size()):
		total += _medio[i - 1].distance_to(_medio[i])
	var falta := total * f
	var out := PackedVector2Array([_px(_medio[0], lado, escala)])
	for i in range(1, _medio.size()):
		var tramo := _medio[i - 1].distance_to(_medio[i])
		if falta >= tramo:
			out.append(_px(_medio[i], lado, escala))
			falta -= tramo
		else:
			out.append(_px(_medio[i - 1].lerp(_medio[i], falta / maxf(tramo, 0.0001)), lado, escala))
			break
	return out

func _px(v: Vector2, lado: float, escala: float) -> Vector2:
	return CENTRO_ESCUDO + Vector2(v.x * lado, v.y) * ANCHO_ESCUDO * escala

## El contorno entero y cerrado (derecha bajando, izquierda subiendo).
func _contorno(escala: float = 1.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for v in _medio:
		p.append(_px(v, 1.0, escala))
	for i in range(_medio.size() - 2, 0, -1):
		p.append(_px(_medio[i], -1.0, escala))
	return p

func _draw() -> void:
	if progreso <= 0.0:
		return
	var oro := Tema.ORO
	var oro_claro := oro.lightened(0.35)
	var lw := 2.4
	## 1) Relleno oscuro (debajo del trazo, para que el borde quede limpio).
	var relleno := smoothstep(0.0, 1.0, _tramo(0.3, 0.55))
	if relleno > 0.0:
		draw_colored_polygon(_contorno(), Color(Tema.FONDO, 0.9 * relleno))
		var dentro := _contorno(lerpf(0.94, 0.86, relleno))
		dentro.append(dentro[0])
		draw_polyline(dentro, Color(oro, 0.8 * relleno), lw * 0.45, true)
	## 2) El contorno, trazado por los dos lados a la vez.
	var trazo := _tramo(0.0, 0.4)
	if trazo >= 1.0:
		var todo := _contorno()
		todo.append(todo[0])
		draw_polyline(todo, oro, lw, true)
	elif trazo > 0.0:
		draw_polyline(_medio_parcial(trazo, 1.0), oro, lw, true)
		draw_polyline(_medio_parcial(trazo, -1.0), oro, lw, true)
	## 3) El monograma, que crece hasta su sitio.
	var pm := _tramo(0.38, 0.6)
	if pm > 0.0:
		var fm := int(ANCHO_ESCUDO * ESCUDO_ALTO * 0.5)
		var ch := _palabra.substr(0, 1)
		var w := _fuente.get_char_size(ch.unicode_at(0), fm).x
		draw_set_transform(CENTRO_ESCUDO + Vector2(0, -1.5), 0.0, Vector2.ONE * lerpf(0.6, 1.0, pm))
		draw_char(_fuente, Vector2(-w * 0.5, fm * 0.35), ch, fm, Color(oro_claro, smoothstep(0.0, 0.5, pm)))
		draw_set_transform_matrix(Transform2D.IDENTITY)
	## 4) La corona, que cae sobre el escudo.
	var pc := _tramo(0.42, 0.62)
	if pc > 0.0:
		var base := CENTRO_ESCUDO - Vector2(0, ANCHO_ESCUDO * (ESCUDO_ALTO * 0.5 + 0.05) + (1.0 - pc) * 7.0)
		var col := Color(oro, smoothstep(0.0, 0.4, pc))
		var pol := PackedVector2Array()
		for v: Vector2 in CORONA:
			pol.append(base + v * ANCHO_ESCUDO)
		draw_colored_polygon(pol, col)
		for i in [2, 4, 6]:
			draw_circle(base + (CORONA[i] as Vector2) * ANCHO_ESCUDO, 1.8, Color(oro_claro, col.a), true, -1.0, true)
	## 5) Las letras, una a una, bajando un poco a su sitio.
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
	## 6) La raya dorada bajo la palabra, de izquierda a derecha.
	var raya := _tramo(0.75, 1.0)
	if raya > 0.0:
		var y := Y_PALABRA + 9.0
		draw_line(Vector2(X_PALABRA, y), Vector2(X_PALABRA + (_ancho_palabra - SEPARACION) * raya, y), Color(oro, 0.85), 1.6, true)

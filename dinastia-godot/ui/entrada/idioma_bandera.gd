class_name BanderaIdioma
extends Control
## LA BANDERA QUE ONDEA de cada idioma (pantalla de idioma, fase 1, 25-10-2026).
##
## POR QUÉ DIBUJADA Y NO UNA IMAGEN NI UN EMOJI. `Idiomas.NOMBRES` trae un emoji de
## bandera por idioma, pero Windows no pinta las banderas emoji (salen dos letras:
## «ES», «GB») y el catalán ni siquiera tiene una que todos los sistemas conozcan
## (por eso allí hay un 🏴 genérico). Una imagen por idioma serían nueve archivos
## más con su licencia. Dibujadas con polígonos se ven igual en todas partes,
## pesan cero y escalan a cualquier tamaño.
##
## CÓMO ONDEA. La bandera se pinta UNA vez en un `SubViewport` pequeño (con MSAA,
## para que el aspa británica y la media luna turca no salgan dentadas) y se
## enseña en un `TextureRect` con `idioma_bandera.gdshader`, que deforma la
## textura como una tela al viento, le pone luz en las crestas y una sombra
## debajo. Ondular polígonos sueltos no se puede (un rectángulo tiene cuatro
## vértices: se tuerce, no ondea); una textura sí.
##
## Las banderas son las de uso común del idioma en el juego: la del Reino Unido
## para el inglés y la de Brasil para «Português (BR)», como ya decía
## `Idiomas.NOMBRES`. Para el catalán, la senyera de cuatro barras, la bandera
## lisa común a los territorios de habla catalana (no la estelada: nada de
## política en el juego).

const SHADER := preload("res://ui/entrada/idioma_bandera.gdshader")
## Hueco alrededor de la tela (en fracción del rectángulo) para que la onda y la
## sombra no se corten contra el borde.
const MARGEN := 0.1

## Los dos colores que mejor resumen cada bandera: tiñen el fondo de la pantalla
## y el brillo de la tarjeta enfocada.
const COLORES := {
	"es": [Color("aa151b"), Color("f1bf00")],
	"en": [Color("012169"), Color("c8102e")],
	"pt": [Color("009c3b"), Color("ffdf00")],
	"fr": [Color("0055a4"), Color("ef4135")],
	"it": [Color("009246"), Color("ce2b37")],
	"de": [Color("dd0000"), Color("ffce00")],
	"ca": [Color("da121a"), Color("fcdd09")],
	"pl": [Color("dc143c"), Color("f4f4f4")],
	"tr": [Color("e30a17"), Color("f4f4f4")],
}

var codigo := "es"
## Píxeles del lienzo donde se pinta (3:2). Las banderas grandes piden más.
var resolucion := Vector2i(300, 200)
## 0 = casi quieta, 1 = ondea con ganas (la tarjeta enfocada).
var fuerza := 0.25: set = _poner_fuerza

var _vista: SubViewport
var _lienzo: Lienzo
var _tela: TextureRect
var _material: ShaderMaterial
var _tween: Tween

## Sin argumentos obligatorios: el orquestador crea las pantallas con `Script.new()`.
func _init(cual: String = "es", res: Vector2i = Vector2i(300, 200)) -> void:
	codigo = cual
	resolucion = res
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_vista = SubViewport.new()
	_vista.size = resolucion
	_vista.transparent_bg = true
	_vista.disable_3d = true
	_vista.msaa_2d = Viewport.MSAA_4X
	## Una bandera no cambia: se pinta una vez y la textura queda.
	_vista.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_vista)
	_lienzo = Lienzo.new()
	_lienzo.codigo = codigo
	_lienzo.tam = Vector2(resolucion)
	_vista.add_child(_lienzo)
	_tela = TextureRect.new()
	_tela.texture = _vista.get_texture()
	_tela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tela.stretch_mode = TextureRect.STRETCH_SCALE
	_tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("margen", MARGEN)
	## Cada bandera en su propio punto de la onda: nueve telas al unísono parecen
	## una sola animación copiada.
	_material.set_shader_parameter("fase", float(COLORES.keys().find(codigo)) * 1.7)
	_material.set_shader_parameter("fuerza", fuerza)
	_tela.material = _material
	add_child(_tela)

## Cambia la bandera que se enseña (la vista previa y la confirmación reutilizan
## el mismo nodo al cambiar de idioma).
func poner(cual: String) -> void:
	codigo = cual
	if _lienzo != null:
		_lienzo.codigo = cual
		_lienzo.queue_redraw()
		_vista.render_target_update_mode = SubViewport.UPDATE_ONCE

func _poner_fuerza(v: float) -> void:
	fuerza = clampf(v, 0.0, 1.0)
	if _material == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_material, "shader_parameter/fuerza", fuerza, 0.35).set_trans(Tween.TRANS_SINE)

# --- el dibujo ---------------------------------------------------------------------

## Pinta la bandera `cual` en el rectángulo (0, 0, t). Estático: cualquier
## `CanvasItem` puede usarlo dentro de su `_draw`.
static func dibujar(ci: CanvasItem, cual: String, t: Vector2) -> void:
	match cual:
		"es":
			## 1:2:1, sin escudo (la bandera civil).
			_franjas(ci, t, [Color("aa151b"), Color("f1bf00"), Color("f1bf00"), Color("aa151b")], true)
		"de":
			_franjas(ci, t, [Color("111111"), Color("dd0000"), Color("ffce00")], true)
		"pl":
			_franjas(ci, t, [Color("f4f4f4"), Color("dc143c")], true)
		"ca":
			var barras: Array[Color] = []
			for i in 9:
				barras.append(Color("fcdd09") if i % 2 == 0 else Color("da121a"))
			_franjas(ci, t, barras, true)
		"fr":
			_franjas(ci, t, [Color("0055a4"), Color("f4f4f4"), Color("ef4135")], false)
		"it":
			_franjas(ci, t, [Color("009246"), Color("f1f2f1"), Color("ce2b37")], false)
		"en":
			_union(ci, t)
		"pt":
			_brasil(ci, t)
		"tr":
			_turquia(ci, t)
		_:
			ci.draw_rect(Rect2(Vector2.ZERO, t), Color("555a66"))

## Franjas iguales, horizontales (`horiz`) o verticales.
static func _franjas(ci: CanvasItem, t: Vector2, colores: Array, horiz: bool) -> void:
	var n := colores.size()
	for i in n:
		var r := Rect2(0.0, t.y * i / n, t.x, t.y / n + 1.0) if horiz else Rect2(t.x * i / n, 0.0, t.x / n + 1.0, t.y)
		ci.draw_rect(r, colores[i])

## La del Reino Unido, con la contraaspa roja desplazada como la de verdad (en
## el cuarto de arriba junto al mástil el rojo va por debajo de la diagonal; los
## otros tres giran igual, como un molinete). Unidades: altura / 30.
static func _union(ci: CanvasItem, t: Vector2) -> void:
	var azul := Color("012169")
	var rojo := Color("c8102e")
	var blanco := Color("f4f4f4")
	var u := t.y / 30.0
	var c := t * 0.5
	ci.draw_rect(Rect2(Vector2.ZERO, t), azul)
	var esquinas := [Vector2.ZERO, Vector2(t.x, 0.0), t, Vector2(0.0, t.y)]
	for e: Vector2 in esquinas:
		var d := (e - c).normalized()
		var n := Vector2(d.y, -d.x)
		var fin := c + d * ((e - c).length() + 6.0 * u)
		ci.draw_colored_polygon(PackedVector2Array([c + n * 3.0 * u, fin + n * 3.0 * u, fin - n * 3.0 * u, c - n * 3.0 * u]), blanco)
	for e: Vector2 in esquinas:
		var d := (e - c).normalized()
		var n := Vector2(d.y, -d.x)
		var fin := c + d * ((e - c).length() + 6.0 * u)
		ci.draw_colored_polygon(PackedVector2Array([c, fin, fin + n * 2.0 * u, c + n * 2.0 * u]), rojo)
	ci.draw_rect(Rect2(0.0, c.y - 5.0 * u, t.x, 10.0 * u), blanco)
	ci.draw_rect(Rect2(c.x - 5.0 * u, 0.0, 10.0 * u, t.y), blanco)
	ci.draw_rect(Rect2(0.0, c.y - 3.0 * u, t.x, 6.0 * u), rojo)
	ci.draw_rect(Rect2(c.x - 3.0 * u, 0.0, 6.0 * u, t.y), rojo)

## La de Brasil: rombo amarillo, esfera azul y la franja blanca, que según la ley
## es un arco con centro dos módulos a la izquierda del pie de la esfera y siete
## por debajo de su centro (radios 8 y 8,5 con la esfera de 3,5). La franja se
## recorta contra el círculo con `Geometry2D`. Las estrellas, simplificadas a
## puntos: a ese tamaño el dibujo exacto no se distingue.
static func _brasil(ci: CanvasItem, t: Vector2) -> void:
	var c := t * 0.5
	ci.draw_rect(Rect2(Vector2.ZERO, t), Color("009c3b"))
	var ix := t.x * 1.7 / 20.0
	var iy := t.y * 1.7 / 14.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(ix, c.y), Vector2(c.x, iy), Vector2(t.x - ix, c.y), Vector2(c.x, t.y - iy)]), Color("ffdf00"))
	var r := t.y * 3.5 / 14.0
	var circulo := _circulo(c, r, 64)
	ci.draw_colored_polygon(circulo, Color("002776"))
	var centro_arco := c + Vector2(-r * 2.0 / 3.5, r * 7.0 / 3.5)
	var franja := PackedVector2Array()
	var r_in := r * 8.0 / 3.5
	var r_out := r * 8.5 / 3.5
	for i in 33:
		var a := lerpf(-PI * 0.95, -PI * 0.05, i / 32.0)
		franja.append(centro_arco + Vector2(cos(a), sin(a)) * r_out)
	for i in 33:
		var a := lerpf(-PI * 0.05, -PI * 0.95, i / 32.0)
		franja.append(centro_arco + Vector2(cos(a), sin(a)) * r_in)
	for trozo: PackedVector2Array in Geometry2D.intersect_polygons(franja, circulo):
		ci.draw_colored_polygon(trozo, Color("f4f4f4"))
	var estrellas := [Vector2(0.0, 0.4), Vector2(-0.38, 0.3), Vector2(0.3, 0.6), Vector2(-0.2, 0.7),
		Vector2(0.45, 0.3), Vector2(-0.6, 0.5), Vector2(0.1, 0.85), Vector2(-0.45, 0.05), Vector2(0.35, -0.5)]
	for k in estrellas.size():
		ci.draw_circle(c + (estrellas[k] as Vector2) * r, r * (0.055 if k % 3 == 0 else 0.038), Color("f4f4f4"))

## La de Turquía, con las medidas oficiales en unidades de la altura G: media luna
## de un círculo blanco (centro a 1/2 G del mástil, radio 1/4 G) menos uno rojo
## (1/16 G más allá, radio 1/5 G), y la estrella de radio 1/8 G con una punta
## hacia el mástil.
static func _turquia(ci: CanvasItem, t: Vector2) -> void:
	var g := t.y
	var rojo := Color("e30a17")
	var blanco := Color("f4f4f4")
	ci.draw_rect(Rect2(Vector2.ZERO, t), rojo)
	var y := g * 0.5
	ci.draw_colored_polygon(_circulo(Vector2(g * 0.5, y), g * 0.25, 72), blanco)
	ci.draw_colored_polygon(_circulo(Vector2(g * 0.5625, y), g * 0.2, 72), rojo)
	var centro := Vector2(g * 0.8208, y)
	var puntas := PackedVector2Array()
	for k in 10:
		var a := PI + k * TAU / 10.0
		var rad := g * 0.125 if k % 2 == 0 else g * 0.125 * 0.381966
		puntas.append(centro + Vector2(cos(a), sin(a)) * rad)
	ci.draw_colored_polygon(puntas, blanco)

static func _circulo(c: Vector2, r: float, lados: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in lados:
		var a := TAU * i / lados
		p.append(c + Vector2(cos(a), sin(a)) * r)
	return p

## El lienzo que vive dentro del `SubViewport`.
class Lienzo:
	extends Node2D
	var codigo := "es"
	var tam := Vector2(300, 200)

	func _draw() -> void:
		BanderaIdioma.dibujar(self, codigo, tam)

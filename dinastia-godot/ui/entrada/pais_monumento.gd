class_name PaisMonumento
extends Control
## UN MONUMENTO DE FONDO de la pantalla de país: la silueta (dibujada en código por
## `PaisTrazo`) de pie sobre el borde inferior del control, centrada y tan grande como
## quepa sin salirse ni de alto ni de ancho. No recibe el ratón: es decorado.

var tipo := ""
var variante := ""
var color_silueta := Color(0.03, 0.04, 0.05, 0.94)
var color_detalle := Color(0.22, 0.26, 0.3, 0.95)
## El último dibujo salió bien (el tipo existía): lo mira la prueba.
var dibujado := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func poner(t: String, v: String) -> void:
	tipo = t
	variante = v
	queue_redraw()

func _draw() -> void:
	dibujado = false
	if tipo == "" or size.x < 4.0 or size.y < 4.0:
		return
	var h := minf(size.y * 0.96, size.x * 0.96 / PaisTrazo.ancho_de(tipo, variante))
	dibujado = PaisTrazo.dibujar(self, tipo, variante, Vector2(size.x * 0.5, size.y), h,
		color_silueta, color_detalle)

class_name MarcaPanel
extends Control
## LA MARCA DE LA TARJETA. Va dentro de cada panel, encima del fondo y debajo
## del contenido, y dibuja el adorno del borde: escuadras en las esquinas, un
## filete arriba, una cinta, un sello.
##
## POR QUÉ NO SE HACE CON `StyleBoxFlat`. Un StyleBox de Godot solo sabe pintar
## un rectángulo con borde uniforme y esquinas redondeadas. Una escuadra —dos
## trazos cortos en cada vértice, con el centro del lado vacío— no se puede
## expresar ahí, y es justo el adorno que hace que una tarjeta parezca una ficha
## y no un `div`.
##
## SIEMPRE CON EL COLOR DE ACENTO. El adorno sale de la identidad del club, así
## que un club rojo tiene escuadras rojas. Es lo mismo que ya hacen el escudo y
## la equipación, y es lo que hace que la interfaz se sienta del club y no del
## juego.

const ESTILOS := {
	"ninguno":  "Sin marca",
	"esquinas": "Escuadras en las esquinas",
	"filete":   "Filete superior",
	"doble":    "Filete doble",
	"cinta":    "Cinta en la esquina",
	"sello":    "Sello",
	"clavos":   "Remaches",
}

var estilo: String = "esquinas"
var color: Color = Color("3fa06a")

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func poner(e: String, c: Color) -> void:
	estilo = e
	color = c
	visible = e != "ninguno" and ESTILOS.has(e)
	queue_redraw()

func _draw() -> void:
	if not visible or estilo == "ninguno":
		return
	var w := size.x
	var h := size.y
	## Nada de esto se dibuja si la tarjeta es minúscula: en una fila de 18 px de
	## alto una escuadra de 14 se come el borde entero y parece un fallo.
	if w < 60.0 or h < 26.0:
		return
	var c := color
	c.a = 0.75
	match estilo:
		"esquinas":
			var l := minf(16.0, minf(w, h) * 0.25)
			var m := 3.0
			for esq in [Vector2(m, m), Vector2(w - m, m), Vector2(m, h - m), Vector2(w - m, h - m)]:
				var sx := 1.0 if esq.x < w / 2.0 else -1.0
				var sy := 1.0 if esq.y < h / 2.0 else -1.0
				draw_line(esq, esq + Vector2(l * sx, 0), c, 2.0)
				draw_line(esq, esq + Vector2(0, l * sy), c, 2.0)
		"filete":
			draw_line(Vector2(10, 2.5), Vector2(w - 10, 2.5), c, 2.0)
		"doble":
			draw_line(Vector2(10, 2.0), Vector2(w - 10, 2.0), c, 2.0)
			var c2 := color
			c2.a = 0.35
			draw_line(Vector2(16, 6.0), Vector2(w - 16, 6.0), c2, 1.0)
		"cinta":
			## Un triángulo pegado al vértice de arriba a la izquierda, como la
			## esquina doblada de una ficha de archivo.
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, 0), Vector2(30, 0), Vector2(0, 30)]), c)
		"sello":
			var r := 5.0
			draw_circle(Vector2(w - 14, 12), r, c)
			var c3 := color
			c3.a = 0.28
			draw_arc(Vector2(w - 14, 12), r + 4.0, 0.0, TAU, 20, c3, 1.5)
		"clavos":
			## Cuatro remaches: la tarjeta como una placa atornillada. Es el que
			## mejor le va a las paletas oscuras y al modo TV.
			var c4 := color
			c4.a = 0.5
			for p in [Vector2(9, 9), Vector2(w - 9, 9), Vector2(9, h - 9), Vector2(w - 9, h - 9)]:
				draw_circle(p, 2.5, c4)

class_name MapaCalorJugador
extends Control
## EL MAPA DE CALOR DEL JUGADOR EN LA PLANTILLA (orden del dueño, 9-11; hecho el 10-11; idea de la «Información del jugador» del PES). Un campo en
## vertical (tu portería abajo, la rival arriba) con las ZONAS por donde se mueve: su demarcación principal en rojo/amarillo intenso, las secundarias
## (`pos_sec`) más suaves, y el radio según su movilidad (ritmo y físico) y su rol (los de banda recorren la línea; los centrales casi no se mueven).
## No se guarda nada: es una lectura de la ficha (`intensidades` es estática y la usa el banco).
const COLS := 12
const FILAS := 16

## Centro de cada demarcación en el campo: x 0 (izquierda) .. 1 (derecha); y 0 (portería rival) .. 1 (la tuya). Y cuánto se estira a lo largo (sy) y a lo ancho (sx).
const ZONAS := {
	"POR": [0.5, 0.94, 0.10, 0.04], "DFC": [0.5, 0.80, 0.14, 0.08], "LD": [0.88, 0.70, 0.07, 0.20], "LI": [0.12, 0.70, 0.07, 0.20],
	"CAD": [0.88, 0.58, 0.07, 0.26], "CAI": [0.12, 0.58, 0.07, 0.26], "MCD": [0.5, 0.64, 0.16, 0.11], "MC": [0.5, 0.50, 0.17, 0.16],
	"MCO": [0.5, 0.34, 0.15, 0.12], "MD": [0.85, 0.46, 0.08, 0.20], "MI": [0.15, 0.46, 0.08, 0.20], "ED": [0.86, 0.26, 0.08, 0.17],
	"EI": [0.14, 0.26, 0.08, 0.17], "SD": [0.5, 0.24, 0.16, 0.10], "DC": [0.5, 0.15, 0.12, 0.08],
}

var _j: Jugador
var _calor := PackedFloat32Array()

static func crear(j: Jugador, tam := Vector2(170, 230)) -> MapaCalorJugador:
	var m := MapaCalorJugador.new()
	m._j = j
	m.custom_minimum_size = tam
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m._calor = intensidades(j)
	m.tooltip_text = Idiomas.t("Zonas por donde se mueve: su puesto principal más intenso, los secundarios más suaves.")
	return m

## La intensidad (0..1) de cada celda de la rejilla COLS×FILAS (fila 0 = arriba, área rival).
static func intensidades(j: Jugador) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(COLS * FILAS)
	if j == null:
		return a
	var mov := 1.0
	if j.pos != "POR" and not j.atributos.is_empty():   ## movilidad: ritmo y físico (60 = normal)
		mov = clampf(0.8 + (float(j.atributos.get("rit", 60)) + float(j.atributos.get("fis", 60)) - 120.0) * 0.006, 0.75, 1.3)
	var focos: Array = [[j.pos_e, 1.0]]
	for s: String in j.pos_sec:
		if s != j.pos_e:
			focos.append([s, 0.55])
	var tope := 0.0001
	for f in FILAS:
		for c in COLS:
			var x := (float(c) + 0.5) / float(COLS)
			var y := (float(f) + 0.5) / float(FILAS)
			var v := 0.0
			for foco: Array in focos:
				var z: Array = ZONAS.get(String(foco[0]), ZONAS["MC"])
				var dx := (x - float(z[0])) / (float(z[2]) * mov)
				var dy := (y - float(z[1])) / (float(z[3]) * mov)
				v += float(foco[1]) * exp(-0.5 * (dx * dx + dy * dy))
			a[f * COLS + c] = v
			tope = maxf(tope, v)
	for i in a.size():
		a[i] = a[i] / tope
	return a

## Rampa del calor: verde tenue → amarillo → rojo.
static func color_calor(v: float) -> Color:
	if v < 0.12:
		return Color(0, 0, 0, 0)
	if v < 0.5:
		return Color(0.25, 0.75, 0.3, 0.25).lerp(Color(0.98, 0.85, 0.2, 0.7), (v - 0.12) / 0.38)
	return Color(0.98, 0.85, 0.2, 0.7).lerp(Color(0.92, 0.2, 0.15, 0.9), (v - 0.5) / 0.5)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("1d5a2c"))
	for k in 8:   ## franjas del césped
		if k % 2 == 0:
			draw_rect(Rect2(0, size.y * k / 8.0, size.x, size.y / 8.0), Color("226633"))
	var cw := size.x / float(COLS)
	var ch := size.y / float(FILAS)
	for f in FILAS:
		for c in COLS:
			var col := color_calor(_calor[f * COLS + c])
			if col.a > 0.0:
				draw_rect(Rect2(c * cw, f * ch, cw + 0.5, ch + 0.5), col)
	var linea := Color(1, 1, 1, 0.55)
	draw_rect(r.grow(-2), linea, false, 1.5)
	draw_line(Vector2(2, size.y * 0.5), Vector2(size.x - 2, size.y * 0.5), linea, 1.5)
	draw_arc(size * 0.5, size.x * 0.16, 0, TAU, 32, linea, 1.5)
	for arriba: bool in [true, false]:   ## las dos áreas
		var y0 := 2.0 if arriba else size.y - 2.0 - size.y * 0.16
		draw_rect(Rect2(size.x * 0.22, y0, size.x * 0.56, size.y * 0.16), linea, false, 1.5)
		var y1 := 2.0 if arriba else size.y - 2.0 - size.y * 0.06
		draw_rect(Rect2(size.x * 0.38, y1, size.x * 0.24, size.y * 0.06), linea, false, 1.5)

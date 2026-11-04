class_name MetroPublicidad
extends RefCounted
## LA PUBLICIDAD Y LA MEGAFONÍA DEL ANDÉN (M-180, 3-11-2026): carteles de anuncios pegados a la pared del fondo (los mismos anunciantes que los del vagón) y un
## aviso de megafonía, EN TEXTO, que rota cada pocos segundos en las pantallas del andén bajo «Próximo tren». La música del metro la maneja el dueño: no está aquí.

const CADA := 6.0   ## s que dura cada aviso de megafonía
const MENSAJES := [
	"Pase detrás de la línea amarilla.",
	"Deje bajar antes de subir.",
	"Cuide sus pertenencias en el andén.",
	"Ceda el asiento a quien más lo necesite.",
	"Mantenga limpia la estación.",
	"Los trenes de esta línea llegan cada pocos minutos.",
]

## Tres carteles en la pared del andén (`base` = pie de la pared; `hacia` sale de la pared al andén; `lon` recorre el andén).
static func carteles(padre: Node3D, base: Vector3, hacia: Vector3, lon: Vector3, y: float, idx: int) -> int:
	var n := 0
	var giro := atan2(hacia.x, hacia.z)
	for f: float in [-8.0, 8.0, 29.0]:   ## en los huecos entre los murales de la estación (-16, 0, 16) y el plano de la red (24)
		var k := idx * 3 + n
		var centro := base + Vector3(0, y + 2.1, 0) + hacia * 0.08 + lon * f
		var col: Color = MetroCiudad.COLORES_ANUNCIO[k % MetroCiudad.COLORES_ANUNCIO.size()]
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = 0.6
		var panel := Mini3D.caja(padre, centro, Vector3(1.5, 2.0, 0.06) if absf(hacia.z) > 0.5 else Vector3(0.06, 2.0, 1.5), m)
		panel.visibility_range_end = 90.0
		var l := Label3D.new()
		l.text = Idiomas.t(String(MetroCiudad.ANUNCIOS[k % MetroCiudad.ANUNCIOS.size()]))
		l.font_size = 30
		l.pixel_size = 0.0036
		l.outline_size = 5
		l.outline_modulate = Color(0, 0, 0, 0.6)
		l.width = 380.0
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.double_sided = false
		l.position = centro + hacia * 0.04
		l.rotation.y = giro
		l.visibility_range_end = 25.0
		padre.add_child(l)
		n += 1
	return n

## El aviso de megafonía que toca ahora (cambia cada `CADA` s), ya traducido.
static func mensaje(tiempo: float) -> String:
	return Idiomas.t(String(MENSAJES[int(tiempo / CADA) % MENSAJES.size()]))

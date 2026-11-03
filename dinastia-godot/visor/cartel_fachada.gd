class_name CartelFachada
extends RefCounted
## EL NOMBRE EN LA FACHADA (3-11-2026, C2 de la prueba del dueño: «el nombre va EN el edificio y solo se ve de cerca»). `CityBuilder._rotulo` es la etiqueta del MAPA (de tamaño fijo, se
## esconde al pasear). Un cartel de un comercio (banco, tienda, lavado, gasolinera) es otra cosa: texto de tamaño de mundo pegado a su pared, que se ve al pasear a pie o en coche
## y desaparece a más de `ALCANCE` m. Mira siempre a quien lo lee (solo gira en vertical, como un cartel de verdad).
const ALCANCE := 70.0

static func poner(b: CityBuilder, pos: Vector3, texto: String, color: Color, tam: int = 28) -> Label3D:
	var l := Label3D.new()
	l.text = Idiomas.t(texto)
	l.font_size = tam
	l.pixel_size = 0.0145
	l.outline_size = 8
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.position = pos
	l.visibility_range_end = ALCANCE
	l.visibility_range_end_margin = 10.0
	l.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	b.add_child(l)
	return l

## Un lugar con nombre: la etiqueta del MAPA (vista aérea, de tamaño fijo) Y su cartel de pared (al pasear, de cerca). Cada una solo se ve donde toca.
static func con_mapa(b: CityBuilder, pos: Vector3, texto: String, color: Color, tam: int = 28) -> void:
	b._rotulo(pos, texto, color, tam)
	poner(b, pos, texto, color, tam)

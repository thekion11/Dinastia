class_name EscalaTipografica
extends Node
## LA ESCALA TIPOGRÁFICA DE LOS MENÚS (10-11-2026, PRIORITARIO 1 del plan: «estética y diseño de los menús, falta pulir»; referencia PES 2020 /
## eFootball, que usan una jerarquía corta y estable). Las pantallas de gestión usaban OCHO tamaños de letra (10, 11, 12, 13, 14, 15, 16, 17)
## repartidos sin regla: en una misma fila convivían 11, 12 y 13 (`pruebas/auditoria_estetica_menus`). Ahora el contenido usa TRES:
##  · ROTULO (11): cabeceras de tabla, etiquetas pequeñas, notas;
##  · CUERPO (13): texto corriente y botones (la letra base de los botones ya era 13);
##  · DESTACADO (16): nombres en tarjetas, subtítulos.
## Los títulos héroe (≥ 18: títulos de pantalla, marcadores, cifras) y lo diminuto (≤ 9: iniciales dentro de un escudo) no se tocan.
## Solo dentro de la pantalla principal, fuera del partido (`PartidoVivo`, `PartidoJugable`: su HUD tiene su propia escala por milímetros),
## y solo con la escala de texto de Ajustes al 100 % (si el jugador la cambió, manda su elección). En el móvil, la letra mínima legible
## (`EscalaMovil._letra`) va después y puede subir el rótulo.
const ROTULO := 11
const CUERPO := 13
const DESTACADO := 16
## Por ruta y no por clase: el menú no nombra las clases del partido (regla de memoria del menú, CLAUDE.md).
const PARTIDO := ["res://ui/partido_vivo.gd", "res://ui/partido_jugable.gd"]

var _p: Control

func _init(p: Control) -> void:
	_p = p
	name = "EscalaTipografica"

func _ready() -> void:
	get_tree().node_added.connect(_al_entrar)
	_repasar.call_deferred()

## Lo que ya estaba montado antes que este vigilante (el riel y su cajón, la cabecera): se ajusta en su próximo dibujado.
func _repasar() -> void:
	if not is_instance_valid(_p):
		return
	for n: Node in _p.find_children("*", "", true, false):
		if n is Label or n is Button:
			_al_entrar(n)
			(n as Control).queue_redraw()

## El nivel de la escala que le toca a un tamaño.
static func nivel(tam: int) -> int:
	if tam <= 9 or tam >= 18:
		return tam
	if tam <= 11:
		return ROTULO
	if tam <= 14:
		return CUERPO
	return DESTACADO

func _al_entrar(n: Node) -> void:
	if (n is Label or n is Button) and is_instance_valid(_p) and _p.is_ancestor_of(n):
		## en su PRIMER dibujado: ya tiene su tamaño (hay filas que lo ponen después de añadirse, como las del mercado)
		if not (n as Control).draw.is_connected(_ajustar.bind(n)):
			(n as Control).draw.connect(_ajustar.bind(n), CONNECT_ONE_SHOT)

func _ajustar(c: Control) -> void:
	if not is_instance_valid(c) or not c.is_inside_tree() or not c.has_theme_font_size_override("font_size"):
		return
	if not is_equal_approx(float(_p.get("_escala_texto")), 1.0):
		return
	var n := c.get_parent()
	while n != null and n != _p:
		if n is SubViewport or (n.get_script() != null and (n.get_script() as Script).resource_path in PARTIDO):
			return
		n = n.get_parent()
	var tam := c.get_theme_font_size("font_size")
	var nuevo := nivel(tam)
	if nuevo != tam:
		c.add_theme_font_size_override("font_size", nuevo)

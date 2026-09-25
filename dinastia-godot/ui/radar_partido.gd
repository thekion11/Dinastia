class_name RadarPartido
extends Control

## Radar / Minimapa 2D del terreno de juego estilo TV / FC 26.
## Muestra las posiciones en tiempo real de los 22 jugadores, árbitros y el balón.

const LARGO_CAMPO := 105.0
const ANCHO_CAMPO := 68.0

var jugadores: Array = []
var balon: Node3D = null
var jugador_activo: Node3D = null
var color_local := Color("3fa06a")
var color_visita := Color("e05555")

func setup(all_players: Array, ball_node: Node3D, c_local: Color = Color("3fa06a"), c_visita: Color = Color("e05555")) -> void:
	jugadores = all_players
	balon = ball_node
	color_local = c_local
	color_visita = c_visita
	custom_minimum_size = Vector2(210, 136)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func actualizar_datos(all_players: Array = [], _ball_pos: Vector3 = Vector3.ZERO, _act_pos: Vector3 = Vector3.ZERO) -> void:
	if not all_players.is_empty():
		jugadores = all_players
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var rect := Rect2(Vector2.ZERO, size)

	# Fondo del campo translúcido redondeado
	draw_rect(rect, Color(0.04, 0.07, 0.05, 0.75), true)
	draw_rect(rect, Color(1, 1, 1, 0.3), false, 1.5)

	# Línea de medio campo y círculo central
	draw_line(Vector2(0, h * 0.5), Vector2(w, h * 0.5), Color(1, 1, 1, 0.25), 1.0)
	draw_arc(Vector2(w * 0.5, h * 0.5), h * 0.14, 0, TAU, 24, Color(1, 1, 1, 0.25), 1.0)

	# Áreas
	var w_area := w * 0.56
	var h_area := h * 0.16
	draw_rect(Rect2(Vector2((w - w_area) * 0.5, 0), Vector2(w_area, h_area)), Color(1, 1, 1, 0.2), false, 1.0)
	draw_rect(Rect2(Vector2((w - w_area) * 0.5, h - h_area), Vector2(w_area, h_area)), Color(1, 1, 1, 0.2), false, 1.0)

	# Posicionar jugadores
	for p in jugadores:
		var node: Node3D = p.get("node")
		if not is_instance_valid(node):
			continue
		var es_arb := bool(p.get("arbitro", false))
		var es_loc := bool(p.get("es_local", true))

		var pos_3d := node.global_position
		# En el 3D X va de -34 a +34, Z va de -52.5 a +52.5
		var u := clampf((pos_3d.x + ANCHO_CAMPO * 0.5) / ANCHO_CAMPO, 0.02, 0.98)
		var v := clampf((pos_3d.z + LARGO_CAMPO * 0.5) / LARGO_CAMPO, 0.02, 0.98)
		var pt := Vector2(u * w, v * h)

		var col := Color(0.95, 0.85, 0.2) if es_arb else (color_local if es_loc else color_visita)
		var r_dot := 2.8 if not es_arb else 2.2

		draw_circle(pt, r_dot, col)

		# Resaltar si es el jugador activo
		if node == jugador_activo:
			draw_arc(pt, 6.0, 0, TAU, 16, Color(1, 1, 1, 0.95), 1.6)

	# Dibujar el balón
	if is_instance_valid(balon):
		var b_pos := balon.global_position
		var bu := clampf((b_pos.x + ANCHO_CAMPO * 0.5) / ANCHO_CAMPO, 0.02, 0.98)
		var bv := clampf((b_pos.z + LARGO_CAMPO * 0.5) / LARGO_CAMPO, 0.02, 0.98)
		var b_pt := Vector2(bu * w, bv * h)
		draw_circle(b_pt, 3.4, Color(1, 1, 1, 1.0))
		draw_circle(b_pt, 4.6, Color(1, 0.9, 0.2, 0.6))

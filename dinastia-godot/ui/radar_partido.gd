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
var _ult_puntos: Array = []   ## (28-10) posiciones (al cm) y tamaño del último dibujo: si nada se movió, no se redibuja

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


## Las líneas del campo son fijas: líneas suaves (`TrazoSuave`, 26-10-2026)
## que solo se rehacen si cambia el tamaño; los puntos se mueven y van en `_draw`.
func _notification(que: int) -> void:
	if que == NOTIFICATION_RESIZED:
		_rehacer_lineas()

func _rehacer_lineas() -> void:
	TrazoSuave.limpiar(self)
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	## Todo DETRÁS de los puntos, y en orden: primero el fondo translúcido (un
	## hijo también, si no taparía las líneas) y después las líneas.
	var fondo := ColorRect.new()
	fondo.set_meta(TrazoSuave.META, true)
	fondo.color = Color(0.04, 0.07, 0.05, 0.75)
	fondo.size = size
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.show_behind_parent = true
	add_child(fondo)
	TrazoSuave.rect(self, Rect2(Vector2.ZERO, size).grow(-0.75), Color(1, 1, 1, 0.3), 1.5, true)
	TrazoSuave.linea(self, PackedVector2Array([Vector2(0, h * 0.5), Vector2(w, h * 0.5)]), Color(1, 1, 1, 0.25), 1.0, false, true)
	TrazoSuave.arco(self, Vector2(w * 0.5, h * 0.5), h * 0.14, Color(1, 1, 1, 0.25), 1.0, 32, true)
	var w_area := w * 0.56
	var h_area := h * 0.16
	TrazoSuave.rect(self, Rect2(Vector2((w - w_area) * 0.5, 0), Vector2(w_area, h_area)), Color(1, 1, 1, 0.2), 1.0, true)
	TrazoSuave.rect(self, Rect2(Vector2((w - w_area) * 0.5, h - h_area), Vector2(w_area, h_area)), Color(1, 1, 1, 0.2), 1.0, true)

func _process(_delta: float) -> void:
	if not visible:
		return
	var puntos: Array = [size, jugador_activo]
	for p in jugadores:
		var node: Node3D = p.get("node")
		if is_instance_valid(node):
			var g := node.global_position
			puntos.append(Vector2i(int(g.x * 100.0), int(g.z * 100.0)))
	if is_instance_valid(balon):
		puntos.append(Vector2i(int(balon.global_position.x * 100.0), int(balon.global_position.z * 100.0)))

	if puntos != _ult_puntos:
		_ult_puntos = puntos
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# El fondo, el borde, el medio campo, el círculo y las áreas son hijos fijos
	# (`_rehacer_lineas`); aquí solo lo que se mueve.

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

		draw_circle(pt, r_dot, col, true, -1.0, true)

		# Resaltar si es el jugador activo
		if node == jugador_activo:
			draw_arc(pt, 6.0, 0, TAU, 16, Color(1, 1, 1, 0.95), 1.6, true)

	# Dibujar el balón
	if is_instance_valid(balon):
		var b_pos := balon.global_position
		var bu := clampf((b_pos.x + ANCHO_CAMPO * 0.5) / ANCHO_CAMPO, 0.02, 0.98)
		var bv := clampf((b_pos.z + LARGO_CAMPO * 0.5) / LARGO_CAMPO, 0.02, 0.98)
		var b_pt := Vector2(bu * w, bv * h)
		draw_circle(b_pt, 3.4, Color(1, 1, 1, 1.0), true, -1.0, true)
		draw_circle(b_pt, 4.6, Color(1, 0.9, 0.2, 0.6), true, -1.0, true)

extends Node
## Busca la "columna vertical translucida" que el usuario reporto por foto del
## celular (centro de la cancha, estatica, solo durante un partido) - no salio
## en 6 capturas anteriores forzando un gol al inicio. En vez de forzar el gol
## y mirar screenshots (lo que ya se probo sin suerte), este script:
##   1. Abre un partido real SIN forzar nada.
##   2. Vuelca TODO el arbol 3D bajo VistaEstadio -tipo, nombre, posicion
##      global- para buscar por texto cualquier nodo cerca del centro de la
##      cancha (offset chico en X/Z) que pueda ser la columna, sin depender de
##      verla a simple vista en una imagen.
##   3. Deja correr el partido varios minutos simulados (no solo el arranque)
##      por si el bug depende de tiempo/evento tardio, capturando PNGs
##      periodicos desde una camara aerea centrada como respaldo visual.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         --position 0,0 res://pruebas/diagnostico_columna.tscn

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _frame := 0
var _volcado := false

const MINUTOS_A_CORRER := 20.0  # a velocidad x4 son ~5 "segundos nominales" reales de sim

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 9001)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)
	print("partido: %s vs %s" % [par[0].nombre, par[1].nombre])
	# Maxima velocidad para cubrir mas minutos simulados por fotograma real.
	var juego = _vista.get("_juego")
	if juego != null:
		juego.vel_idx = 4

func _volcar_arbol(n: Node, profundidad: int) -> void:
	if n is Node3D:
		var n3 := n as Node3D
		var g := n3.global_position
		var cerca_centro := absf(g.x) < 4.0 and absf(g.z) < 4.0
		var marca := " <<<< CERCA DEL CENTRO" if cerca_centro else ""
		print("%s%s (%s) pos=%s vis=%s%s" % ["  ".repeat(profundidad), n.name, n.get_class(), g, n3.visible, marca])
	for c in n.get_children():
		_volcar_arbol(c, profundidad + 1)

func _process(_d: float) -> void:
	_frame += 1
	## A los 30 fotogramas ya esta el once armado y el saque hecho: volcar el
	## arbol entero una vez, buscando algo cerca de (0, *, 0) -centro de cancha.
	if _frame == 30 and not _volcado:
		_volcado = true
		print("--- VOLCADO DEL ARBOL 3D (buscar 'CERCA DEL CENTRO') ---")
		_volcar_arbol(_vista, 0)
		print("--- FIN VOLCADO ---")
	## Camara aerea centrada, mirando derecho hacia abajo: si la columna existe
	## de verdad en el centro, una vista cenital la muestra sin depender del
	## angulo de la camara normal del partido.
	if _frame == 32:
		var cam := Camera3D.new()
		cam.position = Vector3(0, 40, 0.01)
		add_child(cam)
		cam.look_at(Vector3(0, 0, 0), Vector3(0, 0, -1))
		cam.current = true
	if _frame in [40, 400, 900, 1400, 1900]:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/columna_cenital_f%d.png" % _frame)
		var juego = _vista.get("_juego")
		var el = juego.get("elapsed") if juego != null else -1.0
		print("capturado cenital: f%d  elapsed~%s" % [_frame, el])
	if _frame >= 2000:
		print("FIN. 0 fallos")
		get_tree().quit(0)

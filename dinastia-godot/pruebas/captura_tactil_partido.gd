extends Node
## CONTROLES TÁCTILES EN EL PARTIDO (M-433, 27-10-2026): el partido jugable con el stick y los botones puestos, manejado con eventos de pantalla
## simulados (un dedo mueve, otro corre, otro pasa). Comprueba que el jugador se mueve de verdad y saca las fotos.
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_tactil_partido.tscn   (sin pantalla no hace nada)
var _n := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable
var _ct: ControlesTactiles
var _fallos := 0
var _p0 := Vector3.ZERO

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no se captura nada")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	PartidoJugable.con_ceremonia = false
	ControlesTactiles.forzar = true
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _toque(dedo: int, pos: Vector2, pulsa: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = dedo
	e.position = pos
	e.pressed = pulsa
	Input.parse_input_event(e)

func _arrastre(dedo: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = dedo
	e.position = pos
	Input.parse_input_event(e)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("/tmp/%s.png" % nombre)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_ui._crear()
	if _n == 20:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 120.0)
		_ct = _pj.get_node_or_null("ControlesTactiles") as ControlesTactiles
		_comprobar(_ct != null, "el partido monta los controles táctiles")
	if _n == 80:
		_p0 = _pj.motor.pos(_pj.motor.usuario)
		var c0 := Vector2(200, get_viewport().get_visible_rect().size.y - 160)
		_toque(0, c0, true)
		_arrastre(0, c0 + Vector2(0, -90))
		_toque(1, _ct.centro_de("Sprint"), true)
	if _n == 140:
		var p1: Vector3 = _pj.motor.pos(_pj.motor.usuario)
		_comprobar(Input.is_action_pressed("jugar_sprint"), "el dedo del sprint corre")
		_comprobar(Mando.movimiento().length() > 0.5, "el stick empuja con fuerza (%.2f)" % Mando.movimiento().length())
		_comprobar(p0_distancia(p1) > 1.0, "el jugador se ha movido con el dedo (%.1f m)" % p0_distancia(p1))
		_foto("tactil_partido_mueve")
		_toque(2, _ct.centro_de("A"), true)
	if _n == 150:
		_comprobar(Input.is_action_pressed("jugar_pase"), "el botón A (pase / presión) está pulsado")
		_foto("tactil_partido_pase")
		_toque(2, _ct.centro_de("A"), false)
		_toque(1, _ct.centro_de("Sprint"), false)
		_toque(0, Vector2(200, 560), false)
	if _n == 160:
		_comprobar(Mando.movimiento() == Vector2.ZERO and not Input.is_action_pressed("jugar_sprint"), "al levantar los dedos todo se suelta")
		print("===== FIN. %d fallos =====" % _fallos)
		ControlesTactiles.forzar = false
		get_tree().quit(0 if _fallos == 0 else 1)

func p0_distancia(p: Vector3) -> float:
	return Vector2(p.x - _p0.x, p.z - _p0.z).length()

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
	## DPI_PRUEBA=400 simula un teléfono de 400 ppp (HUD y botones por dpi); CAMARA_PRUEBA=no deja la cámara de siempre (para la captura «antes»).
	if OS.get_environment("DPI_PRUEBA") != "":
		PantallaMovil.dpi_forzado = float(OS.get_environment("DPI_PRUEBA"))
	ControlesTactiles.contexto_forzado = OS.get_environment("CONTEXTO_PRUEBA")   ## con / banda / sin: qué botones salen en la captura
	if OS.get_environment("CAMARA_PRUEBA") != "":
		AjustesTactil.poner_camara(OS.get_environment("CAMARA_PRUEBA"))
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

## Las posiciones del juego son del lienzo; el evento de pantalla lleva píxeles de la ventana (con el escalado del proyecto no son lo mismo a otra resolución que 1280×720).
func _a_ventana(pos: Vector2) -> Vector2:
	return pos * (float(DisplayServer.window_get_size().x) / get_viewport().get_visible_rect().size.x)

func _toque(dedo: int, pos: Vector2, pulsa: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = dedo
	e.position = _a_ventana(pos)
	e.pressed = pulsa
	Input.parse_input_event(e)

func _arrastre(dedo: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = dedo
	e.position = _a_ventana(pos)
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
	if _n == 70:
		_comprobar(not _pj._ayuda.visible, "la línea de ayuda de teclado está oculta con los controles táctiles")
	if _n == 80:
		ControlesTactiles.contexto_forzado = "con"
		_p0 = _pj.motor.pos(_pj.motor.usuario)
		var c0 := _ct.centro_reposo()
		_toque(0, c0, true)
		_arrastre(0, c0 + Vector2(0, -90))
		_toque(1, _ct.centro_de("SP"), true)
	if _n == 140:
		var p1: Vector3 = _pj.motor.pos(_pj.motor.usuario)
		_comprobar(Input.is_action_pressed("jugar_sprint"), "el dedo del sprint corre")
		_comprobar(Mando.movimiento().length() > 0.5, "el stick empuja con fuerza (%.2f)" % Mando.movimiento().length())
		_comprobar(p0_distancia(p1) > 1.0, "el jugador se ha movido con el dedo (%.1f m)" % p0_distancia(p1))
		_foto("tactil_partido_mueve")
		_toque(2, _ct.centro_de("PA"), true)
		_toque(3, _ct.centro_de("TI"), true)
		_arrastre(3, _ct.centro_de("TI") + Vector2(0, _ct.radio_de("TI") * 1.3))   ## deslizar hacia abajo desde Tiro = rosca (Mod)
	if _n == 150:
		_comprobar(Input.is_action_pressed("jugar_tiro") and Input.is_action_pressed("jugar_mod"), "tiro y modificador (deslizando desde Tiro) pulsados con otros dedos a la vez")
		_toque(3, _ct.centro_de("TI"), false)
		_comprobar(Input.is_action_pressed("jugar_sprint"), "el sprint sigue pulsado con el tiro soltado")
		_foto("tactil_partido_pase")
		_toque(2, _ct.centro_de("PA"), false)
		_toque(1, _ct.centro_de("SP"), false)
		_toque(0, _ct.centro_reposo(), false)
	if _n == 160:
		_comprobar(Mando.movimiento() == Vector2.ZERO and not Input.is_action_pressed("jugar_sprint"), "al levantar los dedos todo se suelta")
		_toque(5, _ct.centro_de("Pausa"), true)
		ControlesTactiles.contexto_forzado = ""
	if _n == 165:
		_toque(5, _ct.centro_de("Pausa"), false)
	if _n == 190:
		_comprobar(_pj.get("_pausa") != null, "el botón II abre la pausa (táctica y cambios)")
		_foto("tactil_partido_pausa")
		print("===== FIN. %d fallos =====" % _fallos)
		ControlesTactiles.forzar = false
		PantallaMovil.dpi_forzado = 0.0
		ControlesTactiles.contexto_forzado = ""
		AjustesTactil.restaurar()
		get_tree().quit(0 if _fallos == 0 else 1)

func p0_distancia(p: Vector3) -> float:
	return Vector2(p.x - _p0.x, p.z - _p0.z).length()

extends Node
## LEGIBILIDAD DEL PARTIDO EN EL TELÉFONO (sesión 14, 12-11): el partido jugable del modo carrera como lo ve el teléfono (Compatibility,
## 2400×1080 o 1080×2400, zoom de móvil, controles táctiles) y 3 fotos cuando ALGUIEN LLEVA EL BALÓN, para ver si se lee quién la
## lleva y hacia dónde ataca. Tres partidos de países distintos (`PARTIDO=0|1|2`: CHI, ARG, ESP).
##   PARTIDO=1 SUFIJO=x RESOLUCION=2400x1080 herramientas/captura.sh res://pruebas/captura_legible_movil.tscn --compat
## Salida: pruebas/capturas/legible_<orientación>_<partido>_<SUFIJO>_<n>.png
const SEMILLAS := [20261110, 777, 4242]
const PAISES := ["CHI", "ARG", "ESP"]
var _n := 0
var _k := 0
var _fotos := 0
var _ultima := -999
var _ui: CarreraJugadorUI
var _pj: PartidoJugable

func _ready() -> void:
	_k = clampi(int(OS.get_environment("PARTIDO")), 0, 2)
	PartidoJugable.con_ceremonia = false
	ControlesTactiles.forzar = true
	PantallaMovil.dpi_forzado = 400.0
	EscalaMovil.forzar = true
	EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	AjustesTactil.restaurar()
	var m := Mundo.new()
	m.generar([PAISES[_k]], SEMILLAS[_k])
	m.mi_club_id = ""
	m.carrera_jugador = CarreraJugador.crear(m, "Prueba Legible", "DC", false, SEMILLAS[_k])
	CarreraJugadorUI.mundo = m
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)
	_ui.carrera = m.carrera_jugador

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 120.0)
		_pj.motor.autopiloto = true
	if _pj == null or _n < 60:
		return
	var motor = _pj.motor
	if not motor.poseedor.is_empty() and motor.estado == "juego" and _n - _ultima > 45:
		_ultima = _n
		var v := DisplayServer.window_get_size()
		var orient := "vertical" if v.y > v.x else "horizontal"
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/legible_%s_%d_%s_%d.png" % [orient, _k, OS.get_environment("SUFIJO"), _fotos])
		_fotos += 1
	if _fotos >= 3 or _n > 1500:
		get_tree().quit()

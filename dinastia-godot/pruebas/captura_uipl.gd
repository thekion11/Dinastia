extends Node
## Capturas del paquete uipl (sesión 2): plantel con la ficha de un jugador
## propio, la cantera y la ficha de un jugador ajeno, en la resolución que
## pida RESOLUCION (captura.sh). Sufijo de archivo: variable SUFIJO.
##
##   RESOLUCION=1280x720 SUFIJO=antes herramientas/captura.sh res://pruebas/captura_uipl.tscn

const ESPERA := 12

var _pantalla: Node
var _n := 0
var _suf := ""
var _antes: Array = []

func _ready() -> void:
	_suf = OS.get_environment("SUFIJO")
	if _suf == "":
		_suf = "x"
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA - 1:
		_antes = _pantalla.get_children() + get_tree().root.get_children()
	if _n == ESPERA:
		var mundo = _pantalla.get("mundo")
		## Una temporada jugada: hay estadísticas, historial y camada en la cantera.
		mundo.jugar_temporada()
		mundo.nueva_temporada()
		_pantalla.call("_refrescar")
	if _n == ESPERA + 2:
		## La temporada jugada deja abiertos el periódico, la rueda de prensa y
		## avisos: se quitan para ver la pantalla de gestión limpia.
		for h in _pantalla.get_children() + get_tree().root.get_children():
			if h not in _antes and h != self:
				h.queue_free()
		_pantalla.call("_ir_a_pestana", "Mi plantel")
		var mundo = _pantalla.get("mundo")
		var mio = mundo.mi_club()
		_pantalla.call("_ver_ficha", mio.plantilla[0])
	if _n == ESPERA + 6:
		_guardar("uipl_plantel")
		_pantalla.call("_ir_a_pestana", "Cantera")
	if _n == ESPERA + 10:
		_guardar("uipl_cantera")
		var mundo2 = _pantalla.get("mundo")
		for c in mundo2.clubes.values():
			if c.id != mundo2.mi_club_id and not c.plantilla.is_empty():
				_pantalla.call("_ver_ficha", c.plantilla[0])
				break
	if _n == ESPERA + 14:
		_guardar("uipl_ficha_ajena")
		get_tree().quit()

func _guardar(nombre: String) -> void:
	var ruta := "res://pruebas/capturas/%s_%s.png" % [nombre, _suf]
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])

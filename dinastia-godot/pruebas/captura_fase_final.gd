extends Node
## Sesión 6 (10-11): la ficha de Competición con la FASE FINAL de la liga (grupos de Egipto, playoffs de Argentina y de la MLS).
##   RESOLUCION=1280x900 herramientas/captura.sh res://pruebas/captura_fase_final.tscn
## Tres ligas de tres países (ARG, USA, EGY) con otras tantas semillas; se juega hasta la mitad de la fase final y se muestra desde el cuadro.
## Fotos: pruebas/capturas/fase_final_<pais>.png (JPG tras `captura.sh`).
const CASOS := [
	{"pais": "ARG", "semilla": 311, "jornadas": 18},
	{"pais": "USA", "semilla": 312, "jornadas": 33},
	{"pais": "EGY", "semilla": 313, "jornadas": 27},
]
var _caso := 0
var _n := 0
var _mundo: Mundo
var _ficha: Competicion
var _liga: Liga

func _ready() -> void:
	_siguiente()

func _siguiente() -> void:
	if _caso >= CASOS.size():
		get_tree().quit()
		return
	var c: Dictionary = CASOS[_caso]
	Azar.sembrar(int(c["semilla"]))
	_mundo = Mundo.new()
	_mundo.generar([String(c["pais"]), "CHI", "ESP"], int(c["semilla"]))
	var mio: Club = null
	for k: Club in _mundo.clubes.values():
		if k.pais == String(c["pais"]) and k.division == 1 and (mio == null or k.rep > mio.rep):
			mio = k
	_mundo.tomar_el_mando(mio.id)
	_liga = _mundo.liga_de(mio)
	while _liga.jornada_actual < int(c["jornadas"]):
		_liga.jugar_jornada()
	if _ficha != null:
		_ficha.queue_free()
	_ficha = Competicion.new()
	_ficha.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ficha)
	_ficha.abrir(_mundo, _liga)
	_n = 0

func _process(_d: float) -> void:
	_n += 1
	if _caso >= CASOS.size():
		return
	if _n == 6:
		var scroll: ScrollContainer = _ficha.get("_scroll")
		var lista: VBoxContainer = _ficha.get("_lista")
		for hijo in lista.get_children():
			if hijo is Label and (hijo as Label).text == Idiomas.t("FASE FINAL"):
				scroll.scroll_vertical = int((hijo as Control).position.y) - 10
	elif _n == 14:
		var nombre := "fase_final_%s" % CASOS[_caso]["pais"]
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)
		print("FOTO ", nombre, " jornada ", _liga.jornada_actual, "/", _liga.jornadas())
		_caso += 1
		_siguiente()

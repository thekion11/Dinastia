extends Node
## LAS SEIS CABECERAS DEL PERIÓDICO (26-9-2026, plan maestro C20), cada una con
## una portada distinta, juntas en una hoja 3x2.
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_portadas.tscn
## Por fotogramas: sin tarjeta gráfica cada uno tarda casi medio segundo.
const PORTADAS := [
	{"t": "«Golpe de autoridad»", "sub": "Lautaro FC 3-0 Marga Marga FC", "img": "dt"},
	{"t": "El club cambia su escudo", "sub": "Buena parte de la hinchada lo rechaza: «con la historia no se juega».", "img": "escudo"},
	{"t": "«Que se preparen los de arriba»: el DT enciende la polémica", "sub": "Lo firma M. Navarrete en Canal Deportes.", "img": "dt"},
	{"t": "Hinchas insatisfechos con el nuevo fichaje", "sub": "El delantero llega con contrato de 1 año.", "img": "pid:"},
	{"t": "Tres puntos que valen oro", "sub": "Lautaro FC 1-0 U. Andina", "img": "dt"},
	{"t": "Sin respuestas: el DT se escondió tras el micrófono", "sub": "Lo firma P. Ibarra en El Pelotazo.", "img": "dt"},
]
var _n := 0
var _p: Node
var _i := -1
var _fotos: Array[Image] = []
var _hoja_actual: PortadaPeriodico

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n < 10 or _n % 5 != 0:
		return
	if _hoja_actual != null:
		var img := get_viewport().get_texture().get_image()
		if _i == 0:
			img.save_png("res://pruebas/portada_completa.png")
		var r := Rect2i(_hoja_actual._hoja.get_global_rect())
		var rec := img.get_region(r.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
		rec.resize(300, 450)
		_fotos.append(rec)
		_hoja_actual.queue_free()
		_hoja_actual = null
	_i += 1
	if _i >= PORTADAS.size():
		var hoja := Image.create(300 * 3, 450 * 2, false, _fotos[0].get_format())
		for k in _fotos.size():
			hoja.blit_rect(_fotos[k], Rect2i(0, 0, 300, 450), Vector2i((k % 3) * 300, (k / 3) * 450))
		hoja.save_png("res://pruebas/portadas_periodico.png")
		get_tree().quit()
		return
	var m: Mundo = _p.get("mundo")
	var d: Dictionary = (PORTADAS[_i] as Dictionary).duplicate()
	d["cab"] = String(PortadaPeriodico.CABECERAS[_i][0])
	d["semana"] = 12
	d["anio"] = 2026
	if String(d["img"]) == "pid:":
		d["img"] = "pid:" + m.mi_club().plantilla[9].id
	_hoja_actual = PortadaPeriodico.mostrar(_p, m, d)

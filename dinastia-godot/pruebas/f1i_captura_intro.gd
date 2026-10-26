extends Node
## CAPTURAS DE LA INTRO DE MARCA (`ui/entrada/intro.gd`, fase 1 etapa 0). Congela la intro en
## cuatro instantes (trazo del escudo, letras formándose, destello, marca completa) y guarda
## cada uno. Todo en la intro es función del tiempo, así que lo congelado es lo que se ve.
##   herramientas/captura.sh res://pruebas/f1i_captura_intro.tscn
## (`RESOLUCION=720x1280` delante para verla en un móvil en vertical.)

const MOMENTOS := [[0.65, "trazo"], [1.72, "letras"], [2.55, "destello"], [3.70, "marca"]]
## Fotogramas de espera: el primero compila los shaders; después, dos por captura.
const ESPERA := 20

var _intro: IntroMarca
var _n := 0
var _i := 0

func _ready() -> void:
	_intro = IntroMarca.new()
	_intro.configurar({})
	add_child(_intro)
	_intro.fijar_tiempo(0.0)

func _process(_d: float) -> void:
	_n += 1
	if _n < ESPERA:
		return
	var k := (_n - ESPERA) % 4
	if k == 0:
		_intro.fijar_tiempo(float(MOMENTOS[_i][0]))
	elif k == 3:
		var ruta := "res://pruebas/capturas/f1i_intro_%d_%s.png" % [_i + 1, MOMENTOS[_i][1]]
		var img := get_viewport().get_texture().get_image()
		img.save_png(ruta)
		print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
		_i += 1
		if _i >= MOMENTOS.size():
			get_tree().quit()

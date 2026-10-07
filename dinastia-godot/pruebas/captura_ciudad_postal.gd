extends Node
## La FOTO COMPLETA del mapa de la ciudad deportiva: un encuadre alto y lejano
## que entra todo a la vez -estadio de verdad, recinto e instalaciones, las
## cinco parcelas con sus carteles, el rio con el velero, el centro comercial y
## el barrio residencial al sur- mas dos planos cercanos del estadio y del
## barrio. Es la prueba de que el plano del mapa funciona como conjunto, no
## solo pieza a pieza.
##
##   godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
##         res://pruebas/captura_ciudad_postal.tscn

var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo
var _paso := 0

## [distancia, altura, angulo, nombre]
const PLANOS := [
	[700.0, 285.0, 0.62, "ciudad_postal_general"],
	[420.0, 135.0, 0.26, "ciudad_postal_estadio"],
	[250.0, 78.0, 3.34, "ciudad_postal_barrio"],
]

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	## Un club con recorrido: instalaciones construidas, terrenos comprados y
	## los negocios levantados, que es cuando el mapa tiene algo que contar.
	for k in ["ct", "acad", "med", "gim", "resid", "pren", "com", "museo", "park", "trib", "huerto", "piscina"]:
		_mundo.obras.niveles[k] = 3
	_mundo.ciudad.terrenos = ["norte", "centro", "periferia", "ribera", "sur"]
	for n in ["hotel", "parking", "comercial", "clinica"]:
		_mundo.ciudad.negocios[n] = true
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad,
		_mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)
	print("club: %s  ·  aforo %d" % [_mundo.mi_club().nombre, _mundo.mi_club().estadio_aforo])

func _process(_d: float) -> void:
	_n += 1
	if _paso >= PLANOS.size():
		return
	## Un plano cada 10 fotogramas: hace falta dejar pasar unos cuantos entre
	## mover la camara y disparar, o la imagen sale con el encuadre anterior
	## -misma trampa que ya documenta `captura_estadio.gd`-.
	if _n < 14:
		return
	var t := _n - 14
	if t % 10 != 0:
		return
	var i: int = t / 10
	if i % 2 == 0:
		var p: Array = PLANOS[_paso]
		_vista.set("_dist", p[0])
		_vista.set("_alto", p[1])
		_vista.set("_ang", p[2])
	else:
		var p: Array = PLANOS[_paso]
		var img := get_viewport().get_texture().get_image()
		var ruta := "res://pruebas/capturas/%s.png" % String(p[3])
		img.save_png(ruta)
		print("captura: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
		_paso += 1
		if _paso >= PLANOS.size():
			get_tree().quit()

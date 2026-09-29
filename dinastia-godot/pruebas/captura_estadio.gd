extends Node
## Abre el estadio 3D de un club y lo captura desde varias camaras.
##
## OJO CON EL ORDEN: cambiar de camara y capturar en el MISMO fotograma no vale.
## `get_viewport().get_texture()` devuelve lo ULTIMO que se pinto, asi que la
## imagen sale con el encuadre anterior y parece que el cambio de camara no
## funciona. Hay que dejar pasar unos fotogramas entre una cosa y la otra.
##
## Tampoco puede correr con --headless (sin ventana no hay framebuffer) y hay que
## arrancar con Vulkan: en Compatibility no existen ni la oclusion ambiental ni
## los reflejos, asi que la captura no probaria nada.
##
##   godot --path . --rendering-driver vulkan res://pruebas/captura_estadio.tscn

const ESPERA := 24     ## fotogramas antes de empezar: el estadio es grande
const ENTRE := 8       ## fotogramas entre cambiar de camara y disparar

var _n := 0
var _vista: VistaEstadio
var _mundo: Mundo
var _paso := 0
## Las tres que mejor cuentan el recinto: el plano de television, el dron y el
## ras de cesped.
const CAMARAS := [0, 5, 3]

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 2026)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), 0.86, _mundo.ligas[0].clubes[1])
	var perfil := _mundo.mi_club().perfil_estadio()
	var g := StadiumBuilder.geom_de_forma(String(perfil["forma"]))
	print("estadio de %s: %s" % [_mundo.mi_club().nombre, perfil])
	print("geometria: dx=%s dz=%s alto=%s" % [
		g["dx"], g["dz"], StadiumBuilder.altura_de(perfil, int(perfil["aforo"]))])

func _process(_d: float) -> void:
	_n += 1
	if _n < ESPERA:
		return
	var t := _n - ESPERA
	if t % ENTRE != 0:
		return
	var i := t / ENTRE
	if i >= CAMARAS.size() * 2:
		get_tree().quit()
		return
	if i % 2 == 0:
		var rig: CameraRig = _vista.get("_rig")
		if i == 0:
			print("en el campo: %d" % (_vista.get("_en_campo") as Array).size())
		rig.switch_to(CAMARAS[i / 2])
		print("camara -> %s" % rig.current_name())
	else:
		var img := get_viewport().get_texture().get_image()
		var ruta := "res://pruebas/capturas/estadio_%d.png" % (i / 2 + 1)
		img.save_png(ruta)
		print("captura: %s" % ruta)

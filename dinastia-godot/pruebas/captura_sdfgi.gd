extends Node
## Prueba de SDFGI (13-9-2026): fuerza calidad ULTRA -donde vive SDFGI- y
## compara un fotograma TEMPRANO (cascadas recien arrancando) contra uno
## CONVERGIDO (bastante despues), para saber si la sobreexposicion vista al
## principio era el propio SDFGI en regimen o solo el arranque en frio de sus
## cascadas.
##
##   godot --path . --resolution 1280x720 res://pruebas/captura_sdfgi.tscn

var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo

func _ready() -> void:
	Calidad.elegida = Calidad.ULTRA
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	for k in _mundo.obras.niveles.keys():
		_mundo.obras.niveles[k] = 3
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad,
		_mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)
	_vista.call("alternar_ciclo")
	_vista.set("_hora", 15.5)
	_vista.call("_aplicar_hora")
	_vista.set("_dist", 260.0)
	_vista.set("_alto", 65.0)
	_vista.set("_ang", 2.6)

func _process(_d: float) -> void:
	_n += 1
	if _n == 40:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/sdfgi_temprano.png")
		print("temprano guardado (frame 40)")
	if _n == 220:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/sdfgi_convergido.png")
		print("convergido guardado (frame 220)")
		var env: Environment = _vista.get("_env")
		env.sdfgi_enabled = false
	if _n == 260:
		var img3 := get_viewport().get_texture().get_image()
		img3.save_png("res://pruebas/sdfgi_apagado.png")
		print("apagado guardado (frame 260)")
		get_tree().quit()

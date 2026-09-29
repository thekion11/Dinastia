extends Node
## Prueba del viento en el follaje (13-9-2026): dos capturas de la MISMA
## vista, separadas por 90 fotogramas (1,5 s a 60 fps), para comprobar que
## las copas -que llevan una silueta fija- se ven distintas de un fotograma a
## otro -es decir que de verdad se mueven-, no solo que compila.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_viento_arboles.tscn

var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad,
		_mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)
	_vista.call("alternar_ciclo")
	_vista.set("_hora", 12.0)
	_vista.call("_aplicar_hora")
	## Bien cerca de un grupo de arboles del barrio, para que se vean grandes.
	_vista.set("_dist", 90.0)
	_vista.set("_alto", 18.0)
	_vista.set("_ang", 0.4)

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/viento_arboles_a.png")
		print("captura A guardada")
	if _n == 110:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/viento_arboles_b.png")
		print("captura B guardada")
		## Verificación numérica, no solo ojo: un punto en el BORDE de la copa
		## grande de primer plano (donde el vaivén desplaza más el contorno,
		## no en el centro donde cualquier desplazamiento pequeño sigue
		## cayendo dentro de la misma copa). Si el shader mueve vértices de
		## verdad, ese punto pasa de "borde de la copa" a "fondo" o viceversa
		## entre una captura y otra.
		var imgA := Image.new()
		imgA.load("res://pruebas/capturas/viento_arboles_a.png")
		var pA := imgA.get_pixel(560, 470)
		var pB := img2.get_pixel(560, 470)
		print("pixel de borde en A: %s   en B: %s   ¿distinto? %s" % [pA, pB, pA != pB])
		get_tree().quit()

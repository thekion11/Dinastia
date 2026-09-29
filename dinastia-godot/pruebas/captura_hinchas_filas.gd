extends Node
## Verifica a ojo el arreglo del 22-9-2026: las 5 filas REALES de butacas
## (`StadiumBuilder._butacas()`) ahora sientan hinchas -antes se veian vacias
## aunque la textura de graderio, desde la fila 6, ya pintara gente. Encuadre
## propio, cerca de la tribuna lateral, para que las primeras filas llenen el
## cuadro -las camaras de partido normales estan pensadas para seguir la
## pelota, no para inspeccionar la grada de cerca-.
##
## NO puede correr con --headless: sin ventana no hay framebuffer.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_hinchas_filas.tscn

var _vista: VistaEstadio
var _frame := 0

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var mio := mundo.mi_club()
	mio.saldo = 999999999

	var p := mundo.perfil_estadio_de(mio)
	_vista = VistaEstadio.new()
	add_child(_vista)
	## Ocupacion alta (0.9) para que las filas reales salgan bien pobladas y el
	## efecto se note sin dudas en la captura. `comercial` (piel del balon) no
	## hace falta para esto -recien lo crea `tomar_el_mando()`, que esta
	## captura no llama a proposito, no le hace falta nada mas del mundo-.
	_vista.abrir(mio, 0.9, null, null, p)

	## Camara propia, a ras de campo mirando de costado hacia la tribuna Este
	## (x positivo) -ahi es donde `_butacas()` puso las 5 filas reales que antes
	## se veian vacias-. Z=15 (no Z=0): a mitad de cancha hay un camarografo de
	## utileria (`stadium_builder.gd::_camarografos()`, puesto (36.5,0,0)) y la
	## primera version de esta captura quedo parada frente a el a contraluz -no
	## es un bug del arreglo de hinchas, era mal encuadre de esta prueba misma.
	var cam := Camera3D.new()
	cam.position = Vector3(31.0, 1.3, 15.0)
	cam.fov = 50.0
	_vista._raiz3d.add_child(cam)
	cam.look_at(Vector3(40.0, 1.1, 15.0), Vector3.UP)
	cam.current = true

func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_hinchas_filas.png")
		print("captura guardada: res://pruebas/pantalla_hinchas_filas.png (%dx%d)" % [img.get_width(), img.get_height()])
	elif _frame == 25:
		## Segunda captura, SOLO para revisar la viñeta (22-9-2026): en el
		## encuadre de arriba las esquinas ya eran negras de por si (cielo +
		## estructura del estadio), asi que ahi no se puede distinguir la viñeta
		## de lo que ya era oscuro. La camara cenital tactica (indice 7 de
		## CameraRig) muestra puro cesped parejo de borde a borde -el fondo mas
		## limpio posible para ver si el oscurecido de esquinas aparece o no-.
		_vista._rig.switch_to(7)
	elif _frame == 45:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/pantalla_vineta_cenital.png")
		print("captura guardada: res://pruebas/pantalla_vineta_cenital.png (%dx%d)" % [img2.get_width(), img2.get_height()])
		print("FIN. 0 fallos")
		get_tree().quit()

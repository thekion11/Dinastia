extends Node
## Verifica a ojo el "efecto banquillo" (22-9-2026, Fase 3 del ROADMAP:
## "animaciones de lenguaje corporal en la banda"). Hasta hoy la banda estaba
## vacia -ni un solo suplente se veia en el visor 3D-. Ahora `_poner_banca()`
## pone hasta 7 por equipo de pie junto a su banquillo, y `_banca_celebra()`
## los hace festejar un gol propio.
##
## NO puede correr con --headless: sin ventana no hay framebuffer.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_banquillo.tscn

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _frame := 0
var _cam: Camera3D
var _cam2: Camera3D
var _cam3: Camera3D

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)
	print("partido: %s vs %s" % [par[0].nombre, par[1].nombre])

	## Camara propia, del LADO DE LA CANCHA mirando hacia afuera al banquillo
	## LOCAL (club, es_local=true en `spawn_banca`, Z=-14) -NO mas afuera en
	## X que la banca misma: `dx=49` de "cuenco" es el CENTRO de la tribuna,
	## que tiene 11m de fondo (cara interior en dx-5.5=~43.5), asi que
	## cualquier camara con X>43 queda DENTRO del graderio, pegada a la
	## textura de la grada -exactamente lo que salio en el primer intento,
	## una imagen borrosa a rayas en vez del banquillo-. Desde dentro de la
	## cancha (X chico) mirando hacia afuera se ve la fila completa sin
	## chocar con nada.
	## En ANGULO respecto a la fila, no de frente -mirando derecho por el eje
	## Z (el mismo eje en el que se reparten los 7) los 7 se tapan entre si
	## en la imagen, aunque geometricamente esten separados; en angulo se
	## reparten por el ancho del cuadro, como mirar una fila de gente desde
	## un costado.
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.fov = 60.0
	_cam.position = Vector3(16.0, 2.4, -22.0)
	_cam.look_at(Vector3(35.0, 1.5, -14.0), Vector3.UP)

	## Segunda camara, pegada a los 5 sentados (mas alla de Z=-19.8) para
	## juzgar la pose de cerca -altura del asiento, piernas dobladas, sin
	## flotar ni hundirse-.
	_cam2 = Camera3D.new()
	add_child(_cam2)
	_cam2.fov = 45.0
	_cam2.position = Vector3(28.0, 1.6, -24.0)
	_cam2.look_at(Vector3(35.0, 0.5, -22.0), Vector3.UP)

	## Tercera camara, a RAS DE SUELO y de PERFIL (no de frente, para ver el
	## doblez de la rodilla de costado, no tapado por el propio cuerpo) sobre
	## el sentado del medio (i=2, z~-23.15) -el usuario pregunto puntualmente
	## si las piernas se ven feas, esto es para mirarlas de cerca sin que el
	## tablon del banco (y=0.45, 0.1 de grosor) tape nada.
	_cam3 = Camera3D.new()
	add_child(_cam3)
	_cam3.fov = 40.0
	_cam3.position = Vector3(33.5, 0.55, -20.5)
	_cam3.look_at(Vector3(35.0, 0.35, -23.15), Vector3.UP)

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 8:
		var en_banca: Array = _vista.get("_en_banca")
		print("banca: %d figuras (esperado hasta 14, 7 por equipo)" % en_banca.size())
		for f: Dictionary in en_banca:
			print("  %s  es_local=%s  pos=%s  rot.y=%.2f" % [
				String(f.get("id", "?")), f.get("es_local"), f.get("node").position,
				f.get("node").rotation.y])
	if _frame == 10:
		_cam.current = true
	if _frame == 20:
		_cam2.current = true
	if _frame == 22:
		var imgc := get_viewport().get_texture().get_image()
		imgc.save_png("res://pruebas/pantalla_banquillo_sentados_cerca.png")
		print("captura guardada: pantalla_banquillo_sentados_cerca.png (%dx%d)" % [imgc.get_width(), imgc.get_height()])
		_cam3.current = true
	if _frame == 24:
		var imgp := get_viewport().get_texture().get_image()
		imgp.save_png("res://pruebas/pantalla_banquillo_piernas.png")
		print("captura guardada: pantalla_banquillo_piernas.png (%dx%d)" % [imgp.get_width(), imgp.get_height()])
		_cam.current = true
	if _frame == 25:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_banquillo_antes.png")
		print("captura guardada: pantalla_banquillo_antes.png (%dx%d)" % [img.get_width(), img.get_height()])
		## Gol forzado del club LOCAL DE LA VISTA (`par[0]`, dueno del
		## estadio) justo despues de la primera captura -mismo patron que
		## `video_jugada_gol.gd`: se dispara vía `.emit()`, no se espera a
		## que la simulacion anote sola.
		if _partido.once_local.size() >= 1:
			var autor: Jugador = _partido.once_local[0]
			print("forzando gol de %s (%s)" % [autor.nombre, _partido.local.nombre])
			_partido.gol.emit(_partido.local, autor, 12, null)
	## `_seguir_jugada_gol()` (ui/estadio.gd) cambia la cámara activa a "Tele
	## Dinámica" en cuanto hay un gol -comportamiento real del juego, no un
	## bug-, así que se lleva puesta la cámara propia de esta prueba. Un
	## primer intento reafirmaba `_cam.current=true` EN EL MISMO frame que la
	## captura y seguía saliendo la vista del partido: el cambio de cámara se
	## aplica al RENDER, que pasa después de que termina `_process()` de todo
	## el frame -capturar inmediatamente después de cambiarla, en el mismo
	## frame, agarra el render viejo, un frame atrasado-. Por eso ahora se
	## reafirma un frame ANTES de cada captura, no en el mismo.
	if _frame == 44 or _frame == 219:
		_cam.current = true
	if _frame == 45:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/pantalla_banquillo_festejo.png")
		print("captura guardada: pantalla_banquillo_festejo.png (%dx%d)" % [img2.get_width(), img2.get_height()])
	if _frame == 220:
		## `_banca_celebra()` vuelve sola a "parado" a los 3s (~180 fotogramas
		## a 60fps) -una tercera captura confirma que no se queda pegada en
		## la pose de festejo para siempre.
		var img3 := get_viewport().get_texture().get_image()
		img3.save_png("res://pruebas/pantalla_banquillo_vuelta.png")
		print("captura guardada: pantalla_banquillo_vuelta.png (%dx%d)" % [img3.get_width(), img3.get_height()])
		print("FIN. 0 fallos")
		get_tree().quit()

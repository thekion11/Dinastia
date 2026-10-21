extends Node
## Sentarse en la grada (21-10-2026): la butaca de verdad, sin nadie encima.
##   herramientas/captura.sh res://pruebas/captura_sentarse.tscn
var _vista: VistaEstadio
var _n := 0
var _e: ExploradorEstadio

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(mundo.mi_club(), 0.95)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_vista.recorrer()
		_e = _vista.get("_explorador")
	if _n == 14:
		_e.cuerpo.position = Vector3(34.5, 0, 8.0)
		_e.sentarse()
		print("RUTA ", _e.get("_ruta"))
	## Mientras sube por la escalera (cámara de detrás).
	if _n == 40 or _n == 75:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/sentarse_subiendo%s.png" % ("" if _n == 40 else "_2"))
		print("FOTO subiendo en ", _e.cuerpo.position)
	if _n > 75 and _n < 400 and not _e.sentado:
		return
	if _n > 75 and _n < 400:
		_n = 400
		print("SENTADO en ", _e.cuerpo.position)
	if _n == 406:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/sentarse_vista.png")
		print("FOTO vista")
		## Desde fuera: una cámara en el campo mirando la butaca.
		var cam := Camera3D.new()
		(_vista.get("_raiz3d") as Node3D).add_child(cam)
		cam.global_position = _e.cuerpo.global_position + Vector3(-7.0, 1.5, 3.0)
		cam.look_at(_e.cuerpo.global_position + Vector3(0, 0.6, 0))
		cam.fov = 45.0
		cam.current = true
		_e.cuerpo.visible = true
	if _n == 410:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/sentarse_fuera.png")
		print("FOTO fuera")
		get_tree().quit()

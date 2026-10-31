extends Node
## CAPTURA DE LA ESTACIÓN CENTRAL CON LA CIUDAD ENTERA (27-10-2026, Forward+), de día:
##   herramientas/captura.sh res://pruebas/ideas/p_captura_estacion.tscn
## Vista aérea cercana sobre el nodo `EstacionCentral` y otra más baja, al rato (los trenes entran y salen).
## Sale en pruebas/capturas/estacion_{aerea,baja}.jpg. Solo mira; no cambia el juego.

var _m: Mundo
var _vista: VistaCiudad

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/estacion_%s.png" % nombre)
	print("captura ", nombre)

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout

func _ready() -> void:
	_m = Mundo.new()
	_m.generar(["CHI", "ARG"], 4242)
	_m.tomar_el_mando(_m.ligas[0].clubes[0].id)
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	_vista.abrir(club, _m.obras, _m.ciudad, _m.perfil_estadio_de(club))
	await _esperar(2.0)
	_vista.set("_girando", false)
	_vista.set("_ciclo_activo", false)
	_vista.set("_hora", 11.0)
	_vista.call("_aplicar_hora")
	var cb: CityBuilder = _vista.get("_ciudad")
	var est := cb.find_child("EstacionCentral", true, false) as Node3D
	if est == null:
		print("sin estación")
		get_tree().quit()
		return
	var c := est.global_position
	print("estación en ", c)
	for toma: Array in [["aerea", 140.0, 90.0, 0.6], ["baja", 70.0, 28.0, 2.2]]:
		_vista.set("_objetivo", c + Vector3(0, 4, 0))
		_vista.set("_objetivo_deseado", c + Vector3(0, 4, 0))
		_vista.set("_dist", float(toma[1]))
		_vista.set("_alto", float(toma[2]))
		_vista.set("_ang", float(toma[3]))
		_vista.call("_mover_camara")
		await _esperar(6.0)
		await _foto(String(toma[0]))
	print("capturas hechas")
	get_tree().quit()

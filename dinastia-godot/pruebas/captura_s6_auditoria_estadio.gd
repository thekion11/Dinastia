extends Node
## SESIÓN 6 · AUDITORÍA VISUAL (26-10-2026): el estadio del club desde el mapa,
## acercando la cámara real (de 430 m a 160 m), para ver si el «bloque blanco»
## de lejos es un LOD que salta o el estadio de verdad.
##   herramientas/captura.sh res://pruebas/captura_s6_auditoria_estadio.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n)

func _encuadre(dist: float, alto: float) -> void:
	_v.set("_girando", false)
	_v.set("_ang", 0.0)
	_v.set("_dist", dist)
	_v.set("_alto", alto)
	_v.set("_objetivo_deseado", CityBuilder.ESTADIO_EN + Vector3(0, 10, 0))
	_v.set("_objetivo", CityBuilder.ESTADIO_EN + Vector3(0, 10, 0))

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 13.0)
		_v.call("_aplicar_hora")
		_encuadre(420.0, 110.0)
	if _n == 22:
		_foto("s6a_estadio_lejos")
		_encuadre(170.0, 60.0)
	if _n == 36:
		_foto("s6a_estadio_cerca")
		get_tree().quit()

extends Node
## SESIÓN 6 (26-10-2026): la Casa Grande con los bloques KayKit (CC0) vista con la
## cámara real del juego -a pie, delante del portón- y el minimapa con la ruta suave.
##   herramientas/captura.sh res://pruebas/captura_s6_casa.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n)

func _a_pie(rumbo: float, atras: float) -> void:
	var f := CiudadExpansion.FINCA_GRANDE
	var e: ExploradorCiudad = _v.get("_explorador")
	e.cuerpo.position = Vector3(f.get_center().x, 0.2, f.position.y - atras)
	e.rumbo = rumbo

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 16.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_a_pie(0.0, 30.0)
	if _n == 20:
		_foto("s6_casa_rumbo0")
		_a_pie(PI, 30.0)
	if _n == 34:
		_foto("s6_casa_rumboPI")
		get_tree().quit()

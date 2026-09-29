extends Node
## LA CIUDAD CRECE CON EL CLUB: la misma ciudad con un club modesto y con uno
## grande, desde el mismo encuadre. Es la prueba de que reputacion y socios de
## verdad cambian el mapa -skyline, barrio y trafico- y no solo un numero.
##
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 \
##         res://pruebas/captura_crecimiento.tscn

## [reputacion, socios, nombre]
const CASOS := [
	[28, 4000, "crecimiento_club_chico"],
	[92, 68000, "crecimiento_club_grande"],
]

var _n := 0
var _paso := 0
var _vista: VistaCiudad
var _mundo: Mundo

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	for k in ["ct", "acad", "med", "gim", "park", "huerto"]:
		_mundo.obras.niveles[k] = 2
	_mundo.ciudad.terrenos = ["norte", "periferia"]
	_montar()

func _montar() -> void:
	if _vista != null:
		_vista.queue_free()
	var caso: Array = CASOS[_paso]
	var c := _mundo.mi_club()
	c.rep = int(caso[0])
	c.socios = int(caso[1])
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(c, _mundo.obras, _mundo.ciudad, _mundo.perfil_estadio_de(c))
	_vista.set("_girando", false)
	_vista.call("alternar_ciclo")
	_vista.set("_hora", 16.5)
	_vista.set("_dist", 620.0)
	_vista.set("_alto", 230.0)
	_vista.set("_ang", 0.75)
	_vista.call("_aplicar_hora")
	var ciudad3d: Node = _vista.get("_ciudad")
	var faros: Array = ciudad3d.get("_farolas_luz")
	print("rep %d, socios %d  ->  %d nodos en la ciudad, %d farolas" % [
		c.rep, c.socios, ciudad3d.get_child_count(), faros.size()])

func _process(_d: float) -> void:
	_n += 1
	if _n < 12:
		return
	if (_n - 12) % 10 != 0:
		return
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://pruebas/capturas/%s.png" % String(CASOS[_paso][2]))
	print("captura %s" % String(CASOS[_paso][2]))
	_paso += 1
	if _paso >= CASOS.size():
		get_tree().quit()
		return
	_montar()
	_n = 2

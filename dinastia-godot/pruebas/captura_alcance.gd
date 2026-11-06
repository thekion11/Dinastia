extends Node
## ¿CÓMO SE VE EL ALCANCE DE DIBUJO A PIE? (7-11) Entra a la ciudad a pie en tres sitios (calle del barrio, avenida, junto al estadio) y guarda una foto de cada uno con la cámara real.
##   ALCANCE_PIE=700 SALIDA=/tmp/alc_700 herramientas/captura.sh res://pruebas/captura_alcance.tscn   (y con otro alcance: se comparan las fotos)
var _n := 0
var _p: Node
var _v: VistaCiudad
const SITIOS := [Vector3(20, 0.2, 300), Vector3(-60, 0.2, 390), Vector3(150, 0.2, 100)]
const DESPUES := [Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, 1)]

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ULTRA_BAJA)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	Engine.max_fps = 0
	_n += 1
	if _n == 5:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_girando", false)
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 13.0)
		_v.call("_aplicar_hora")
	if _n == 60:
		_v.explorar("pie")
	var k := (_n - 70) / 40
	if _n >= 70 and k < SITIOS.size():
		var e: ExploradorCiudad = _v.get("_explorador")
		if (_n - 70) % 40 == 0:
			e.cuerpo.position = SITIOS[k]
		if (_n - 70) % 40 == 30:
			var carpeta := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "/tmp"
			get_viewport().get_texture().get_image().save_png("%s/alcance_%d.png" % [carpeta, k])
	if k >= SITIOS.size():
		get_tree().quit()

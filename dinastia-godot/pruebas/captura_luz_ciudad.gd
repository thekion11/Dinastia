extends Node
## LUZ DE LA CIUDAD con la cámara real (S5 «look GTA», 27-10-2026): la misma calle a 7:00, 12:00, 18:20 (hora dorada) y 21:30.
## Salen en $PREFIJO_N.png (PREFIJO por defecto /tmp/luz). Para el antes/después: PREFIJO=/tmp/luz_antes y /tmp/luz_despues.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_luz_ciudad.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
const HORAS := [7.0, 12.0, 18.3, 21.5]
const POR_ESCENA := 24

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.explorar("pie")
		_e = _v.get("_explorador")
		VidaCiudad.enganchar(_e, _v, _p.get("mundo"))
		return
	if _n < 8:
		return
	for cl in get_tree().root.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	var k := (_n - 8) / POR_ESCENA
	var f := (_n - 8) % POR_ESCENA
	if k >= HORAS.size():
		print("FIN. 0 fallos")
		get_tree().quit()
		return
	if f == 0:
		_v.set("_hora", HORAS[k])
		_v.call("_aplicar_hora")
		var b: CityBuilder = _e.cb
		var p: Vector3 = b.puertas_vida[0]["p"]
		var nn: Vector3 = b.puertas_vida[0]["n"]
		var d := (nn + nn.cross(Vector3.UP) * 0.8).normalized()
		var en := p + d * 16.0
		_e.cuerpo.position = Vector3(en.x, _e.altura_suelo(en.x, en.z), en.z)
		_e.set("rumbo", atan2(-d.x, -d.z))
	if f == POR_ESCENA - 2:
		var pref := OS.get_environment("PREFIJO") if OS.get_environment("PREFIJO") != "" else "/tmp/luz"
		get_viewport().get_texture().get_image().save_png("%s_%d.png" % [pref, k])
		print("FOTO ", pref, "_", k)

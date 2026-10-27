extends Node
## P3 con la CÁMARA REAL en la ciudad (27-10-2026): un vecino abre la puerta de un portal, otro sube la escalinata del
## ayuntamiento y el banquillo local de la visita con sus 5 suplentes. Salen en /tmp/p3_ciudad_N.png (0 puerta, 1 escalinata, 2 banquillo).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_p3_ciudad.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
const POR_ESCENA := 14

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

## Pone al jugador a `dist` m de `objetivo`, en la dirección `desde` (horizontal), mirándolo.
func _plantar(objetivo: Vector3, desde: Vector3, dist: float) -> void:
	var d := Vector3(desde.x, 0, desde.z).normalized()
	var en := objetivo + d * dist
	_e.cuerpo.position = Vector3(en.x, _e.altura_suelo(en.x, en.z), en.z)
	_e.set("rumbo", atan2(-d.x, -d.z))

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 12.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_e = _v.get("_explorador")
		return
	if _n < 8:
		return
	for cl in get_tree().root.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	var k := (_n - 8) / POR_ESCENA
	var f := (_n - 8) % POR_ESCENA
	var b: CityBuilder = _e.cb
	if k > 2:
		print("FIN. 0 fallos")
		get_tree().quit()
		return
	if f == 0:
		match k:
			0:
				var pv: PuertaVida = _e.vida.puertas
				var i := 0
				var p: Vector3 = b.puertas_vida[i]["p"]
				var nn: Vector3 = b.puertas_vida[i]["n"]
				_plantar(p, nn + nn.cross(Vector3.UP) * 0.5, 10.0)
				pv.iniciar(i, true)
				pv._mover(5.6)
			1:
				var ev: EscaleraVida = _e.vida.escaleras
				var j := -1
				for q in b.escaleras.size():
					var e: Dictionary = b.escaleras[q]
					if int(e["n"]) == 6 and (e["pie"] as Vector3).y > -0.1 and (e["cima"] as Vector3).y > 1.2:
						j = q
						break
				print("ESCALINATA ", j, " ", b.escaleras[j] if j >= 0 else {})
				if j >= 0:
					var pie: Vector3 = b.escaleras[j]["pie"]
					var cima: Vector3 = b.escaleras[j]["cima"]
					_plantar(pie, Vector3(pie.x - cima.x, 0, pie.z - cima.z) + Vector3(1, 0, 0), 9.0)
					ev.iniciar(j, true)
					ev._mover(float(b.escaleras[j]["n"]) * EscaleraVida.V_PASO * 0.45)
			2:
				var banco := CityBuilder.ESTADIO_EN + Vector3(35.0, 0.0, -20.4)
				_plantar(banco, Vector3(-1, 0, 0.35), 9.0)
	if f == POR_ESCENA - 2:
		var nom := "/tmp/p3_ciudad_%d.png" % k
		get_viewport().get_texture().get_image().save_png(nom)
		print("FOTO ", nom)

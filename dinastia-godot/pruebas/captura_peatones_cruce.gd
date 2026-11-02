extends Node
## Peatones NPC que esperan en el bordillo y cruzan con su semáforo (a pie, en el cruce más cercano al centro). → /tmp/pcruce_<n>.png
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _cruce := Vector3.ZERO

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
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
		return
	if _n < 8:
		return
	for cl in get_tree().root.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	_v.set("_hora", 12.0)
	_v.call("_aplicar_hora")
	var f := _n - 8
	if f == 0:
		var lista: Array = _e.cb.expansion.cruces_semaforo.duplicate()
		lista.sort_custom(func(a: Vector3, b: Vector3) -> bool: return Vector2(a.x, a.z).length() < Vector2(b.x, b.z).length())
		_cruce = lista[0]
		var en := _cruce   ## en el centro del cruce (calzada segura)
		_e.cuerpo.position = Vector3(en.x, _e.altura_suelo(en.x, en.z), en.z)
		_e.set("rumbo", atan2(-(_cruce.x - en.x), -(_cruce.z - en.z)))
		print("cruce ", _cruce)
	if f == 40 or f == 400:
		get_viewport().get_texture().get_image().save_png("/tmp/pcruce_%d.png" % (0 if f == 40 else 1))
	if f == 401:
		print("FIN. 0 fallos")
		get_tree().quit()

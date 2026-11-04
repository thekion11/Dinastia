class_name RotulosPerezosos
extends Node
## ROTULOS 3D QUE SE CREAN CERCA DE LA CÁMARA (4-11-2026, A4-REND-004). Un `Label3D` cuesta ~32 KB de memoria nada más
## entrar en el árbol (se forma su malla de texto), aunque su `visibility_range_end` lo oculte: los ~3.300 carteles de
## comercios de la ciudad eran ~110 MB (medido: +105 MB headless, +114 MB con GL) que solo se ven a menos de 110 m.
## Aquí se guarda la ESPECIFICACIÓN de cada cartel y su nodo solo existe mientras la cámara esté a menos de `RADIO`
## (su rango de visión + 30 m), con histéresis para no crearlo y soltarlo en el borde. Lo que se ve es lo mismo.
## Sin pantalla (pruebas headless) o sin cámara se crean todos al momento, como antes. El texto se traduce al crear.
const MARGEN := 30.0
const SALIDA_EXTRA := 35.0
const POR_TICK := 25

var _esp: Array[Dictionary] = []
var _vivo: Array = []
var _t := 1.0e9
var _todos := false

static func de(b: Node3D) -> RotulosPerezosos:
	var r := b.get_node_or_null("RotulosPerezosos") as RotulosPerezosos
	if r == null:
		r = RotulosPerezosos.new()
		r.name = "RotulosPerezosos"
		r._todos = DisplayServer.get_name() == "headless"
		b.add_child(r)
	return r

## `a`: propiedades del cartel (`texto`, `pos`, `giro`, `rango`, `traducir`, `font_size`, `pixel_size`, `outline_size`,
## `borde`, `modulate`, `ancho`). Lo que no se da queda como en un `Label3D` nuevo.
func anadir(a: Dictionary) -> void:
	_esp.append(a)
	_vivo.append(_crear(_esp.size() - 1) if _todos else null)

func _crear(i: int) -> Label3D:
	var e: Dictionary = _esp[i]
	var l := Label3D.new()
	l.text = Idiomas.t(String(e["texto"])) if bool(e.get("traducir", false)) else String(e["texto"])
	l.font_size = int(e.get("font_size", 48))
	l.pixel_size = float(e.get("pixel_size", 0.01))
	l.outline_size = int(e.get("outline_size", 12))
	if e.has("borde"):
		l.outline_modulate = e["borde"]
	if e.has("modulate"):
		l.modulate = e["modulate"]
	if e.has("ancho"):
		l.width = float(e["ancho"])
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.position = e["pos"]
	l.rotation.y = float(e["giro"])
	l.visibility_range_end = float(e["rango"])
	get_parent().add_child(l)
	return l

func _process(delta: float) -> void:
	if _todos:
		return
	_t += delta
	if _t < 0.2:
		return
	var primera := _t > 1.0e8
	_t = 0.0
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var c := cam.global_position
	var nuevos := 0
	for i in _esp.size():
		var e: Dictionary = _esp[i]
		var d2 := c.distance_squared_to(e["pos"] as Vector3)
		var r: float = float(e["rango"]) + MARGEN
		var l: Variant = _vivo[i]
		if l == null:
			if d2 <= r * r and (primera or nuevos < POR_TICK):
				_vivo[i] = _crear(i)
				nuevos += 1
		elif d2 > (r + SALIDA_EXTRA) * (r + SALIDA_EXTRA):
			(l as Label3D).free()
			_vivo[i] = null

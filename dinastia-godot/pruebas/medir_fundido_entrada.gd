extends Node
## Mide (Forward+, `herramientas/captura.sh`) cuánto se queda la pantalla en negro desde
## «Nuevo juego» hasta que la intro ya enseña algo: brillo medio del viewport por fotograma.
##   herramientas/captura.sh res://pruebas/medir_fundido_entrada.tscn
## Este nodo cuelga de la raíz (no es la escena actual) para sobrevivir al cambio de escena.

var _n := 0
var _t0 := 0
var _inicio: Node
var _negro_desde := -1
var _visto := false

func _ready() -> void:
	OrquestadorEntrada.ruta_prefs = "user://medir_fundido_entrada.cfg"
	if get_parent() != get_tree().root or get_tree().current_scene == self:
		var yo := Node.new()
		yo.set_script(get_script())
		yo.name = "Medidor"
		get_tree().root.add_child.call_deferred(yo)
		_inicio = (load("res://escenas/inicio.tscn") as PackedScene).instantiate()
		add_child(_inicio)
		set_process(false)
		return

func _brillo() -> float:
	var img := get_viewport().get_texture().get_image()
	img.resize(64, 36, Image.INTERPOLATE_BILINEAR)
	var s := 0.0
	for y in 36:
		for x in 64:
			s += img.get_pixel(x, y).get_luminance()
	return s / (64.0 * 36.0)

func _process(_d: float) -> void:
	_n += 1
	if _n == 40:
		var ini: Node = get_tree().current_scene.get_child(0)
		print("pulso «Nuevo juego» en ", ini.name)
		_t0 = Time.get_ticks_msec()
		ini.call("_nuevo_juego")
		return
	if _n < 40:
		return
	var ms := Time.get_ticks_msec() - _t0
	var b := _brillo()
	if b < 0.02 and _negro_desde < 0:
		_negro_desde = ms
	if _negro_desde >= 0 and b >= 0.02 and not _visto:
		_visto = true
		print("NEGRO: %d ms (de %d a %d ms tras el clic)" % [ms - _negro_desde, _negro_desde, ms])
	if true:
		print("  %5d ms  brillo %.3f" % [ms, b])
	if b >= 0.06 and _negro_desde >= 0 and not has_meta("claro"):
		set_meta("claro", true)
		print("CLARO (brillo ≥ 0,06): %d ms tras el clic" % ms)
	if has_meta("claro") or ms > 6000:
		get_tree().quit()

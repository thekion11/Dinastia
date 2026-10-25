extends Node
var _p: Node
var _t := 0.0
var _hecho := false
var _av: Node
func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(d: float) -> void:
	if Engine.get_process_frames() < 12:
		return
	_t += d
	if not _hecho:
		_hecho = true
		Aviso.mostrar(_p, "logro", "🏆", "Prueba", "desc")
		for n in _p.get_children():
			if n is Aviso:
				_av = n
		print("frames ", Engine.get_process_frames())
	if is_instance_valid(_av):
		print("t %.2f pos %s a %.2f inside %s" % [_t, _av.position, _av.modulate.a, _av.is_inside_tree()])
	if _t > 1.0:
		get_tree().quit()

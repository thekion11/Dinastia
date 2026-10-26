class_name Repeticion
extends "res://visor/repeticion_p1.gd"
## (Parte 2 de 2 de `repeticion.gd`.)

## El punto de la animación entre dos cuadros (dando la vuelta si es un ciclo).
static func _punto_anim(ap: AnimationPlayer, anim: String, pa: float, anim_b: String, pb: float, f: float, dt: float) -> float:
	var largo := ap.get_animation(anim).length
	if anim_b != anim:
		return minf(pa + f * dt, largo)
	if pb >= pa:
		return lerpf(pa, pb, f)
	if largo <= 0.0:
		return pa
	return fmod(pa + f * (pb + largo - pa), largo)

func _terminar() -> void:
	for i in mini(_vivo.size() - 1, _jugadores.size()):
		var e: Variant = _vivo[i]
		if e == null:
			continue
		var f: Dictionary = _jugadores[i]
		var n: Node3D = f.get("node")
		var ap: AnimationPlayer = f.get("anim")
		if not is_instance_valid(n):
			continue
		n.global_transform = (e as Array)[0]
		if is_instance_valid(ap):
			if String(e[1]) != "" and ap.has_animation(String(e[1])):
				ap.play(String(e[1]), 0.0)
				ap.seek(float(e[2]), true)
			ap.speed_scale = float(e[3])
	if is_instance_valid(_balon) and not _vivo.is_empty():
		_balon.global_transform = _vivo[-1]
	for c: Camera3D in _cams.values():
		if is_instance_valid(c):
			c.queue_free()
	_cams.clear()
	if is_instance_valid(_cam_previa):
		_cam_previa.current = true
	reproduciendo = false
	plano_actual = ""
	_espera = 0.0
	_salida = -1.0
	## Lo grabado durante la jugada ya se repitió: se empieza a grabar de cero.
	_cuadros.clear()
	terminada.emit()

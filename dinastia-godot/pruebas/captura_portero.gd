extends Node
## EL PORTERO DE CERCA (14-10-2026): partido con el motor real y una cámara
## detrás de un arco, mirando al portero. Imprime su colocación y su gesto.
## Salida: pruebas/capturas/portero.png (hoja de 12 fotogramas).
##   xvfb-run -a godot --path . --resolution 1280x720 res://pruebas/captura_portero.tscn
var _n := 0
var _vista: VistaEstadio
var _fotos: Array[Image] = []
var _cam: Camera3D

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _process(_d: float) -> void:
	_n += 1
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
	var motor: MotorJugable = _vista.get("_motor")
	if motor == null:
		return
	## El portero que tiene el balón más cerca.
	var gk: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if bool(p["por"]) and (gk.is_empty() or motor.pos(p).distance_to(motor.balon.position) < motor.pos(gk).distance_to(motor.balon.position)):
			gk = p
	if _cam == null:
		_cam = Camera3D.new()
		_cam.fov = 50
		add_child(_cam)
	var g := motor.pos(gk)
	var z_arco := signf(g.z) * 52.5
	_cam.position = Vector3(g.x * 0.4 + 6.0, 4.0, z_arco + signf(z_arco) * 9.0)
	_cam.look_at(g.lerp(motor.balon.position, 0.25) + Vector3(0, 0.8, 0))
	_cam.current = true
	for k in 4:
		motor.paso(1.0 / 60.0)
	if _n >= 40 and _n % 10 == 0 and _fotos.size() < 12:
		print("PORTERO %s pos (%.1f, %.1f) balón (%.1f, %.1f) anim %s vel %.1f" % ["L" if bool(gk["es_local"]) else "V",
			g.x, g.z, motor.balon.position.x, motor.balon.position.z, String(gk.get("anim_actual", "")), (gk["vel"] as Vector3).length()])
		var img := get_viewport().get_texture().get_image()
		img.resize(640, 360)
		_fotos.append(img)
	if _fotos.size() >= 12:
		var hoja := Image.create(640 * 3, 360 * 4, false, _fotos[0].get_format())
		for k in _fotos.size():
			hoja.blit_rect(_fotos[k], Rect2i(0, 0, 640, 360), Vector2i((k % 3) * 640, (k / 3) * 360))
		hoja.save_png("res://pruebas/capturas/portero.png")
		print("HOJA guardada")
		get_tree().quit()

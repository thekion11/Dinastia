extends Node
## LA REPETICIÓN DEL GOL (25-9-2026, plan maestro B3), en un partido real.
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/prueba_repeticion.tscn
var _vista: VistaEstadio
var _n := 0
var _fallos := 0
var _minuto_antes := -1
var _pos_antes: Array = []
var _imgs: Array[Image] = []

func _ok(c: bool, t: String) -> void:
	print(("  ok    " if c else "  FALLO ") + t)
	if not c:
		_fallos += 1

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	_n += 1
	var repe: Repeticion = _vista.get("_repe")
	if _n == 600:
		_ok(repe.segundos_guardados() >= 8.0, "se graban los últimos segundos (%.1f s)" % repe.segundos_guardados())
		_minuto_antes = (_vista.get("partido") as Partido).minuto
		_pos_antes.clear()
		for f: Dictionary in _vista.get("_en_campo"):
			_pos_antes.append((f["node"] as Node3D).global_position)
		_vista.call("_repetir_gol")
		_ok(repe.reproduciendo, "arranca la repetición")
	if repe != null and repe.reproduciendo and _imgs.size() < 2:
		var frac := (repe._rep_t - repe._rep_desde) / maxf(0.01, repe._rep_hasta - repe._rep_desde)
		if frac < (0.25 if _imgs.is_empty() else 0.75):
			return
		var img := get_viewport().get_texture().get_image()
		img.resize(640, 360)
		_imgs.append(img)
	if _n == 600 + 5 and repe.reproduciendo:
		## A mitad de la repetición los jugadores están en OTRO sitio (el pasado).
		var movidos := 0
		var i := 0
		for f: Dictionary in _vista.get("_en_campo"):
			if (f["node"] as Node3D).global_position.distance_to(_pos_antes[i]) > 0.3:
				movidos += 1
			i += 1
		_ok(movidos > 5, "durante la repetición los jugadores vuelven a donde estaban antes (%d movidos)" % movidos)
	if _n > 610 and repe != null and not repe.reproduciendo and not has_meta("fin"):
		set_meta("fin", true)
		_ok((_vista.get("partido") as Partido).minuto == _minuto_antes, "el reloj del partido no avanzó durante la repetición")
		var peor := 0.0
		var i := 0
		for f: Dictionary in _vista.get("_en_campo"):
			peor = maxf(peor, (f["node"] as Node3D).global_position.distance_to(_pos_antes[i]))
			i += 1
		_ok(peor < 0.05, "al terminar cada uno vuelve exactamente a su sitio (desvío máx %.3f m)" % peor)
		if _imgs.size() == 2:
			var hoja := Image.create(1280, 360, false, Image.FORMAT_RGBA8)
			hoja.blit_rect(_imgs[0], Rect2i(0, 0, 640, 360), Vector2i(0, 0))
			hoja.blit_rect(_imgs[1], Rect2i(0, 0, 640, 360), Vector2i(640, 0))
			hoja.save_png("res://pruebas/capturas/repeticion_gol.png")
		print("===== REPETICIÓN: %d fallos =====" % _fallos)
		get_tree().quit()
	if _n > 3000:
		print("no terminó la repetición")
		get_tree().quit()

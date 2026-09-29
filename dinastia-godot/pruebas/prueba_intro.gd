extends Node
## LA PRESENTACIÓN DEL PARTIDO (25-9-2026, plan maestro B3): vuelo de cámara con
## el rótulo; el reloj no corre mientras dura y el partido arranca después.
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/prueba_intro.tscn
var _vista: VistaEstadio
var _n := 0
var _fallos := 0
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
	var intro: IntroPartido = _vista.get("_intro")
	if _n == 3:
		_ok(intro != null and intro.activa, "arranca la presentación")
	if intro != null and intro.activa and _imgs.size() < 2:
		var f := intro._t / IntroPartido.DURACION
		if f >= (0.15 if _imgs.is_empty() else 0.8):
			var img := get_viewport().get_texture().get_image()
			img.resize(640, 360)
			_imgs.append(img)
			_ok((_vista.get("partido") as Partido).minuto == 0, "el reloj no corre durante la presentación")
	if intro != null and not intro.activa and not has_meta("fin"):
		set_meta("fin", _n)
	if has_meta("fin") and _n == int(get_meta("fin")) + 400:
		_ok((_vista.get("partido") as Partido).minuto > 0, "después el partido arranca (minuto %d)" % (_vista.get("partido") as Partido).minuto)
		if _imgs.size() == 2:
			var hoja := Image.create(1280, 360, false, Image.FORMAT_RGBA8)
			hoja.blit_rect(_imgs[0], Rect2i(0, 0, 640, 360), Vector2i(0, 0))
			hoja.blit_rect(_imgs[1], Rect2i(0, 0, 640, 360), Vector2i(640, 0))
			hoja.save_png("res://pruebas/capturas/intro_partido.png")
		print("===== INTRO: %d fallos =====" % _fallos)
		get_tree().quit()
	if _n > 5000:
		print("no terminó")
		get_tree().quit()

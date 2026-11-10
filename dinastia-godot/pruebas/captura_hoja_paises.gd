extends Node
## Hoja de ESCUDO + CAMISETA de todos los clubes de primera de unos países (sesión 6, 10-11): para revisar el aspecto de los clubes nuevos.
##   PAISES=TUR,SWE,CHN RESOLUCION=1280x900 herramientas/captura.sh res://pruebas/captura_hoja_paises.tscn
## Con REAL=0 se usan los nombres de la base pública; con VISITA=1 la camiseta es la del segundo uniforme.
## Fotos: pruebas/capturas/hoja_<país>.png (JPG tras `captura.sh`). Sin pantalla (`--headless`) solo comprueba que se construye.
var _paises: Array[String] = []
var _i := 0
var _n := 0
var _mundo: Mundo
var _hoja: Node2D

func _ready() -> void:
	Datos.usar_base_real(OS.get_environment("REAL") != "0")
	for p in (OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "TUR,SWE,CHN").split(","):
		_paises.append(p.strip_edges())
	_mundo = Mundo.new()
	_mundo.generar(_paises, 4712)
	Datos.tabla("EQUIP_REAL").clear()   ## sin las fotos privadas de equipaciones: lo que ve el build público
	_armar()

func _armar() -> void:
	if _hoja != null:
		_hoja.queue_free()
	_hoja = Node2D.new()
	add_child(_hoja)
	var fondo := ColorRect.new()
	fondo.color = Color("#2a3a30")
	fondo.size = Vector2(1280, 900)
	_hoja.add_child(fondo)
	var club_n := 0
	for l in _mundo.ligas:
		if l.pais != _paises[_i] or l.division() != 1:
			continue
		for c: Club in l.clubes:
			var x := 16.0 + (club_n % 6) * 210.0
			var y := 8.0 + (club_n / 6) * 218.0
			var cam := TextureRect.new()
			cam.texture = Jersey.textura(c, 1 if OS.get_environment("VISITA") == "1" else 0, 256)
			cam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cam.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cam.size = Vector2(112, 112)
			cam.position = Vector2(x, y)
			_hoja.add_child(cam)
			var esc := TextureRect.new()
			esc.texture = Escudo.textura(c, 96)
			esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			esc.size = Vector2(80, 88)
			esc.position = Vector2(x + 118, y + 12)
			_hoja.add_child(esc)
			var t := Label.new()
			t.text = Nombres.limpiar(c.nombre)
			t.position = Vector2(x, y + 118)
			t.add_theme_font_size_override("font_size", 14)
			_hoja.add_child(t)
			club_n += 1
	_n = 0

func _process(_d: float) -> void:
	if _i >= _paises.size():
		return
	_n += 1
	if _n == 16:
		var nombre := "hoja_%s" % _paises[_i]
		if DisplayServer.get_name() != "headless":
			get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)
		print("FOTO ", nombre)
		_i += 1
		if _i >= _paises.size():
			get_tree().quit()
		else:
			_armar()

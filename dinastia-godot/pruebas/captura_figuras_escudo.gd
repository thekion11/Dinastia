extends Node
## Hoja de las figuras y letras del escudo, en grande (orden 15, escudos v2).
var _f := 0

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color("#2a3a30")
	fondo.size = Vector2(1280, 720)
	add_child(fondo)
	var i := 0
	for k: String in EscudoEmblemas.FIGURAS:
		var svg := '<svg width="80" height="80" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg"><rect width="40" height="40" fill="#7a1f2b"/>%s</svg>' % EscudoEmblemas.figura_svg(k, 20.0, 20.0, 36.0, "#ffffff", "#7a1f2b")
		var img := Image.new()
		img.load_svg_from_string(svg, 2.0)
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.position = Vector2(20 + (i % 8) * 155, 10 + (i / 8) * 150)
		add_child(tr)
		var l := Label.new()
		l.text = k
		l.position = tr.position + Vector2(0, 138)
		add_child(l)
		i += 1

func _process(_d: float) -> void:
	_f += 1
	if _f == 8:
		get_viewport().get_texture().get_image().save_png("/tmp/figuras.png")
		get_tree().quit()

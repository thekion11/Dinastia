extends Node
## Hoja de camisetas (12 estampados) y escudos de clubes para revisar su parecido
## con los reales (14-10-2026).
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_camisetas_escudos.tscn
var _f := 0

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI", "ESP", "ENG"], 4711)
	var fondo := ColorRect.new()
	fondo.color = Color("#2a3a30")
	fondo.size = Vector2(1280, 720)
	add_child(fondo)
	var cs: Array = []
	for l in mundo.ligas:
		for c in l.clubes:
			cs.append(c)
	for i in 24:
		var c: Club = cs[i * 3 % cs.size()]
		var tr := TextureRect.new()
		tr.texture = Jersey.textura_procedural(c.color_kit1(), c.color_kit2(), Jersey.KITS[i % 12], 256)
		tr.position = Vector2(20 + (i % 8) * 155, 10 + (i / 8) * 130)
		tr.custom_minimum_size = Vector2(140, 115)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.size = tr.custom_minimum_size
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(tr)
	for i in 24:
		var c: Club = cs[(i * 7 + 1) % cs.size()]
		var tr := TextureRect.new()
		tr.texture = Escudo.textura(c, 160)
		tr.position = Vector2(20 + (i % 8) * 155, 400 + (i / 8) * 110)
		tr.scale = Vector2.ONE * (100.0 / maxf(1.0, tr.texture.get_height()))
		add_child(tr)

func _process(_d: float) -> void:
	_f += 1
	if _f == 10:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/camisetas_escudos.png")
		print("FIN. 0 fallos")
		get_tree().quit()

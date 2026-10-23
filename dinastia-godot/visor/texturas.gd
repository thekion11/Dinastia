class_name Texturas
extends "res://visor/texturas_p1.gd"
## (Parte 2 de 2 de `texturas.gd`.)

# ------------------------------------------------------- manchas y desgaste

## Churretes de agua bajo una ventana. Es una de las cosas que mas "edad" da a
## una fachada, y sale gratis: un plano muy fino pegado al muro con una textura
## de rayas verticales que se desvanece hacia abajo.
static func churrete() -> StandardMaterial3D:
	if _cache.has("chu"):
		return _cache["chu"]
	var img := Image.create(64, 128, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	img.fill(Color(0, 0, 0, 0))
	for x in range(64):
		if rng.randf() > 0.42:
			continue
		var ancho: int = 1 + int(rng.randf() * 2.0)
		var largo: int = 30 + int(rng.randf() * 96.0)
		var fuerza: float = 0.18 + rng.randf() * 0.30
		for y in range(largo):
			## se va apagando hacia abajo, como el agua al secarse
			var a: float = fuerza * (1.0 - float(y) / float(largo))
			for dx in range(ancho):
				if x + dx < 64:
					img.set_pixel(x + dx, y, Color(0.16, 0.15, 0.13, a))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache["chu"] = m
	return m

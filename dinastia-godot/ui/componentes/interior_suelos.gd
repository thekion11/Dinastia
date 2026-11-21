extends RefCounted
## Los dibujos de los suelos del interior (textura de 256x256). Salen de `InteriorInstalacion._textura_suelo`, que los
## llama en el mismo orden y con el mismo generador: el resultado tiene que ser el de antes, byte a byte.

## Dibujo del suelo «parquet» (mismas llamadas al azar que antes, en el mismo orden).
static func _dibujar_parquet(img: Image, rng: RandomNumberGenerator, n: int) -> void:
	## 8 hileras de tablas de largo variable, con veta y junta oscura.
	for fila in 8:
		var x0 := rng.randi_range(0, 120)
		var x := -x0
		while x < n:
			var largo := rng.randi_range(90, 170)
			var tono := rng.randf_range(0.78, 1.0)
			var veta := rng.randf_range(0.0, 6.28)
			for px in range(maxi(x, 0), mini(x + largo, n)):
				for py in range(fila * 32, fila * 32 + 32):
					var v := tono * (0.94 + 0.06 * sin(float(px) * 0.09 + float(py) * 0.6 + veta))
					if py == fila * 32 or px == x:
						v *= 0.55
					img.set_pixel(px, py, Color(v, v, v))
			x += largo

## Dibujo del suelo «losa» (mismas llamadas al azar que antes, en el mismo orden).
static func _dibujar_losa(img: Image, rng: RandomNumberGenerator, n: int) -> void:
	for i in 4:
		for j in 4:
			var tono := rng.randf_range(0.92, 1.0)
			for px in range(i * 64, i * 64 + 64):
				for py in range(j * 64, j * 64 + 64):
					var v := tono * rng.randf_range(0.97, 1.0)
					if px - i * 64 < 2 or py - j * 64 < 2:
						v = 0.62
					img.set_pixel(px, py, Color(v, v, v))

## Dibujo del suelo «moqueta» (mismas llamadas al azar que antes, en el mismo orden).
static func _dibujar_moqueta(img: Image, rng: RandomNumberGenerator, n: int) -> void:
	for px in n:
		for py in n:
			var v := rng.randf_range(0.86, 1.0)
			img.set_pixel(px, py, Color(v, v, v))

## Dibujo del suelo «_» (mismas llamadas al azar que antes, en el mismo orden).
static func _dibujar_ruido(img: Image, rng: RandomNumberGenerator, n: int) -> void:
	var ruido := FastNoiseLite.new()
	ruido.seed = 7
	ruido.frequency = 0.02
	for px in n:
		for py in n:
			var v := 0.88 + ruido.get_noise_2d(float(px), float(py)) * 0.1 + rng.randf_range(-0.03, 0.03)
			img.set_pixel(px, py, Color(v, v, v))

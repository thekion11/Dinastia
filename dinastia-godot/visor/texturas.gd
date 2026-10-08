class_name Texturas
extends RefCounted

## Fabrica de materiales con imperfecciones para la ciudad y las instalaciones.
##
## POR QUE
## Una caja de un solo color plano se lee como plastico por mucha luz que le
## eches: no tiene grano, no tiene desgaste y refleja igual en toda su
## superficie. Lo que hace que un muro parezca hormigon de verdad es que la
## rugosidad CAMBIE de un punto a otro, que haya manchas donde escurre el agua y
## que las esquinas esten sucias.
##
## Se generan con FastNoiseLite y NoiseTexture2D, que son codigo nativo del
## motor: un ruido de 1024x1024 se calcula en milisegundos, mientras que ese
## mismo bucle escrito en GDScript tardaba segundos por textura.
##
## DENSIDAD DE TEXEL
## El objetivo es 512-1024 pixeles por metro de fachada. Con `uv1_scale` se
## repite la textura cada `METRO_POR_TILE` metros, asi que una textura de 1024
## repetida cada 2 m da ~512 px/m. Subir de ahi no se nota en pantalla y si se
## nota en memoria de una integrada.
const TEX := 1024
const METRO_POR_TILE := 2.0

static var _cache := {}

# ------------------------------------------------------------------- ruidos

static func _ruido(tipo: int, frec: float, semilla: int, octavas: int = 4) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = tipo
	n.frequency = frec
	n.seed = semilla
	n.fractal_octaves = octavas
	return n

## Textura de ruido lista para usar como mapa. `normal` la convierte en mapa de
## normales, que es lo que da relieve sin anadir un solo poligono.
static func _tex_ruido(frec: float, semilla: int, normal: bool = false,
		octavas: int = 4, tipo: int = FastNoiseLite.TYPE_SIMPLEX_SMOOTH) -> NoiseTexture2D:
	var t := NoiseTexture2D.new()
	t.width = TEX
	t.height = TEX
	t.seamless = true
	t.as_normal_map = normal
	t.bump_strength = 5.0
	t.noise = _ruido(tipo, frec, semilla, octavas)
	return t

## Ruido para MULTIPLICAR el color (albedo y detalle): de `piso` a blanco.
## 8-10-2026: el ruido crudo va de negro a blanco (media 0,5), y con albedo y
## detalle multiplicados el hormigón quedaba a ~¼ de su tinte: la espalda de
## las gradas y las fachadas salían NEGRAS a mediodía. Así el grano se nota
## pero el tinte manda.
static func _ruido_claro(frec: float, semilla: int, octavas: int, piso: float) -> NoiseTexture2D:
	var t := _tex_ruido(frec, semilla, false, octavas)
	var g := Gradient.new()
	g.set_color(0, Color(piso, piso, piso))
	g.set_color(1, Color.WHITE)
	t.color_ramp = g
	return t

# --------------------------------------------------------------- hormigon

## Hormigon visto: grano fino, rugosidad desigual y un relieve muy suave. Es la
## base de casi todo el complejo.
static func hormigon(tinte: Color, semilla: int = 11) -> StandardMaterial3D:
	var clave := "horm|%s|%d" % [tinte.to_html(false), semilla]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.albedo_texture = _ruido_claro(0.012, semilla, 5, 0.72)
	## El ruido en albedo entra como gris: se mezcla con el tinte en vez de
	## sustituirlo, para que el color del edificio siga mandando.
	m.detail_enabled = true
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_albedo = _ruido_claro(0.05, semilla + 7, 3, 0.8)
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_1
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.03, semilla + 3, true, 4)
	m.normal_scale = 0.55
	## Rugosidad NO uniforme: es lo que impide que la pared entera brille igual.
	m.roughness = 0.92
	m.roughness_texture = _tex_ruido(0.02, semilla + 11, false, 3)
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.metallic = 0.02
	m.metallic_specular = 0.35
	m.uv1_scale = Vector3(1.0 / METRO_POR_TILE, 1.0 / METRO_POR_TILE, 1.0)
	m.uv1_triplanar = true
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[clave] = m
	return m

## Ladrillo visto (plan maestro B6.2, la fachada de estadio inglés). La
## textura cubre 1 m x 1 m: cuatro hiladas de 25 cm con las juntas a matajunta.
## Se pinta en gris y el tinte manda el color, como en `hormigon()`.
static func ladrillo(tinte: Color, semilla: int = 17) -> StandardMaterial3D:
	var clave := "ladr|%s|%d" % [tinte.to_html(false), semilla]
	if _cache.has(clave):
		return _cache[clave]
	const T := 256
	var img := Image.create(T, T, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var hilada := T / 4
	var junta := 5
	for fila in 4:
		var desfase := 0 if fila % 2 == 0 else T / 4
		for n in 3:
			var x0 := (n * T / 2 + desfase) % T
			var tono := rng.randf_range(0.72, 1.0)
			for y in range(fila * hilada, (fila + 1) * hilada):
				for dx in T / 2:
					var x := (x0 + dx) % T
					var en_junta := y - fila * hilada < junta or dx < junta
					var g := 1.35 if en_junta else tono * rng.randf_range(0.93, 1.0)
					img.set_pixel(x, y, Color(g, g, g) if not en_junta else Color(0.95, 0.93, 0.88))
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.05, semilla + 3, true, 3)
	m.normal_scale = 0.35
	m.roughness = 0.9
	m.uv1_scale = Vector3(1.0, 1.0, 1.0)
	m.uv1_triplanar = true
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[clave] = m
	return m

## Asfalto: mas oscuro, mas grano y algo pulido por el paso de los coches.
## `tinte` (17-9-2026): esta funcion existia desde antes de esta sesion sin
## UN SOLO call site en todo el proyecto -escrita y nunca conectada, el mismo
## patron de "quedo escrito, no quedo hecho" que el propio ROADMAP avisa que
## se repite-. Se le agrega tinte parametrizable, mismo criterio que
## `hormigon()`, justo para poder conectarla por fin en `city_builder.gd`.
static func asfalto(tinte: Color = Color(0.17, 0.175, 0.185), semilla: int = 23) -> StandardMaterial3D:
	## REHECHO (26-9-2026, el usuario: "las calles se ven mal, no hagas eso de
	## rayar zonas para ahorrar tiempo"). Antes era ruido suave pegado a la UV
	## de la caja: en una calle de 800 m la textura entera se ESTIRABA a lo
	## largo y se veían rayas. Ahora:
	##   - una imagen de asfalto de verdad: árido claro y oscuro grano a grano,
	##     manchas grandes de rodadura y aceite, y alguna grieta fina;
	##   - se repite en coordenadas del MUNDO (triplanar), un mosaico cada 4 m,
	##     da igual lo larga que sea la calle;
	##   - filtrado anisótropo: en ángulo rasante no se emborrona.
	var clave := "asf|%s|%d" % [tinte.to_html(false), semilla]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1)
	m.albedo_texture = _imagen_asfalto(tinte, semilla)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.35, semilla + 5, true, 2)
	m.normal_scale = 0.45
	m.roughness = 0.82
	m.roughness_texture = _tex_ruido(0.03, semilla + 9, false, 3)
	m.metallic = 0.0
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.25, 0.25, 0.25)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[clave] = m
	return m

## La imagen del asfalto (512 px = 4 m): se genera una vez y se repite sin
## costuras (el ruido es "seamless").
static func _imagen_asfalto(tinte: Color, semilla: int) -> ImageTexture:
	var n := 512
	var grande := _ruido(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.004, semilla, 3)
	var medio := _ruido(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.03, semilla + 1, 3)
	var grieta := _ruido(FastNoiseLite.TYPE_CELLULAR, 0.012, semilla + 2, 1)
	grieta.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var img_g := grande.get_seamless_image(n, n)
	var img_m := medio.get_seamless_image(n, n)
	var img_c := grieta.get_seamless_image(n, n)
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	for y in n:
		for x in n:
			var g := img_g.get_pixel(x, y).r
			var md := img_m.get_pixel(x, y).r
			var v := 0.82 + (g - 0.5) * 0.28 + (md - 0.5) * 0.12
			## Árido: granos claros y oscuros sueltos.
			var r := rng.randf()
			if r < 0.05:
				v += 0.35
			elif r < 0.10:
				v -= 0.22
			else:
				v += (rng.randf() - 0.5) * 0.1
			## Grietas finas (los bordes de las celdas).
			if img_c.get_pixel(x, y).r < 0.035:
				v -= 0.28
			var c := Color(tinte.r * v, tinte.g * v, tinte.b * v)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## Acera de baldosa: losas de 40 cm con su junta, cada una de un tono un poco
## distinto, y el mismo grano fino del hormigón. Triplanar en el mundo.
static func baldosa(tinte: Color = Color(0.72, 0.71, 0.68), semilla: int = 51) -> StandardMaterial3D:
	var clave := "bald|%s|%d" % [tinte.to_html(false), semilla]
	if _cache.has(clave):
		return _cache[clave]
	var n := 256   ## 256 px = 0,8 m (2 x 2 losas)
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var tonos: Array[float] = []
	for i in 4:
		tonos.append(rng.randf_range(0.9, 1.06))
	for y in n:
		for x in n:
			var junta := (x % 128) < 3 or (y % 128) < 3
			var losa := (x / 128) + 2 * (y / 128)
			var v: float = tonos[losa] + (rng.randf() - 0.5) * 0.08
			if junta:
				v = 0.55
			img.set_pixel(x, y, Color(tinte.r * v, tinte.g * v, tinte.b * v))
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.88
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(1.25, 1.25, 1.25)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[clave] = m
	return m

## ENREDADERA (26-9-2026): hojas superpuestas de varios verdes sobre fondo
## oscuro, con alguna flor. Para el muro que tapa la casa del barrio. 256 px =
## 2 m, sin costuras (las hojas que se salen por un borde entran por el otro).
static func enredadera(semilla: int = 71) -> StandardMaterial3D:
	var clave := "enred|%d" % semilla
	if _cache.has(clave):
		return _cache[clave]
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	img.fill(Color(0.07, 0.15, 0.05))
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	for k in 1400:
		var cx := rng.randi() % n
		var cy := rng.randi() % n
		var r: int = rng.randi_range(3, 7)
		var ang := rng.randf() * TAU
		var tono := Color(rng.randf_range(0.08, 0.22), rng.randf_range(0.24, 0.46), rng.randf_range(0.06, 0.14))
		if k > 1300:
			tono = tono.lightened(0.25)
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				## Hoja: elipse girada, más clara hacia el centro.
				var u := dx * cos(ang) + dy * sin(ang)
				var w := -dx * sin(ang) + dy * cos(ang)
				var q := (u * u) / float(r * r) + (w * w) / float(r * r) * 3.0
				if q <= 1.0:
					img.set_pixel(posmod(cx + dx, n), posmod(cy + dy, n), tono.lightened((1.0 - q) * 0.15))
	for k in 40:
		var fx := rng.randi() % n
		var fy := rng.randi() % n
		var flor := Color(0.95, 0.95, 0.9) if k % 3 != 0 else Color(0.7, 0.45, 0.85)
		for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			img.set_pixel(posmod(fx + d.x, n), posmod(fy + d.y, n), flor)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.85
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.5, 0.5, 0.5)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[clave] = m
	return m

## Cesped: verde con manchas grandes (zonas mas secas) y grano fino encima.
## `tinte` (17-9-2026): igual que `asfalto()`, esta funcion no tenia ni un
## call site en todo el proyecto -escrita y nunca conectada- hasta que se
## conecto en `city_builder.gd`. Parametrizable como el resto de la fabrica.
static func cesped(tinte: Color = Color(0.30, 0.46, 0.24), semilla: int = 31) -> StandardMaterial3D:
	var clave := "ces|%s|%d" % [tinte.to_html(false), semilla]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.albedo_texture = _ruido_claro(0.008, semilla, 5, 0.7)
	m.detail_enabled = true
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_albedo = _ruido_claro(0.25, semilla + 4, 2, 0.8)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.2, semilla + 8, true, 3)
	m.normal_scale = 0.7
	m.roughness = 0.97
	## En el mundo, un mosaico cada 16 m: sin estirarse en parques grandes.
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.0625, 0.0625, 0.0625)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[clave] = m
	return m

## Cristal de ventana. `encendida` decide si detras hay luz: en un edificio real
## a media tarde unas habitaciones estan iluminadas y otras no, y esa variedad es
## lo que impide que la fachada parezca un espejo ciego.
static func cristal(encendida: bool, calido: bool = true) -> StandardMaterial3D:
	var clave := "cri|%s|%s" % [encendida, calido]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.06, 0.08, 0.11)
	m.metallic = 0.9
	m.metallic_specular = 0.85
	m.roughness = 0.05
	## Un poco de ruido en la rugosidad = reflejo LIGERAMENTE distorsionado, que
	## es lo que separa un cristal real de un espejo perfecto.
	m.roughness_texture = _tex_ruido(0.4, 61, false, 2)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.6, 67, true, 2)
	m.normal_scale = 0.12
	if encendida:
		m.emission_enabled = true
		m.emission = Color(1.0, 0.82, 0.55) if calido else Color(0.72, 0.86, 1.0)
		m.emission_energy_multiplier = 1.6
	_cache[clave] = m
	return m

## Tela: banderines, el pórtico inflable del túnel, cualquier lona. Sin esto
## eran cajas de color plano -ni un banderín de verdad ni una lona se ven
## como plástico rígido, tienen trama (el tejido en sí) y arrugas (que un
## normal map barato ya sugiere sin animar nada). Rugoso alto por defecto:
## la tela no brilla como el metal ni el cristal de al lado.
static func tela(tinte: Color, rugoso: float = 0.88) -> StandardMaterial3D:
	var clave := "tel|%s|%.2f" % [tinte.to_html(false), rugoso]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	## La trama: ruido fino en el detalle, multiplicado sobre el color -mismo
	## truco que ya usa `cesped()` para la brizna- para que no se vea un
	## plano de color puro incluso de cerca.
	m.detail_enabled = true
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_albedo = _ruido_claro(0.6, 71, 2, 0.75)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.35, 73, true, 3)
	m.normal_scale = 0.4
	m.roughness = rugoso
	m.roughness_texture = _tex_ruido(0.25, 79, false, 2)
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[clave] = m
	return m

## Madera: bancos, tarimas. El grano tiene que ir en UNA dirección marcada
## -por eso `roughness_texture` usa una frecuencia baja en un eje y el normal
## una más alta en el otro, a diferencia de `hormigon()` o `cesped()` donde el
## ruido es igual de random en las dos direcciones-, si no se lee como piedra
## clara, no como tablones.
static func madera(tinte: Color, rugoso: float = 0.65) -> StandardMaterial3D:
	var clave := "mad|%s|%.2f" % [tinte.to_html(false), rugoso]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.detail_enabled = true
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_albedo = _ruido_claro(0.15, 83, 2, 0.75)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.4, 87, true, 3)
	m.normal_scale = 0.3
	m.roughness = rugoso
	m.roughness_texture = _tex_ruido(0.1, 89, false, 2)
	m.metallic = 0.0
	_cache[clave] = m
	return m

## Cuero: sillones y butacas premium. Mismo espiritu que `tela()` pero mas
## brillante y con menos relieve -el cuero se ve, la lona se siente.
static func cuero(tinte: Color, rugoso: float = 0.32) -> StandardMaterial3D:
	var clave := "cue|%s|%.2f" % [tinte.to_html(false), rugoso]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.roughness = rugoso
	m.roughness_texture = _tex_ruido(0.5, 97, false, 2)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.8, 101, true, 2)
	m.normal_scale = 0.18
	m.metallic = 0.05
	m.metallic_specular = 0.4
	_cache[clave] = m
	return m

## Metal pintado, para barandillas, rejillas, farolas y equipos de cubierta.
static func metal(tinte: Color, rugoso: float = 0.35) -> StandardMaterial3D:
	var clave := "met|%s|%.2f" % [tinte.to_html(false), rugoso]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.metallic = 0.75
	m.metallic_specular = 0.6
	m.roughness = rugoso
	m.roughness_texture = _tex_ruido(0.3, 43, false, 2)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.5, 47, true, 2)
	m.normal_scale = 0.2
	_cache[clave] = m
	return m

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

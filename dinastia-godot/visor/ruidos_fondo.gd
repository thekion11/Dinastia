class_name RuidosFondo
extends RefCounted
## LAS TEXTURAS DE RUIDO, EN SEGUNDO PLANO (30-10-2026, rendimiento). La primera vez que se
## juega, `Texturas` tenía que generar ~70 ruidos de 1024×1024 al montar la ciudad o el estadio,
## y Godot calcula la primera imagen de cada `NoiseTexture2D` en el hilo principal: el prólogo se
## quedaba congelado ~20 s. Aquí se generan al arrancar, en hilos, mientras el jugador está en los
## menús, con las MISMAS funciones del motor que usa `NoiseTexture2D` (`get_seamless_image`,
## la rampa de color, `bump_map_to_normal_map`, `generate_mipmaps`), y se dejan en la caché de
## disco de `Texturas`. La lista sale de `datos/ruidos_previstos.json` (las que piden la ciudad y
## el estadio); una que no esté en la lista se genera como siempre cuando se pide.
## Probado byte a byte contra `NoiseTexture2D`: `pruebas/probar_ruidos_fondo.tscn` (en `especiales.sh`).

const LISTA := "res://datos/ruidos_previstos.json"

static var _empezado := false
## Leídas del disco en hilos (`precargar`): clave de disco -> [tarea, Image o null].
static var _leidas := {}
static var _cerrojo := Mutex.new()

## Lanza la generación de las que falten en disco. Una vez por sesión.
static func empezar() -> void:
	if _empezado or not CacheDisco.activa():
		return
	_empezado = true
	Nativo.obj()   ## se mira aquí, en el hilo principal, antes de los hilos
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(LISTA)) if FileAccess.file_exists(LISTA) else null
	if not (d is Dictionary):
		return
	for c: Array in (d as Dictionary).get("claves", []):
		var p := normalizar(c)
		if p.is_empty() or FileAccess.file_exists(CacheDisco._ruta_png(clave_disco(str(p)))):
			continue
		var lut := _lut(float(p[4])) if p[0] is String else PackedByteArray()
		WorkerThreadPool.add_task(_generar.bind(p, lut), true, "Ruido de Texturas")

## La clave con sus tipos (el JSON lo devuelve todo como float).
static func normalizar(c: Array) -> Array:
	if c.size() == 6 and c[0] is String and c[0] == "claro":
		return ["claro", float(c[1]), int(c[2]), int(c[3]), float(c[4]), int(c[5])]
	if c.size() == 6:
		return [float(c[0]), int(c[1]), bool(c[2]), int(c[3]), int(c[4]), int(c[5])]
	return []

## La imagen, como la haría `NoiseTexture2D` con esos parámetros (ver `Texturas._nuevo_ruido`).
static func imagen(p: Array, lut: PackedByteArray = PackedByteArray()) -> Image:
	var claro := p[0] is String
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH if claro else int(p[4])
	n.frequency = float(p[1]) if claro else float(p[0])
	n.seed = int(p[2]) if claro else int(p[1])
	n.fractal_octaves = int(p[3])
	var tam := int(p[5])
	var img := n.get_seamless_image(tam, tam, false, false, 0.1, true)
	if claro:
		img = _con_rampa(img, lut)
	elif bool(p[2]):
		img.bump_map_to_normal_map(5.0)
	img.generate_mipmaps()
	return img

static func _generar(p: Array, lut: PackedByteArray) -> void:
	CacheDisco.guardar_imagen_ya(clave_disco(str(p)), imagen(p, lut))

## La clave de la textura en la caché de disco (la usa también `Texturas`).
static func clave_disco(clave: String) -> String:
	return "ruido|%s|%s" % [clave, Engine.get_version_info()["string"]]

## La rampa de `_ruido_claro` (de `piso` a blanco) para cada uno de los 256 grises, calculada
## con las funciones del motor (`get_pixel`, `get_luminance`, `Gradient.sample`, `set_pixel`):
## los mismos bytes que pone `NoiseTexture2D` al modular con la rampa.
static func _lut(piso: float) -> PackedByteArray:
	var g := Gradient.new()
	g.set_color(0, Color(piso, piso, piso))
	g.set_color(1, Color.WHITE)
	var bytes := PackedByteArray()
	for v in 256:
		bytes.append(v)
	var gris := Image.create_from_data(256, 1, false, Image.FORMAT_L8, bytes)
	var sale := Image.create_empty(256, 1, false, Image.FORMAT_RGBA8)
	for v in 256:
		sale.set_pixel(v, 0, g.sample(gris.get_pixel(v, 0).get_luminance()))
	return sale.get_data()

static func _con_rampa(img: Image, lut: PackedByteArray) -> Image:
	if Nativo.obj() != null:   ## en C++ (mismos bytes, ~100× más rápido)
		return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8,
			Nativo.obj().rampa(img.get_data(), lut))
	return _con_rampa_gd(img, lut)

static func _con_rampa_gd(img: Image, lut: PackedByteArray) -> Image:
	var src := img.get_data()
	var dst := PackedByteArray()
	dst.resize(src.size() * 4)
	for i in src.size():
		var o := int(src[i]) * 4
		dst[i * 4] = lut[o]
		dst[i * 4 + 1] = lut[o + 1]
		dst[i * 4 + 2] = lut[o + 2]
		dst[i * 4 + 3] = lut[o + 3]
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, dst)

## AL EMPEZAR A MONTAR UN ESTADIO O LA CIUDAD: los hilos leen del disco (PNG + mipmaps) las
## texturas previstas mientras el hilo principal construye; `tomar` recoge cada una ya lista.
static func precargar() -> void:
	if not CacheDisco.activa() or not FileAccess.file_exists(LISTA):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(LISTA))
	if not (d is Dictionary):
		return
	for c: Array in (d as Dictionary).get("claves", []):
		var p := normalizar(c)
		if p.is_empty() or Texturas._ruidos.has(str(p)):   ## ya en memoria: no hace falta leerla
			continue
		var clave := clave_disco(str(p))
		_cerrojo.lock()
		var ya := _leidas.has(clave)
		_cerrojo.unlock()
		if ya or not FileAccess.file_exists(CacheDisco._ruta_png(clave)):
			continue
		var t := WorkerThreadPool.add_task(_leer.bind(clave), true, "Leer ruido")
		_cerrojo.lock()
		_leidas[clave] = [t, null]
		_cerrojo.unlock()

## Del disco, con sus mipmaps (los mismos que haría `NoiseTexture2D`), o null.
static func leer(clave: String) -> Image:
	var img := CacheDisco.cargar_imagen(clave)
	if img != null:
		img.generate_mipmaps()
	return img

static func _leer(clave: String) -> void:
	var img := leer(clave)
	_cerrojo.lock()
	if _leidas.has(clave):
		_leidas[clave][1] = img
	_cerrojo.unlock()

## La imagen leída en un hilo (esperándolo si aún no terminó), o null si no se precargó.
static func tomar(clave: String) -> Image:
	_cerrojo.lock()
	var e: Variant = _leidas.get(clave)
	_cerrojo.unlock()
	if e == null:
		return null
	WorkerThreadPool.wait_for_task_completion(int(e[0]))
	_cerrojo.lock()
	var img: Image = _leidas[clave][1]
	_leidas.erase(clave)
	_cerrojo.unlock()
	return img

